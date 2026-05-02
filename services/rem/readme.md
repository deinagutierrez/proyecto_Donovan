Estructura directorios para 
services/rem/
├── Dockerfile
├── requirements.txt 	     # Requerimientos de py
├── crontab		     # configuracion de ejecución por tiempo 
└── scripts/
    ├── __init__.py          # Opcional, ayuda a Python a reconocer el paquete
    ├── database.py          # Contiene get_connection, insertar_dato...
    ├── estaciones.py        # Contiene la constante ESTACIONES e ID 26 (Loyola)
    ├── fetch.py             # Contiene obtener_datos
    ├── cargarDatosREM.py    # Script principal de ingesta
    └── ... (resto de scripts)
