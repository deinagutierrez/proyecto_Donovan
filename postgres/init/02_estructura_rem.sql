--
-- PostgreSQL database dump
--

\restrict VBhgVQzupUsUORVQC49X0X2qlCADf77jGvFJ6knhtBUoGaaZaqJqhQNuh7m7fce

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: db_rem; Type: DATABASE; Schema: -; Owner: dba
--

--CREATE DATABASE db_rem WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


ALTER DATABASE db_rem OWNER TO dba;

\unrestrict VBhgVQzupUsUORVQC49X0X2qlCADf77jGvFJ6knhtBUoGaaZaqJqhQNuh7m7fce
\connect db_rem
\restrict VBhgVQzupUsUORVQC49X0X2qlCADf77jGvFJ6knhtBUoGaaZaqJqhQNuh7m7fce

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: db_rem; Type: DATABASE PROPERTIES; Schema: -; Owner: dba
--

ALTER DATABASE db_rem SET "TimeZone" TO 'America/Argentina/Buenos_Aires';


\unrestrict VBhgVQzupUsUORVQC49X0X2qlCADf77jGvFJ6knhtBUoGaaZaqJqhQNuh7m7fce
\connect db_rem
\restrict VBhgVQzupUsUORVQC49X0X2qlCADf77jGvFJ6knhtBUoGaaZaqJqhQNuh7m7fce

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alertas_viento; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.alertas_viento (
    id_estacion integer CONSTRAINT alertas_viento_id_not_null NOT NULL,
    fecha_hora_alerta timestamp with time zone NOT NULL,
    velocidad_viento numeric(5,2) NOT NULL,
    direccion_viento numeric(5,2) NOT NULL
);


ALTER TABLE public.alertas_viento OWNER TO dba;

--
-- Name: alertas_viento_id_seq; Type: SEQUENCE; Schema: public; Owner: dba
--

CREATE SEQUENCE public.alertas_viento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alertas_viento_id_seq OWNER TO dba;

--
-- Name: alertas_viento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dba
--

ALTER SEQUENCE public.alertas_viento_id_seq OWNED BY public.alertas_viento.id_estacion;


--
-- Name: analogos_temperatura; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.analogos_temperatura (
    id integer NOT NULL,
    id_estacion integer NOT NULL,
    fecha_generacion timestamp with time zone NOT NULL,
    rank_analogo integer NOT NULL,
    fecha_inicio_analogo timestamp with time zone NOT NULL,
    distancia_euclidiana numeric(10,4),
    hora_ventana integer NOT NULL,
    temp_actual numeric(5,2),
    temp_analogo numeric(5,2)
);


ALTER TABLE public.analogos_temperatura OWNER TO dba;

--
-- Name: analogos_temperatura_id_seq; Type: SEQUENCE; Schema: public; Owner: dba
--

CREATE SEQUENCE public.analogos_temperatura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analogos_temperatura_id_seq OWNER TO dba;

--
-- Name: analogos_temperatura_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dba
--

ALTER SEQUENCE public.analogos_temperatura_id_seq OWNED BY public.analogos_temperatura.id;


--
-- Name: datos_rem; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.datos_rem (
    id_estacion integer NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    temperatura numeric(5,2),
    humedad numeric(5,2),
    precipitacion numeric(6,2),
    viento_velocidad numeric(5,2),
    viento_direccion smallint
);


ALTER TABLE public.datos_rem OWNER TO dba;

--
-- Name: datos_rem_temp; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.datos_rem_temp (
    id_estacion integer NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    temperatura numeric(5,2),
    humedad numeric(5,2),
    precipitacion numeric(6,2),
    viento_velocidad numeric(5,2),
    viento_direccion smallint
);


ALTER TABLE public.datos_rem_temp OWNER TO dba;

--
-- Name: estaciones_rem; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.estaciones_rem (
    id_estacion integer NOT NULL,
    nombre character varying(100) NOT NULL,
    latitud numeric(9,6) NOT NULL,
    longitud numeric(9,6) NOT NULL,
    altura numeric(6,2)
);


ALTER TABLE public.estaciones_rem OWNER TO dba;

--
-- Name: predicciones_temperatura; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.predicciones_temperatura (
    id integer NOT NULL,
    modelo smallint NOT NULL,
    id_estacion integer NOT NULL,
    fecha_generacion timestamp with time zone NOT NULL,
    fecha_pronostico timestamp with time zone NOT NULL,
    horizonte smallint NOT NULL,
    temperatura_predicha numeric(5,2) NOT NULL,
    CONSTRAINT check_horizonte CHECK (((horizonte >= 1) AND (horizonte <= 48)))
);


ALTER TABLE public.predicciones_temperatura OWNER TO dba;

--
-- Name: predicciones_temperatura_id_seq; Type: SEQUENCE; Schema: public; Owner: dba
--

CREATE SEQUENCE public.predicciones_temperatura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.predicciones_temperatura_id_seq OWNER TO dba;

--
-- Name: predicciones_temperatura_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dba
--

ALTER SEQUENCE public.predicciones_temperatura_id_seq OWNED BY public.predicciones_temperatura.id;


