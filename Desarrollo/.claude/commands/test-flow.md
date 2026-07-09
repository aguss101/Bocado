Trazá y verificá el flujo completo de extremo a extremo para una funcionalidad del proyecto.

Funcionalidad a trazar: $ARGUMENTS
(Ej: "login con email", "publicar receta", "seguir usuario", "ver feed")

Trazado del flujo:
1. **Flutter UI**: ¿qué pantalla/widget inicia la acción? ¿qué servicio llama?
2. **Flutter Service**: ¿qué método del service se invoca? ¿qué parámetros pasa al channel?
3. **MethodChannel**: ¿qué canal y qué método se invoca en Java?
4. **Java Channel Handler**: ¿qué validaciones hace antes de llamar al Manager?
5. **Java Manager**: ¿qué lógica de negocio aplica? ¿llama a uno o varios DAOs?
6. **Java DAO**: ¿qué RPC o endpoint REST llama? ¿qué body construye?
7. **Respuesta**: ¿cómo vuelve el dato hasta la UI de Flutter? ¿pasa por el Mapper?

Verificaciones adicionales:
- ¿Hay puntos donde el error puede perderse sin notificar al usuario?
- ¿El flujo funciona en modo offline o falla silenciosamente?
- ¿Hay validaciones duplicadas en Flutter y Java, o falta alguna?

Formato: diagrama de texto del flujo + issues encontrados.
