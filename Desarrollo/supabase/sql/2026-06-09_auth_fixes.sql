-- Cambios de autenticación aplicados el 2026-06-09 vía Management API.
-- Contexto: ver Base de datos/ESTRUCTURA-COMPLETA-SUPABASE.md §15.

-- ────────────────────────────────────────────────────────────────────────────
-- #1  registrar_usuario (Opción A): recibe un jsonb con TODOS los campos.
--     Antes solo insertaba (usuario, correo, contrasena) y violaba los NOT NULL
--     de nombre/apellido/id_nacion/id_genero/fecha_nacimiento.
-- ────────────────────────────────────────────────────────────────────────────
drop function if exists public.registrar_usuario(text, text, text);

create or replace function public.registrar_usuario(p_data jsonb)
returns setof usuarios
language plpgsql
as $function$
begin
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

-- ────────────────────────────────────────────────────────────────────────────
-- #10 login_usuario: ahora actualiza fecha_acceso al validar credenciales.
--     Solo actualiza/retorna la fila si usuario/correo + contraseña coinciden
--     y la cuenta está activa.
-- ────────────────────────────────────────────────────────────────────────────
create or replace function public.login_usuario(p_usuario text, p_contrasena text)
returns setof usuarios
language plpgsql
as $function$
begin
  return query
  update usuarios
     set fecha_acceso = (now() at time zone 'utc')
   where (usuario = p_usuario or correo = p_usuario)
     and contrasena = p_contrasena
     and activo = true
  returning *;
end;
$function$;
