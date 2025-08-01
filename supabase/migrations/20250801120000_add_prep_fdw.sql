-- Ensure necessary extensions
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Define FDW Server & User Mapping (safe to execute locally)
CREATE SERVER IF NOT EXISTS prep_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host 'db.qdvntffeffkfmvgmtdze.supabase.co',
    port '5432',
    dbname 'postgres'
  );

CREATE USER MAPPING IF NOT EXISTS FOR postgres
  SERVER prep_server
  OPTIONS (
    user 'prep_reader',
    password 'strong_pw'
  );

-- Ensure prep schema exists
CREATE SCHEMA IF NOT EXISTS prep;

-- Conditional FDW Import / Local Mock Table Creation
DO $$
DECLARE
  fdw_accessible BOOLEAN := false;
  table_exists BOOLEAN;
BEGIN
  -- Check if tables already exist
  SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'prep'
      AND table_name = 'daily_seasonal_indices'
  ) INTO table_exists;

  IF NOT table_exists THEN
    -- Attempt FDW Query to detect cloud environment
    BEGIN
      PERFORM 1 FROM prep_server.public."locations" LIMIT 1;
      fdw_accessible := true;
      RAISE NOTICE 'FDW server accessible. Importing foreign tables...';
    EXCEPTION WHEN OTHERS THEN
      fdw_accessible := false;
      RAISE NOTICE 'FDW server NOT accessible. Creating local mock tables...';
    END;

    IF fdw_accessible THEN
      -- Cloud Environment: Import Foreign Tables
      EXECUTE '
        IMPORT FOREIGN SCHEMA public
        LIMIT TO ("daily_seasonal_indices", "locations")
        FROM SERVER prep_server INTO prep
      ';
    ELSE
      -- Local Environment: Create Mock Tables
      
      -- prep.locations table with generated column
      EXECUTE '
        CREATE TABLE IF NOT EXISTS prep.locations (
          location_id SERIAL PRIMARY KEY,
          name VARCHAR(255),
          address TEXT,
          city VARCHAR(100),
          state VARCHAR(100),
          latitude NUMERIC(9,6) NOT NULL,
          longitude NUMERIC(9,6) NOT NULL,
          address_tsv TSVECTOR GENERATED ALWAYS AS (
            to_tsvector(
              ''english''::regconfig,
              COALESCE(address, '''') || '' '' || COALESCE(city, '''') || '' '' || COALESCE(state, '''')
            )
          ) STORED,
          created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
          updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
          "BOM_SiteID" INTEGER NOT NULL,
          height NUMERIC,
          region VARCHAR,
          status TEXT,
          is_coastal BOOLEAN,
          distance_to_coast_km NUMERIC,
          processed BOOLEAN DEFAULT false,
          timezone VARCHAR(50) DEFAULT '''',
          enso_rainfall_correlation NUMERIC,
          wmo INTEGER,
          geom GEOGRAPHY,
          CONSTRAINT locations_bom_siteid_key UNIQUE ("BOM_SiteID")
        )
      ';

      -- prep.daily_seasonal_indices table
      EXECUTE '
        CREATE TABLE IF NOT EXISTS prep.daily_seasonal_indices (
          id SERIAL PRIMARY KEY,
          location_id INTEGER NOT NULL,
          month_of_year INTEGER NOT NULL,
          day_of_month INTEGER NOT NULL,
          base_seasonal_index NUMERIC,
          modified_seasonal_index NUMERIC,
          modified_rainfall_trigger NUMERIC,
          climate_anomaly_flag BOOLEAN DEFAULT false,
          optimal_hour_trigger INTEGER DEFAULT 1,
          avg_rainfall_duration NUMERIC,
          sample_count INTEGER,
          last_pattern_analysis TIMESTAMP WITHOUT TIME ZONE,
          extended_risk_level VARCHAR(20),
          median_rainfall NUMERIC,
          rainfall_90th_percentile NUMERIC,
          version VARCHAR(50),
          climate_anomaly_id INTEGER,
          enso_factor NUMERIC,
          applied_anomaly_type VARCHAR(50),
          applied_anomaly_intensity VARCHAR(50),
          comprehensive_risk_index NUMERIC,
          policy_recommendation VARCHAR(100),
          high_risk_flag BOOLEAN DEFAULT false,
          trigger_1hr_prob NUMERIC,
          trigger_2hr_prob NUMERIC,
          trigger_3hr_prob NUMERIC,
          trigger_4hr_prob NUMERIC,
          temporal_context_flag BOOLEAN DEFAULT false,
          moderate_risk_flag BOOLEAN DEFAULT false,
          CONSTRAINT unique_location_day UNIQUE (location_id, month_of_year, day_of_month),
          CONSTRAINT daily_seasonal_indices_location_id_fkey FOREIGN KEY (location_id) REFERENCES prep.locations (location_id),
          CONSTRAINT daily_seasonal_indices_day_of_month_check CHECK (day_of_month >= 1 AND day_of_month <= 31),
          CONSTRAINT daily_seasonal_indices_month_of_year_check CHECK (month_of_year >= 1 AND month_of_year <= 12)
        )
      ';

      -- Indexes for prep.locations
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_address_tsv ON prep.locations USING gin (address_tsv)';
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_locations_active_status ON prep.locations (status) WHERE status = ''active''';
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_locations_geom ON prep.locations USING gist (geom)';
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_locations_geom_gist ON prep.locations USING gist (geom)';
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_locations_id ON prep.locations (location_id)';
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_locations_status ON prep.locations (status)';
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_locations_wmo ON prep.locations (wmo)';

      -- Indexes for prep.daily_seasonal_indices
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_daily_seasonal_composite_lookup ON prep.daily_seasonal_indices (
        location_id, month_of_year, day_of_month, modified_seasonal_index,
        modified_rainfall_trigger, optimal_hour_trigger, high_risk_flag,
        temporal_context_flag, version
      )';

      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_daily_seasonal_indices_location_id ON prep.daily_seasonal_indices (location_id)';

      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_daily_seasonal_indices_location_month_day ON prep.daily_seasonal_indices (
        location_id, month_of_year, day_of_month
      ) INCLUDE (
        modified_seasonal_index, modified_rainfall_trigger, optimal_hour_trigger,
        high_risk_flag, temporal_context_flag
      )';

      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_daily_seasonal_indices_lookup ON prep.daily_seasonal_indices (
        location_id, month_of_year, day_of_month
      ) WHERE modified_seasonal_index IS NOT NULL';

      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_daily_seasonal_indices_moderate_risk ON prep.daily_seasonal_indices (
        location_id, moderate_risk_flag
      ) WHERE moderate_risk_flag = true';

      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_daily_seasonal_indices_month_day ON prep.daily_seasonal_indices (
        month_of_year, day_of_month
      )';

    END IF;

  ELSE
    RAISE NOTICE 'Tables already exist. Skipping creation/import.';
  END IF;
END $$;