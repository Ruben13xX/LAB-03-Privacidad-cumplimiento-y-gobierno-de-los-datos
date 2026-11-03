# LAB-03 — Privacidad, cumplimiento y gobierno de los datos

| | |
|---|---|
| **Alumno** | Jesus Ruben Monzon Garcia |
| **Grupo y grado** | 4-3 |
| **Materia** | Gestión de Seguridad y Fundamentos de Base de Datos |
| **Unidad** | II. Seguridad, privacidad y control de acceso — Tema 2.5 |
| **Motor** | PostgreSQL 16 |
## Contenido del repositorio

```
lab-03-privacidad-cumplimiento/
├── README.md                       ← este informe
├── sql/
│   ├── 01-minimizacion.sql         ← escenario base + tabla mínima de soporte
│   ├── 02-finalidad.sql            ← consultas agregadas para analítica
│   └── 03-control-acceso.sql       ← rol/vista de analítica, ARCO, bitácora
└── evidencias/
    ├── 01-inventario-datos.md
    ├── 05-finalidad-secundaria.md
    ├── 08-ciclo-vida.md            ← incluye Acceso, Rectificación, Cancelación y Oposición
    ├── 10-retencion.md
    ├── 11-gobierno-datos.md        ← incluye controles técnicos vs. administrativos
    ├── 12-privacidad-diseno.md
    ├── 14-evaluacion-integral.md
    └── 15-arquitectura.md
```

## 1. Introducción

Una base de datos puede estar bien configurada técnicamente y aun así incumplir la privacidad: recopilar datos innecesarios, usarlos para fines no informados, conservarlos indefinidamente o dejar que cualquiera los consulte. Este laboratorio aborda el escenario de **Comercializadora Norte S.A. de C.V.**, cuya tabla `clientes` (`id, nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta`) es usada por Atención al cliente, Facturación, Analítica y el DBA.

El objetivo es traducir principios de privacidad (finalidad, minimización, retención, derechos ARCO) en decisiones concretas de diseño y administración en PostgreSQL, distinguiendo lo que el DBA implementa técnicamente de lo que debe decidir Privacidad, Jurídico o Dirección.

## 2. Inventario de datos

Detalle completo en [`evidencias/01-inventario-datos.md`](evidencias/01-inventario-datos.md).

| Campo | Clasificación | Observación |
|---|---|---|
| `id` | Dato personal indirecto | Identificador interno vinculable a la persona |
| `nombre`, `correo`, `telefono` | Dato personal directo | Contacto e identificación |
| `rfc` | Dato personal directo, **riesgo alto** | Solo Facturación |
| `edad`, `ciudad`, `codigo_postal` | Cuasi-identificadores | Combinados pueden reidentificar; se generalizan para analítica |
| `fecha_alta` | Dato por asociación | Marca el inicio del conteo de retención |

Ninguno es "sensible" en sentido estricto, pero todos son datos personales y `rfc` requiere protección reforzada.

## 3. Finalidades

| Proceso | Datos que necesita | Datos que NO necesita |
|---|---|---|
| Atención al cliente | nombre, correo, teléfono | rfc, edad, ciudad, CP |
| Facturación | nombre, RFC, datos fiscales (CP fiscal) | edad, ciudad |
| Analítica | ciudad, rango de edad, región de CP (agregados) | nombre, correo, teléfono, RFC |
| DBA | Custodia técnica | No tiene derecho de uso sobre los datos solo por ser administrador |

## 4. Minimización

**Actividad 2 — análisis de la tabla `clientes_soporte` propuesta**

1. **¿Todos los campos son necesarios para atención?** No. Solo `id`, `nombre`, `correo` y `telefono`.
2. **¿Por qué soporte necesitaría el RFC?** No lo necesita; es un dato fiscal propio de Facturación y de alto riesgo.
3. **¿Necesita la edad?** No, no es requerida para atender solicitudes.
4. **¿Necesita el código postal?** No, salvo un caso de soporte específico que lo justifique.
5. **Principio relacionado:** **minimización de datos** (y necesidad/proporcionalidad).

**Resultado de implementación:** la tabla `clientes_soporte` tiene 4 columnas (`id, nombre, correo, telefono`) y se cargó desde `clientes` (12 registros ficticios). Se verificó con `information_schema.columns` que `clientes` tiene 9 columnas y `clientes_soporte` solo 4.

**Datos que pueden eliminarse o limitarse:** RFC, edad, CP, ciudad y fecha de alta de la copia de soporte; en analítica, todos los identificadores; en un diseño nuevo, cualquier campo sin finalidad demostrada ([`12-privacidad-diseno.md`](evidencias/12-privacidad-diseno.md)).

**Actividad 3 — ¿Por qué la información agregada es más apropiada para analítica que la tabla completa?** Porque cumple la finalidad (estadísticas) sin identificar a ninguna persona: se reduce el riesgo de reidentificación, de uso indebido y de impacto ante una filtración, y se respeta la limitación de finalidad. Resultado obtenido: Culiacán 5, Mazatlán 3, Los Mochis 2, Guasave 2; y distribución por rangos de edad (18-29: 3; 30-44: 5; 45-59: 2; 60 o más: 1; menor de 18: 1). Además se generalizó el código postal a región (`80xxx`, `81xxx`, `82xxx`).

