-- Unicidad de correo (y usuario) en el registro, aplicado el 2026-06-11.
-- Contexto: la tabla `usuarios` NO tiene constraint UNIQUE en correo/usuario
-- (ver ESTRUCTURA-COMPLETA-SUPABASE.md §15 #7), así que se permitían duplicados.
-- Estas funciones rechazan el alta si el correo (o el usuario) ya existe,
-- devolviendo SQLSTATE 23505 → el nativo lo mapea al código `DUPLICADO` y
-- muestra el mensaje claro en la pantalla.

-- ── registro manual ─────────────────────────────────────────────────────────
create or replace function public.registrar_usuario(p_data jsonb)
returns setof usuarios
language plpgsql
as $function$
begin
  if exists (select 1 from usuarios where lower(correo) = lower(p_data->>'correo')) then
    raise exception 'Ese correo ya está registrado.' using errcode = 'unique_violation';
  end if;
  if exists (select 1 from usuarios where lower(usuario) = lower(p_data->>'usuario')) then
    raise exception 'Ese nombre de usuario ya está en uso.' using errcode = 'unique_violation';
  end if;

  return query
  insert into usuarios (
    usuario, correo, contrasena, nombre, apellido,
    id_nacion, id_genero, fecha_nacimiento, activo
  )
  values (
    p_data->>'usuario',
    p_data->>'correo',
    p_data->>'contrasena',
    p_data->>'nombre',
    p_data->>'apellido',
    (p_data->>'id_nacion')::int,
    (p_data->>'id_genero')::int,
    (p_data->>'fecha_nacimiento')::timestamp,
    true
  )
  returning *;
end;
$function$;

-- ── alta social (Google) ────────────────────────────────────────────────────
create or replace function public.registrar_usuario_google(p_data jsonb)
returns setof usuarios
language plpgsql
as $function$
begin
  if exists (select 1 from usuarios where lower(correo) = lower(p_data->>'correo')) then
    raise exception 'Ese correo ya está registrado.' using errcode = 'unique_violation';
  end if;

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
