---
name: bocado-run
description: Lanza la app Bocado en el emulador Android. Sabe cómo buildear el módulo Flutter antes de correr la app nativa.
---

Para correr la app Bocado en este proyecto:

1. Primero verificá que el emulador está corriendo o que hay un dispositivo conectado:
   ```
   Bash(flutter devices)
   ```

2. Buildeá el Flutter module (necesario antes de correr la app Android):
   ```
   Bash(cd flutter_module && flutter build aar)
   ```
   O si es debug:
   ```
   Bash(cd flutter_module && flutter build aar --debug)
   ```

3. Compilá y ejecutá la app Android:
   ```
   Bash(./gradlew installDebug)
   ```

4. Si hay errores de build, corré el análisis primero:
   ```
   Bash(flutter analyze flutter_module/lib/)
   ```
   y:
   ```
   Bash(./gradlew lint)
   ```

Estructura de módulos:
- `Desarrollo/app/` → app Android nativa (Java)
- `Desarrollo/flutter_module/` → módulo Flutter embebido
- Las credenciales de Supabase van en `local.properties` (no en código)
