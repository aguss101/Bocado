# Estructura completa de la base de datos (Supabase) — Bocado

> **Snapshot tomado:** 2026-06-09 vía Supabase Management API (introspección en vivo del proyecto productivo).
> **Motor:** PostgreSQL 17.6 · **Proyecto (ref):** `sosbomunpwbgcezgfgzs` · **URL:** `https://sosbomunpwbgcezgfgzs.supabase.co`
> Este archivo es la **fuente de verdad** del estado real de la BD (no el DER viejo). Si hay dudas sobre la base, consultar acá primero.

---

## ⏱️ Changelog de cambios aplicados

**2026-06-09 — Fixes de autenticación** (SQL en `Desarrollo/supabase/sql/2026-06-09_auth_fixes.sql`):
- `registrar_usuario` reescrita: ahora recibe `p_data jsonb` con todos los campos e inserta `nombre/apellido/id_nacion/id_genero/fecha_nacimiento` (antes violaba los NOT NULL → registro estaba roto). **Resuelve el issue #1 de §15.**
- `login_usuario` ahora actualiza `fecha_acceso` al validar credenciales.
- Nota: `usuarios.foto`/`banner` se manejan como URL de Storage (text); el cliente Java dejó de pasarlas por `byteaToBase64`.

---

## 0. Índice

