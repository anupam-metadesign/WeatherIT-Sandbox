create extension if not exists postgres_fdw;

create server prep_server
  foreign data wrapper postgres_fdw
  options (
    host "db.qdvntffeffkfmvgmtdze.supabase.co",
    port "5432",
    dbname "postgres"
  );

create user mapping for postgres
  server prep_server
  options (user "prep_reader", password "strong_pw");


create schema if not exists prep;

import foreign schema public
  limit to ("daily_seasonal_indices","locations")
  from server prep_server into prep;