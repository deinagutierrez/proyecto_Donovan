from db_conexion import get_connection, close_connection

def main():
    # 1. Consulta para datos_rem (Excluyendo 22, 14 y 52)
    sql_datos_rem = """
        INSERT INTO datos_rem (
            id_estacion, fecha_hora, temperatura, humedad,
            precipitacion, viento_velocidad, viento_direccion
        )
        SELECT
            id_estacion,
            date_trunc('hour', fecha_hora) AS hora,
            AVG(temperatura), AVG(humedad), SUM(precipitacion),
            AVG(viento_velocidad), AVG(viento_direccion)
        FROM datos_rem_temp
        WHERE fecha_hora < date_trunc('hour', NOW())
          AND id_estacion NOT IN (22, 14, 52)
        GROUP BY id_estacion, hora
        ON CONFLICT (id_estacion, fecha_hora) DO NOTHING;
    """

    # 2. Consulta para alertas_viento
    sql_alerta_viento = """
        INSERT INTO alertas_viento (
        id_estacion,
        fecha_hora_alerta,
        velocidad_viento,
        direccion_viento
    )
    SELECT
        id_estacion,
        date_trunc('hour', fecha_hora) AS hora,
        AVG(viento_velocidad) AS avg_velocidad,
        AVG(viento_direccion) AS avg_direccion
    FROM datos_rem_temp
    WHERE fecha_hora < date_trunc('hour', NOW())
    GROUP BY id_estacion, hora
    HAVING
        -- Estación 22
        (
            id_estacion = 22
            AND AVG(viento_direccion) BETWEEN 270 AND 359
            AND MAX(viento_velocidad) >= 6.5
        )
        OR
        -- Estaciones 14 y 52
        (
            id_estacion IN (14, 52)
            AND AVG(viento_direccion) BETWEEN 90 AND 190
            AND MAX(viento_velocidad) >= 4.5
        )
        OR
        -- Estación 26
        (
            id_estacion = 26
            AND AVG(viento_direccion) BETWEEN 135 AND 225
            AND MAX(viento_velocidad) >= 4.5
        )
        ON CONFLICT (id_estacion, fecha_hora_alerta) DO NOTHING;
    """

    conn = None
    cur = None

    try:
        # Se solicita explícitamente el rol de escritura ('writer')
        conn = get_connection(role="writer")
        cur = conn.cursor()

        # Ejecución de las consultas
        cur.execute(sql_datos_rem)
        cur.execute(sql_alerta_viento)
        
        conn.commit()
        print("Proceso completado exitosamente.")
        
    except Exception as e:
        # Revertir transacciones si algo falla
        if conn:
            conn.rollback()
        print(f"Error durante la ejecución: {e}")
        
    finally:
        # Delegamos el cierre seguro de la conexión al módulo
        close_connection(conn, cur)

if __name__ == "__main__":
    main()