--
-- Name: analogos_temperatura id; Type: DEFAULT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.analogos_temperatura ALTER COLUMN id SET DEFAULT nextval('public.analogos_temperatura_id_seq'::regclass);


--
-- Name: predicciones_temperatura id; Type: DEFAULT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.predicciones_temperatura ALTER COLUMN id SET DEFAULT nextval('public.predicciones_temperatura_id_seq'::regclass);


--
-- Name: alertas_viento alertas_viento_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.alertas_viento
    ADD CONSTRAINT alertas_viento_pkey PRIMARY KEY (id_estacion, fecha_hora_alerta);


--
-- Name: analogos_temperatura analogos_temperatura_id_estacion_fecha_generacion_rank_anal_key; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.analogos_temperatura
    ADD CONSTRAINT analogos_temperatura_id_estacion_fecha_generacion_rank_anal_key UNIQUE (id_estacion, fecha_generacion, rank_analogo, hora_ventana);


--
-- Name: analogos_temperatura analogos_temperatura_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.analogos_temperatura
    ADD CONSTRAINT analogos_temperatura_pkey PRIMARY KEY (id);


--
-- Name: datos_rem datos_rem_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.datos_rem
    ADD CONSTRAINT datos_rem_pkey PRIMARY KEY (id_estacion, fecha_hora);


--
-- Name: datos_rem_temp datos_rem_temp_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.datos_rem_temp
    ADD CONSTRAINT datos_rem_temp_pkey PRIMARY KEY (id_estacion, fecha_hora);


--
-- Name: estaciones_rem estaciones_rem_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.estaciones_rem
    ADD CONSTRAINT estaciones_rem_pkey PRIMARY KEY (id_estacion);


--
-- Name: predicciones_temperatura predicciones_temperatura_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.predicciones_temperatura
    ADD CONSTRAINT predicciones_temperatura_pkey PRIMARY KEY (id);


--
-- Name: predicciones_temperatura unique_prediccion; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.predicciones_temperatura
    ADD CONSTRAINT unique_prediccion UNIQUE (modelo, id_estacion, fecha_generacion, horizonte);


--
-- Name: analogos_temperatura analogos_temperatura_id_estacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.analogos_temperatura
    ADD CONSTRAINT analogos_temperatura_id_estacion_fkey FOREIGN KEY (id_estacion) REFERENCES public.estaciones_rem(id_estacion);


--
-- Name: datos_rem datos_rem_id_estacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.datos_rem
    ADD CONSTRAINT datos_rem_id_estacion_fkey FOREIGN KEY (id_estacion) REFERENCES public.estaciones_rem(id_estacion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: datos_rem_temp datos_rem_temp_id_estacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.datos_rem_temp
    ADD CONSTRAINT datos_rem_temp_id_estacion_fkey FOREIGN KEY (id_estacion) REFERENCES public.estaciones_rem(id_estacion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: predicciones_temperatura fk_estacion; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.predicciones_temperatura
    ADD CONSTRAINT fk_estacion FOREIGN KEY (id_estacion) REFERENCES public.estaciones_rem(id_estacion);


--
-- Name: DATABASE db_rem; Type: ACL; Schema: -; Owner: dba
--

GRANT CONNECT ON DATABASE db_rem TO read_role;
GRANT CONNECT ON DATABASE db_rem TO write_role;


--
-- Name: TABLE alertas_viento; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT ON TABLE public.alertas_viento TO read_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.alertas_viento TO write_role;


--
-- Name: TABLE analogos_temperatura; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT ON TABLE public.analogos_temperatura TO read_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.analogos_temperatura TO write_role;


--
-- Name: SEQUENCE analogos_temperatura_id_seq; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,USAGE ON SEQUENCE public.analogos_temperatura_id_seq TO writer_user;


--
-- Name: TABLE datos_rem; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.datos_rem TO write_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.datos_rem TO writer_user;
GRANT SELECT ON TABLE public.datos_rem TO reader_user;


--
-- Name: TABLE datos_rem_temp; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT ON TABLE public.datos_rem_temp TO read_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.datos_rem_temp TO write_role;


--
-- Name: TABLE estaciones_rem; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.estaciones_rem TO write_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.estaciones_rem TO writer_user;
GRANT SELECT ON TABLE public.estaciones_rem TO reader_user;


--
-- Name: TABLE predicciones_temperatura; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT ON TABLE public.predicciones_temperatura TO read_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.predicciones_temperatura TO write_role;


--
-- Name: SEQUENCE predicciones_temperatura_id_seq; Type: ACL; Schema: public; Owner: dba
--

GRANT ALL ON SEQUENCE public.predicciones_temperatura_id_seq TO writer_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: dba
--

ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT ON TABLES TO read_role;
ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO write_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT ON TABLES TO read_role;
ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT,INSERT,UPDATE ON TABLES TO write_role;


--
-- PostgreSQL database dump complete
--

\unrestrict VBhgVQzupUsUORVQC49X0X2qlCADf77jGvFJ6knhtBUoGaaZaqJqhQNuh7m7fce

