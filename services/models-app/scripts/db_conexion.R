# ==============================================================================
# db_conexion.R - GESTOR DE CONEXIONES POSTGRESQL PARA DOCKER
# ==============================================================================
library(DBI)
library(RPostgres)

get_secret <- function(secret_name) {
  # Intenta leer la contraseña desde el sistema de secretos de Docker
  path <- paste0("/run/secrets/", secret_name)
  
  if (file.exists(path)) {
    # Lee la primera línea y elimina espacios extra o saltos de línea
    return(trimws(readLines(path, warn = FALSE)[1]))
  } else {
    # Si no existe (ej. corriendo local), busca en las variables de entorno
    return(Sys.getenv(secret_name))
  }
}

get_connection <- function(role = "reader") {
  # Asigna usuario y contraseña según el rol
  if (role == "writer") {
    usuario <- "writer_user"
    password <- get_secret("pg_writer_password")
  } else if (role == "reader") {
    usuario <- "reader_user"
    password <- get_secret("pg_reader_password")
  } else {
    stop("El rol debe ser estrictamente 'reader' o 'writer'")
  }

  # Intenta establecer la conexión
  con <- tryCatch({
    dbConnect(
      RPostgres::Postgres(),
      dbname   = Sys.getenv("DB_NAME"),
      host     = Sys.getenv("DB_HOST"),
      port     = Sys.getenv("DB_PORT", unset = "5432"),
      user     = usuario,
      password = password
    )
  }, error = function(e) {
    stop(paste("Error crítico al conectar a la BD con el rol", role, ":", e$message))
  })
  
  return(con)
}
