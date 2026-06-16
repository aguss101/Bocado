# Bocado

App Android de recetas con módulo Flutter embebido y backend en Supabase (proyecto de tesis).

## Stack

- Android nativo (Java): `app/src/main/java/com/example/bocado/`
- Flutter module: `flutter_module/lib/`
- Base de datos: Supabase — REST API + RPC stored procedures
- Auth: email/password + Google OAuth
- Storage: Supabase Storage (avatares e imágenes de recetas)
- HTTP: OkHttp3 via `HttpClientManager` (Singleton)

## Arquitectura — flujo de datos obligatorio

```
Flutter UI → Flutter Service → MethodChannel → Java Channel → Manager → DAO → Supabase
```

Nunca saltear capas. Channel no llama al DAO directamente.

### MethodChannels

| Canal Flutter | Clase Java | Responsabilidad |
|---|---|---|
| `com.example.bocado/access` | `AccessChannel` | Auth, perfil, OTP, seguidores |
| `com.example.bocado/recetas` | `RecetasChannel` | Recetas, alimentos, feed |
| `com.example.bocado/interacciones` | `InteractionsChannel` | Likes, saves, seguir/dejar de seguir |
| `com.example.bocado/images` | `ImagesChannel` | Upload a Supabase Storage |

### Capas Java

| Carpeta | Rol |
|---|---|
| `channel/` | Handler de MethodChannel. Sin lógica de negocio. |
| `manager/` | Lógica de negocio y validaciones. |
| `dao/` | Llamadas a Supabase (RPC o REST). Sin lógica. |
| `model/` | Entidades Java (POJOs). |
| `util/` | `Mapper`, `RpcCallHelper`, `HttpClientManager`. |

## Convenciones críticas

- **Errores:** siempre `CallbackCB.onError(code, message, details)` — nunca dejar un branch sin manejo.
- **Respuesta de usuario:** usar `responderUsuarioLimpio()` en `AccessChannel` — mapea via Mapper sin exponer contraseña.
- **Secrets:** `BuildConfig.SUPABASE_URL` y `BuildConfig.SUPABASE_KEY`. Nunca hardcodeados en código.
- **RPCs:** `RpcCallHelper.callAsync(rpcName, body, callback)` para todas las stored procedures.
- **REST:** `HttpClientManager.getInstance().get/post/delete/patch()`.
- **Mapeos:** siempre via `Mapper.java`. Nunca construir Maps a mano en el Channel ni en el DAO.
- **Comentarios:** solo cuando el motivo es no obvio. No comentar qué hace el código, sino por qué.

## Comandos disponibles

```
/new-feature <nombre>       Scaffold completo Channel → Manager → DAO para una feature nueva
/analyze-channel <canal>    Auditoría de un MethodChannel (access|recetas|interacciones|images)
/check-mapper [entidad]     Verifica consistencia de Mapper.java contra entidades y modelos Flutter
/review-rpc <nombre>        Revisa una RPC de Supabase y su integración con el DAO
/test-flow <funcionalidad>  Traza un flujo completo de punta a punta
/sync-supabase [tabla]      Compara el código contra el schema de Supabase documentado
```

## Agentes disponibles

- **`db-analyst`** — analiza schema, RPCs y uso de Supabase en el DAO. Contexto propio, respuesta condensada.
- **`code-analyst`** — análisis completo Java + Flutter. Devuelve resumen ejecutivo de arquitectura, features y deuda técnica.

## Skills disponibles

- **`/run`** — buildea el Flutter module y lanza la app en el emulador.
- **`/code-review`** — revisa cambios con contexto de la arquitectura Bocado.
- **`/verify`** — verifica un flujo Channel → DAO de forma estática sin correr la app.
