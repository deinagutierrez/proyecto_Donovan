# Cargar librerías necesarias
library(forecast)
library(dplyr)
library(tidyr)
library(zoo)

# Cargar el módulo de conexión
# (Asume que ambos archivos están en la misma carpeta /app/scripts/)
source("/app/scripts/db_conexion.R")

# ► INICIO DEL CRONÓMETRO ◄
tiempo_inicio <- proc.time()

#-------------------------------------------------------------------------------
# 1. EXTRACCIÓN Y PREPARACIÓN DE DATOS (POSTGRESQL)
#-------------------------------------------------------------------------------
# Llamamos a nuestra función personalizada para obtener la conexión
con <- get_connection(role = "writer")

# Asegurar que la conexión se cierre al terminar o si el script falla
on.exit(dbDisconnect(con))

query <- "
  SELECT id_estacion, fecha_hora, temperatura 
  FROM public.datos_rem 
  WHERE id_estacion IN (42, 9, 85, 29, 26) 
    AND fecha_hora >= NOW() - INTERVAL '2 months'
  ORDER BY fecha_hora ASC;
"
datos_db <- dbGetQuery(con, query)

dbExecute(con, "SET TIME ZONE 'America/Argentina/Buenos_Aires'")
Sys.setenv(TZ = "America/Argentina/Buenos_Aires")

datos_completos <- datos_db %>%
  mutate(estacion_nombre = case_when(
    id_estacion == 85 ~ "temp_donovan",
    id_estacion == 26 ~ "temp_loyola",
    id_estacion == 29 ~ "temp_nogoli",
    id_estacion == 42 ~ "temp_mercedes",
    id_estacion == 9  ~ "temp_desaguadero"
  )) %>%
  select(-id_estacion) %>%
  pivot_wider(names_from = estacion_nombre, values_from = temperatura) %>%
  mutate(fecha_hora = as.POSIXct(format(fecha_hora, "%Y-%m-%d %H:%M:%S"), tz="America/Argentina/Buenos_Aires"))

rango_horas <- seq(min(datos_completos$fecha_hora), 
                   max(datos_completos$fecha_hora), 
                   by = "hour")

datos_limpios <- datos_completos %>%
  complete(fecha_hora = rango_horas) %>%
  mutate(across(-fecha_hora, ~ na.approx(., na.rm = FALSE, rule = 2))) %>%
  arrange(fecha_hora)

#-------------------------------------------------------------------------------
# 2. CONFIGURACIÓN DEL MODELO
#-------------------------------------------------------------------------------
h <- 6
entrenamiento <- datos_limpios

lag_sur   <- 7; lag_norte <- 4; lag_este  <- 6; lag_oeste <- 6

ultima_hora  <- max(entrenamiento$fecha_hora)
horas_futuras <- seq(ultima_hora + 3600, by = "hour", length.out = h)

#-----------------------------------------------------------------------------
# 3. EJECUCIÓN MODELO 1: ARIMA SIMPLE
#-----------------------------------------------------------------------------
tiempo_m1_ini <- proc.time()

serie_m1    <- ts(entrenamiento$temp_donovan, frequency = 24)
fit1        <- auto.arima(serie_m1, seasonal = TRUE)
pronostico1 <- forecast(fit1, h = h)

tiempo_m1 <- proc.time() - tiempo_m1_ini

#-----------------------------------------------------------------------------
# 4. EJECUCIÓN MODELO 3: PONDERADO LAGGED
#-----------------------------------------------------------------------------
tiempo_m3_ini <- proc.time()

sur       <- ts(entrenamiento$temp_loyola,      frequency = 24)
norte     <- ts(entrenamiento$temp_nogoli,      frequency = 24)
este      <- ts(entrenamiento$temp_mercedes,    frequency = 24)
oeste     <- ts(entrenamiento$temp_desaguadero, frequency = 24)
y_donovan <- ts(entrenamiento$temp_donovan,     frequency = 24)

x_hist <- cbind(
  Sur_Lag   = dplyr::lag(as.numeric(sur),   lag_sur),
  Norte_Lag = dplyr::lag(as.numeric(norte), lag_norte),
  Este_Lag  = dplyr::lag(as.numeric(este),  lag_este),
  Oeste_Lag = dplyr::lag(as.numeric(oeste), lag_oeste)
)

df_model3 <- na.omit(data.frame(Temp_Donovan = as.numeric(y_donovan), x_hist))

r_sur   <- abs(cor(df_model3$Temp_Donovan, df_model3$Sur_Lag))
r_norte <- abs(cor(df_model3$Temp_Donovan, df_model3$Norte_Lag))
r_este  <- abs(cor(df_model3$Temp_Donovan, df_model3$Este_Lag))
r_oeste <- abs(cor(df_model3$Temp_Donovan, df_model3$Oeste_Lag))
suma_r  <- r_sur + r_norte + r_este + r_oeste
w <- c(sur = r_sur/suma_r, norte = r_norte/suma_r, este = r_este/suma_r, oeste = r_oeste/suma_r)

