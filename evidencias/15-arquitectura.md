# Evidencia 15 — Propuesta de arquitectura de datos protegidos

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividad 15)

## Objetivo

Diseñar una propuesta **conceptual** que separe la información por finalidad y traduzca los principios de privacidad en decisiones técnicas concretas.

## Procedimiento

1. Partí del esquema sugerido (Operación, Analítica, Auditoría).
2. Asigné a cada esquema su finalidad, datos, roles y controles.
3. Añadí controles de acceso, minimización, protección, retención, trazabilidad, eliminación y atención de solicitudes.
4. Incluí ejemplos SQL conceptuales (no se implementa físicamente toda la arquitectura).

## Resultado

### Arquitectura propuesta

```
                         BASE DE DATOS (PostgreSQL 16)
                                     │
        ┌────────────────────────────┼─────────────────────────────┐
        │                            │                             │
        ▼                            ▼                             ▼
  esquema OPERACIÓN            esquema ANALÍTICA             esquema AUDITORÍA
  (datos necesarios)           (datos agregados)             (trazabilidad)
   ├─ clientes (mínima)         ├─ v_analitica_clientes       ├─ bitacora_cambios
   ├─ clientes_soporte          ├─ v_marketing_promos         ├─ bitacora_accesos
   ├─ clientes_fiscal (RFC)     └─ tablas agregadas           ├─ bitacora_exportaciones
   └─ preferencias_privacidad      (sin identificadores)       └─ solicitudes_arco
        │                            ▲                             ▲
        │   proceso ETL/vistas       │                             │
        └── minimiza/agrega ─────────┘      registra ──────────────┘
```

### Esquemas, finalidad y roles

| Esquema | Finalidad | Contenido | Roles con acceso | Restricciones |
|---|---|---|---|---|
| `operacion` | Atender y facturar | Datos identificables necesarios | `atencion` (contacto), `facturacion` (nombre + fiscal) | Cada rol solo ve sus columnas/tablas |
| `analitica` | Estadísticas | Solo vistas/tablas agregadas | `analista` | **Sin** acceso a `operacion` |
| `auditoria` | Trazabilidad y cumplimiento | Bitácoras y solicitudes ARCO | `auditor`, `privacidad` (lectura) | Escritura solo por triggers/proceso; no editable por usuarios |

### Controles propuestos

| Control | Decisión técnica | Ejemplo |
|---|---|---|
| **Acceso** | Mínimo privilegio por rol y por finalidad; sin acceso por defecto | `REVOKE ALL ON SCHEMA operacion FROM PUBLIC;` + `GRANT` puntual |
| **Minimización** | Tablas por finalidad con solo columnas necesarias; vistas con generalización | `clientes_soporte` (4 campos); `v_analitica_clientes` (ciudad + rango de edad) |
| **Protección de información sensible** | Cifrado de RFC (pgcrypto/aplicación); cifrado en reposo y en tránsito (TLS); enmascaramiento en entornos no productivos | RFC visible solo para `facturacion`; copias de dev con datos sintéticos |
| **Retención** | Tabla `politica_retencion` + job de depuración con reporte previo | Soporte: eliminar a los 12 meses de terminada la relación (propuesta) |
| **Trazabilidad** | `pgaudit`/triggers en tablas con datos personales; bitácora de exportaciones; revisión periódica | `bitacora_cambios` con usuario, fecha, campo y folio ARCO |
| **Eliminación** | Procedimiento de cancelación que recorre tablas, copias, exportaciones y terceros; evidencia de cada paso | Checklist de Evidencia 08; lista de supresiones al restaurar respaldos |
| **Atención de solicitudes** | Tabla `solicitudes_arco` (folio, tipo, estado, fecha, responsable) + consultas predefinidas de localización | `SELECT ... WHERE correo = :titular` sobre todas las tablas del catálogo |

### Ejemplo conceptual de implementación

```sql
CREATE SCHEMA operacion;  CREATE SCHEMA analitica;  CREATE SCHEMA auditoria;

-- Roles por función
CREATE ROLE atencion NOLOGIN;    CREATE ROLE facturacion NOLOGIN;
CREATE ROLE analista NOLOGIN;    CREATE ROLE auditor NOLOGIN;

-- Privacidad por defecto
REVOKE ALL ON SCHEMA operacion, analitica, auditoria FROM PUBLIC;

-- Operación: cada rol accede solo a lo que necesita
GRANT USAGE ON SCHEMA operacion TO atencion, facturacion;
GRANT SELECT (id, nombre, correo, telefono) ON operacion.clientes TO atencion;
GRANT SELECT (id, nombre) ON operacion.clientes TO facturacion;
GRANT SELECT ON operacion.clientes_fiscal TO facturacion;

-- Analítica: solo información preparada
GRANT USAGE ON SCHEMA analitica TO analista;
GRANT SELECT ON analitica.v_analitica_clientes TO analista;

-- Auditoría: lectura para auditor; sin UPDATE/DELETE para nadie
GRANT USAGE ON SCHEMA auditoria TO auditor;
GRANT SELECT ON ALL TABLES IN SCHEMA auditoria TO auditor;
```

### Entornos no productivos

- Producción → proceso de **enmascaramiento/sintetización** → Desarrollo/Pruebas.
- Prohibido copiar datos reales a desarrollo; si es indispensable, con autorización y plazo de eliminación.

### Responsabilidades

| Actor | Responsabilidad |
|---|---|
| DBA (custodio) | Implementar esquemas, roles, cifrado, auditoría, respaldos y depuración |
| Propietario de datos | Definir finalidad y quién accede |
| Privacidad / Jurídico | Base jurídica, aviso, plazos legales, atención de ARCO |
| Dirección | Aprobar política y recursos |

## Análisis

Separar por finalidad hace que el **error o la fuga** de un área no exponga todo. Analítica nunca toca datos identificables; soporte no ve RFC; auditoría no puede ser modificada por quienes operan los datos. Los controles técnicos (esquemas, roles, vistas, cifrado, triggers) materializan decisiones administrativas (finalidad, retención, propietario).

## Conclusión

Una arquitectura de datos protegidos nace de responder: *¿por qué tengo el dato, quién lo necesita, para qué, cuánto tiempo y con qué controles?* La propuesta traduce esos principios en esquemas separados, permisos mínimos, minimización, retención, trazabilidad, procedimientos de eliminación y atención de derechos ARCO.
