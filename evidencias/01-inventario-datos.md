# Evidencia 01 — Inventario y finalidad de los datos

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Materia:** Gestión de Seguridad y Fundamentos de Base de Datos · **Laboratorio:** LAB-03 (Actividad 1)

## Objetivo

Identificar qué campos de la tabla `clientes` son datos personales, para qué finalidad existe cada uno, si realmente es necesario, quién debe accederlo y cuánto tiempo debe conservarse, justificando cada decisión.

## Procedimiento

1. Revisé las columnas de `clientes` (`id, nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta`).
2. Contrasté cada campo contra los cuatro procesos del escenario: **Atención al cliente**, **Facturación**, **Analítica** y **DBA**.
3. Para cada campo me pregunté: *¿qué proceso lo necesita?, ¿se puede cumplir la finalidad sin él o con una versión menos precisa?*
4. Propuse acceso por rol y una retención **preliminar**. Los plazos son propuestas técnicas que deben ser validadas por el área jurídica/privacidad (el DBA no los decide).

## Resultado

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retención (propuesta) |
|---|---|---|---|---|---|
| `id` | Sí, **indirecto** (seudónimo que identifica un registro y es vinculable con la persona) | Identificador interno para relacionar registros entre tablas | Sí (técnico) | Atención y Facturación vía sistema; Analítica **no** lo recibe; DBA como custodio | Igual que el registro del cliente |
| `nombre` | Sí, **directo** | Identificar al cliente en atención y como receptor en la factura | Sí (Atención y Facturación) | Atención: lectura. Facturación: lectura. Analítica: **sin acceso** | Relación comercial vigente + plazo fiscal/legal aplicable |
| `correo` | Sí, **directo** | Contacto de soporte y envío de comprobantes. Uso promocional solo con base jurídica/consentimiento | Sí (Atención/Facturación) | Atención: lectura/rectificación. Facturación: lectura. Marketing: **no directo**, solo lista autorizada | Relación vigente; al terminar, bloqueo y supresión conforme a política |
| `telefono` | Sí, **directo** | Contacto de soporte | Sí para soporte, **opcional** para el cliente | Atención: lectura. Resto: sin acceso | Relación vigente + periodo corto de atención posterior |
| `rfc` | Sí, **directo** y de **riesgo alto** (identifica fiscalmente a la persona; con homoclave es vinculable a nombre y fecha de nacimiento). No es "sensible" en sentido estricto, pero requiere protección reforzada | Emisión de facturas (obligación fiscal) | Sí **solo** para Facturación; **no** para soporte ni analítica | Solo Facturación (y DBA en custodia sin uso) | Plazo fiscal de conservación (a confirmar con jurídico/contabilidad; referencia: 5 años desde el ejercicio) |
| `edad` | Sí (atributo de una persona identificable; si `edad < 18` implica **menor de edad**, caso de atención especial) | Estadística agregada en rangos | Solo para Analítica, y **en rangos** | Analítica: solo `rango_edad` por vista. Soporte/Facturación: sin acceso | Individual: mientras el cliente esté activo. Agregado/anonimizado: sin límite |
| `ciudad` | Sí, por **combinación** (cuasi-identificador) | Estadística por zona; marketing regional (finalidad secundaria) | Sí para Analítica | Analítica: lectura vía vista | Igual que `edad` |
| `codigo_postal` | Sí, por **combinación** (cuasi-identificador; con edad+ciudad puede reidentificar) | Región geográfica en analítica. En Facturación puede requerirse el CP del domicilio fiscal | Analítica: **solo región** (2 dígitos). Facturación: CP completo si es dato fiscal requerido | Analítica: región generalizada. Facturación: completo | Igual que `edad`; el dato fiscal sigue plazo fiscal |
| `fecha_alta` | Sí, por **asociación** con una persona identificada (metadato de la relación) | Medir antigüedad y **calcular el inicio del plazo de retención** | Sí (control del ciclo de vida) | DBA/privacidad para control de retención; Analítica puede usar antigüedad agregada | Igual que el registro del cliente |

### Datos que se pueden retirar o limitar por rol

- Soporte **no** necesita: `rfc`, `edad`, `ciudad`, `codigo_postal`, `fecha_alta`.
- Analítica **no** necesita: `nombre`, `correo`, `telefono`, `rfc` (ni `id`).
- Ningún proceso del escenario necesita `rfc` fuera de Facturación.

## Análisis

- Casi **todos** los campos son personales; lo importante no es solo si lo son, sino **quién los necesita y para qué**. Un campo "necesario" para un proceso no lo es para los demás.
- `ciudad`, `codigo_postal` y `edad` parecen inofensivos por separado, pero juntos son **cuasi-identificadores**: en una ciudad pequeña, una combinación `(ciudad, rango de edad, CP)` puede apuntar a una sola persona. Por eso para analítica se generalizan (rangos y región de CP).
- El `rfc` es el campo de mayor riesgo del inventario: permite relacionar a la persona con información fiscal. Su acceso se restringe a Facturación.
- La retención depende de **finalidad + obligación legal**, no de que el dato "pueda ser útil".

## Conclusión

El inventario demuestra que el acceso y la conservación deben derivarse de la finalidad de cada proceso. Con esta matriz se pueden justificar la tabla mínima de soporte, la vista de analítica y la restricción de `rfc` a Facturación. Los periodos de retención se dejan como propuesta técnica sujeta a validación jurídica.
