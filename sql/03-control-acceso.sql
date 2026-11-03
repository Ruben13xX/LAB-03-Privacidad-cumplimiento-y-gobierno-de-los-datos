-- =====================================================================
-- LAB-03 - Privacidad, cumplimiento y gobierno de los datos
-- Script 03: Control de acceso por finalidad y derechos ARCO (Actividades 4, 6, 7)
-- Alumno: Jesus Ruben Monzon Garcia | Grupo 4-3
-- =====================================================================

-- Actividad 4: rol de analítica con acceso solo a información preparada
DROP VIEW IF EXISTS v_analitica_clientes;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analista') THEN
        DROP OWNED BY analista;   -- revoca todos sus privilegios
        DROP ROLE analista;
    END IF;
END $$;

CREATE ROLE analista NOLOGIN;

CREATE VIEW v_analitica_clientes AS
SELECT ciudad,
       CASE
           WHEN edad < 18 THEN 'Menor de 18'
           WHEN edad BETWEEN 18 AND 29 THEN '18-29'
           WHEN edad BETWEEN 30 AND 44 THEN '30-44'
           WHEN edad BETWEEN 45 AND 59 THEN '45-59'
           ELSE '60 o más'
       END AS rango_edad
FROM clientes;

GRANT USAGE ON SCHEMA public TO analista;
GRANT SELECT ON v_analitica_clientes TO analista;
-- NO se otorga: GRANT SELECT ON clientes TO analista;

-- Verificación de privilegios concedidos
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analista';

-- Prueba funcional: lo que el rol SÍ puede hacer
SET ROLE analista;
SELECT rango_edad, COUNT(*) AS cantidad
FROM v_analitica_clientes
GROUP BY rango_edad
ORDER BY rango_edad;
RESET ROLE;

-- Prueba funcional: lo que el rol NO puede hacer
-- Se ejecuta en un bloque que captura el error para que el script continúe.
DO $$
BEGIN
    SET LOCAL ROLE analista;
    PERFORM nombre, correo, rfc FROM clientes LIMIT 1;
    RAISE NOTICE 'FALLO DE SEGURIDAD: analista pudo leer clientes';
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK: analista NO puede leer la tabla clientes (permiso denegado)';
END $$;

DO $$
BEGIN
    SET LOCAL ROLE analista;
    PERFORM correo FROM clientes_soporte LIMIT 1;
    RAISE NOTICE 'FALLO DE SEGURIDAD: analista pudo leer clientes_soporte';
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK: analista NO puede leer clientes_soporte (permiso denegado)';
END $$;

-- Actividad 6.1: Derecho de ACCESO
-- Localiza TODOS los datos del titular (identificado por su correo)
SELECT id, nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta
FROM clientes
WHERE correo = 'ana@example.com';

-- Copias derivadas del mismo titular (hay que buscarlas también):
SELECT * FROM clientes_soporte WHERE correo = 'ana@example.com';


-- Actividad 7: Derecho de RECTIFICACIÓN
BEGIN;
UPDATE clientes
SET correo = 'nuevo-correo@example.com'
WHERE id = 1;

-- Propagar la corrección a la copia de soporte
UPDATE clientes_soporte
SET correo = 'nuevo-correo@example.com'
WHERE id = 1;
COMMIT;

SELECT id, nombre, correo FROM clientes WHERE id = 1;
SELECT id, nombre, correo FROM clientes_soporte WHERE id = 1;

-- Trazabilidad mínima (propuesta para Actividad 7, preguntas 1-3):
-- bitácora de cambios sobre datos personales.
DROP TABLE IF EXISTS bitacora_cambios_clientes;
CREATE TABLE bitacora_cambios_clientes (
    id_bitacora    BIGSERIAL PRIMARY KEY,
    fecha_cambio   TIMESTAMPTZ NOT NULL DEFAULT now(),
    usuario_bd     TEXT        NOT NULL DEFAULT current_user,
    id_cliente     BIGINT      NOT NULL,
    campo          TEXT        NOT NULL,
    valor_anterior TEXT,
    valor_nuevo    TEXT,
    referencia_solicitud TEXT  -- folio de la solicitud ARCO autorizada
);

-- Registro manual del cambio de correo realizado arriba
INSERT INTO bitacora_cambios_clientes
    (id_cliente, campo, valor_anterior, valor_nuevo, referencia_solicitud)
VALUES
    (1, 'correo', 'ana@example.com', 'nuevo-correo@example.com', 'ARCO-2026-0001');

SELECT * FROM bitacora_cambios_clientes;

