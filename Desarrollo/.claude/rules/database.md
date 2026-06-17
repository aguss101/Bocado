# Base de datos Bocado — Supabase (fuente de verdad)

Snapshot: 2026-06-09 · DDL actualizado: 2026-06-16 · Triggers implementados: 2026-06-16 · PostgreSQL 17.6 · Ref: `sosbomunpwbgcezgfgzs`
**Fuente primaria: `Base de datos/ESTRUCTURA-COMPLETA-SUPABASE.md`. El DDL en `query-creation-database.txt` ahora está actualizado y es consistente.**

## Arquitectura de acceso
- Toda la lógica vive en 18 funciones PL/pgSQL invocadas por RPC (PostgREST).
- Las imágenes se guardan en Storage; en las tablas se persiste la **URL** (text), no el binario.
- RLS **deshabilitado** en todas las tablas — la seguridad depende de que la app solo llame RPCs.
- Buckets Storage: `avatars` (5 MB) y `recetas` (10 MB), ambos públicos con RLS en `storage.objects`.

## Tablas

### usuarios
`id` serial PK · `id_cuenta` int NN default=1 (FK cuentas) · `id_nacion` int NN (FK naciones) · `id_genero` int NN (FK generos) · `nombre` text NN · `apellido` text NN · `correo` text NN · `usuario` text NN · `contrasena` text NN ⚠️ texto plano · `fecha_nacimiento` timestamp NN · `fecha_creacion` timestamp NN default=now() UTC · `fecha_acceso` timestamp NN default=now() UTC · `activo` bool NN default=true · `visibilidad` bool NN default=true · `foto` text NULL (URL avatars) · `banner` text NULL (URL avatars)
> ⚠️ `correo` y `usuario` no tienen UNIQUE — el sistema asume unicidad pero no la garantiza.
> Los contadores de cant_seguidores, cant_siguiendo, cant_recetas están en `estadisticas_usuario` (ver abajo).

### cuentas
`id` serial PK · `nombre` text NN
Seed: 1=Free · 2=Premium · 3=Administrador

### naciones / generos
`id` serial PK · `nombre` text NN
Seed generos: 1=Masculino · 2=Femenino · 3=Otro

### dificultades *(no estaba en el DER original)*
`id` int PK `GENERATED ALWAYS AS IDENTITY` · `nombre` text NN
Seed: 1=Principiante · 2=Aficionado · 3=Intermedio · 4=Profesional · 5=Experto

### alimentos
`id` serial PK · `nombre` text NN · `id_usuario` int NN (FK usuarios; 0=global del sistema) · `id_medida` int NN (FK medidas)

### nutrientes
`id` serial PK · `nombre` text NN · `"esMacro"` bool NN ⚠️ nombre camelCase requiere comillas · `id_medida` int NN (FK medidas)
Seed: 1=Proteinas(macro) · 2=Carbohidratos(macro) · 3=Grasas(macro) · 4=Vitamina C · 5=Fibra · 6=Hierro · 7=Calcio · 8=Potasio · 9=Magnesio · 10=Vitamina A · 11=Vitamina B12

### alimentos_nutrientes
PK `(id_alimento, id_nutriente)` · `valor100gr` int NULL (cantidad del nutriente por 100 g)

### medidas
`id` serial PK · `nombre` text NN · `tipo` int NN (FK medidas_tipos)
Seed: 1=Gramos · 2=Kilogramos · 3=Mililitros · 4=Litros · 5=Unidad

### medidas_tipos
`id` serial PK · `nombre` text NN
Seed: 1=Peso · 2=Volumen · 3=Unidad

### medidas_conversiones
PK `(id_medida1, id_medida2)` · `factor` numeric NN

