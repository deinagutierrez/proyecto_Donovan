# 1. Usamos la imagen oficial de R (versión fija para evitar que se rompa a futuro)
FROM rocker/r-ver:4.3.2

# 2. Instalamos dependencias del sistema operativo (drivers de PostgreSQL y herramientas)
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 3. Instalamos Supercronic (para ejecutar tu modelo cada hora)
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64
ENV SUPERCRONIC=supercronic-linux-amd64
ENV SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b

RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# 4. Instalamos tus librerías de R
# Rocker está configurado para descargar binarios rápidos en lugar de compilar
RUN Rscript -e "install.packages(c('DBI', 'RPostgres', 'forecast', 'dplyr', 'tidyr', 'zoo'))"

# 5. Configuramos el directorio de trabajo
WORKDIR /app

# 6. Copiamos tus scripts y el archivo de cron (los crearemos en el próximo paso)
COPY scripts/ ./scripts/
COPY crontab ./

# 7. Comando de arranque: Iniciar el programador de tareas
CMD ["supercronic", "/app/crontab"]
