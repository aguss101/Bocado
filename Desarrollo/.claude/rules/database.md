# Base de datos Bocado — Supabase (fuente de verdad)

Snapshot: 2026-06-09 · DDL actualizado: 2026-06-16 · Triggers implementados: 2026-06-16 · RLS activado y verificado: 2026-07-04 · PostgreSQL 17.6 · Ref: `sosbomunpwbgcezgfgzs`
**Fuente primaria: `Base de datos/ESTRUCTURA-COMPLETA-SUPABASE.md`. El DDL en `query-creation-database.txt` ahora está actualizado y es consistente.**

## Arquitectura de acceso
- Toda la lógica vive en funciones PL/pgSQL invocadas por RPC (PostgREST) — ver tabla de funciones abajo (más de 30, la doc vieja decía "18" pero quedó desactualizada).
- Las imágenes se guardan en Storage; en las tablas se persiste la **URL** (text), no el binario.
- ✅ **RLS activado (2026-07-04)** en todas las tablas. Lectura pública donde corresponde (catálogos, recetas/comentarios solo si `visibilidad=true AND activo=true`, `usuarios` solo `activo=true`), escritura cerrada por defecto (sin política = deny total). `pass_reset` completamente cerrada (ni lectura). Detalle completo de políticas y qué RPCs necesitaron `SECURITY DEFINER` para seguir funcionando: ver bug #6 abajo y memoria `rls-seguridad-supabase`.
- Buckets Storage: `avatars` (5 MB) y `recetas` (10 MB), ambos públicos con RLS en `storage.objects`.

## Tablas

