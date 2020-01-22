create extension if not exists "uuid-ossp";

create table if not exists chart_repository (
    chart_repository_id uuid primary key default uuid_generate_v4(),
    name text not null check (name <> '') unique,
    display_name text,
    url text not null check (url <> '') unique
);

{{ template "data/charts-repos.sql" }}

create table if not exists package_kind (
    package_kind_id integer primary key,
    name text not null check (name <> '')
);

insert into package_kind values (0, 'chart');

create function generate_package_tsdoc(
    p_name text,
    p_display_name text,
    p_description text,
    p_keywords text[]
) returns tsvector as $$
    select
        setweight(to_tsvector(p_name), 'A') ||
        setweight(to_tsvector(coalesce(p_display_name, '')), 'A') ||
        setweight(to_tsvector(coalesce(p_description, '')), 'B') ||
        setweight(array_to_tsvector(coalesce(p_keywords, '{}')), 'C');
$$ language sql immutable;

create table if not exists package (
    package_id uuid primary key default uuid_generate_v4(),
    name text not null check (name <> ''),
    display_name text check (display_name <> ''),
    description text check (description <> ''),
    home_url text check (home_url <> ''),
    logo_url text check (logo_url <> ''),
    keywords text[],
    latest_version text not null check (latest_version <> ''),
    tsdoc tsvector generated always as (
        generate_package_tsdoc(name, display_name, description, keywords)
    ) stored,
    package_kind_id integer not null references package_kind on delete restrict,
    chart_repository_id uuid references chart_repository on delete restrict,
    check (package_kind_id <> 0 or chart_repository_id is not null),
    unique (chart_repository_id, name)
);

create index package_tsdoc_idx on package using gin (tsdoc);
create index package_package_kind_id_idx on package (package_kind_id);
create index package_chart_repository_id_idx on package (chart_repository_id);

create table if not exists snapshot (
    package_id uuid not null references package on delete cascade,
    version text not null check (version <> ''),
    app_version text check (app_version <> ''),
    digest text not null check (digest <> ''),
    readme text check (readme <> ''),
    links jsonb,
    primary key (package_id, version)
);

create table if not exists maintainer (
    maintainer_id uuid primary key default uuid_generate_v4(),
    name text not null,
    email text not null check (email <> '') unique
);

create table if not exists package__maintainer (
    package_id uuid not null references package on delete cascade,
    maintainer_id uuid not null references maintainer on delete cascade,
    primary key (package_id, maintainer_id)
);

{{ template "functions/functions.sql" }}

---- create above / drop below ----

{{ template "functions/drop_all_functions.sql" }}

drop table if exists package__maintainer;
drop table if exists maintainer;
drop table if exists snapshot;
drop index if exists package_chart_repository_id_idx;
drop index if exists package_package_kind_id_idx;
drop index if exists package_tsdoc_idx;
drop table if exists package;
drop function if exists generate_package_tsdoc(
    p_name text,
    p_display_name text,
    p_description text,
    p_keywords text[]
);
drop table if exists package_kind;
drop table if exists chart_repository;
drop extension if exists "uuid-ossp";
