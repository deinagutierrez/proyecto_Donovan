"""
ingesta_rem.py
Script unificado para la obtención, validación y almacenamiento 
de datos meteorológicos desde la API REM a PostgreSQL.
"""

import logging
import requests
from datetime import datetime
from db_conexion import get_connection, close_connection

# Configuración de Logging
logging.basicConfig(
    filename='guardar_datos_rem.log',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Estaciones a consultar. 
# IMPORTANTE: Recuerda actualizar esta lista con los IDs correctos para 
# reflejar la topología actual (eliminar el ID de Varela, quitar Botija y agregar el ID de Nogoli).
ESTACIONES = [9, 14, 22, 26, 29, 42, 52, 85]

def obtener_datos_estacion(id_estacion: int) -> dict:
    """
    Consulta la API de la REM para obtener los datos de una estación específica.
    """
    url = f"http://wsestaciones.sanluis.gov.ar//Modulos/Datos/Datos.aspx?function=minutos&EstacionId={id_estacion}"
    
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        data = r.json()
        
        if not data.get("Datos"):
            logger.warning(f"La API no devolvió registros para la estación {id_estacion}.")
            return None
            
        return data["Datos"][0]
        
    except requests.exceptions.Timeout:
        logger.error(f"Timeout al consultar la estación {id_estacion}.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error de red al consultar la estación {id_estacion}: {e}")
    except ValueError as e:
        logger.error(f"Error al decodificar el JSON de la estación {id_estacion}: {e}")
    except Exception as e:
        logger.error(f"Error inesperado obteniendo estación {id_estacion}: {e}")
        
    return None

def insertar_estacion(conn, datos):
    """
    Inserta o actualiza los metadatos de la estación en la base de datos.
    """
    sql = """
    INSERT INTO estaciones_rem (id_estacion, nombre, latitud, longitud, altura)
    VALUES (%s, %s, %s, %s, %s)
    ON CONFLICT (id_estacion) DO NOTHING;
    """

    valores = (
        int(datos["id_estacion"]),
        datos["nombre"],
        float(datos["latitud"].replace(",", ".")),
        float(datos["longitud"].replace(",", ".")),
        float(datos["altura"])
    )

    with conn.cursor() as cur:
        cur.execute(sql, valores)

def insertar_dato(conn, datos):
    """
    Valida, limpia e inserta los registros meteorológicos en la base de datos.
    """
    fecha_texto = datos["fecha"]

    try:
        # Formato: '8/4/2026 10:57:00' o '7/4/2026 22:39:00'
        fecha_real = datetime.strptime(fecha_texto, "%d/%m/%Y %H:%M:%S")
    except ValueError:
        # Por si vuelve a venir con AM/PM o para compatibilidad
        fecha_limpia = fecha_texto.replace("a.m.", "AM").replace("p.m.", "PM")
        fecha_real = datetime.strptime(fecha_limpia, "%d/%m/%Y %I:%M:%S %p")

    def obtener_float(clave):
        valor = datos.get(clave)
        if not valor: 
            return None
        try:
            return float(valor.replace(",", "."))
        except ValueError:
            return None

    def obtener_int(clave):
        valor = obtener_float(clave)
        return int(valor) if valor is not None else None

    # Extracción de los valores crudos
    id_estacion = int(datos["id_estacion"])
    temp = obtener_float("temp")
    hum = obtener_int("hh")
    prec = obtener_float("pp")
    vv_kmh = obtener_float("vv") # Llega en km/h
    dv = obtener_int("dvGrados")

    # --- Lógica de Validación y Filtro ---

    # Temperatura: -15 a 50
    if temp is not None:
        if not (-15 <= temp <= 50):
            logger.warning(f"Estación {id_estacion}: Temperatura fuera de rango ({temp}°C). Descartada.")
            temp = None 

    # Humedad: 0 a 100
    if hum is not None and not (0 <= hum <= 100):
        logger.warning(f"Estación {id_estacion}: Humedad fuera de rango ({hum}%). Descartada.")
        hum = None

    # Velocidad del Viento: Convertir y validar (0 a 162 km/h)
    vv_ms = None
    if vv_kmh is not None:
        if 0 <= vv_kmh <= 162: 
            vv_ms = round(vv_kmh / 3.6, 2)
        else:
            logger.warning(f"Estación {id_estacion}: Viento fuera de rango ({vv_kmh} km/h). Descartado.")
            vv_ms = None

    # Dirección Viento: 0 a 360 grados
    if dv is not None and not (0 <= dv <= 360):
        logger.warning(f"Estación {id_estacion}: Dirección del viento inválida ({dv}°). Descartada.")
        dv = None

    # Precipitaciones: 0 a 60 mm
    if prec is not None and not (0 <= prec <= 60):
        logger.warning(f"Estación {id_estacion}: Precipitaciones fuera de rango ({prec} mm). Descartadas.")
        prec = None

    # --- Inserción en la Base de Datos ---
    sql = """
    INSERT INTO datos_rem_temp 
    (id_estacion, fecha_hora, temperatura, humedad, precipitacion, 
     viento_velocidad, viento_direccion)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (id_estacion, fecha_hora) DO NOTHING;
    """
    
    valores = (id_estacion, fecha_real, temp, hum, prec, vv_ms, dv)

    with conn.cursor() as cur:
        cur.execute(sql, valores)

def cargar_datos_estaciones():
    """
    Orquesta la obtención de datos y su inserción en PostgreSQL.
    Gestiona la conexión a la base de datos con rol de escritura.
    """
    logger.info("Iniciando carga de datos desde la API REM...")
    
    conn = None
    cursor = None
    
    try:
        conn = get_connection(role="writer")
        cursor = conn.cursor()
        logger.info("Conexión de escritura a PostgreSQL establecida con éxito.")
    except Exception as e:
        logger.error(f"Abortando proceso: No se pudo establecer conexión a la base de datos. Detalles: {e}")
        return

    try:
        for est_id in ESTACIONES:
            datos = obtener_datos_estacion(est_id)
            
            if not datos:
                continue
                
            try:
                insertar_estacion(conn, datos)
                insertar_dato(conn, datos)
                
                conn.commit()
                logger.info(f"Datos de la estación {est_id} guardados correctamente.")
                
            except Exception as e:
                conn.rollback()
                logger.error(f"Error al guardar la estación {est_id}. Transacción revertida: {e}")

    finally:
        close_connection(conn, cursor)
        logger.info("Conexión a la base de datos cerrada. Proceso finalizado.")

if __name__ == "__main__":
    cargar_datos_estaciones()