### usuarios
`id` serial PK · `id_cuenta` int NN default=1 (FK cuentas) · `id_nacion` int NN (FK naciones) · `id_genero` int NN (FK generos) · `nombre` text NN · `apellido` text NN · `correo` text NN · `usuario` text NN · `contrasena` text NN ⚠️ texto plano · `fecha_nacimiento` timestamp NN · `fecha_creacion` timestamp NN default=now() UTC · `fecha_acceso` timestamp NN default=now() UTC · `activo` bool NN default=true · `visibilidad` bool NN default=true · `foto` text NULL (URL avatars) · `banner` text NULL (URL avatars)
> ✅ `correo` y `usuario` tienen `UNIQUE` real en la BD (ver bug #5).
> ✅ **`contrasena` y `correo` bloqueadas por REVOKE para el rol `anon`** (2026-07-04) — devuelven `42501` si se piden por REST directo. Solo accesibles desde RPCs `SECURITY DEFINER` (login, registro, etc.), que corren como `postgres` y no se ven afectadas. Ver bug #6 para el detalle de por qué el primer intento de `REVOKE` no funcionó.
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
> ⚠️ **`activo` y `visibilidad` son independientes, no confundir** (hallado 2026-07-04): `crear_receta` fija `activo = NOT es_borrador` — es decir, `activo` es el que marca borrador/publicada de verdad. `visibilidad` es un toggle de privacidad aparte (público/privado), independiente del estado de borrador. Un borrador puede tener `visibilidad=true`. El filtro de pestañas en `MyRecipes.dart` (`_esBorrador`/`_esPublicada`) originalmente exigía las dos condiciones juntas — bug corregido, ahora solo mira `activo`.
> RLS exige `visibilidad=true AND activo=true` para que `anon` lea una fila por REST directo — por eso los borradores (`activo=false`) y privadas necesitan pasar por una RPC `SECURITY DEFINER` para que su propio dueño los vea (`mis_recetas_completo`, `obtener_detalle_completo`).

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
> ✅ **Escritura movida a RPC (2026-07-04)**: antes `InteraccionDAO.toggleInteraccion` hacía POST/DELETE directo por REST — único punto de escritura sin RPC de todo el proyecto, y explotable con la anon key (cualquiera podía togglear el like/save de otro usuario). Ahora usa la RPC `toggle_interaccion` (`SECURITY DEFINER`, `ON CONFLICT DO NOTHING` para el alta idempotente). RLS en esta tabla ya no permite ningún INSERT/DELETE directo por REST.

### etiquetas
`id_etiqueta` int PK `GENERATED ALWAYS AS IDENTITY` · `nombre` text NN · `id_usuario` int NN (FK usuarios; 0=global del sistema)

### etiquetas_recetas
PK `(id_recetas, id_etiquetas)`

### pass_reset
`id` bigint serial PK · `id_usuario` int NN (FK usuarios) · `codigo_hash` text NN · `expira_en` timestamp NN · `usado` bool NN default=false · `intentos` int NN default=0 · `creado_en` timestamp NN default=now() UTC

### seguidos_usuario
PK `(id_seguidor, id_seguido)` · `id_seguidor` int NN (FK usuarios) · `id_seguido` int NN (FK usuarios) · `fecha_seguido` timestamp default=now()
> ✅ El bug anterior de `GENERATED ALWAYS AS IDENTITY` en `id_seguidor` fue corregido — ahora es un `integer` normal.
> ✅ **Lista de "Seguidores" (quién me sigue) agregada (2026-07-04)**: no existía antes (`vista_mis_seguidos` solo resuelve "a quién sigo yo", filtrando por `id_seguidor`). Se resolvió con REST directo + embed de PostgREST sobre esta misma tabla, sin crear vista/RPC nueva: `seguidos_usuario?select=id_seguidor,usuarios!id_seguidor(id,usuario,foto)&id_seguido=eq.X`. El hint `!id_seguidor`/`!id_seguido` desambigua las 2 FK a `usuarios` que tiene esta tabla. Ver `AccessChannel.handleGetSeguidoresDe` y `handleEstasSiguiendoVarios` (chequeo de seguimiento en lote para varias filas de una).

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
- ⚠️ **`lista_interacciones` usa la clave `tipo`** (NO `tipo_interaccion`, que es el nombre de la columna en la tabla): formato `[{"tipo":"like","id_usuario":1},{"tipo":"save","id_usuario":24}]`. El front (`RecetaFeed.isLikedBy/isSavedBy`) filtra por `i['tipo']` — es correcto, NO cambiar a `tipo_interaccion`. (Verificado por GET directo 2026-06-24.)
- Soporta paginación PostgREST: `&order=id_receta.desc&limit=N&offset=M` (usado por el feed y los tabs de perfil).

## Funciones RPC

> ⚠️ La doc vieja decía "18 total" — desactualizado. El listado real (2026-07-04) tiene más de 30, incluyendo varias no documentadas antes (`crear_etiqueta`, `actualizar_id_cuenta`, `actualizar_estado_premium`, `actualizar_receta`, `obtener_receta_por_id`, `vincular_etiqueta_receta`) y los triggers `fn_stats_*`. Tabla actualizada abajo con las agregadas hoy; el resto sigue en la lista original.

| Función | Firma simplificada | Qué hace |
|---|---|---|
| `registrar_usuario` | `(p_data jsonb)` → SETOF usuarios | Alta de usuario. Acepta todos los campos via jsonb. **SECURITY DEFINER**. |
| `login_usuario` | `(p_usuario, p_contrasena)` → SETOF usuarios | Login por usuario o correo. Actualiza `fecha_acceso`. **SECURITY DEFINER**. |
| `login_or_create_google` | `(p_correo, p_nombre, p_apellido, p_foto, p_google_id)` → SETOF usuarios | Login social Google. **SECURITY DEFINER**. |
| `actualizar_usuario_json` | `(p_id, p_data jsonb)` → jsonb | Update parcial por coalesce. **SECURITY DEFINER**. |
| `eliminar_usuario` | `(p_id)` → boolean | Baja lógica (`activo=false`). **SECURITY DEFINER**. |
| `crear_alimento` | `(p_data jsonb)` → SETOF alimentos | ❌ **ROTA** — inserta columnas inexistentes. Usar `crear_alimento_simple`. |
| `crear_alimento_simple` | `(p_nombre, p_id_usuario)` → integer | Inserta alimento con `id_medida=1`, devuelve id. **SECURITY DEFINER**. |
| `listar_alimentos` | `()` → SETOF alimentos | Todos los alimentos. |
| `listar_mis_alimentos` | `(p_id_usuario)` → TABLE | Alimentos del usuario + globales (`id_usuario IN (0, p_id)`). |
| `crear_receta` | `(p_data jsonb)` → json | Inserta receta + ingredientes. Devuelve `{ok, data}`. **SECURITY DEFINER**. |
| `actualizar_receta` | `(p_data jsonb)` → json | Edita receta existente + ingredientes. **SECURITY DEFINER**. |
| `obtener_receta_completa` | `(p_id_receta)` → json | Receta + autor + alimentos con nutrientes y medidas (anidado). ❌ **ROTA** — referencia `n.esmacro` sin comillas (la columna real es `"esMacro"`, camelCase). **SECURITY DEFINER** (pero no usable hasta arreglar el bug). |
| `obtener_receta_detalle` | `(p_id_receta)` → json | Receta + etiquetas + comentarios + calificaciones. Forma anidada `{receta,etiquetas,comentarios,calificaciones}`, no compatible 1:1 con `RecipeDetailData` de Flutter. **SECURITY DEFINER**, no usada por la app hoy. |
| `obtener_receta_por_id` | Sobrecargada: `(p_id_receta integer)` **y** `(p_data jsonb)` | Dos firmas distintas conviven con el mismo nombre — cuidado al llamar por RPC con un objeto JSON ambiguo (puede resolver a la firma equivocada). **SECURITY DEFINER** ambas. |
| `listar_recetas_usuario` | `(p_id_usuario)` → TABLE | Recetas de un usuario (incluye inactivas/privadas si se llama con anon key SIN RLS; con RLS activo y sin ser `SECURITY DEFINER`, corre como `anon` y queda filtrada a solo públicas). No usada por la app — para "mis recetas" completas se usa `mis_recetas_completo` (ver abajo). |
| `listar_favoritos` | `(p_id_usuario)` → TABLE | ⚠️ Puede estar rota si referencia tabla `favoritos` vieja. |
| `listar_recetas_por_etiqueta` | `(p_id_etiqueta)` → TABLE | Recetas activas con esa etiqueta. |
| `listar_recetas_por_nutriente` | `(p_id_nutriente)` → TABLE | Recetas activas con ese nutriente (DISTINCT). |
| `listar_recetas_por_dificultad` | `(p_id_dificultad)` → TABLE | Recetas activas por dificultad. |
| `listar_mis_etiquetas` | `(p_id_usuario)` → TABLE | Etiquetas del usuario + globales. |
| `crear_etiqueta` | — | Alta de etiqueta (no documentada en la lista original). |
| `vincular_etiqueta_receta` | `(p_id_receta, p_id_etiqueta)` | Vincula etiqueta a receta. **SECURITY DEFINER**. |
| `actualizar_id_cuenta` | `(p_id_usuario, p_id_cuenta)` → boolean | Cambia el tipo de cuenta (Free/Premium/Admin). **SECURITY DEFINER**. |
| `actualizar_estado_premium` | `(p_id_usuario, p_es_premium)` → boolean | Similar/alias de arriba, usado por `PremiumStore`. **SECURITY DEFINER**. |
| `seguir_usuario` / `dejar_seguir` | `(p_idseguidor, p_idseguido)` → json `{ok, mensaje}` | Alta/baja en `seguidos_usuario`. **SECURITY DEFINER**. |
| `agregar_comentario` | `(p_id_receta, p_id_usuario, p_comentario, p_id_comentario_padre, p_calificacion)` | Alta de comentario (hilos). **SECURITY DEFINER**. |
| `feed_aleatorio` | `(p_seed, p_limit, p_offset)` → SETOF vistas_recetas_macros | Feed paginado, orden pseudoaleatorio estable. **NO** es `SECURITY DEFINER` a propósito — corre como `anon`, así RLS filtra automáticamente a solo recetas públicas (correcto para un feed público). |
| `mis_recetas_completo` | `(p_id_usuario integer)` → SETOF vistas_recetas_macros | 🆕 **2026-07-04**. `SECURITY DEFINER`. Envoltorio de 1 línea sobre la vista, filtrado por `id_usuario`, para que el dueño vea sus propias recetas privadas/borradores pese a RLS. Usado por `RecetaDAO.misRecetasCompleto` → Flutter `getMisRecetas` (MyRecipes.dart y Profil.dart cuando `_isMiPerfil`). |
| `obtener_detalle_completo` | `(p_id_receta integer)` → SETOF jsonb | 🆕 **2026-07-04**. `SECURITY DEFINER`. Reemplaza el REST directo que tenía `RecetaDAO.obtenerDetalle()` — construye a mano (`to_jsonb` + `jsonb_build_object`) la misma forma que el REST embebido devolvía (`usuarios{usuario,foto}` + `recetas_alimentos[{cantidad,alimentos{nombre}}]`), para que el dueño pueda ver el detalle de sus propias recetas privadas/borradores. `RETURNS SETOF jsonb` (no `jsonb` escalar) para que PostgREST lo devuelva envuelto en array `[{...}]`, igual que el REST — así no hubo que tocar Flutter. |
| `toggle_interaccion` | `(p_id_usuario, p_id_receta, p_tipo, p_agregar boolean)` → void | 🆕 **2026-07-04**. `SECURITY DEFINER`. Reemplaza el POST/DELETE directo que hacía `InteraccionDAO` sobre `interacciones_usuario` (único punto de escritura sin RPC del proyecto, y el único agujero de seguridad real encontrado en todo este trabajo). `ON CONFLICT (id_receta,id_usuario,tipo_interaccion) DO NOTHING` para que togglear un like que ya existe sea idempotente sin depender de manejar el 409 del lado de Java. |

## Bugs conocidos y deuda técnica

1. ❌ `crear_alimento(jsonb)` **rota** — referencia columnas `proteinas/carbohidratos/grasas` que no existen en `alimentos`. Usar siempre `crear_alimento_simple`.
2. ⚠️ `listar_favoritos` puede estar rota — la tabla `favoritos` fue reemplazada por `interacciones_usuario`. Verificar si la función fue actualizada.
3. ⚠️ `contrasena` se guarda en **texto plano** y se compara con `=`. Sin hashing. (La lectura vía REST directo con la anon key ya está bloqueada — ver bug #6 — pero dentro de la BD/RPCs sigue en texto plano, sin hashear.)
4. ⚠️ `comentarios.id_comentario` no tiene autoincrement ni default — el id hay que generarlo desde la app o falla el insert. (`etiquetas` y `dificultades` sí tienen `GENERATED ALWAYS AS IDENTITY` — ya corregido).
5. ✅ **RESUELTO** — `usuarios.correo` y `usuarios.usuario` ahora tienen constraints `UNIQUE` reales en la BD (`usuarios_correo_unique`, `usuarios_usuario_unique`). El manejo de errores ya estaba listo del lado de la app (`RpcCallHelper` detecta SQLSTATE `23505` → `ErrorCode.DUPLICADO` → mensaje amigable en `Register.dart`/`OnboardingGoogle.dart`).
6. ✅ **RESUELTO Y VERIFICADO EN VIVO (2026-07-04)** — RLS activado en todas las tablas (lectura pública donde corresponde, escritura cerrada por defecto — sin política = deny total). `pass_reset` cerrada del todo (ni lectura, confirmado: devuelve `[]` con HTTP 200). Vistas (`vistas_recetas_macros`, `vista_mis_seguidos`, `vista_comentarios_recetas`) pasadas a `security_invoker=true` — sin esto las vistas corren con los permisos del dueño (típicamente un rol que bypassea RLS) y la protección de las tablas de abajo no se aplicaría nunca al consultarlas.
   - **Todas las RPCs que escriben, y las 4 que necesitan leer recetas propias privadas/borradores** (`obtener_receta_completa`, `obtener_receta_detalle`, `obtener_receta_por_id` x2, más `mis_recetas_completo` y `obtener_detalle_completo` creadas nuevas) se pasaron a `SECURITY DEFINER`. Verificado con pruebas reales contra la anon key: creación/edición de receta, comentarios, seguir/dejar de seguir (ciclo completo), alimentos, cuentas/premium, etiquetas — ninguna devuelve error de RLS (`42501`).
   - ⚠️ **Lección clave sobre columnas** — `REVOKE SELECT (columna) ON tabla FROM rol` es un **no-op silencioso** (corre "con éxito" pero no hace nada) si el permiso de esa columna viene de un `GRANT` a **nivel tabla completa** (`GRANT SELECT ON tabla TO rol`), que es como Supabase arma los permisos por defecto. El fix real es sacar el `GRANT` de tabla completa y volver a otorgar `SELECT` columna por columna, excluyendo las sensibles:
     ```sql
     REVOKE SELECT ON usuarios FROM anon;
     GRANT SELECT (id, id_cuenta, id_nacion, id_genero, nombre, apellido, usuario,
                   fecha_nacimiento, fecha_creacion, fecha_acceso, activo, visibilidad,
                   foto, banner) ON usuarios TO anon;
     ```
     Confirmado en vivo: `contrasena`/`correo` ahora devuelven `42501` para `anon`, el resto de columnas sigue funcionando.
   - Bugs de UI/Flutter encontrados y arreglados en el camino (por el mismo RLS exponiendo casos no cubiertos antes): ver `RecetaDAO.obtenerDetalle`, filtro `_esBorrador`/`_esPublicada` en MyRecipes.dart, y parseo de `tiempo_coccion` en EditRecipe.dart.
7. ✅ **RESUELTO** — Índices secundarios redundantes (duplicaban exactamente las PKs) borrados: `Alimentos_Nutrientes_index_0`, `Calificaciones_index_3`, `Etiquetas_Recetas_index_5`, `Medidas_Conversiones_index_1`, `Recetas_Alimentos_index_2`.
8. ⏳ **Pendiente**: las funciones `SECURITY DEFINER` no fijan `search_path` explícito — riesgo teórico de "search_path hijacking" (alguien crea una tabla con el mismo nombre en otro schema para interferir). Fix: agregar `SET search_path = public` a cada función `SECURITY DEFINER` (las ~24 marcadas en el punto 6). No urgente, es hardening defensivo, no un agujero explotado hoy.
