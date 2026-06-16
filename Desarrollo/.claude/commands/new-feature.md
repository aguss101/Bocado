Creá una nueva feature para la app Bocado siguiendo el patrón de arquitectura del proyecto:
Flutter service → MethodChannel → Java Manager → DAO → Supabase RPC/REST.

Feature a crear: $ARGUMENTS

Pasos a seguir:
1. Identificá qué MethodChannel corresponde: access, recetas, interacciones o images.
2. En Flutter (`flutter_module/lib/`): creá o actualizá el service que llama al channel.
3. En Java: actualizá el Channel handler correspondiente (método nuevo en el switch de `onMethodCall`).
4. Creá o actualizá el Manager con la lógica de negocio y validaciones.
5. Creá o actualizá el DAO con la llamada a Supabase usando `RpcCallHelper.callAsync()` o `HttpClientManager`.
6. Actualizá `Mapper.java` si hay campos nuevos en la entidad.
7. Si hay nueva entidad, definila en Java y en Flutter, y registrala en el Mapper.

Convenciones obligatorias:
- Nunca llames al DAO directamente desde el Channel; siempre pasá por el Manager.
- Usá `CallbackCB.onError(code, message, details)` para todos los errores.
- Usá `responderUsuarioLimpio()` en AccessChannel para cualquier respuesta de usuario.
- Secrets: nunca hardcodees URLs o keys; usá BuildConfig.
