-- =====================================================================
-- LAB-03 - Privacidad, cumplimiento y gobierno de los datos
-- Script 02: Separación por finalidad (Actividad 3)
-- Alumno: Jesus Ruben Monzon Garcia | Grupo 4-3
-- =====================================================================

-- 3.1 Clientes por ciudad (información agregada, sin identificar a nadie)
SELECT ciudad, COUNT(*) AS cantidad_clientes
FROM clientes
GROUP BY ciudad
ORDER BY cantidad_clientes DESC;

-- 3.2 Clientes por rango de edad
SELECT CASE
           WHEN edad < 18 THEN 'Menor de 18'
           WHEN edad BETWEEN 18 AND 29 THEN '18-29'
           WHEN edad BETWEEN 30 AND 44 THEN '30-44'
           WHEN edad BETWEEN 45 AND 59 THEN '45-59'
           ELSE '60 o más'
       END AS rango_edad,
       COUNT(*) AS cantidad
FROM clientes
GROUP BY CASE
             WHEN edad < 18 THEN 'Menor de 18'
             WHEN edad BETWEEN 18 AND 29 THEN '18-29'
             WHEN edad BETWEEN 30 AND 44 THEN '30-44'
             WHEN edad BETWEEN 45 AND 59 THEN '45-59'
             ELSE '60 o más'
         END
ORDER BY rango_edad;

-- 3.3 Región del código postal
SELECT LEFT(codigo_postal, 2) || 'xxx' AS region_cp,
       COUNT(*) AS cantidad
FROM clientes
GROUP BY LEFT(codigo_postal, 2)
ORDER BY cantidad DESC;

-- 3.4 Consulta combinada: ciudad + rango de edad + región CP
--     Es el conjunto exacto que Analítica necesita (nada más).
SELECT ciudad,
       CASE
           WHEN edad < 18 THEN 'Menor de 18'
           WHEN edad BETWEEN 18 AND 29 THEN '18-29'
           WHEN edad BETWEEN 30 AND 44 THEN '30-44'
           WHEN edad BETWEEN 45 AND 59 THEN '45-59'
           ELSE '60 o más'
       END AS rango_edad,
       LEFT(codigo_postal, 2) || 'xxx' AS region_cp,
       COUNT(*) AS cantidad
FROM clientes
GROUP BY 1, 2, 3
ORDER BY ciudad, rango_edad;
