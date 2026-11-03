# Evidencia 08 — Ciclo de vida de los datos y derechos ARCO

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividades 6, 7, 8 y 9)

## Objetivo

Identificar las implicaciones técnicas de los derechos ARCO (Acceso, Rectificación, Cancelación y Oposición) sobre la base de datos, con énfasis en que **eliminar un registro de una tabla no elimina toda la información de una persona**.

## Procedimiento

1. **Acceso:** ejecuté una consulta para localizar los datos del titular y analicé qué información adicional debe entregarse.
2. **Rectificación:** actualicé el correo de un cliente (`id = 1`), verifiqué el resultado y propuse trazabilidad.
3. **Cancelación:** **no ejecuté `DELETE`**. Construí el mapa de ubicaciones donde puede existir el dato.
4. **Oposición:** analicé qué cambia técnicamente al oponerse a una finalidad secundaria.

(Scripts en `sql/03-control-acceso.sql`, probados en PostgreSQL 16.)

## Resultado

### 6.1 Acceso

```sql
SELECT id, nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta
FROM clientes WHERE correo = 'ana@example.com';
```

Resultado: 1 fila (`id=1`, Ana Torres Ruiz, ana@example.com, 6671000001, RFC ficticio, 35, Culiacán, 80000, 2015-03-10). La misma búsqueda sobre `clientes_soporte` devolvió también su copia (`id, nombre, correo, telefono`).

**Información adicional que debe proporcionarse** (la define Privacidad/Jurídico; el DBA aporta los datos técnicos):
- finalidades para las que se usan los datos y a qué proceso/área corresponde cada uno;
- origen de los datos y fecha de alta;
- áreas o roles que los consultan, y si se transfirieron a terceros/encargados;
- plazo de conservación;
- copias existentes (soporte, analítica, exportaciones);
- cómo ejercer rectificación, cancelación y oposición.

**Implicaciones técnicas:** el DBA necesita poder **localizar al titular en todas las tablas y copias** (no solo `clientes`), exportar el resultado en formato legible, verificar la identidad del solicitante (proceso administrativo previo) y registrar la atención de la solicitud.

### 7. Rectificación

```sql
UPDATE clientes SET correo = 'nuevo-correo@example.com' WHERE id = 1;
SELECT id, nombre, correo FROM clientes WHERE id = 1;
```

Resultado: `UPDATE 1`; el correo del cliente 1 quedó como `nuevo-correo@example.com`. Se actualizó también la copia de `clientes_soporte` para evitar **datos inconsistentes entre copias**. Se registró el cambio en `bitacora_cambios_clientes`.

1. **¿Cómo comprobar que el cambio fue autorizado?** Con un folio de solicitud ARCO autorizado por Privacidad (`referencia_solicitud`) y la verificación de identidad del titular; el `UPDATE` solo lo ejecuta un rol con permiso, bajo una orden de cambio.
2. **¿Debe registrarse quién lo hizo?** Sí: usuario de BD, fecha/hora, campo, valor anterior/nuevo y folio.
3. **¿Por qué importa la trazabilidad?** Permite demostrar cumplimiento (qué se cambió y por qué), detectar cambios no autorizados y reconstruir incidentes. Se retoma en la Unidad III (auditoría).

### 8. Cancelación — mapa de ubicaciones del dato

```
clientes (tabla principal)
 │
 ├── clientes_soporte ........ copia mínima para atención (existe en este lab)
 ├── v_analitica_clientes .... vista: no almacena datos, hereda la eliminación
 ├── bitacora_cambios ........ contiene correos anteriores/nuevos
 ├── respaldos ............... copias completas con el dato, inmutables
 ├── réplicas ................ copias en tiempo casi real
 ├── ambientes dev/pruebas ... copias de producción con datos reales
 ├── reportes ................ PDF/Excel generados con el dato
 ├── exportaciones ........... CSV a marketing o a contabilidad
 ├── logs de aplicación/BD ... pueden registrar consultas con el correo/RFC
 └── sistemas externos ....... CRM, facturación electrónica, proveedor de correo
```

**Checklist antes de cualquier `DELETE`** (autorizada la solicitud):

| ¿Existe? | Qué implica |
|---|---|
| Otras tablas relacionadas | Revisar llaves foráneas; borrar/anonimizar en cascada o bloquear si hay obligación de conservar |
| Respaldos | No se editan; definir **plazo de expiración**, y si se restaura, volver a aplicar las cancelaciones (lista de supresiones) |
| Réplicas | La eliminación se propaga, pero se verifica |
| Registros de auditoría | Pueden conservarse por obligación; minimizar contenido personal |
| Copias de analítica | Verificar que solo haya datos agregados/anonimizados |
| Archivos exportados | Localizar y eliminar o confirmar su vencimiento |
| Sistemas externos | Notificar al responsable/encargado para que apliquen la cancelación |

**¿Por qué `DELETE` no basta?** Porque el dato vive en un **ecosistema**: respaldos, réplicas, ambientes de prueba, exportaciones, logs y terceros. Un `DELETE` solo afecta la tabla principal; el resto sigue conteniendo información identificable hasta que se aborde cada ubicación. Además, parte de la información puede **bloquearse y conservarse** por obligaciones legales (p. ej. fiscales) aunque la solicitud proceda; esa decisión es jurídica.

### 9. Oposición

**¿Hay que eliminar todos sus datos?** **No necesariamente.** La oposición se refiere a una **finalidad** (p. ej. promociones), no al tratamiento total.

1. **Debe mantenerse:** lo necesario para la relación y obligaciones vigentes (nombre, RFC y datos fiscales para facturar; contacto de soporte).
2. **Debe dejar de usarse:** su correo y perfil para promociones personalizadas.
3. **Mecanismos técnicos:** tabla `preferencias_privacidad` con `acepta_promos = FALSE`; vistas por finalidad que filtran a quienes se opusieron; listas de exclusión (suppression list) en la herramienta de correo; roles separados por finalidad.
4. **¿Por qué no decide solo el DBA?** Porque determinar si procede la oposición, qué datos deben conservarse por ley y qué se informa al titular son decisiones jurídicas/de privacidad. El DBA implementa técnicamente lo decidido.

## Análisis

Los cuatro derechos exigen capacidades técnicas previas: **catálogo de datos** (saber dónde está cada dato), **identificadores para localizar al titular**, **separación por finalidad**, **bitácora** y **procesos para propagar cambios** a copias y terceros. Sin inventario de dónde viven los datos, atender un ARCO a tiempo es inviable.

## Conclusión

El DBA no resuelve jurídicamente las solicitudes ARCO, pero debe tener la base técnica para localizar, corregir, bloquear/eliminar y dejar evidencia en todas las copias. Eliminar una fila no es suficiente: hay que gobernar el ciclo de vida completo del dato, incluidos respaldos, réplicas, ambientes de desarrollo, exportaciones y terceros.
