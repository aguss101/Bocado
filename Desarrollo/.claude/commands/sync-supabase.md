Comparar el estado actual del código contra lo documentado del schema de Supabase y detectar inconsistencias.

$ARGUMENTS
(Opcional: "tabla usuarios", "rpc recetas", o dejalo vacío para un análisis completo)

Qué comparar:
1. **DAOs vs Schema**: ¿los campos que usan los DAOs existen en las tablas de Supabase documentadas?
2. **RPCs usadas**: ¿todas las RPCs llamadas desde Java están documentadas? ¿alguna puede haber cambiado su firma?
3. **Entidades Java vs tablas**: ¿los campos de las entidades Java matchean las columnas de las tablas?
4. **Modelos Flutter vs tablas**: ¿los modelos Dart tienen campos obsoletos o faltantes?
5. **Storage**: ¿los buckets referenciados en `ImagesChannel` son los correctos?
6. **Auth**: ¿el flujo de auth en `AccessChannel` usa los endpoints de Supabase Auth correctos?

Resultado esperado:
- Lista de inconsistencias detectadas (campo/tabla/RPC)
- Campos que el código usa pero que podrían no existir en la DB
- Sugerencia: qué revisar en el dashboard de Supabase para confirmar
