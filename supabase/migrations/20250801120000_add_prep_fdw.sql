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
  is_local boolean;
  table_exists boolean;
begin
  -- Detect if running locally (Supabase local Docker PostgreSQL is version 15.x, Cloud is 14.x)
  select current_setting('supabase_env', true) = 'local' into is_local;

  -- Check if tables already exist in 'prep' schema
  select exists (
    select from information_schema.tables
    where table_schema = 'prep'
      and table_name = 'daily_seasonal_indices'
  ) into table_exists;

  if not table_exists then
    if is_local then
      raise notice 'Local environment detected. Creating simplified mock tables...';

      -- Create prep schema
      execute 'create schema if not exists prep';

      -- Create simplified prep.locations table
      execute '
        create table if not exists prep.locations (
          location_id serial primary key,
          name character varying(255),
          address text,
          city character varying(100),
          state character varying(100),
          latitude numeric(9,6) not null,
          longitude numeric(9,6) not null,
          created_at timestamp without time zone default now(),
          updated_at timestamp without time zone default now(),
          "BOM_SiteID" integer not null,
          height numeric,
          region character varying,
          status text,
          is_coastal boolean,
          distance_to_coast_km numeric,
          processed boolean default false,
          timezone character varying(50) default '''',
          enso_rainfall_correlation numeric,
          wmo integer,
          geom geography,
          constraint locations_bom_siteid_key unique ("BOM_SiteID")
        )
      ';

      -- Create simplified prep.daily_seasonal_indices table
      execute '
        create table if not exists prep.daily_seasonal_indices (
          id serial primary key,
          location_id integer not null,
          month_of_year integer not null,
          day_of_month integer not null,
          base_seasonal_index numeric,
          modified_seasonal_index numeric,
          modified_rainfall_trigger numeric,
          climate_anomaly_flag boolean default false,
          optimal_hour_trigger integer default 1,
          avg_rainfall_duration numeric,
          sample_count integer,
          last_pattern_analysis timestamp without time zone,
          extended_risk_level character varying(20),
          median_rainfall numeric,
          rainfall_90th_percentile numeric,
          version character varying(50),
          climate_anomaly_id integer,
          enso_factor numeric,
          applied_anomaly_type character varying(50),
          applied_anomaly_intensity character varying(50),
          comprehensive_risk_index numeric,
          policy_recommendation character varying(100),
          high_risk_flag boolean default false,
          trigger_1hr_prob numeric,
          trigger_2hr_prob numeric,
          trigger_3hr_prob numeric,
          trigger_4hr_prob numeric,
          temporal_context_flag boolean default false,
          moderate_risk_flag boolean default false,
          constraint unique_location_day unique (location_id, month_of_year, day_of_month),
          constraint daily_seasonal_indices_location_id_fkey foreign key (location_id) references prep.locations (location_id),
          constraint daily_seasonal_indices_day_of_month_check check (day_of_month >= 1 and day_of_month <= 31),
          constraint daily_seasonal_indices_month_of_year_check check (month_of_year >= 1 and month_of_year <= 12)
        )
      ';

      -- Create basic indexes (safe for local dev)
      execute 'create index if not exists idx_locations_status on prep.locations (status)';
      execute 'create index if not exists idx_daily_seasonal_indices_location_id on prep.daily_seasonal_indices (location_id)';
      execute 'create index if not exists idx_daily_seasonal_indices_location_month_day on prep.daily_seasonal_indices (location_id, month_of_year, day_of_month)';

    else
      raise notice 'Cloud environment detected. Importing foreign tables from prep_server...';

      -- Import actual foreign tables via FDW in Cloud
      execute '
        import foreign schema public
        limit to ("daily_seasonal_indices", "locations")
        from server prep_server into prep
      ';
    end if;
  else
    raise notice 'Foreign tables or mock tables already exist. Skipping creation.';
  end if;
end $$;