xreg_hist <- (df_model3$Sur_Lag * w['sur']) + (df_model3$Norte_Lag * w['norte']) +
  (df_model3$Este_Lag * w['este']) + (df_model3$Oeste_Lag * w['oeste'])

fit3 <- auto.arima(ts(df_model3$Temp_Donovan, frequency = 24), xreg = xreg_hist, seasonal = TRUE)

pron_norte_aux <- stlf(norte, h = h, s.window = "periodic", method = "arima")

f_sur   <- tail(dplyr::lag(c(as.numeric(sur),   rep(NA, h)), lag_sur), h)
f_norte <- tail(dplyr::lag(c(as.numeric(norte), pron_norte_aux$mean), lag_norte), h)
f_este  <- tail(dplyr::lag(c(as.numeric(este),  rep(NA, h)), lag_este), h)
f_oeste <- tail(dplyr::lag(c(as.numeric(oeste), rep(NA, h)), lag_oeste), h)

xreg_futuro <- (f_sur * w['sur']) + (f_norte * w['norte']) + (f_este * w['este']) + (f_oeste * w['oeste'])
pronostico3  <- forecast(fit3, xreg = matrix(xreg_futuro, ncol=1), h = h)

tiempo_m3 <- proc.time() - tiempo_m3_ini

#-----------------------------------------------------------------------------
# 5. GENERACIÓN Y GUARDADO DE RESULTADOS (LOG Y BASE DE DATOS)
#-----------------------------------------------------------------------------
Sys.setenv(TZ = "America/Argentina/Buenos_Aires")
print(Sys.time())

modelo_m1_str <- as.character(fit1)
modelo_m3_str <- gsub("Regression with | errors", "", as.character(fit3))

resultados_log <- data.frame(
  marca_temporal_calculo = trunc(Sys.time(), "hours"),
  modelo_m1              = modelo_m1_str,
  modelo_m3              = modelo_m3_str,
  fecha_hora_objetivo    = horas_futuras,
  temp_estimada_m1       = round(as.numeric(pronostico1$mean), 2),
  temp_estimada_m3       = round(as.numeric(pronostico3$mean), 2)
)

ruta_log <- "predicciones_donovan.log"
write.table(resultados_log, file = ruta_log, append = TRUE, sep = ",", 
            row.names = FALSE, col.names = !file.exists(ruta_log))

fecha_gen_truncada <- as.POSIXct(trunc(Sys.time(), "hours"))
attr(fecha_gen_truncada, "tzone") <- "America/Argentina/Buenos_Aires"

df_db <- data.frame(
  modelo               = as.integer(rep(c(11, 13), each = h)),
  id_estacion          = as.integer(85),
  fecha_generacion     = fecha_gen_truncada,
  fecha_pronostico     = horas_futuras,
  horizonte            = as.integer(rep(1:h, times = 2)),
  temperatura_predicha = c(round(as.numeric(pronostico1$mean), 2),
                           round(as.numeric(pronostico3$mean), 2))
)

tryCatch({
  dbWriteTable(con, "temp_predicciones", df_db, temporary = TRUE, overwrite = TRUE)
  
  query_insert <- "
    INSERT INTO predicciones_temperatura (modelo, id_estacion, fecha_generacion, fecha_pronostico, horizonte, temperatura_predicha)
    SELECT modelo, id_estacion, 
           fecha_generacion::timestamptz,
           fecha_pronostico::timestamptz,
           horizonte, temperatura_predicha
    FROM temp_predicciones
    ON CONFLICT (modelo, id_estacion, fecha_generacion, horizonte) DO NOTHING;
  "
  filas_afectadas <- dbExecute(con, query_insert)
  
  cat(sprintf("Ejecución exitosa: %d predicciones insertadas en BD y guardadas en %s\n", 
              filas_afectadas, ruta_log))
  
}, error = function(e) {
  cat(sprintf("ERROR al insertar en la base de datos: %s\n", e$message))
})

# ► REPORTE FINAL DE TIEMPOS ◄
tiempo_total <- proc.time() - tiempo_inicio

cat("\n========== DURACIÓN DE EJECUCIÓN ==========\n")
cat(sprintf("  Modelo 1 (ARIMA simple)   : %.2f seg\n", tiempo_m1["elapsed"]))
cat(sprintf("  Modelo 3 (Ponderado Lag)  : %.2f seg\n", tiempo_m3["elapsed"]))
cat(sprintf("  TOTAL (todo el script)    : %.2f seg\n", tiempo_total["elapsed"]))
cat("============================================\n")
