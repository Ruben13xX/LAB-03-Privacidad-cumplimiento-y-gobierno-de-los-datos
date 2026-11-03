# Evidencia 10 — Política de retención

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividad 10)

## Objetivo

Analizar la política propuesta por la empresa: *"Conservar todos los datos de clientes indefinidamente porque podrían ser útiles en el futuro"*, y proponer cómo debe determinarse un periodo de retención.

## Procedimiento

1. Contrasté la política con los principios de minimización, finalidad y ciclo de vida.
2. Identifiqué los riesgos de conservar información innecesaria.
3. Definí qué debe decidir y documentar la organización antes de fijar plazos.
4. Propuse una estructura técnica de retención (tabla de política + proceso de depuración).

## Resultado

### Pregunta 1 — ¿Es compatible con la minimización?

**No.** La minimización exige tratar datos **necesarios para una finalidad determinada**. "Podrían ser útiles en el futuro" no es una finalidad concreta: es una expectativa especulativa. Cuando la finalidad termina (p. ej. el cliente dejó de serlo y pasó el plazo legal), el dato deja de ser necesario y debe eliminarse, bloquearse o anonimizarse.

### Pregunta 2 — Riesgos de conservar información innecesaria

| Riesgo | Explicación |
|---|---|
| Mayor superficie de ataque | Más datos = más impacto si hay una filtración |
| Incumplimiento | Tratar datos sin finalidad vigente contradice los principios de privacidad |
| Datos desactualizados | Contactos, domicilios o correos incorrectos generan errores y envíos indebidos |
| Costo | Almacenamiento, respaldos y réplicas crecen sin beneficio |
| Complejidad ARCO | Hay más copias que localizar y cancelar |
| Uso indebido | Información "olvidada" es reutilizada para finalidades no informadas |
| Más copias en respaldos y pruebas | Cada dato se multiplica en el ciclo de vida |

### Pregunta 3 — Qué debe determinar la organización antes de establecer un periodo

1. **Finalidad** de cada dato y cuándo se cumple.
2. **Obligaciones legales o fiscales** de conservación (las identifica Jurídico/Contabilidad).
3. **Obligaciones contractuales** (garantías, plazos de reclamación).
4. **Necesidad operativa** real (soporte posterior, devoluciones).
5. **Riesgo** de conservar vs. riesgo de eliminar.
6. **Qué ocurre al finalizar:** eliminar, bloquear o anonimizar.
7. **Quién aprueba** la política (propietario de datos + Privacidad + Jurídico).

### Pregunta 4 — Qué documentar para justificar el periodo

- Dato/categoría y finalidad asociada.
- Fundamento del plazo (norma, contrato, necesidad operativa).
- Fecha de inicio del conteo (por eso existe `fecha_alta`, y se necesitaría `fecha_baja`).
- Acción al terminar (eliminar / bloquear / anonimizar).
- Responsable de ejecutar y de aprobar.
- Excepciones (litigios, requerimientos de autoridad).
- Fecha y versión de la política; evidencia de cada depuración ejecutada.

### Propuesta técnica de retención (conceptual)

| Categoría de dato | Plazo propuesto* | Al finalizar |
|---|---|---|
| Datos de contacto de soporte (`nombre`, `correo`, `telefono`) | Relación vigente + periodo corto de atención posterior (p. ej. 12 meses) | Eliminar de `clientes_soporte` |
| Datos fiscales (`rfc`, CP fiscal, comprobantes) | Plazo fiscal aplicable (referencia: 5 años; confirmar con Jurídico/Contabilidad) | Bloquear y luego eliminar |
| Datos para analítica individual (`edad`, `ciudad`, `codigo_postal`) | Mientras el cliente esté activo | Conservar solo agregados/anonimizados |
| Datos para promociones | Mientras exista consentimiento vigente | Eliminar de listas; respetar oposición |
| Bitácoras de acceso/cambios | Según política de auditoría (definir en Unidad III) | Eliminar o anonimizar |

\* Plazos **propuestos**, sujetos a validación de Jurídico/Privacidad.

```sql
-- Idea conceptual: política de retención como dato gobernable
CREATE TABLE politica_retencion (
    categoria       TEXT PRIMARY KEY,
    finalidad       TEXT NOT NULL,
    plazo_meses     INTEGER NOT NULL,
    fundamento      TEXT NOT NULL,
    accion_final    TEXT NOT NULL CHECK (accion_final IN ('eliminar','bloquear','anonimizar')),
    aprobado_por    TEXT NOT NULL,
    version         TEXT NOT NULL
);
```

## Análisis

Con **12 años de datos** y sin política documentada (Actividad 14), la organización probablemente retiene clientes inactivos cuya finalidad ya terminó. La retención no es un detalle de almacenamiento: es una etapa del **ciclo de vida** que debe decidirse desde el diseño. Además, borrar al final exige conocer dónde están las copias (respaldos, réplicas, pruebas).

## Conclusión

La conservación indefinida es incompatible con minimización y limitación de finalidad, y es un riesgo de seguridad, cumplimiento y costo. La retención debe basarse en finalidad y obligaciones legales, documentarse, aprobarse por las áreas responsables y ejecutarse técnicamente con evidencia.