## 5. Control de acceso

**Implementación** (`sql/03-control-acceso.sql`):

- Rol `analista` (`NOLOGIN`).
- Vista `v_analitica_clientes` con `ciudad` y `rango_edad`.
- `GRANT USAGE ON SCHEMA public` y `GRANT SELECT ON v_analitica_clientes`.
- **No** se otorgó `SELECT` sobre `clientes`.

**Verificación:** `information_schema.role_table_grants` muestra una sola fila para `analista`: `v_analitica_clientes | SELECT`. Con `SET ROLE analista`, la consulta sobre la vista funciona; sobre `clientes` y `clientes_soporte` PostgreSQL responde *permiso denegado* (comprobado dentro del script).

**Preguntas de la Actividad 4**

1. **¿Qué información puede consultar el rol?** Solo `ciudad` y `rango_edad` a través de la vista.
2. **¿Puede consultar directamente `clientes`?** No.
3. **¿Puede obtener nombre, correo y RFC?** No.
4. **Principio de privacidad aplicado:** minimización y limitación de finalidad.
5. **Principio de seguridad aplicado:** mínimo privilegio (y separación de funciones).

Cada permiso se vincula a una función: Atención ve contacto, Facturación ve datos fiscales, Analítica ve datos generalizados, y el DBA administra sin usar los datos. Matriz completa en [`11-gobierno-datos.md`](evidencias/11-gobierno-datos.md).

## 6. Derechos ARCO

Detalle y pruebas en [`08-ciclo-vida.md`](evidencias/08-ciclo-vida.md).

| Derecho | Implicación técnica |
|---|---|
| **Acceso** | Localizar al titular en **todas** las tablas y copias (`clientes`, `clientes_soporte`, etc.); exportar los datos; informar finalidades, destinatarios, plazo y origen |
| **Rectificación** | `UPDATE` controlado, propagado a todas las copias; bitácora con usuario, fecha, valor anterior/nuevo y folio de solicitud |
| **Cancelación** | No basta un `DELETE`: hay respaldos, réplicas, ambientes de prueba, exportaciones, logs y terceros; puede requerirse bloqueo y conservación por obligación legal |
| **Oposición** | No implica borrar todo: se deja de usar el dato para una finalidad (tabla de preferencias, vistas filtradas, listas de exclusión) y se conserva lo necesario para la relación |

## 7. Retención

Detalle en [`10-retencion.md`](evidencias/10-retencion.md). La política "conservar todo indefinidamente" **contradice la minimización**: genera más superficie de ataque, datos obsoletos, costos y complejidad para ARCO.

El periodo debe determinarse a partir de: (1) la finalidad y cuándo termina, (2) obligaciones legales/fiscales, (3) obligaciones contractuales, (4) necesidad operativa real, (5) análisis de riesgo, (6) la acción al terminar (eliminar, bloquear o anonimizar) y (7) quién aprueba. Debe documentarse el fundamento, la fecha de inicio del conteo, el responsable y la evidencia de cada depuración. Los plazos propuestos en la evidencia son **propuestas** sujetas a validación jurídica.

## 8. Gobierno de datos

Matriz completa en [`11-gobierno-datos.md`](evidencias/11-gobierno-datos.md). Resumen:

| Dato | Responsable | Usuarios autorizados | Protección | Acción al finalizar |
|---|---|---|---|---|
| nombre | Atención / Facturación | Atención, Facturación | Permisos por rol, auditoría | Eliminar / bloquear |
| correo | Atención | Atención, Facturación; Marketing solo consentidos | Vista filtrada, bitácora | Eliminar / retirar de listas |
| telefono | Atención | Atención | Permisos, enmascaramiento | Eliminar |
| rfc | Facturación / Contabilidad | Solo Facturación | Cifrado, auditoría | Bloquear y eliminar |
| edad | Analítica | Solo `rango_edad` | Vista con rangos | Conservar agregados |
| ciudad | Analítica | Analítica (vista) | Vista, grupo mínimo | Conservar agregados |
| codigo_postal | Analítica / Facturación | Región (analítica); CP fiscal (facturación) | Generalización | Agregados / bloquear |

**Reparto de responsabilidades** (pregunta 10 de reflexión): el **DBA** implementa y custodia técnicamente; el **propietario de datos** decide finalidad, usuarios y plazos con apoyo de **Privacidad**; el **área jurídica** determina base jurídica, aviso y plazos legales; **Dirección** aprueba políticas y recursos.

## 9. Evaluación integral

Detalle en [`14-evaluacion-integral.md`](evidencias/14-evaluacion-integral.md). Principales riesgos (14 identificados):

