-- Onboarding social en 2 pasos, aplicado el 2026-06-11.
-- Contexto: la función vieja `login_or_create_google` creaba el usuario en el
-- acto, pero dejaba id_nacion/id_genero/nombre/apellido/fecha_nacimiento en NULL
-- → violaba los NOT NULL de `usuarios` (error 23502). Google no provee
-- nación/género/fecha, así que ahora se piden en una pantalla de onboarding y
-- el alta se hace con TODOS los campos vía esta función.
--
-- El "login si ya existe" se resuelve con un simple GET por correo desde el
-- nativo (RLS está deshabilitado en public.usuarios), así que no hace falta una
-- función para ese paso.

-- ────────────────────────────────────────────────────────────────────────────
-- registrar_usuario_google: alta social con los campos del onboarding.
--   - usuario      → se deriva del correo (parte antes del @).
--   - contrasena   → aleatoria md5(uuid) (el usuario de Google no usa password).
--   - id_cuenta    → default 1 (Free) de la tabla.
-- ────────────────────────────────────────────────────────────────────────────
create or replace function public.registrar_usuario_google(p_data jsonb)
returns setof usuarios
language plpgsql
as $function$
begin
  return query
  insert into usuarios (
    correo, usuario, contrasena, nombre, apellido,
    id_nacion, id_genero, fecha_nacimiento, foto, activo
  )
  values (
    p_data->>'correo',
    split_part(p_data->>'correo', '@', 1),
    md5(gen_random_uuid()::text),
    p_data->>'nombre',
    p_data->>'apellido',
    (p_data->>'id_nacion')::int,
    (p_data->>'id_genero')::int,
    (p_data->>'fecha_nacimiento')::timestamp,
    nullif(p_data->>'foto', ''),
    true
  )
  returning *;
end;
$function$;

-- Opcional: la función vieja ya no se usa desde la app.
-- drop function if exists public.login_or_create_google(text, text, text, text, text);
