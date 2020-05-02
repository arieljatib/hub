-- Start transaction and plan tests
begin;
select plan(4);

-- Declare some variables
\set user1ID '00000000-0000-0000-0000-000000000001'
\set user2ID '00000000-0000-0000-0000-000000000002'
\set repo1ID '00000000-0000-0000-0000-000000000001'
\set package1ID '00000000-0000-0000-0000-000000000001'
\set package2ID '00000000-0000-0000-0000-000000000002'
\set image1ID '00000000-0000-0000-0000-000000000001'


-- Seed some data
insert into "user" (user_id, alias, email) values (:'user1ID', 'user1', 'user1@email.com');
insert into "user" (user_id, alias, email) values (:'user2ID', 'user2', 'user2@email.com');
insert into chart_repository (chart_repository_id, name, display_name, url, user_id)
values (:'repo1ID', 'repo1', 'Repo 1', 'https://repo1.com', :'user1ID');
insert into package (
    package_id,
    name,
    latest_version,
    logo_image_id,
    stars,
    package_kind_id,
    chart_repository_id
) values (
    :'package1ID',
    'Package 1',
    '1.0.0',
    :'image1ID',
    10,
    0,
    :'repo1ID'
);
insert into user_starred_package(user_id, package_id) values (:'user1ID', :'package1ID');


-- Run some tests
select is(
    get_package_stars(null, :'package1ID')::jsonb,
    '{
        "stars": 10,
        "starred_by_user": null
    }'::jsonb,
    'starred_by_user should be null when using a null user_id'
);
select is(
    get_package_stars(:'user1ID', :'package1ID')::jsonb,
    '{
        "stars": 10,
        "starred_by_user": true
    }'::jsonb,
    'starred_by_user should be true'
);
select is(
    get_package_stars(:'user2ID', :'package1ID')::jsonb,
    '{
        "stars": 10,
        "starred_by_user": false
    }'::jsonb,
    'starred_by_user should be false'
);
select is(
    get_package_stars(:'user2ID', :'package2ID')::jsonb,
    '{
        "stars": null,
        "starred_by_user": false
    }'::jsonb,
    'stars should be null as package does not exist'
);


-- Finish tests and rollback transaction
select * from finish();
rollback;