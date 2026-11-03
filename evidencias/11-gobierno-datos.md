# Evidencia 11 — Matriz de gobierno de datos y controles

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividades 11 y 13)

## Objetivo

Construir una matriz de gobierno de datos que relacione cada campo con su finalidad, responsable, usuarios autorizados, protección, retención y acción final, y clasificar medidas como controles técnicos o administrativos.

## Procedimiento

1. Partí del inventario (Evidencia 01) y asigné **propietario** (decide sobre el dato) y **custodio** (implementa controles técnicos: el DBA).
2. Definí usuarios autorizados según necesidad funcional, no por jerarquía.
3. Asigné protección técnica proporcional al riesgo.
4. Clasifiqué ocho medidas como técnicas, administrativas o mixtas.

## Resultado

### Actividad 11 — Matriz de gobierno

| Dato | Finalidad | Responsable (propietario) | Usuarios autorizados | Protección | Retención | Acción al finalizar |
|---|---|---|---|---|---|---|
| `nombre` | Identificar cliente; receptor de factura | Gerencia de Atención / Facturación (propietarios compartidos) | Atención al cliente, Facturación | Permisos por rol; acceso solo por tabla/vista autorizada; auditoría de consultas | Relación vigente + plazo fiscal | Eliminar (soporte) / bloquear (fiscal) |
| `correo` | Contacto de soporte; envío de comprobantes; promociones solo con consentimiento | Gerencia de Atención | Atención, Facturación; Marketing solo vía vista de consentidos | Permisos por rol; vista filtrada por consentimiento; bitácora de exportaciones | Relación vigente; promociones mientras exista consentimiento | Eliminar / retirar de listas |
| `telefono` | Contacto de soporte | Gerencia de Atención | Atención | Permisos por rol; enmascaramiento parcial en pantallas no necesarias | Relación vigente + periodo corto | Eliminar |
| `rfc` | Facturación (obligación fiscal) | Gerencia de Facturación / Contabilidad | **Solo Facturación** | Permisos mínimos; cifrado de la columna (ver LAB-02); auditoría de acceso; nunca en entornos de prueba | Plazo fiscal (confirmar con Jurídico) | Bloquear y luego eliminar |
| `edad` | Estadística agregada (rangos de edad) | Dirección / Analítica (propietario del uso estadístico) | Analítica **solo vía `rango_edad`** | Vista con rangos; sin acceso a valor exacto; exclusión o tratamiento especial de menores | Activo: mientras exista el cliente; agregados: sin límite | Conservar solo agregados |
| `ciudad` | Estadística por zona | Dirección / Analítica | Analítica (vista) | Vista; agregación mínima por grupo (evitar grupos muy pequeños) | Igual que `edad` | Conservar solo agregados |
| `codigo_postal` | Región geográfica (analítica); domicilio fiscal (facturación) | Analítica (región) / Facturación (fiscal) | Analítica: región generalizada; Facturación: CP completo | Generalización a 2 dígitos para analítica; permisos por rol | Analítica: igual que `edad`; fiscal: plazo fiscal | Agregados / bloqueo y eliminación |

**Roles transversales**

| Rol | Responsabilidad respecto al dato |
|---|---|
| **DBA (custodio)** | Implementa permisos, vistas, cifrado, respaldos y depuración. **Acceso administrativo ≠ derecho de uso**: no consulta datos personales para fines propios |
| **Propietarios de datos** | Deciden finalidad, quién accede y plazos (con Privacidad/Jurídico) |
| **Responsable de privacidad / Jurídico** | Base jurídica, aviso de privacidad, atención de ARCO, plazos legales |
| **Dirección** | Aprueba políticas y asigna recursos; recibe reportes agregados |

### Actividad 13 — Controles técnicos vs. administrativos

| Medida | Técnico | Administrativo | Justificación |
|---|:---:|:---:|---|
| Crear roles de PostgreSQL | ✔ | | Se implementa con `CREATE ROLE`/`GRANT`. Pero **qué** roles existen debe definirlo una política (parte administrativa) |
| Política de retención | | ✔ | Es una regla organizacional; su ejecución usa jobs/scripts (control técnico complementario) |
| Cifrado de datos | ✔ | | Medida tecnológica; la gestión de llaves requiere procedimientos administrativos |
| Procedimiento para solicitudes ARCO | | ✔ | Flujo organizacional (recepción, verificación, plazos); soportado por consultas técnicas |
| Vista con información limitada | ✔ | | Control técnico de minimización; el contenido de la vista lo define el propietario |
| Clasificación de información | | ✔ | Decisión de la organización; después se refleja en permisos y cifrado |
| Registro de auditoría | ✔ | | Se configura técnicamente; **revisarlo** y actuar es administrativo |
| Política de control de acceso | | ✔ | Define quién puede qué; se implementa mediante GRANT/REVOKE (técnico) |

**Mixtos:** roles, cifrado, auditoría y retención son técnicos en su ejecución pero necesitan una política administrativa que los respalde. Un control técnico sin política no se sostiene; una política sin control técnico no se cumple.

## Análisis

La matriz muestra que el acceso se asigna por **necesidad funcional**: solo Facturación ve `rfc`; solo Atención ve contacto completo; Analítica ve únicamente atributos generalizados. El DBA, aunque técnicamente puede leer todo, actúa como **custodio**, no como dueño. Las áreas de Privacidad y Jurídico validan finalidad y plazos.

## Conclusión

El gobierno de datos combina roles claros (propietario, custodio), políticas y controles técnicos verificables. La matriz permite justificar cada permiso y cada plazo, y evita que el acceso se conceda "por costumbre" o por jerarquía.
