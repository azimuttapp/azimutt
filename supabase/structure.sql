-- TODO: handle updated_by column
-- TODO: forbid change columns: id, created_at, created_by, updated_at, updated_by => https://dev.to/jdgamble555/supabase-date-protection-on-postgresql-1n91

-- security definers: https://supabase.com/docs/guides/auth/row-level-security#policies-with-security-definer-functions

-- drop everything

drop table if exists public.profiles;
drop table if exists public.projects;

-- create db
create extension if not exists moddatetime schema extensions;

create table public.profiles
(
    id         uuid        not null primary key references auth.users,
    email      varchar     not null unique check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    username   varchar     not null unique check (char_length(username) > 3),
    name       varchar     not null,
    avatar     varchar,
    bio        varchar,
    company    varchar,
    location   varchar,
    website    varchar,
    github     varchar,
    twitter    varchar,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);
comment on table public.profiles is 'browsable user information';
comment on column public.profiles.id is 'references the internal supabase auth user';
create trigger handle_updated_at
    before update
    on public.profiles
    for each row
execute procedure moddatetime(updated_at);
alter table public.profiles
    enable row level security;
create policy "Users can insert their" on public.profiles as permissive for insert to authenticated with check (auth.uid() = id);
create policy "Users can delete their" on public.profiles as permissive for delete to authenticated using (auth.uid() = id);
create policy "Users can update their" on public.profiles as permissive for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users can select any" on public.profiles as permissive for select to authenticated using (true);


create table public.projects
(
    id         uuid        not null primary key,
    name       varchar     not null,
    tables     smallint    not null,
    relations  smallint    not null,
    layouts    smallint    not null,
    owners     uuid[]      not null,
    project    json        not null,
    created_at timestamptz not null default timezone('utc'::text, now()),
    created_by uuid        not null default auth.uid() references auth.users,
    updated_at timestamptz not null default timezone('utc'::text, now()),
    updated_by uuid        not null default auth.uid() references auth.users
);
comment on table public.projects is 'list stored projects';
create trigger handle_updated_at
    before update
    on public.projects
    for each row
execute procedure moddatetime(updated_at);
alter table public.projects
    enable row level security;
create policy "Users can insert" on public.projects as permissive for insert to authenticated with check (true);
create policy "Owners can delete" on public.projects as permissive for delete to authenticated using (auth.uid() = any (owners));
create policy "Owners can update" on public.projects as permissive for update to authenticated using (auth.uid() = any (owners)) with check (auth.uid() = any (owners));
create policy "Owners can select" on public.projects as permissive for select to authenticated using (auth.uid() = any (owners));


insert into storage.buckets (id, name)
values ('avatars', 'avatars');
create policy "Users can create avatars" on storage.objects for insert to authenticated with check (bucket_id = 'avatars');
create policy "Users can delete their avatar" on storage.objects for delete to authenticated using (bucket_id = 'avatars' and auth.uid() = owner);
create policy "Users can update their avatar" on storage.objects for update to authenticated using (bucket_id = 'avatars' and auth.uid() = owner);
create policy "Anyone can select avatars" on storage.objects for select to authenticated, anon using (bucket_id = 'avatars');
