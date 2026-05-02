import os
import psycopg2
from dotenv import load_dotenv

# Cargar .env por si estás ejecutando en desarrollo local (fuera del contenedor)
load_dotenv()

def get_secret(secret_name):
    """
    Intenta leer la contraseña desde el sistema de secretos de Docker/Podman.
    Si no existe (ej. entorno local), busca en las variables de entorno.
    """
    path = f"/run/secrets/{secret_name}"
    if os.path.exists(path):
        with open(path, 'r') as f:
            return f.read().strip()
    return os.getenv(secret_name)

def get_connection(role="reader"):
    """
    Establece la conexión a PostgreSQL según el rol solicitado.
    
    :param role: 'reader' (solo lectura) o 'writer' (escritura).
    :return: Objeto de conexión psycopg2.
    """
    if role == "writer":
        usuario = os.getenv("DB_USER_WRITER")
        password = get_secret("pg_writer_password")
    elif role == "reader":
        usuario = os.getenv("DB_USER_READER")
        password = get_secret("pg_reader_password")
    else:
        raise ValueError("El rol debe ser estrictamente 'reader' o 'writer'")

    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT", "5432"),
            database=os.getenv("DB_NAME"),
            user=usuario,
            password=password
        )
        return conn
    except psycopg2.Error as e:
        print(f"Error crítico al conectar a la BD con el rol '{role}' (Usuario: {usuario}): {e}")
        raise

def close_connection(conn, cursor=None):
    """
    Cierra de forma segura el cursor y la conexión.
    """
    try:
        if cursor is not None and not cursor.closed:
            cursor.close()
        if conn is not None and not conn.closed:
            conn.close()
    except psycopg2.Error as e:
        print(f"Error al cerrar la conexión: {e}")
