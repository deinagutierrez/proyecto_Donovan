import os
import requests
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Importar el módulo de conexión que ya creaste
from db_conexion import get_connection, get_secret, close_connection

load_dotenv()

# Obtener el token de forma segura leyendo el secreto físico de Docker
TELEGRAM_TOKEN = get_secret("telegram_bot_token")
# El Chat ID no es sensible, se lee de las variables de entorno normales
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

def enviar_telegram(mensaje):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    datos = {"chat_id": TELEGRAM_CHAT_ID, "text": mensaje}
    try:
        requests.post(url, data=datos)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Mensaje enviado a Telegram.")
    except Exception as e:
        print(f"Error enviando Telegram: {e}")

def obtener_ultima_alerta(nombre_archivo):
    try:
        with open(nombre_archivo, "r") as f:
            return datetime.fromisoformat(f.read().strip())
    except FileNotFoundError:
        return datetime.min

def actualizar_ultima_alerta(nombre_archivo):
    with open(nombre_archivo, "w") as f:
        f.write(datetime.now().isoformat())

def procesar_alertas():
    conn = None
    cursor = None
    try:
        # Llamamos a tu conexión maestra con rol de escritura (porque hace un INSERT)
        conn = get_connection(role="writer")
        cursor = conn.cursor()
        ahora = datetime.now()

        # ==========================================
        # PASO PREVIO: INSERT alertas_viento en tiempo real
        # ==========================================
        sql_insert_viento = """
            INSERT INTO alertas_viento (
                id_estacion,
                fecha_hora_alerta,
                velocidad_viento,
                direccion_viento
            )
            SELECT
                id_estacion,
                date_trunc('minute', fecha_hora) AS momento,
                MAX(viento_velocidad),
                AVG(viento_direccion)
            FROM datos_rem_temp
            WHERE fecha_hora >= NOW() - INTERVAL '15 minutes'
            GROUP BY id_estacion, date_trunc('minute', fecha_hora)
            HAVING
                (
                    id_estacion = 22
                    AND AVG(viento_direccion) BETWEEN 270 AND 359
                    AND MAX(viento_velocidad) >= 8
                )
                OR
                (
                    id_estacion IN (14, 52)
                    AND AVG(viento_direccion) BETWEEN 90 AND 190
                    AND MAX(viento_velocidad) >= 8
                )
                OR
                (
                    id_estacion = 26
                    AND AVG(viento_direccion) BETWEEN 135 AND 225
                    AND MAX(viento_velocidad) >= 6
                )
            ON CONFLICT (id_estacion, fecha_hora_alerta) DO NOTHING;
        """
        cursor.execute(sql_insert_viento)
        conn.commit()

        # ==========================================
        # REGLA 1: VIENTO FUERTE (Repite cada 4 horas)
        # ==========================================
        cursor.execute("""
            SELECT COUNT(*) 
            FROM alertas_viento 
            WHERE id_estacion IN (26, 52, 14, 22) 
            AND fecha_hora_alerta >= NOW() - INTERVAL '90 minutes';
        """)
        cantidad_viento = cursor.fetchone()[0]

        if cantidad_viento > 0:
            ultima_vez_viento = obtener_ultima_alerta("estado_viento.txt")
            if ahora - ultima_vez_viento > timedelta(hours=4):
                mensaje = """🚨 🚨 ALERTA DE VIENTO EN DONOVAN

Se registró un viento fuerte en las estaciones cercanas a Donovan

⚠️ Posibles condiciones intensas detectadas en las próximas horas. (1 a 3 horas)

📊 Ver en Grafana para mas informacion:
https://proyectodonovan.unsl.edu.ar/public-dashboards/c1d60cb5716b49e69bede1587a59ad41"""
                enviar_telegram(mensaje)
                actualizar_ultima_alerta("estado_viento.txt")

        # ==========================================
        # REGLA 2: FRIO EXTREMO (Repite cada 24 horas)
        # ==========================================
        cursor.execute("""
            SELECT MIN(t.temperatura_predicha)
            FROM predicciones_temperatura t
            INNER JOIN (
                SELECT modelo, MAX(fecha_generacion) as ultima_fecha
                FROM predicciones_temperatura
                WHERE id_estacion = 85 AND modelo IN (1, 3)
                GROUP BY modelo
            ) ultimos ON t.modelo = ultimos.modelo AND t.fecha_generacion = ultimos.ultima_fecha
            WHERE t.id_estacion = 85;
        """)
        resultado_frio = cursor.fetchone()[0]
        
        if resultado_frio is not None and float(resultado_frio) < 4:
            ultima_vez_frio = obtener_ultima_alerta("estado_frio.txt")
            if ahora - ultima_vez_frio > timedelta(hours=20):
                mensaje = f"""❄️ ALERTA DE FRÍO

Se prevé un descenso significativo de temperatura.

📍 Estación: Donovan
🌡 Pronóstico: ≤ 5°C

⚠️ Riesgo de heladas.

📊 Ver en Grafana para mas informacion:
https://proyectodonovan.unsl.edu.ar/public-dashboards/c1d60cb5716b49e69bede1587a59ad41"""
                enviar_telegram(mensaje)
                actualizar_ultima_alerta("estado_frio.txt")

        # ==========================================
        # REGLA 3: CALOR EXTREMO (Repite cada 24 horas)
        # ==========================================
        cursor.execute("""
            SELECT MAX(t.temperatura_predicha)
            FROM predicciones_temperatura t
            INNER JOIN (
                SELECT modelo, MAX(fecha_generacion) as ultima_fecha
                FROM predicciones_temperatura
                WHERE id_estacion = 85 AND modelo IN (1, 3)
                GROUP BY modelo
            ) ultimos ON t.modelo = ultimos.modelo AND t.fecha_generacion = ultimos.ultima_fecha
            WHERE t.id_estacion = 85;
        """)
        resultado_calor = cursor.fetchone()[0]
        
        if resultado_calor is not None and float(resultado_calor) > 35:
            ultima_vez_calor = obtener_ultima_alerta("estado_calor.txt")
            if ahora - ultima_vez_calor > timedelta(hours=20):
                mensaje = f"""🔥 ALERTA DE CALOR

Se prevé un aumento significativo de temperatura.

📍 Estación: Donovan
🌡 Pronóstico: ≥ 35°C

⚠️ Riesgo de condiciones extremas.

📊 Ver en Grafana para mas informacion:
https://proyectodonovan.unsl.edu.ar/public-dashboards/c1d60cb5716b49e69bede1587a59ad41"""
                enviar_telegram(mensaje)
                actualizar_ultima_alerta("estado_calor.txt")

        print(f"[{datetime.now().strftime('%H:%M:%S')}] Chequeo finalizado con éxito.")

    except Exception as e:
        print(f"Error conectando a la BD o ejecutando query: {e}")
    finally:
        # Asegurar que se cierre la conexión siempre usando tu módulo
        if conn:
            close_connection(conn, cursor)

if __name__ == "__main__":
    procesar_alertas()