-- drop everything

delete from storage.buckets where id = 'projects';
delete from storage.buckets where id = 'avatars';
drop policy if exists "Users can create avatars" on storage.objects;
drop policy if exists "Users can delete their avatar" on storage.objects;
drop policy if exists "Users can update their avatar" on storage.objects;
drop policy if exists "Anyone can select avatars" on storage.objects;
drop table if exists public.projects;
drop table if exists public.profiles;
delete from auth.users where true;

-- create db
create table public.profiles
(
    id         uuid        not null primary key references auth.users,
    email      varchar     not null unique check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    username   varchar     not null unique check (char_length(username) > 3),
    name       varchar     not null check (char_length(username) > 2),
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
alter table public.profiles enable row level security;
comment on table public.profiles is 'browsable user information';
comment on column public.profiles.id is 'references the internal supabase auth user';

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
alter table public.projects enable row level security;
comment on table public.projects is 'list stored projects';

insert into storage.buckets (id, name) values ('projects', 'projects');

insert into storage.buckets (id, name) values ('avatars', 'avatars');
create policy "Users can create avatars" on storage.objects for insert to authenticated with check (bucket_id = 'avatars');
create policy "Users can delete their avatar" on storage.objects for delete to authenticated using (bucket_id = 'avatars' and auth.uid() = owner);
create policy "Users can update their avatar" on storage.objects for update to authenticated using (bucket_id = 'avatars' and auth.uid() = owner);
create policy "Anyone can select avatars" on storage.objects for select to authenticated, anon using (bucket_id = 'avatars');
