-- 1. Enable the FDW extension
create extension if not exists postgres_fdw;

-- 2. Define the foreign server
create server if not exists prep_server
  foreign data wrapper postgres_fdw
  options (
    host 'db.qdvntffeffkfmvgmtdze.supabase.co',
    port '5432',
    dbname 'postgres'
  );

-- 3. Map the local role to the remote role
create user mapping if not exists for postgres
  server prep_server
  options (
    user 'prep_reader',
    password 'strong_pw'
  );

-- 4. Create a local schema to hold foreign tables
create schema if not exists prep;

-- 5. Import the tables you want
import foreign schema public
  limit to ('daily_seasonal_indices', 'locations')
  from server prep_server into prep;