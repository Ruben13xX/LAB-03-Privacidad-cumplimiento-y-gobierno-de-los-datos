# Evidencia 14 — Evaluación integral de privacidad

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividad 14)

## Objetivo

Identificar al menos 10 problemas de privacidad y cumplimiento en el escenario de 50,000 clientes, indicando el principio afectado, el riesgo y el control propuesto.

## Procedimiento

1. Leí cada afirmación del escenario como un posible hallazgo.
2. Relacioné cada hallazgo con un principio (minimización, finalidad, retención, mínimo privilegio, etc.).
3. Describí el riesgo concreto y propuse un control técnico y/o administrativo.
4. Prioricé: **Alto** (exposición directa de datos personales), **Medio**, **Bajo**.

## Resultado

| # | Problema | Principio afectado | Riesgo | Control propuesto | Prioridad |
|---|---|---|---|---|---|
| 1 | Todo el área de analítica consulta directamente la tabla `clientes` | Mínimo privilegio; minimización | Acceso a nombre, correo, teléfono y RFC sin necesidad; exposición interna | Rol `analista` solo con `SELECT` sobre `v_analitica_clientes`; revocar acceso a la tabla base | Alto |
| 2 | Analítica solo genera estadísticas mensuales pero ve datos identificables | Minimización; proporcionalidad | Reidentificación y uso indebido; filtración de 50,000 registros | Vista con ciudad, rango de edad y región de CP; consultas agregadas con tamaño mínimo de grupo | Alto |
| 3 | La tabla contiene RFC accesible a quien consulte `clientes` | Necesidad; confidencialidad | Fraude de identidad y vinculación fiscal | Mover RFC a tabla fiscal con acceso solo para Facturación; cifrar columna | Alto |
| 4 | Datos conservados por 12 años sin política de retención | Retención / limitación del plazo | Datos de clientes inactivos expuestos; incumplimiento; costo | Política de retención documentada, aprobada y con depuración periódica | Alto |
| 5 | Desarrolladores reciben copias completas de la base | Mínimo privilegio; finalidad | Muchas personas con acceso a datos reales | Entregar solo copias **sintéticas o enmascaradas** | Alto |
| 6 | Las copias de desarrollo contienen datos reales | Minimización; seguridad del ciclo de vida | Entornos con menos controles: filtración, repositorios, laptops | Enmascaramiento/anonimización antes de salir de producción; prohibir datos reales en dev | Alto |
| 7 | Marketing usa correos sin base ni consentimiento documentado | Limitación de finalidad; consentimiento; aviso de privacidad | Uso para finalidad no informada; sanciones; quejas de titulares | Validar aviso y base jurídica; tabla de consentimiento; vista solo para consentidos | Alto |
| 8 | No hay documentación de la finalidad de cada dato | Finalidad; gobierno de datos | No se puede justificar el tratamiento ni responder ARCO | Catálogo de datos con finalidad, propietario, clasificación y retención | Medio |
| 9 | No hay clasificación de datos | Clasificación; protección proporcional | Se protege igual (o nada) datos de distinto riesgo | Clasificar campos (identificación directa, cuasi-identificadores, alto riesgo) y asignar controles | Medio |
| 10 | No hay propietario/custodio de los datos definido | Responsabilidad (gobierno) | Nadie decide ni responde por el uso | Asignar data owner por dominio y custodio (DBA); RACI documentado | Medio |
| 11 | No hay trazabilidad de consultas ni de exportaciones | Trazabilidad; rendición de cuentas | No se detecta ni investiga un uso indebido | Auditoría (p. ej. `pgaudit`) y bitácora de exportaciones; revisión periódica | Medio |
| 12 | Sin proceso para atender ARCO ni inventario de copias | Derechos de los titulares | Imposible localizar y cancelar datos en todas las copias | Procedimiento ARCO + mapa de datos (respaldos, réplicas, dev, exportaciones, terceros) | Medio |
| 13 | Posibles menores de edad en la base (`edad < 18`) sin tratamiento especial | Protección reforzada; proporcionalidad | Tratamiento sin consideración del interés del menor | Identificar menores; excluirlos de marketing; revisión jurídica | Medio |
| 14 | Respaldos y réplicas con los mismos datos sin control de expiración | Ciclo de vida; retención | Datos "eliminados" siguen existiendo | Retención de respaldos definida; respaldos cifrados; lista de supresiones al restaurar | Medio |

## Análisis

El escenario mezcla fallas **técnicas** (permisos excesivos, copias reales en desarrollo, falta de auditoría) y fallas **administrativas** (sin retención, sin finalidades, sin propietario, sin ARCO). Aunque la base estuviera perfectamente "hardeneada", seguiría habiendo problemas de privacidad porque se recopilan, usan y conservan datos sin una justificación. Los hallazgos de mayor prioridad son los que exponen identidad real a más personas de las necesarias (1–7).

## Conclusión

Se identificaron 14 problemas. La corrección parte de preguntarse **por qué existe cada dato, quién lo necesita y por cuánto tiempo**, y luego aplicar controles: vistas por finalidad, mínimo privilegio, datos enmascarados en desarrollo, retención documentada, catálogo de datos, consentimiento y trazabilidad.
