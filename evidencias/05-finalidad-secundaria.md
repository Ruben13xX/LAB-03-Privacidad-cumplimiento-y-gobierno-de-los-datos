# Evidencia 05 — Análisis de una finalidad secundaria

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividad 5)

## Objetivo

Analizar si la empresa puede usar los datos de clientes para una nueva finalidad: *"Enviar promociones personalizadas basadas en la edad, ciudad y comportamiento de compra"*, e identificar los controles técnicos que limitarían la información entregada a Marketing.

## Procedimiento

1. Comparé la finalidad nueva contra las finalidades originales del inventario (soporte, facturación, analítica).
2. Evalué si es una **finalidad compatible** o una **finalidad nueva** que requiere base jurídica propia.
3. Determiné qué datos son realmente necesarios (necesidad y proporcionalidad).
4. Propuse mecanismos técnicos para entregar a Marketing solo lo indispensable.

## Resultado

### 1. ¿Tener los datos permite usarlos para cualquier finalidad?

**No.** Que la organización ya posea los datos solo significa que tuvo una razón para obtenerlos, no que pueda reutilizarlos libremente. Por el principio de **limitación de finalidad**, un dato se usa para las finalidades informadas al titular (aviso de privacidad) o para finalidades compatibles. Las promociones personalizadas, con perfilado por comportamiento de compra, **no son evidentemente compatibles** con "atender y facturar", por lo que requieren análisis jurídico y, probablemente, aviso/consentimiento específico.

### 2. Preguntas que la organización debe hacerse antes

| Pregunta | Quién la responde |
|---|---|
| ¿El aviso de privacidad vigente informa esta finalidad? ¿Es una finalidad secundaria? | Privacidad / Jurídico |
| ¿Cuál es la base jurídica (consentimiento u otra aplicable)? | Jurídico |
| ¿Existe un mecanismo para que el titular **se oponga** a esta finalidad sin perder el servicio principal? | Privacidad |
| ¿Es necesario y proporcional el perfilado por comportamiento? | Dirección + Privacidad |
| ¿Qué clientes consintieron y cuáles no? ¿Hay menores de edad en la base? | Privacidad / DBA (dato técnico) |
| ¿Se comparte con terceros (agencias de email, plataformas)? ¿Es una transferencia? | Jurídico |
| ¿Cuánto tiempo se conservará la información de perfilado? | Propietario de datos |
| ¿Se realizó evaluación de riesgo del tratamiento? | Privacidad / Seguridad |

### 3. Datos realmente necesarios

| Dato | ¿Necesario para marketing? | Forma |
|---|---|---|
| `correo` | Sí (canal de envío) | Solo de clientes **con consentimiento / sin oposición** |
| `ciudad` | Sí, para segmentar | Valor directo o por región |
| `edad` | Solo para segmentar | **Rango** de edad, nunca el valor exacto; excluir menores |
| Comportamiento de compra | Sí, si se aprueba el perfilado | Resumen/categoría de compra, no historial detallado |
| `rfc`, `telefono`, `codigo_postal` exacto, `nombre` completo | **No** | No se entregan (el nombre solo si la personalización lo justifica: usar nombre de pila) |

### 4. ¿Marketing necesita acceso directo a `clientes`?

**No.** No debe tener `SELECT` sobre la tabla base. Debe recibir un conjunto preparado y limitado.

### 5. Controles técnicos para limitar la información

```sql
-- 1. Tabla de consentimiento/oposición por finalidad
CREATE TABLE preferencias_privacidad (
    id_cliente      BIGINT PRIMARY KEY,
    acepta_promos   BOOLEAN NOT NULL DEFAULT FALSE,   -- privacidad por defecto
    fecha_decision  TIMESTAMPTZ,
    version_aviso   TEXT
);

-- 2. Vista exclusiva para marketing: solo clientes que aceptaron
CREATE VIEW v_marketing_promos AS
SELECT c.id, c.correo, c.ciudad,
       CASE WHEN c.edad BETWEEN 18 AND 29 THEN '18-29'
            WHEN c.edad BETWEEN 30 AND 44 THEN '30-44'
            WHEN c.edad BETWEEN 45 AND 59 THEN '45-59'
            ELSE '60 o más' END AS rango_edad
FROM clientes c
JOIN preferencias_privacidad p ON p.id_cliente = c.id
WHERE p.acepta_promos = TRUE
  AND c.edad >= 18;

-- 3. Rol dedicado, sin acceso a la tabla base
CREATE ROLE marketing NOLOGIN;
GRANT SELECT ON v_marketing_promos TO marketing;
```

## Análisis

La finalidad secundaria **no es un asunto técnico**: es una decisión de privacidad/jurídica. El DBA aporta la parte técnica: separar quién consentió, entregar solo columnas necesarias, generalizar la edad y evitar que Marketing tenga acceso a la tabla completa. La **privacidad por defecto** se refleja en `acepta_promos DEFAULT FALSE`: sin decisión expresa, no hay uso promocional.

## Conclusión

Ya tener los datos no autoriza a usarlos para cualquier cosa. Para promociones personalizadas hay que validar base jurídica y aviso, minimizar los datos entregados (correo, ciudad, rango de edad), excluir a quienes se opusieron o son menores, y aislar a Marketing con vistas y roles propios en lugar de acceso directo a `clientes`.
