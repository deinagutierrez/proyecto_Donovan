# Librerías nativas de Python
import sys
import logging
from datetime import datetime

# Librerías externas (instaladas por pip)
import requests
from dotenv import load_dotenv
from psycopg2.extras import execute_values

# Librerías externas (instaladas por pip)
#import requests
#from psycopg2.extras import execute_values


# módulo propio
from db_conexion import get_connection, close_connection

load_dotenv()

# --- CONFIGURACIÓN DEL LOG PARA DOCKER ---
logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(name)s - %(message)s'
)
logger = logging.getLogger('IoT_Ingest')

def es_valor_valido(valor: float, unidad: str) -> bool:
    """Filtro de calidad de datos."""
    if unidad in ('°C', 'C'):
        return -30.0 <= valor <= 80.0
    elif unidad in ('%', '%HR'):
        return 0.0 <= valor <= 100.0
    elif unidad in ('lx', 'lux'):
        return 0.0 <= valor <= 200000.0
    return True

def procesar_canales():
    conn = None
    try:
        # Obtenemos la conexión con permisos de escritura
        conn = get_connection(role="writer")
        
        with conn.cursor() as cur:
            # 1. Consultar configuración de sensores
            cur.execute("""
                SELECT st.channel_id, st.field_number, st.id_sensor, s.unidad_medida 
                FROM sensor_thingspeak st
                JOIN sensor s ON st.id_sensor = s.id_sensor
                ORDER BY st.channel_id;
            """)
            mapeos = cur.fetchall()

            if not mapeos:
                logger.warning("No hay mapeos configurados en 'sensor_thingspeak'.")
                return

            canales = {}
            for channel_id, field_number, id_sensor, unidad in mapeos:
                if channel_id not in canales:
                    canales[channel_id] = {}
                canales[channel_id][f'field{field_number}'] = (id_sensor, unidad)

            lote_mediciones = []
            
            # 2. Consultar API y Controlar Datos
            for channel_id, campos_configurados in canales.items():
                url = f"https://thingspeak.mathworks.com/channels/{channel_id}/feed.json"
                try:
                    response = requests.get(url, timeout=10)
                    response.raise_for_status()
                    feeds = response.json().get('feeds', [])
                    
                    for feed in feeds:
                        fecha_str = feed.get('created_at')
                        fecha_hora = datetime.strptime(fecha_str, "%Y-%m-%dT%H:%M:%SZ")

                        for field_key, (id_sensor, unidad) in campos_configurados.items():
                            valor_str = feed.get(field_key)
                            if valor_str is not None:
                                try:
                                    valor_float = float(valor_str)
                                    if es_valor_valido(valor_float, unidad):
                                        lote_mediciones.append((id_sensor, fecha_hora, valor_float))
                                    else:
                                        logger.warning(f"Descartado - Sensor: {id_sensor}, Valor: {valor_float} {unidad}")
                                except ValueError:
                                    logger.error(f"Dato no numérico en Channel {channel_id}, {field_key}: '{valor_str}'")
                except requests.exceptions.RequestException as e:
                    logger.error(f"Error consultando Channel {channel_id}: {e}")

            # 3. Guardar en Base de Datos (Batch Insert)
            if lote_mediciones:
                query = """
                    INSERT INTO medicion (id_sensor, fecha_hora, valor)
                    VALUES %s
                    ON CONFLICT (id_sensor, fecha_hora) DO NOTHING;
                """
                execute_values(cur, query, lote_mediciones)
                conn.commit()  # Fundamental: Confirmar la transacción
                logger.info(f"Ciclo completado. Insertadas {len(lote_mediciones)} mediciones.")
            else:
                logger.info("Ciclo completado. Sin datos nuevos para procesar.")

    except Exception as e:
        if conn:
            conn.rollback() # Revertimos si hay un error SQL
        logger.exception(f"Error general en la ejecución: {e}")
    finally:
        close_connection(conn)

if __name__ == "__main__":
    procesar_canales()
