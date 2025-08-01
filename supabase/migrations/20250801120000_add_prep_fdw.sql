-- Enable necessary extensions
create extension if not exists postgis;
create extension if not exists postgres_fdw;

-- Set up foreign server
create server if not exists prep_server
  foreign data wrapper postgres_fdw
  options (
    host 'db.qdvntffeffkfmvgmtdze.supabase.co',
    port '5432',
    dbname 'postgres'
  );

-- Create user mapping
create user mapping if not exists for postgres
  server prep_server
  options (
    user 'prep_reader',
    password 'strong_pw'
  );

-- Create schema if missing
create schema if not exists prep;

-- Conditionally import foreign tables
do $$
declare
  table_exists boolean;
begin
  select exists (
    select from information_schema.tables
    where table_schema = 'prep'
      and table_name = 'daily_seasonal_indices'
  ) into table_exists;

  if not table_exists then
    execute $import$
      import foreign schema public
      limit to ("daily_seasonal_indices", "locations")
      from server prep_server into prep
    $import$;
  end if;
end $$;