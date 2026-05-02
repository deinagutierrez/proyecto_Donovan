# Usamos una versión estable de Python
FROM python:3.11-slim

# Evitar que Python genere archivos .pyc y asegurar que los logs se emitan sin buffer
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Configuración de Supercronic
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64

# 1. Instalar dependencias del sistema
# - libpq-dev y gcc son necesarios para compilar psycopg2
# - curl para descargar supercronic
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libpq-dev \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Descargar e instalar Supercronic
RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" /usr/local/bin/supercronic

# 3. Preparar el directorio de trabajo
WORKDIR /app

# 4. Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copiar el código de la aplicación y la configuración de cron
# Nota: La carpeta 'scripts' debe contener database.py, estaciones.py, fetch.py, etc.
COPY scripts/ ./scripts/
COPY crontab .

# 6. Ejecutar Supercronic
# Apuntamos al archivo crontab definido
CMD ["supercronic", "-json", "/app/crontab"]