1. [Resumen rápido](#1-resumen-rápido)
2. [Extensiones](#2-extensiones-instaladas)
3. [Tablas y columnas](#3-tablas-y-columnas)
4. [Claves primarias / únicas](#4-claves-primarias--únicas)
5. [Claves foráneas (FKs)](#5-claves-foráneas-fks)
6. [Índices](#6-índices)
7. [Vistas](#7-vistas)
8. [Funciones y Stored Procedures](#8-funciones-y-stored-procedures-rpc)
9. [Triggers](#9-triggers)
10. [RLS / Políticas de seguridad](#10-rls--políticas)
11. [Edge Functions](#11-edge-functions)
12. [Storage (buckets)](#12-storage-buckets)
13. [Datos de catálogo (seed)](#13-datos-de-catálogo-seed)
14. [Diferencias contra el DER/DDL original](#14-diferencias-contra-el-derddl-original)
15. [Problemas detectados / deuda técnica](#15-problemas-detectados--deuda-técnica)
16. [Cómo regenerar este snapshot](#16-cómo-regenerar-este-snapshot)

---

## 1. Resumen rápido

| Objeto | Cantidad | Detalle |
|---|---|---|
| Tablas (`public`) | **18** | Ver §3 |
| Vistas | **1** | `vistas_recetas_macros` |
| Funciones / SP | **18** | Toda la lógica de negocio vive acá (se llaman por RPC) |
| Triggers | **0** | No hay ninguno |
| Políticas RLS | **0** | **RLS deshabilitado en todas las tablas** ⚠️ |
| Edge Functions | **0** | No hay funciones Deno desplegadas |
| Buckets Storage | **2** | `avatars`, `recetas` (ambos públicos) |
| Enums custom | **0** | — |

**Arquitectura de acceso:** la app (Flutter + Android) no usa ORM ni queries directas; **toda la lógica está en funciones PL/pgSQL** que se invocan por RPC (PostgREST). Las imágenes se guardan en Storage y en las tablas se persiste la **URL** (texto), no el binario.

---

## 2. Extensiones instaladas

| Extensión | Versión | Uso |
|---|---|---|
| `plpgsql` | 1.0 | Lenguaje de las funciones |
| `pgcrypto` | 1.3 | `gen_random_uuid()`, `md5()` (usado en login Google) |
| `uuid-ossp` | 1.1 | Generación de UUIDs |
| `pg_stat_statements` | 1.11 | Métricas de queries |
| `supabase_vault` | 0.3.1 | Secret management de Supabase |

---

## 3. Tablas y columnas

Esquema `public`. Tipo entre paréntesis; `NN` = NOT NULL; default si aplica.

### `usuarios`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | `nextval(Usuarios_id_seq)` (serial) |
| 2 | id_cuenta | integer | NN | `1` |
| 3 | id_nacion | integer | NN | — |
| 4 | id_genero | integer | NN | — |
| 5 | nombre | text | NN | — |
| 6 | apellido | text | NN | — |
| 7 | correo | text | NN | — |
| 8 | usuario | text | NN | — |
| 9 | contrasena | text | NN | — (⚠️ texto plano, ver §15) |
| 10 | fecha_nacimiento | timestamp | NN | — |
| 11 | fecha_creacion | timestamp | NN | `now() AT TIME ZONE 'utc'` |
| 12 | fecha_acceso | timestamp | NN | `now() AT TIME ZONE 'utc'` |
| 13 | activo | boolean | NN | `true` |
| 14 | visibilidad | boolean | NN | `true` |
| 15 | foto | text | NULL | — (URL a Storage `avatars`) |
| 16 | banner | text | NULL | — (URL a Storage) |

### `cuentas`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |

### `naciones`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |

### `generos`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |

### `dificultades`  *(nueva, no estaba en el DER)*
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | — (sin serial) |
| 2 | nombre | text | NN | — |

### `alimentos`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |
| 3 | id_usuario | integer | NN | — (0 = alimento "del sistema/global") |
| 4 | id_medida | integer | NN | — |

### `nutrientes`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |
| 3 | `esMacro` | boolean | NN | — (⚠️ nombre camelCase, requiere comillas) |
| 4 | id_medida | integer | NN | — |

### `alimentos_nutrientes` *(N:M alimento↔nutriente)*
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_alimento | integer | NN | — |
| 2 | id_nutriente | integer | NN | — |
| 3 | valor100gr | integer | NULL | — (cantidad del nutriente por 100 g) |

### `medidas`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |
| 3 | tipo | integer | NN | — (FK → medidas_tipos) |

### `medidas_tipos`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | nombre | text | NN | — |

### `medidas_conversiones`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_medida1 | integer | NN | — |
| 2 | id_medida2 | integer | NN | — |
| 3 | factor | numeric | NN | — |

### `recetas`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id | integer | NN | serial |
| 2 | id_usuario | integer | NN | — |
| 3 | nombre | text | NN | — |
| 4 | foto | text | NULL | — (URL a Storage `recetas`) |
| 5 | calorias_totales | numeric | NULL | — |
| 6 | porciones | integer | NULL | — |
| 7 | porciones_peso | numeric | NULL | — |
| 8 | instrucciones | text | NN | — |
| 9 | fecha_creacion | timestamp | NULL | — |
| 10 | visibilidad | boolean | NN | — |
| 11 | activo | boolean | NN | — |
| 12 | precio | numeric | NN | — |
| 13 | id_dificultad | integer | NULL | — (nueva, FK → dificultades) |

### `recetas_alimentos` *(ingredientes de cada receta)*
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_receta | integer | NN | — |
| 2 | id_alimento | integer | NN | — |
| 3 | cantidad | numeric | NN | — |
| 4 | precio | numeric | NN | — |

### `comentarios`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_comentario | integer | NN | — (⚠️ sin serial/default, ver §15) |
| 2 | id_comentario_padre | integer | NULL | — (auto-FK, hilos) |
| 3 | id_receta | integer | NULL | — |
| 4 | id_comentarista | integer | NULL | — |
| 5 | comentario | text | NN | — |

### `calificaciones`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_receta | integer | NN | — |
| 2 | id_usuario | integer | NN | — |
| 3 | calificacion | numeric | NULL | — |

### `interacciones_usuario` *(reemplaza a la vieja tabla `favoritos`)*
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_receta | integer | NN | — |
| 2 | id_usuario | integer | NN | — |
| 3 | tipo_interaccion | text | NN | — (ej: `'like'`) |

### `etiquetas`
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_etiqueta | integer | NN | — |
| 2 | nombre | text | NN | — |
| 3 | id_usuario | integer | NN | — (0 = etiqueta global) |

### `etiquetas_recetas` *(N:M receta↔etiqueta)*
| # | Columna | Tipo | Null | Default |
|---|---|---|---|---|
| 1 | id_recetas | integer | NN | — |
| 2 | id_etiquetas | integer | NN | — |

---

## 4. Claves primarias / únicas

| Tabla | PK |
|---|---|
| usuarios | `id` |
| cuentas | `id` |
| naciones | `id` |
| generos | `id` |
| dificultades | `id` |
| alimentos | `id` |
| nutrientes | `id` |
| alimentos_nutrientes | `(id_alimento, id_nutriente)` |
| medidas | `id` |
| medidas_tipos | `id` |
| medidas_conversiones | `(id_medida1, id_medida2)` |
| recetas | `id` |
| recetas_alimentos | `(id_receta, id_alimento)` |
| comentarios | `id_comentario` |
| calificaciones | `(id_receta, id_usuario)` |
| **interacciones_usuario** | `(id_receta, id_usuario, tipo_interaccion)` ← clave de 3 columnas |
| etiquetas | `id_etiqueta` |
| etiquetas_recetas | `(id_recetas, id_etiquetas)` |

> No hay constraints UNIQUE adicionales más allá de las PK (ojo: `usuarios.correo` y `usuarios.usuario` **no** tienen UNIQUE).

---

## 5. Claves foráneas (FKs)

Todas con `ON UPDATE NO ACTION` / `ON DELETE NO ACTION`.

| Tabla origen | Columna | → Tabla destino | Columna | Constraint |
|---|---|---|---|---|
| usuarios | id_cuenta | cuentas | id | CU |
| usuarios | id_nacion | naciones | id | NU |
| usuarios | id_genero | generos | id | GU |
| alimentos | id_usuario | usuarios | id | UA |
| alimentos | id_medida | medidas | id | MA |
| alimentos_nutrientes | id_alimento | alimentos | id | AAN |
| alimentos_nutrientes | id_nutriente | nutrientes | id | NAN |
| nutrientes | id_medida | medidas | id | MN |
| medidas | tipo | medidas_tipos | id | MTM |
| medidas_conversiones | id_medida1 | medidas | id | MMC |
| medidas_conversiones | id_medida2 | medidas | id | MMC2 |
| recetas | id_usuario | usuarios | id | UR |
| recetas | id_dificultad | dificultades | id | recetas_dificultad_fk |
| recetas_alimentos | id_receta | recetas | id | RRA |
| recetas_alimentos | id_alimento | alimentos | id | ARA |
| comentarios | id_comentario_padre | comentarios | id_comentario | CC |
| comentarios | id_receta | recetas | id | RC |
| comentarios | id_comentarista | usuarios | id | UC |
| calificaciones | id_receta | recetas | id | RC2 |
| calificaciones | id_usuario | usuarios | id | UC2 |
| interacciones_usuario | id_receta | recetas | id | RF |
| interacciones_usuario | id_usuario | usuarios | id | UF |
| etiquetas | id_usuario | usuarios | id | etiquetas_id_usuario_fkey |
| etiquetas_recetas | id_recetas | recetas | id | RER |
| etiquetas_recetas | id_etiquetas | etiquetas | id_etiqueta | EER |

---

## 6. Índices

Además de los índices únicos de cada PK, hay estos índices secundarios (btree):

| Tabla | Índice | Columnas |
|---|---|---|
| alimentos_nutrientes | `Alimentos_Nutrientes_index_0` | (id_alimento, id_nutriente) |
| medidas_conversiones | `Medidas_Conversiones_index_1` | (id_medida1, id_medida2) |
| recetas_alimentos | `Recetas_Alimentos_index_2` | (id_receta, id_alimento) |
| calificaciones | `Calificaciones_index_3` | (id_receta, id_usuario) |
| interacciones_usuario | `Favoritos_index_4` | (id_receta, id_usuario) |
| etiquetas_recetas | `Etiquetas_Recetas_index_5` | (id_recetas, id_etiquetas) |

> Estos índices secundarios duplican columnas ya cubiertas por la PK → en la práctica son redundantes (ver §15).

---

## 7. Vistas

### `vistas_recetas_macros`
Vista "feed" que arma, por receta, toda la info para mostrar en la UI: datos de la receta, autor, etiquetas (jsonb), interacciones (jsonb), conteo de favoritos/comentarios, promedio de calificación y **macros totales calculados** (proteínas/carbohidratos/grasas) sumando `recetas_alimentos × alimentos_nutrientes`.

Columnas: `id_receta, nombre_receta, calorias_totales, porciones, foto, precio_porcion, lista_etiquetas (jsonb), lista_interacciones (jsonb), id_usuario, apellido_nombre, usuario, foto_perfil, cant_favoritos, cant_comentarios, promedio_calificacion, proteinas_totales, carbohidratos_totales, grasas_totales`.

Lógica destacada:
- `precio_porcion = round(precio / NULLIF(porciones,0), 2)`
- `cant_favoritos` = interacciones con `tipo_interaccion = 'like'`
- Macros: clasifica nutrientes por nombre con `ILIKE 'Proteina%' / 'Carbohidrato%' / 'Grasa%'` y suma `(cantidad/100) * valor100gr`.

> La definición SQL completa está en `Desarrollo/supabase/_raw/views.json`.

---

## 8. Funciones y Stored Procedures (RPC)

18 funciones en `public`. **Acá vive toda la lógica de negocio.** Se invocan desde la app por RPC.

| Función | Args | Retorna | Lang | Qué hace |
|---|---|---|---|---|
| `registrar_usuario` | p_usuario, p_correo, p_contrasena | SETOF usuarios | plpgsql | Alta de usuario (activo=true). |
| `login_usuario` | p_usuario, p_contrasena | SETOF usuarios | plpgsql | Login por usuario **o** correo + contraseña (⚠️ compara texto plano). |
| `login_or_create_google` | p_correo, p_nombre, p_apellido, p_foto, p_google_id | SETOF usuarios | plpgsql | Login social: si existe el correo lo devuelve, si no crea usuario con pass aleatoria (`md5(uuid)`). |
| `actualizar_usuario_json` | p_id, p_data jsonb | jsonb | plpgsql · **SECURITY DEFINER** | Update parcial del usuario desde un JSON (coalesce campo por campo). |
| `eliminar_usuario` | p_id | boolean | plpgsql | Baja lógica (`activo=false`). |
| `crear_alimento` | p_data jsonb | SETOF alimentos | plpgsql | ⚠️ **ROTA**: inserta columnas `proteinas/carbohidratos/grasas` que no existen en `alimentos` (ver §15). |
| `crear_alimento_simple` | p_nombre, p_id_usuario | integer | plpgsql | Inserta alimento con `id_medida=1`, devuelve id. |
| `listar_alimentos` | — | SETOF alimentos | plpgsql | Todos los alimentos. |
| `listar_mis_alimentos` | p_id_usuario | TABLE | sql | Alimentos del usuario + globales (`id_usuario IN (0, p_id)`). |
| `crear_receta` | p_data jsonb | json | plpgsql | Inserta receta + sus ingredientes (itera `p_data->'ingredientes'`). Devuelve `{ok, data}`. |
| `obtener_receta_completa` | p_id_receta | json | plpgsql | Receta + autor + alimentos con sus nutrientes y medidas (anidado). |
| `obtener_receta_detalle` | p_id_receta | json | plpgsql | Receta + etiquetas + comentarios + promedio/cantidad de calificaciones. |
| `listar_recetas_usuario` | p_id_usuario | TABLE | sql | Recetas de un usuario (incluye inactivas). |
| `listar_favoritos` | p_id_usuario | TABLE | sql | Recetas marcadas como favoritas (join con `favoritos`… ver §15). |
| `listar_recetas_por_etiqueta` | p_id_etiqueta | TABLE | sql | Recetas activas con esa etiqueta. |
| `listar_recetas_por_nutriente` | p_id_nutriente | TABLE | sql | Recetas activas que contienen ese nutriente (DISTINCT). |
| `listar_recetas_por_dificultad` | p_id_dificultad | TABLE | sql | Recetas activas por dificultad. |
| `listar_mis_etiquetas` | p_id_usuario | TABLE | sql | Etiquetas del usuario + globales (`id_usuario IN (0, p_id)`). |

> Las definiciones SQL completas están en `Desarrollo/supabase/_raw/functions.json`.

---

## 9. Triggers

**No hay triggers.** Ninguna tabla tiene triggers de usuario.

---

## 10. RLS / Políticas

⚠️ **Row Level Security está DESHABILITADO en las 18 tablas.** No existe ninguna `POLICY`.

Implicancia: con la **anon key** (que está embebida en la app) cualquiera puede leer/escribir todas las tablas vía PostgREST sin restricción. La "seguridad" actual depende 100% de que la app solo llame a las funciones RPC. Ver §15.

---

## 11. Edge Functions

**No hay Edge Functions desplegadas** (`/v1/projects/.../functions` devuelve `[]`). Toda la lógica server-side son las funciones PL/pgSQL del §8, no funciones Deno.

---

## 12. Storage (buckets)

| Bucket | Público | Límite | MIME permitidos | Creado |
|---|---|---|---|---|
| `avatars` | ✅ sí | 5 MB | image/jpeg, image/png, image/webp | 2026-05-10 |
| `recetas` | ✅ sí | 10 MB | image/jpeg, image/png, image/webp | 2026-05-10 |

> **Sí hay RLS en Storage:** `storage.objects` tiene **8 policies** (4 por bucket: SELECT/INSERT/UPDATE/DELETE) para los roles `anon` + `authenticated`, todas filtrando por `bucket_id`. O sea, a diferencia de las tablas de `public` (RLS off), acá Storage sí está protegido a nivel bucket. La subida se hace directo Flutter→Storage vía REST con la anon key (no hay Edge Function de fotos).

En `usuarios.foto`/`banner` y `recetas.foto` se guarda la **URL pública** del objeto, no el binario. La app construye las URLs con `SupabaseConfig.storagePublicUrl(bucket, path)` (ver `Desarrollo/flutter_module/lib/config/supabase_config.dart`).

---

## 13. Datos de catálogo (seed)

**cuentas:** 1=Free · 2=Premium · 3=Administrador
**generos:** 1=Masculino · 2=Femenino · 3=Otro
**dificultades:** 1=Principiante · 2=Aficionado · 3=Intermedio · 4=Profesional · 5=Experto
**medidas_tipos:** 1=Peso · 2=Volumen · 3=Unidad
**medidas:** 1=Gramos(Peso) · 2=Kilogramos(Peso) · 3=Mililitros(Vol) · 4=Litros(Vol) · 5=Unidad(Unidad)
**nutrientes:** 1=Proteinas(macro) · 2=Carbohidratos(macro) · 3=Grasas(macro) · 4=Vitamina C · 5=Fibra(macro) · 6=Hierro · 7=Calcio · 8=Potasio · 9=Magnesio · 10=Vitamina A · 11=Vitamina B12

> `usuarios.id_cuenta` default = `1` (Free). Convención: `id_usuario = 0` en `alimentos`/`etiquetas` representa recursos "globales/del sistema".

---

## 14. Diferencias contra el DER/DDL original

El DER (`Procesos/Proceso #03-DER/DER.dbml`) y el DDL (`Base de datos/query-creation-database.txt`) están **desactualizados**. Cambios reales en producción:

1. **`favoritos` → `interacciones_usuario`.** La tabla `favoritos` (id_receta, id_usuario) fue reemplazada por `interacciones_usuario` con una 3ª columna `tipo_interaccion` (text) y PK de 3 columnas. Los "favoritos" hoy son interacciones con `tipo_interaccion = 'like'`.
2. **Nueva tabla `dificultades`** + nueva columna `recetas.id_dificultad` (FK `recetas_dificultad_fk`).
3. **Imágenes como texto:** `usuarios.foto`, `usuarios.banner` y `recetas.foto` pasaron de `bytea` a `text` (guardan URL de Storage). En el DER figuran como `byte`/`bytea`.
4. **Defaults nuevos en `usuarios`:** `id_cuenta=1`, `fecha_creacion`/`fecha_acceso = now() utc`, `activo=true`, `visibilidad=true`. `foto`/`banner` ahora son NULLables.
5. **FK de `etiquetas` corregida:** el DDL viejo tenía `Etiquetas.id_etiqueta → Usuarios.id` (bug). En producción es correctamente `etiquetas.id_usuario → usuarios.id` y `nombre`/`id_usuario` son NOT NULL.
6. **Nueva vista** `vistas_recetas_macros` (no existía en el DER).
7. **18 funciones/SP** que no están documentadas en el DER.

---

## 15. Problemas detectados / deuda técnica

> Anotados para no re-descubrirlos. No se tocó nada — son observaciones.

1. **`crear_alimento(jsonb)` está rota.** Inserta en columnas `proteinas, carbohidratos, grasas` que **no existen** en la tabla `alimentos`. Llamarla tira error. La versión funcional es `crear_alimento_simple`. (Los macros viven en `alimentos_nutrientes`, no en `alimentos`.)
2. **`listar_favoritos` referencia la tabla `favoritos`**, que fue renombrada a `interacciones_usuario`. Verificar si la función sigue resolviendo (puede haber quedado una vista/tabla `favoritos` o estar rota). Si está rota, hay que reescribirla contra `interacciones_usuario` filtrando `tipo_interaccion='like'`.
3. **Contraseñas en texto plano.** `registrar_usuario` guarda `contrasena` tal cual y `login_usuario` compara con `=`. Sin hashing (bcrypt/argon). Riesgo alto para la tesis si se evalúa seguridad.
4. **RLS deshabilitado + anon key embebida.** Cualquier cliente con la anon key puede operar sobre todas las tablas vía PostgREST. Recomendado: activar RLS y exponer solo las RPC necesarias (o `SECURITY DEFINER` + `REVOKE` de tablas).
5. **`comentarios.id_comentario` sin autoincrement.** No tiene `default`/secuencia → hay que generar el id desde la app o falla el insert. Mismo patrón a revisar en `etiquetas.id_etiqueta` y `dificultades.id`.
6. **Índices secundarios redundantes.** `Alimentos_Nutrientes_index_0`, `..._index_1..5` duplican exactamente las columnas de la PK respectiva → no aportan y ocupan espacio/escritura.
7. **`usuarios.correo`/`usuario` sin UNIQUE.** Permite duplicados; `login_usuario` y `login_or_create_google` asumen unicidad.

---

## 16. Cómo regenerar este snapshot

La BD se introspeccionó por la **Management API** sobre HTTPS (no requiere puerto 5432 ni Docker). Los JSON crudos quedaron en `Desarrollo/supabase/_raw/`.

```bash
# Requiere un Personal Access Token (https://supabase.com/dashboard/account/tokens)
TOKEN="<PERSONAL_ACCESS_TOKEN>"
REF="sosbomunpwbgcezgfgzs"
API="https://api.supabase.com/v1/projects/$REF/database/query"

# Ejemplo: volcar todas las funciones
curl -s -X POST "$API" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"select p.proname, pg_get_functiondef(p.oid) def from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='\''public'\'';"}'

# Edge functions y buckets
curl -s "https://api.supabase.com/v1/projects/$REF/functions" -H "Authorization: Bearer $TOKEN"
```

Las queries usadas (columnas, FKs, triggers, policies, índices, enums, vistas, funciones) están reflejadas en los archivos de `Desarrollo/supabase/_raw/`. Para actualizar este documento, re-correr y reflejar los cambios acá.

> ⚠️ **Seguridad:** nunca commitear el Personal Access Token ni la Database password. El PAT usado para generar este snapshot debe rotarse.
