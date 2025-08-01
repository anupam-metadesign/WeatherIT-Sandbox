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
  -- Detect if running locally (Supabase Local Docker PostgreSQL is version 15.x, Cloud is 14.x)
  select current_setting('server_version') like '15.%' into is_local;

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
      execute $$
        create table if not exists prep.locations (
          location_id serial primary key,
          name character varying(255) null,
          address text null,
          city character varying(100) null,
          state character varying(100) null,
          latitude numeric(9, 6) not null,
          longitude numeric(9, 6) not null,
          created_at timestamp without time zone null default now(),
          updated_at timestamp without time zone null default now(),
          "BOM_SiteID" integer not null,
          height numeric null,
          region character varying null,
          status text null,
          is_coastal boolean null,
          distance_to_coast_km numeric null,
          processed boolean null default false,
          timezone character varying(50) null default ''::character varying,
          enso_rainfall_correlation numeric null,
          wmo integer null,
          geom geography null,
          constraint locations_bom_siteid_key unique ("BOM_SiteID")
        )
      $$;

      -- Create simplified prep.daily_seasonal_indices table
      execute $$
        create table if not exists prep.daily_seasonal_indices (
          id serial primary key,
          location_id integer not null,
          month_of_year integer not null,
          day_of_month integer not null,
          base_seasonal_index numeric null,
          modified_seasonal_index numeric null,
          modified_rainfall_trigger numeric null,
          climate_anomaly_flag boolean null default false,
          optimal_hour_trigger integer not null default 1,
          avg_rainfall_duration numeric null,
          sample_count integer null,
          last_pattern_analysis timestamp without time zone null,
          extended_risk_level character varying(20) null,
          median_rainfall numeric null,
          rainfall_90th_percentile numeric null,
          version character varying(50) null,
          climate_anomaly_id integer null,
          enso_factor numeric null,
          applied_anomaly_type character varying(50) null,
          applied_anomaly_intensity character varying(50) null,
          comprehensive_risk_index numeric null,
          policy_recommendation character varying(100) null,
          high_risk_flag boolean null default false,
          trigger_1hr_prob numeric null,
          trigger_2hr_prob numeric null,
          trigger_3hr_prob numeric null,
          trigger_4hr_prob numeric null,
          temporal_context_flag boolean null default false,
          moderate_risk_flag boolean null default false,
          constraint unique_location_day unique (location_id, month_of_year, day_of_month),
          constraint daily_seasonal_indices_location_id_fkey foreign key (location_id) references prep.locations (location_id),
          constraint daily_seasonal_indices_day_of_month_check check ((day_of_month >= 1) and (day_of_month <= 31)),
          constraint daily_seasonal_indices_month_of_year_check check ((month_of_year >= 1) and (month_of_year <= 12))
        )
      $$;

      -- Only minimal essential indexes
      execute $$ create index if not exists idx_locations_id on prep.locations (location_id) $$;
      execute $$ create index if not exists idx_locations_status on prep.locations (status) $$;
      execute $$ create index if not exists idx_daily_seasonal_indices_location_id on prep.daily_seasonal_indices (location_id) $$;
      execute $$ create index if not exists idx_daily_seasonal_indices_location_month_day on prep.daily_seasonal_indices (location_id, month_of_year, day_of_month) $$;

    else
      raise notice 'Cloud environment detected. Importing foreign tables from prep_server...';

      -- Import actual foreign tables via FDW in Cloud
      execute $import$
        import foreign schema public
        limit to ("daily_seasonal_indices", "locations")
        from server prep_server into prep
      $import$;
    end if;
  else
    raise notice 'Foreign tables or mock tables already exist. Skipping creation.';
  end if;
end $$;