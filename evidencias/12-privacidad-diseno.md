# Evidencia 12 — Privacidad por diseño

**Alumno:** Jesus Ruben Monzon Garcia · **Grupo:** 4-3
**Laboratorio:** LAB-03 (Actividad 12)

## Objetivo

Evaluar el diseño propuesto por un desarrollador para una nueva tabla `clientes` con múltiples campos "por si se necesitan después" y rediseñarla aplicando privacidad por diseño y por defecto.

## Procedimiento

1. Analicé la propuesta (`nombre, correo, telefono, rfc, edad, direccion, ciudad, codigo_postal, fecha_nacimiento, ocupacion, salario, estado_civil, ...`).
2. Identifiqué problemas, principios ignorados y preguntas previas a la aprobación.
3. Clasifiqué campos a eliminar, a justificar y a conservar.
4. Propuse un diseño con privacidad por defecto.

## Resultado

### 1. Problemas identificados

- Se recopilan datos **sin finalidad definida** ("por si acaso").
- Incluye datos de **alto riesgo** (`salario`, `estado_civil`, `rfc`, `fecha_nacimiento`, `direccion`) sin justificar.
- Todos los campos son `TEXT` sin restricciones: sin validación, sin longitud, sin obligatoriedad.
- No hay llave primaria, `NOT NULL` ni `UNIQUE`.
- No hay separación por finalidad: una sola tabla para soporte, facturación, analítica y marketing.
- No hay control de consentimiento, fecha de alta ni mecanismo de retención.
- `edad` y `fecha_nacimiento` son redundantes (y la edad se desactualiza).
- Mayor impacto en caso de filtración y mayor dificultad para atender ARCO.

### 2. Principio ignorado

**Minimización de datos** (datos adecuados, relevantes y necesarios), junto con **limitación de finalidad**, **proporcionalidad** y, de fondo, **privacidad por diseño y por defecto**.

### 3. Preguntas antes de aprobar

1. ¿Para qué proceso exacto se usará cada campo?
2. ¿Qué ocurre si **no** se recopila? ¿Se puede cumplir la finalidad sin él?
3. ¿Hay base jurídica y aviso de privacidad para cada dato?
4. ¿Quién será propietario y quién tendrá acceso?
5. ¿Cuánto tiempo se conservará y qué pasará al terminar?
6. ¿Se recopilan datos de menores o datos sensibles?
7. ¿Se compartirá con terceros?
8. ¿Existe una versión menos precisa que cumpla (rango en vez de fecha exacta)?

### 4. Datos que eliminaría (sin finalidad demostrada)

`salario`, `estado_civil`, `ocupacion`, `fecha_nacimiento` (si basta `edad` o ni siquiera), `direccion` (salvo que se justifique envío o dato fiscal) y el `...` de columnas sin definir.

### 5. Datos que requieren justificación adicional

| Dato | Condición para conservarlo |
|---|---|
| `rfc` | Solo si la app factura; acceso restringido y cifrado |
| `direccion` | Solo si hay entregas o domicilio fiscal requerido |
| `fecha_nacimiento` | Solo si hay requisito legal de verificar mayoría de edad; usar `es_mayor_edad` si basta |
| `edad` | Solo para analítica, en rangos |
| `telefono` | Opcional si ya hay correo |

### 6. Privacidad por defecto — diseño propuesto

```sql
CREATE TABLE clientes (
    id            BIGSERIAL PRIMARY KEY,
    nombre        VARCHAR(120) NOT NULL,
    correo        VARCHAR(150) NOT NULL UNIQUE,
    telefono      VARCHAR(20),                        -- opcional
    fecha_alta    DATE NOT NULL DEFAULT CURRENT_DATE  -- control de retención
);

-- Datos fiscales aparte, solo si se factura, con acceso restringido
CREATE TABLE clientes_fiscal (
    id_cliente    BIGINT PRIMARY KEY REFERENCES clientes(id),
    rfc           VARCHAR(13) NOT NULL,
    cp_fiscal     VARCHAR(5)  NOT NULL
);

-- Preferencias: por defecto SIN uso secundario
CREATE TABLE preferencias_privacidad (
    id_cliente     BIGINT PRIMARY KEY REFERENCES clientes(id),
    acepta_promos  BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_decision TIMESTAMPTZ
);

-- Privilegios: nadie recibe nada por defecto
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
```

Principios aplicados: solo columnas necesarias; datos de distinto riesgo en tablas separadas; consentimiento en `FALSE` por defecto; campos opcionales realmente opcionales; permisos mínimos; `fecha_alta` para poder aplicar retención.

## Análisis

"Guardar todo por si acaso" traslada el riesgo al futuro: cada columna extra es un dato más que proteger, respaldar, replicar, auditar, consultar en ARCO y eliminar. Es más barato **no recolectar** que proteger indefinidamente. Si una necesidad nueva aparece, se agrega la columna con su justificación, no al revés.

## Conclusión

La privacidad se decide en el **diseño de la tabla**, antes que en los permisos. Un buen diseño pregunta primero "¿por qué necesito este dato?" y, por defecto, recolecta, expone y conserva lo mínimo.
