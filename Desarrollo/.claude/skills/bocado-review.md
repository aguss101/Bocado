---
name: bocado-review
description: Revisa el código cambiado en Bocado con contexto de la arquitectura del proyecto (Java + Flutter + Supabase).
---

Al revisar código del proyecto Bocado, tené en cuenta:

## Arquitectura que debe respetarse
- Flujo: Flutter service → MethodChannel → Java Channel → Manager → DAO → Supabase
- Nunca: Channel llamando directo a DAO (saltear Manager)
- Nunca: lógica de negocio en el DAO
- Nunca: credenciales hardcodeadas (usar BuildConfig.SUPABASE_URL / SUPABASE_KEY)

## Qué buscar en cada capa

**Java Channels** (`*Channel.java`):
- ¿Tiene try-catch alrededor de la lógica?
- ¿Llama a `CallbackCB.onError` en todos los casos de error?
- ¿Valida que los argumentos no sean null antes de usarlos?

**Java Managers** (`*Manager.java`):
- ¿La lógica de negocio está aquí y no en el Channel ni en el DAO?
- ¿Las validaciones son claras?

**Java DAOs** (`*DAO.java`):
- ¿Usa `RpcCallHelper.callAsync()` para RPCs?
- ¿Usa `HttpClientManager.getInstance()` para REST?
- ¿Maneja el callback de error?

**Mapper.java**:
- ¿Mapea todos los campos necesarios?
- ¿Hay null checks defensivos?

**Flutter services** (`flutter_module/lib/`):
- ¿Los métodos del service tienen los mismos nombres que los handlers en Java?
- ¿Se manejan los errores del PlatformException?

## Formato de reporte
Listá los hallazgos agrupados por severidad: Bug / Advertencia / Sugerencia.
