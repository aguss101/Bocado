---
name: bocado-verify
description: Verifica que un flujo Channel→DAO en Bocado funciona correctamente leyendo el código fuente de punta a punta.
---

Para verificar un flujo en Bocado sin correr la app:

## Método de verificación estática

1. **Identificá el método a verificar** (ej: "seguir usuario", "guardar receta")

2. **Rastreá desde Flutter hacia abajo**:
   - ¿Qué widget/screen llama al service?
   - ¿Qué método del service invoca al channel? ¿Con qué argumentos?

3. **Cruzá al lado Java**:
   - ¿El Channel handler tiene el método correspondiente en el `onMethodCall`?
   - ¿Los argumentos que envía Flutter los lee correctamente el Channel?

4. **Verificá la cadena Manager → DAO**:
   - ¿El Manager recibe los argumentos correctos?
   - ¿El DAO construye el body JSON correcto para la RPC?

5. **Verificá la respuesta**:
   - ¿El DAO pasa la respuesta al callback?
   - ¿El Manager la procesa?
   - ¿El Channel la devuelve al Flutter con `result.success()`?
   - ¿Flutter recibe y parsea correctamente el Map?

## Veredicto
- ✅ Flujo completo y consistente
- ⚠️ Posible problema en [capa]: [descripción]
- ❌ Bug encontrado en [capa]: [descripción y corrección sugerida]