1. Analítica accede directamente a `clientes` (mínimo privilegio).
2. Ven datos identificables aunque solo generan estadísticas (minimización).
3. RFC expuesto a quien consulte la tabla.
4. 12 años de datos sin política de retención.
5. Desarrolladores reciben copias completas.
6. Copias de desarrollo con datos reales.
7. Marketing usa correos sin base/consentimiento documentado (finalidad).
8. Finalidad por dato sin documentar.
9. Sin clasificación ni propietarios de datos.
10. Sin trazabilidad ni proceso ARCO.

Los controles propuestos incluyen vistas por finalidad, mínimo privilegio, datos enmascarados en desarrollo, política de retención, catálogo de datos, consentimiento y auditoría. La arquitectura conceptual está en [`15-arquitectura.md`](evidencias/15-arquitectura.md).

## 10. Conclusiones

Aprendí que **seguridad y privacidad son complementarias pero distintas**: la seguridad protege los datos contra accesos indebidos; la privacidad decide si se debe tener ese dato, para qué y por cuánto tiempo. Los controles técnicos (roles, vistas, cifrado, auditoría) solo son efectivos si se apoyan en decisiones de finalidad, retención y responsables. Como DBA, mi responsabilidad es traducir esas decisiones en configuraciones verificables, documentar y escalar a Privacidad, Jurídico o Dirección lo que no me corresponde decidir. Tener acceso administrativo no equivale a tener derecho a usar los datos.

---

## Verificación final (Sección 22 del laboratorio)

- **Seguridad vs. privacidad:** la seguridad protege la confidencialidad, integridad y disponibilidad de la información; la privacidad regula el tratamiento adecuado de los datos personales (qué se recolecta, para qué, quién lo usa, por cuánto tiempo y los derechos del titular).
- **Finalidad:** porque los datos se obtuvieron para propósitos informados; reutilizarlos para otros sin base jurídica o compatibilidad vulnera la confianza del titular y la norma.
- **Minimización:** más datos implican más riesgo, costo, complejidad y obligaciones, sin mayor valor si no hay finalidad.
- **ARCO:** localizar, corregir, bloquear/eliminar y separar finalidades en todas las copias, con trazabilidad.
- **Retención:** conservar sin límite acumula datos obsoletos y amplía el daño de una filtración.
- **Gobierno:** el propietario de datos con Privacidad y Jurídico; el DBA implementa.
- **DBA:** implementa controles técnicos, localiza datos, mantiene trazabilidad y propone mejoras; escala decisiones legales, de finalidad y de política.

## Preguntas de reflexión

1. **¿Una base técnicamente segura cumple con todos los requisitos de privacidad?** No. Puede estar cifrada y con permisos correctos, y aun así recolectar datos innecesarios, usarlos para fines no informados o conservarlos sin límite.
2. **¿Por qué el mínimo privilegio contribuye a la privacidad?** Porque limita quién puede ver cada dato a quienes lo necesitan para su función, reduciendo accesos innecesarios y usos indebidos.
3. **¿Por qué el DBA no debe decidir solo la finalidad?** Porque la finalidad es una decisión de negocio y jurídica (base legal, aviso, consentimiento); el DBA conoce lo técnico pero no es quien define el propósito ni interpreta la ley.
4. **¿Por qué los desarrolladores no deben recibir copias completas de producción?** Porque no necesitan datos reales para desarrollar, y multiplicarlos amplía quién accede y dónde existen.
5. **¿Por qué una copia de desarrollo también es un riesgo?** Porque suele tener menos controles (laptops, repositorios, servidores sin hardening) y contiene los mismos datos personales reales; una filtración allí es una filtración real.
6. **¿Por qué la retención forma parte del ciclo de vida?** Porque todo dato debe tener un fin planificado (eliminar, bloquear o anonimizar) desde que se recolecta; si no se planifica, se acumula.
7. **¿Relación entre privacidad por diseño y diseño de bases de datos?** El diseño del esquema decide qué columnas existen, cómo se separan por finalidad y cuáles son las condiciones por defecto; si no se piensa ahí, luego es difícil corregirlo con permisos.
8. **¿Qué controles técnicos implementaría?** Roles por función, vistas por finalidad, `REVOKE` por defecto, cifrado (columna sensible, reposo y tránsito), enmascaramiento en dev, auditoría/bitácoras, retención automatizada y depuración, respaldos cifrados con expiración.
9. **¿Qué debe conocer el DBA para atender técnicamente un ARCO?** Dónde vive cada dato (catálogo/mapa de datos), cómo identificar al titular, qué copias existen (respaldos, réplicas, dev, exportaciones, terceros), qué datos deben conservarse por obligación, y cómo dejar evidencia de lo realizado.
10. **¿Responsabilidades por rol?** **DBA:** implementar y custodiar controles técnicos, localizar y ejecutar cambios. **Responsable de privacidad:** conducir el proceso ARCO, aviso, evaluación de riesgos. **Área jurídica:** base jurídica, plazos legales, interpretación normativa. **Propietario de datos:** decidir finalidad, usuarios autorizados y retención.