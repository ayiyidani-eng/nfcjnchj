-- CineVault · Comunidad (ejecútalo UNA vez en Supabase → SQL Editor → Run)
-- Requiere haber ejecutado antes supabase.sql

-- 1) Perfil público o privado + resumen ligero que se muestra en el listado
alter table public.profiles add column if not exists is_public boolean not null default true;
alter table public.profiles add column if not exists summary jsonb not null default '{}'::jsonb;

-- 2) Los perfiles solo son visibles si son públicos (o si son tuyos)
drop policy if exists "perfiles visibles para usuarios registrados" on public.profiles;
drop policy if exists "ver perfiles públicos" on public.profiles;
create policy "ver perfiles públicos" on public.profiles
  for select to authenticated using (is_public or id = auth.uid());

-- 3) Los datos completos (diario, calendario, favoritas…) de perfiles públicos se pueden leer
drop policy if exists "ver datos de perfiles públicos" on public.cinevault_data;
create policy "ver datos de perfiles públicos" on public.cinevault_data
  for select to authenticated using (
    exists (select 1 from public.profiles p where p.id = cinevault_data.user_id and p.is_public)
  );

-- 4) Seguidores
create table if not exists public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followee_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
alter table public.follows enable row level security;
drop policy if exists "ver seguimientos" on public.follows;
drop policy if exists "seguir" on public.follows;
drop policy if exists "dejar de seguir" on public.follows;
create policy "ver seguimientos" on public.follows for select to authenticated using (true);
create policy "seguir" on public.follows for insert to authenticated with check (auth.uid() = follower_id);
create policy "dejar de seguir" on public.follows for delete to authenticated using (auth.uid() = follower_id);