### recetas
`id` serial PK · `id_usuario` int NN (FK usuarios) · `nombre` text NN · `foto` text NULL (URL recetas) · `calorias_totales` numeric NULL · `porciones` int NULL · `porciones_peso` numeric NULL · `instrucciones` text NN (pasos separados por `|`) · `fecha_creacion` timestamp NULL · `visibilidad` bool NN · `activo` bool NN (soft delete) · `precio` numeric NN · `id_dificultad` int NULL (FK dificultades)
> Los contadores cant_likes, cant_saves y promedio_calificacion están en `estadisticas_receta` (ver abajo).

### recetas_alimentos *(ingredientes)*
PK `(id_receta, id_alimento)` · `cantidad` numeric NN · `precio` numeric NN

### comentarios
`id_comentario` int PK ⚠️ SIN autoincrement/serial · `id_comentario_padre` int NULL (auto-FK hilos) · `id_receta` int NULL (FK recetas) · `id_comentarista` int NULL (FK usuarios) · `comentario` text NN

### calificaciones
PK `(id_receta, id_usuario)` · `calificacion` numeric NULL

### interacciones_usuario *(antes se llamaba `favoritos` — CAMBIADA)*
PK `(id_receta, id_usuario, tipo_interaccion)` — clave de 3 columnas
`tipo_interaccion` text NN — valores: `'like'`, `'save'`
> La función `listar_favoritos` puede estar rota si aún referencia la tabla `favoritos` vieja (ver bugs).

### etiquetas
`id_etiqueta` int PK `GENERATED ALWAYS AS IDENTITY` · `nombre` text NN · `id_usuario` int NN (FK usuarios; 0=global del sistema)

### etiquetas_recetas
PK `(id_recetas, id_etiquetas)`

### pass_reset
`id` bigint serial PK · `id_usuario` int NN (FK usuarios) · `codigo_hash` text NN · `expira_en` timestamp NN · `usado` bool NN default=false · `intentos` int NN default=0 · `creado_en` timestamp NN default=now() UTC

### seguidos_usuario
PK `(id_seguidor, id_seguido)` · `id_seguidor` int NN (FK usuarios) · `id_seguido` int NN (FK usuarios) · `fecha_seguido` timestamp default=now()
> ✅ El bug anterior de `GENERATED ALWAYS AS IDENTITY` en `id_seguidor` fue corregido — ahora es un `integer` normal.

### estadisticas_usuario *(tabla nueva — triggers activos)*
`id_usuario` int PK (FK usuarios) · `cant_recetas` int NN default=0 · `cant_seguidores` int NN default=0 · `cant_siguiendo` int NN default=0
> ✅ Mantenida por triggers `fn_stats_seguidos` (INSERT/DELETE en seguidos_usuario) y `fn_stats_recetas_usuario` (INSERT/DELETE en recetas). Leída por `handleContarSeguidores`, `handleContarSiguiendo`, `handleContarRecetas` en Java. Contadores usan `GREATEST(0, x-1)` para evitar negativos.

### estadisticas_receta *(tabla nueva — triggers activos)*
`id_receta` int PK (FK recetas) · `cant_likes` int NN default=0 · `cant_saves` int NN default=0 · `promedio_calificacion` numeric NULL
> ✅ Mantenida por trigger `fn_stats_interacciones` (INSERT/DELETE en interacciones_usuario) y `fn_stats_calificaciones` (INSERT/UPDATE/DELETE en calificaciones). Leída directamente por la vista `vistas_recetas_macros`.

## Vista: vistas_recetas_macros
Feed denormalizado. Columnas: `id_receta, nombre_receta, calorias_totales, porciones, foto, precio_porcion, lista_etiquetas (jsonb), lista_interacciones (jsonb), id_usuario, apellido_nombre, usuario, foto_perfil, cant_favoritos, cant_comentarios, promedio_calificacion, proteinas_totales, carbohidratos_totales, grasas_totales`.
- ✅ **Reescrita 2026-06-16**: `cant_favoritos` y `promedio_calificacion` leen de `estadisticas_receta` (JOIN O(1)) en lugar de `COUNT`/`AVG` inline.
- `cant_comentarios` sigue siendo `COUNT` de comentarios (no tiene tabla de stats aún).
- Macros: clasifica nutrientes por nombre con `ILIKE 'Proteina%'/'Carbohidrato%'/'Grasa%'`
- `precio_porcion = round(precio / NULLIF(porciones,0), 2)`

