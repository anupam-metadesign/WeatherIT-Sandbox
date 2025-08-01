-- ✅ Ensure postgis and FDW are installed **before** the DO block
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";
create extension if not exists postgres_fdw;

-- ✅ Create server & mapping (safe to repeat)
create server if not exists prep_server
  foreign data wrapper postgres_fdw
  options (
    host 'db.qdvntffeffkfmvgmtdze.supabase.co',
    port '5432',
    dbname 'postgres'
  );

create user mapping if not exists for postgres
  server prep_server
  options (
    user 'prep_reader',
    password 'strong_pw'
  );

create schema if not exists prep;

-- ✅ Conditionally import only if table doesn't exist
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
    raise notice 'Importing foreign tables from prep_server...';
    execute $import$
      import foreign schema public
      limit to ("daily_seasonal_indices", "locations")
      from server prep_server into prep
    $import$;
  else
    raise notice 'Foreign tables already exist. Skipping import.';
  end if;
end $$;