
# Proyecto Donovan: Infraestructura de Monitoreo

Este repositorio contiene la arquitectura de servicios para el sistema de monitoreo y modelado climático del invernadero en la localidad de **Donovan**. La infraestructura está diseñada para la ingesta de datos, almacenamiento persistente y visualización mediante contenedores.

## 🏗️ Arquitectura del Sistema

El sistema se basa en una arquitectura de microservicios orquestada con **Docker Compose**, que incluye:

- **Base de Datos:** PostgreSQL para el almacenamiento de series temporales.
- **Ingesta (REM):** Scripts de Python para la captura y limpieza de datos meteorológicos.
- **Visualización:** Grafana para el monitoreo en tiempo real.
- **Modelado:** Aplicación dedicada para modelos predictivos (SARIMAX/Time-series).

---

## 🛠️ Configuración Inicial

Antes de desplegar la infraestructura, es necesario realizar los siguientes pasos de configuración:

### 1. Gestión de Secretos (Seguridad)

El sistema utiliza Docker Secrets para gestionar credenciales de forma segura. Los archivos deben alojarse en el directorio `/secrets` y **no tienen extensión**.

**Comando para crear secretos:**

```bash
echo -n "tu_password_aqui" > ./secrets/nombre_archivo

#**Antes de levantar Docker**

1. Asegurarse de tener un backup de la BD en el directorio postgres/init
	a. Tener un backup llamado backup.sql (No debe contener el rol de postgres)
2. Configurar las contraseñas en la carpeta *secrets*, reenombre *secrets_ejemplo -> 'secrets'*


#**Manejo de los secretos**
en el directorio secrets van las contraseñas y se crean con el siguiente comando
echo -n "password" > nombre_archivo ##(sin extesión)##

En este directorio deben ir los siguientes archivos:
 - grafana_password
 - pg_dba_password
 - pg_password
 - pg_reader_password
 - pg_writer_password