## Funciones RPC (18 total)

| Función | Firma simplificada | Qué hace |
|---|---|---|
| `registrar_usuario` | `(p_data jsonb)` → SETOF usuarios | Alta de usuario. Acepta todos los campos via jsonb. |
| `login_usuario` | `(p_usuario, p_contrasena)` → SETOF usuarios | Login por usuario o correo. Actualiza `fecha_acceso`. |
| `login_or_create_google` | `(p_correo, p_nombre, p_apellido, p_foto, p_google_id)` → SETOF usuarios | Login social Google. |
| `actualizar_usuario_json` | `(p_id, p_data jsonb)` → jsonb | Update parcial por coalesce. **SECURITY DEFINER**. |
| `eliminar_usuario` | `(p_id)` → boolean | Baja lógica (`activo=false`). |
| `crear_alimento` | `(p_data jsonb)` → SETOF alimentos | ❌ **ROTA** — inserta columnas inexistentes. Usar `crear_alimento_simple`. |
| `crear_alimento_simple` | `(p_nombre, p_id_usuario)` → integer | Inserta alimento con `id_medida=1`, devuelve id. |
| `listar_alimentos` | `()` → SETOF alimentos | Todos los alimentos. |
| `listar_mis_alimentos` | `(p_id_usuario)` → TABLE | Alimentos del usuario + globales (`id_usuario IN (0, p_id)`). |
| `crear_receta` | `(p_data jsonb)` → json | Inserta receta + ingredientes. Devuelve `{ok, data}`. |
| `obtener_receta_completa` | `(p_id_receta)` → json | Receta + autor + alimentos con nutrientes y medidas (anidado). |
| `obtener_receta_detalle` | `(p_id_receta)` → json | Receta + etiquetas + comentarios + calificaciones. |
| `listar_recetas_usuario` | `(p_id_usuario)` → TABLE | Recetas de un usuario (incluye inactivas). |
| `listar_favoritos` | `(p_id_usuario)` → TABLE | ⚠️ Puede estar rota si referencia tabla `favoritos` vieja. |
| `listar_recetas_por_etiqueta` | `(p_id_etiqueta)` → TABLE | Recetas activas con esa etiqueta. |
| `listar_recetas_por_nutriente` | `(p_id_nutriente)` → TABLE | Recetas activas con ese nutriente (DISTINCT). |
| `listar_recetas_por_dificultad` | `(p_id_dificultad)` → TABLE | Recetas activas por dificultad. |
| `listar_mis_etiquetas` | `(p_id_usuario)` → TABLE | Etiquetas del usuario + globales. |

## Bugs conocidos y deuda técnica

1. ❌ `crear_alimento(jsonb)` **rota** — referencia columnas `proteinas/carbohidratos/grasas` que no existen en `alimentos`. Usar siempre `crear_alimento_simple`.
2. ⚠️ `listar_favoritos` puede estar rota — la tabla `favoritos` fue reemplazada por `interacciones_usuario`. Verificar si la función fue actualizada.
3. ⚠️ `contrasena` se guarda en **texto plano** y se compara con `=`. Sin hashing.
4. ⚠️ `comentarios.id_comentario` no tiene autoincrement ni default — el id hay que generarlo desde la app o falla el insert. (`etiquetas` y `dificultades` sí tienen `GENERATED ALWAYS AS IDENTITY` — ya corregido).
5. ⚠️ `usuarios.correo` y `usuarios.usuario` no tienen UNIQUE en la BD — duplicados posibles.
6. ⚠️ RLS deshabilitado en todas las tablas — cualquier cliente con la anon key tiene acceso total via PostgREST.
7. ⚠️ Índices secundarios (`*_index_0` al `*_index_5`) duplican exactamente las PKs — son redundantes.
