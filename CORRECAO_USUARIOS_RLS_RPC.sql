-- CORRECAO_USUARIOS_RLS_RPC.sql
-- Objetivo:
-- 1. Restabelecer o fluxo de usuarios/login esperado pelo front.
-- 2. Criar aliases RPC que o mapa-rede-optica.html ja tenta consumir.
-- 3. Blindar a tabela public.usuarios para uso com x-app-token/check_app_token().

begin;

-- Remove assinaturas antigas incompatíveis com o front atual.
drop function if exists public.fn_login_usuario(text, text);
drop function if exists public.fn_touch_usuario(uuid, uuid);
drop function if exists public.fn_create_usuario(text, text, text, text, boolean);
drop function if exists public.fn_create_usuario(text, text, text, text, boolean, text);
drop function if exists public.fn_update_usuario(uuid, uuid, text, text, text, text, boolean);
drop function if exists public.fn_update_usuario(uuid, uuid, text, text, text, text, boolean, text);
drop trigger if exists trg_usuarios_hash on public.usuarios;
drop function if exists public.fn_usuarios_fill_hash();

create or replace function public.fn_usuarios_fill_hash()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.senha_texto is not null and trim(new.senha_texto) <> '' then
    new.senha_hash := encode(extensions.digest(trim(new.senha_texto)::text, 'sha256'::text), 'hex');
  end if;
  return new;
end;
$$;

create trigger trg_usuarios_hash
before insert or update of senha_texto
on public.usuarios
for each row
execute function public.fn_usuarios_fill_hash();

-- Politicas REST para o app local.
-- Mantem o modelo atual baseado em x-app-token sem abrir a tabela publicamente.
do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'check_app_token'
  ) then
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'usuarios'
        and policyname = 'usuarios_select_app'
    ) then
      create policy usuarios_select_app
      on public.usuarios
      for select
      to public
      using (check_app_token());
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'usuarios'
        and policyname = 'usuarios_write_app'
    ) then
      create policy usuarios_write_app
      on public.usuarios
      for all
      to public
      using (check_app_token())
      with check (check_app_token());
    end if;
  end if;
end $$;

-- Alias de login que o front espera.
create or replace function public.fn_login_usuario(
  p_email text default null,
  email text default null
)
returns table (
  id uuid,
  nome text,
  email text,
  perfil text,
  ativo boolean,
  senha_texto text,
  senha_hash text,
  ultimo_acesso timestamptz,
  criado_em timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    u.id,
    u.nome,
    u.email,
    u.perfil,
    u.ativo,
    u.senha_texto,
    u.senha_hash,
    u.ultimo_acesso,
    u.criado_em
  from public.usuarios u
  where lower(u.email) = lower(coalesce(fn_login_usuario.p_email, fn_login_usuario.email, ''))
    and coalesce(u.ativo, true) = true
  order by u.criado_em asc nulls last
  limit 1;
$$;

-- Alias de touch/ultimo acesso.
create or replace function public.fn_touch_usuario(
  p_id uuid default null,
  id uuid default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := coalesce(p_id, id);
begin
  if v_id is null then
    return false;
  end if;

  update public.usuarios
     set ultimo_acesso = now()
   where usuarios.id = v_id;

  return found;
end;
$$;

-- Criacao de usuario compatível com o payload do front.
create or replace function public.fn_create_usuario(
  nome text,
  email text,
  senha_texto text default null,
  perfil text default 'colaborador',
  ativo boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into public.usuarios (
    nome,
    email,
    senha_hash,
    senha_texto,
    perfil,
    ativo
  )
  values (
    trim(nome),
    lower(trim(email)),
    '',
    nullif(trim(senha_texto), ''),
    coalesce(nullif(trim(perfil), ''), 'colaborador'),
    coalesce(ativo, true)
  )
  returning usuarios.id into v_id;

  return v_id;
end;
$$;

-- Atualizacao parcial de usuario compativel com o payload do front.
create or replace function public.fn_update_usuario(
  p_id uuid default null,
  id uuid default null,
  nome text default null,
  email text default null,
  senha_texto text default null,
  perfil text default null,
  ativo boolean default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := coalesce(p_id, id);
begin
  if v_id is null then
    return false;
  end if;

  update public.usuarios u
     set nome = coalesce(nullif(trim(fn_update_usuario.nome), ''), u.nome),
         email = coalesce(lower(nullif(trim(fn_update_usuario.email), '')), u.email),
         senha_texto = case
           when fn_update_usuario.senha_texto is null or trim(fn_update_usuario.senha_texto) = '' then u.senha_texto
           else trim(fn_update_usuario.senha_texto)
         end,
         perfil = coalesce(nullif(trim(fn_update_usuario.perfil), ''), u.perfil),
         ativo = coalesce(fn_update_usuario.ativo, u.ativo)
   where u.id = v_id;

  return found;
end;
$$;

grant execute on function public.fn_login_usuario(text, text) to anon, authenticated;
grant execute on function public.fn_touch_usuario(uuid, uuid) to anon, authenticated;
grant execute on function public.fn_create_usuario(text, text, text, text, boolean) to anon, authenticated;
grant execute on function public.fn_update_usuario(uuid, uuid, text, text, text, text, boolean) to anon, authenticated;

commit;
