--
-- PostgreSQL database dump
--


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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: medicion; Type: TABLE; Schema: public; Owner: dba
--


CREATE DATABASE sistema_iot;
ALTER DATABASE sistema_iot OWNER TO dba;
\connect sistema_iot

CREATE TABLE public.medicion (
    id_sensor integer NOT NULL,
    fecha_hora timestamp with time zone NOT NULL,
    valor double precision NOT NULL
);


ALTER TABLE public.medicion OWNER TO dba;

--
-- Name: productor; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.productor (
    id integer NOT NULL,
    cuil_cuit character varying(11) NOT NULL,
    nombre_razon_social character varying(150) NOT NULL,
    telefono character varying(10),
    ubicacion_lat double precision,
    ubicacion_lon double precision,
    CONSTRAINT chk_formato_cuit CHECK (((cuil_cuit)::text ~ '^[0-9]{11}$'::text)),
    CONSTRAINT chk_formato_telefono CHECK (((telefono IS NULL) OR ((telefono)::text ~ '^[0-9]{10}$'::text))),
    CONSTRAINT productor_ubicacion_lat_check CHECK (((ubicacion_lat >= ('-90'::integer)::double precision) AND (ubicacion_lat <= (90)::double precision))),
    CONSTRAINT productor_ubicacion_lon_check CHECK (((ubicacion_lon >= ('-180'::integer)::double precision) AND (ubicacion_lon <= (180)::double precision)))
);


ALTER TABLE public.productor OWNER TO dba;

--
-- Name: productor_id_seq; Type: SEQUENCE; Schema: public; Owner: dba
--

ALTER TABLE public.productor ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.productor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sensor; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.sensor (
    id_sensor integer NOT NULL,
    id_zona integer NOT NULL,
    nombre character varying(100) NOT NULL,
    unidad_medida character varying(20) NOT NULL,
    ubicacion character varying(50),
    descripcion text,
    tipo_ubicacion character varying(10) NOT NULL,
    CONSTRAINT chk_sensor_tipo_ubic CHECK (((tipo_ubicacion)::text = ANY ((ARRAY['INTERNO'::character varying, 'EXTERNO'::character varying])::text[])))
);


ALTER TABLE public.sensor OWNER TO dba;

--
-- Name: sensor_thingspeak; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.sensor_thingspeak (
    channel_id bigint NOT NULL,
    field_number integer NOT NULL,
    id_sensor integer NOT NULL
);


ALTER TABLE public.sensor_thingspeak OWNER TO dba;

--
-- Name: zona; Type: TABLE; Schema: public; Owner: dba
--

CREATE TABLE public.zona (
    id integer NOT NULL,
    id_productor integer NOT NULL,
    numero_zona_local integer NOT NULL,
    nombre_zona character varying(100) NOT NULL,
    tipo_zona character varying(50),
    CONSTRAINT zona_numero_zona_local_check CHECK ((numero_zona_local > 0))
);


ALTER TABLE public.zona OWNER TO dba;

--
-- Name: zona_id_seq; Type: SEQUENCE; Schema: public; Owner: dba
--

ALTER TABLE public.zona ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.zona_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: medicion medicion_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.medicion
    ADD CONSTRAINT medicion_pkey PRIMARY KEY (id_sensor, fecha_hora);


--
-- Name: productor productor_cuil_cuit_key; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.productor
    ADD CONSTRAINT productor_cuil_cuit_key UNIQUE (cuil_cuit);


--
-- Name: productor productor_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.productor
    ADD CONSTRAINT productor_pkey PRIMARY KEY (id);


--
-- Name: sensor sensor_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.sensor
    ADD CONSTRAINT sensor_pkey PRIMARY KEY (id_sensor);


--
-- Name: sensor_thingspeak sensor_thingspeak_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.sensor_thingspeak
    ADD CONSTRAINT sensor_thingspeak_pkey PRIMARY KEY (channel_id, field_number);


--
-- Name: sensor_thingspeak uq_mapping_sensor; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.sensor_thingspeak
    ADD CONSTRAINT uq_mapping_sensor UNIQUE (id_sensor);


--
-- Name: zona uq_zona_productor_numero; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.zona
    ADD CONSTRAINT uq_zona_productor_numero UNIQUE (id_productor, numero_zona_local);


--
-- Name: zona zona_pkey; Type: CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.zona
    ADD CONSTRAINT zona_pkey PRIMARY KEY (id);


--
-- Name: medicion medicion_id_sensor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.medicion
    ADD CONSTRAINT medicion_id_sensor_fkey FOREIGN KEY (id_sensor) REFERENCES public.sensor(id_sensor) ON DELETE CASCADE;


--
-- Name: sensor sensor_id_zona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.sensor
    ADD CONSTRAINT sensor_id_zona_fkey FOREIGN KEY (id_zona) REFERENCES public.zona(id) ON DELETE RESTRICT;


--
-- Name: sensor_thingspeak sensor_thingspeak_id_sensor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.sensor_thingspeak
    ADD CONSTRAINT sensor_thingspeak_id_sensor_fkey FOREIGN KEY (id_sensor) REFERENCES public.sensor(id_sensor) ON DELETE CASCADE;


--
-- Name: zona zona_id_productor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dba
--

ALTER TABLE ONLY public.zona
    ADD CONSTRAINT zona_id_productor_fkey FOREIGN KEY (id_productor) REFERENCES public.productor(id) ON DELETE RESTRICT;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO write_role;
GRANT USAGE ON SCHEMA public TO reader_user;


--
-- Name: TABLE medicion; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.medicion TO write_role;
GRANT SELECT ON TABLE public.medicion TO reader_user;


--
-- Name: TABLE productor; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.productor TO write_role;
GRANT SELECT ON TABLE public.productor TO reader_user;


--
-- Name: SEQUENCE productor_id_seq; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,USAGE ON SEQUENCE public.productor_id_seq TO write_role;


--
-- Name: TABLE sensor; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sensor TO write_role;
GRANT SELECT ON TABLE public.sensor TO reader_user;


--
-- Name: TABLE sensor_thingspeak; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sensor_thingspeak TO write_role;
GRANT SELECT ON TABLE public.sensor_thingspeak TO reader_user;


--
-- Name: TABLE zona; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.zona TO write_role;
GRANT SELECT ON TABLE public.zona TO reader_user;


--
-- Name: SEQUENCE zona_id_seq; Type: ACL; Schema: public; Owner: dba
--

GRANT SELECT,USAGE ON SEQUENCE public.zona_id_seq TO write_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: dba
--

ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO write_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO write_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: dba
--

ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT ON TABLES TO reader_user;
ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO write_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE dba IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO write_role;


--
-- PostgreSQL database dump complete
--


