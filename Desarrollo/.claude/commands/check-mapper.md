Verificá la consistencia de Mapper.java contra todas las entidades Java y modelos Flutter del proyecto.

$ARGUMENTS
(Opcional: pasá el nombre de una entidad específica para verificar solo esa, ej: "Usuario" o "Receta")

Qué verificar:
1. **Entidades Java** (`app/src/main/java/com/example/bocado/model/`): listá todos los campos de cada entidad.
2. **Mapper.java**: para cada entidad, ¿existe un método de conversión? ¿mapea todos los campos?
3. **Campos faltantes**: ¿hay campos en la entidad que no se mapean en el Mapper?
4. **Campos extra**: ¿el Mapper intenta mapear campos que no existen en la entidad?
5. **Flutter models**: ¿los modelos Dart en `flutter_module/lib/` tienen los mismos campos que sus contrapartes Java?
6. **Nulos**: ¿hay campos que podrían ser null sin manejo defensivo en el Mapper?

Formato del reporte:
- Por entidad: ✅ Completa / ⚠️ Campos faltantes: [lista] / ❌ Campos rotos: [lista]
- Resumen de inconsistencias Flutter ↔ Java
- Sugerencias de corrección con código si hay problemas
