-- CineVault · esquema de Supabase
-- Pégalo en Supabase → SQL Editor → Run

-- 1) Perfiles públicos (nombre de usuario único)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  created_at timestamptz not null default now()
);
create unique index if not exists profiles_username_lower_idx on public.profiles (lower(username));

alter table public.profiles enable row level security;
create policy "perfiles visibles para usuarios registrados" on public.profiles
  for select to authenticated using (true);
create policy "cada usuario edita su perfil" on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- 2) Crear el perfil automáticamente al registrarse (toma el nombre de user_metadata)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)));
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3) Comprobar si un nombre de usuario está libre (se llama antes de registrarse)
create or replace function public.username_available(p_username text)
returns boolean language sql security definer set search_path = public stable as $$
  select not exists (select 1 from public.profiles where lower(username) = lower(p_username));
$$;
grant execute on function public.username_available(text) to anon, authenticated;

-- 4) Datos de cada usuario (colección, diario, diseño…) como JSON
create table if not exists public.cinevault_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.cinevault_data enable row level security;
create policy "leer mis datos" on public.cinevault_data
  for select to authenticated using (auth.uid() = user_id);
create policy "crear mis datos" on public.cinevault_data
  for insert to authenticated with check (auth.uid() = user_id);
create policy "actualizar mis datos" on public.cinevault_data
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "borrar mis datos" on public.cinevault_data
  for delete to authenticated using (auth.uid() = user_id);
