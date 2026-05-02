from db_conexion import get_connection, close_connection

def limpiar_datos_temporales():
    """
    Elimina los registros de la tabla datos_rem_temp que tienen
    más de 12 horas de antigüedad para liberar espacio y mantener
    la tabla optimizada.
    """
    sql_delete = """
        DELETE FROM datos_rem_temp
        WHERE fecha_hora < NOW() - INTERVAL '12 hours';
    """

    conn = None
    cur = None

    try:
        # Se requiere rol de escritura ('writer') para ejecutar DELETE
        conn = get_connection(role="writer")
        cur = conn.cursor()

        cur.execute(sql_delete)
        
        # Obtenemos la cantidad de filas afectadas para el registro
        filas_borradas = cur.rowcount
        
        conn.commit()
        print(f"Limpieza completada exitosamente. Registros eliminados: {filas_borradas}")

    except Exception as e:
        # Revertimos la transacción en caso de fallo
        if conn:
            conn.rollback()
        print(f"Error durante la limpieza de datos temporales: {e}")

    finally:
        # Cerramos de manera segura
        close_connection(conn, cur)

if __name__ == "__main__":
    limpiar_datos_temporales()
