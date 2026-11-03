-- =====================================================================
-- LAB-03 - Privacidad, cumplimiento y gobierno de los datos
-- Script 01: Escenario base y principio de minimización (Actividades 1-2)
-- Alumno: Jesus Ruben Monzon Garcia | Grupo 4-3
-- Motor: PostgreSQL 16
-- =====================================================================


DROP TABLE IF EXISTS clientes_soporte;
DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    id            BIGSERIAL PRIMARY KEY,
    nombre        VARCHAR(120) NOT NULL,
    correo        VARCHAR(150) NOT NULL,
    telefono      VARCHAR(20),
    rfc           VARCHAR(13),
    edad          INTEGER,
    ciudad        VARCHAR(80),
    codigo_postal VARCHAR(10),
    fecha_alta    DATE NOT NULL DEFAULT CURRENT_DATE
);

INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta) VALUES
('Ana Torres Ruiz',        'ana@example.com',      '6671000001', 'TORA900101AB1', 35, 'Culiacán',    '80000', '2015-03-10'),
('Luis Pérez Soto',        'luis@example.com',     '6671000002', 'PESL850512CD2', 41, 'Culiacán',    '80010', '2016-07-21'),
('María López Vega',       'maria@example.com',    '6691000003', 'LOVM010203EF3', 24, 'Mazatlán',    '82000', '2019-01-15'),
('Carlos Ramírez Díaz',    'carlos@example.com',   '6871000004', 'RADC700815GH4', 55, 'Los Mochis',  '81200', '2014-11-02'),
('Sofía Hernández Cruz',   'sofia@example.com',    '6671000005', 'HECS030909IJ5', 22, 'Culiacán',    '80020', '2021-05-30'),
('Jorge Medina Ortiz',     'jorge@example.com',    '6691000006', 'MEOJ650420KL6', 60, 'Mazatlán',    '82010', '2013-09-09'),
('Lucía Flores Nava',      'lucia@example.com',    '6671000007', 'FONL950714MN7', 30, 'Culiacán',    '80030', '2018-02-18'),
('Pedro Castro Lara',      'pedro@example.com',    '6871000008', 'CALP880101OP8', 38, 'Los Mochis',  '81210', '2017-06-12'),
('Valeria Núñez Ibarra',   'valeria@example.com',  '6671000009', 'NUIV040630QR9', 17, 'Culiacán',    '80040', '2022-08-01'),
('Ricardo Salas Pineda',   'ricardo@example.com',  '6691000010', 'SAPR750825ST0', 50, 'Mazatlán',    '82020', '2012-12-20'),
('Elena Beltrán Rojas',    'elena@example.com',    '6671000011', 'BERE920318UV1', 33, 'Guasave',     '81000', '2020-10-05'),
('Daniel Acosta Mejía',    'daniel@example.com',   '6871000012', 'AOMD991111WX2', 26, 'Guasave',     '81010', '2023-04-27');

SELECT COUNT(*) AS total_clientes FROM clientes;
-- Actividad 2: solicitud de Atención al Cliente (DISEÑO RECHAZADO)
-- La siguiente estructura NO se crea porque copia TODOS los campos
-- de clientes sin justificación de necesidad (viola minimización):
--
--   CREATE TABLE clientes_soporte (
--       id BIGSERIAL, nombre VARCHAR(120), correo VARCHAR(150),
--       telefono VARCHAR(20), rfc VARCHAR(13), edad INTEGER,
--       ciudad VARCHAR(80), codigo_postal VARCHAR(10), fecha_alta DATE
--    );

-- 8.1 Estructura mínima para soporte
-- ---------------------------------------------------------------------
CREATE TABLE clientes_soporte (
    id       BIGINT PRIMARY KEY,
    nombre   VARCHAR(120) NOT NULL,
    correo   VARCHAR(150) NOT NULL,
    telefono VARCHAR(20)
);

INSERT INTO clientes_soporte (id, nombre, correo, telefono)
SELECT id, nombre, correo, telefono
FROM clientes;

SELECT * FROM clientes_soporte;

-- Comprobación de minimización: columnas de cada tabla
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('clientes', 'clientes_soporte')
ORDER BY table_name, ordinal_position;
