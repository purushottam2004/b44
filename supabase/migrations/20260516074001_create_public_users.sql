-- public.users
-- Mirrors auth.users with extra profile fields. id is a FK to auth.users(id).
-- Auto-populated on signup via a trigger on auth.users.

create table if not exists public.users (
    id uuid primary key references auth.users(id) on delete cascade,
    email text unique not null,
    full_name text,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_users_set_updated_at on public.users;
create trigger trg_users_set_updated_at
before update on public.users
for each row
execute function public.set_updated_at();

-- Auto-create public.users row when a new auth.users row is created.
-- Pulls full_name and avatar_url from raw_user_meta_data (Google OAuth provides these).
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.users (id, email, full_name, avatar_url)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
        coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture')
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

-- Keep public.users in sync when auth.users metadata changes (e.g., on re-login).
create or replace function public.handle_auth_user_updated()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.users
    set
        email = new.email,
        full_name = coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', full_name),
        avatar_url = coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', avatar_url)
    where id = new.id;
    return new;
end;
$$;

drop trigger if exists trg_on_auth_user_updated on auth.users;
create trigger trg_on_auth_user_updated
after update on auth.users
for each row
execute function public.handle_auth_user_updated();

-- RLS: a user can read/update only their own row. service_role bypasses RLS.
alter table public.users enable row level security;

drop policy if exists "users_select_self" on public.users;
create policy "users_select_self"
on public.users
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "users_update_self" on public.users;
create policy "users_update_self"
on public.users
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- No insert/delete policies: inserts are done by the trigger (security definer),
-- and deletes cascade from auth.users.
