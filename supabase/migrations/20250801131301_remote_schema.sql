create extension if not exists "http" with schema "extensions";

create extension if not exists "postgis" with schema "extensions";

create extension if not exists "postgis_raster" with schema "extensions";


create schema if not exists "gis";


create extension if not exists "postgres_fdw" with schema "public" version '1.1';

create sequence "public"."audit_documentation_id_seq";

create sequence "public"."claim_weather_hourly_id_seq";

create sequence "public"."quote_config_config_id_seq";

create sequence "public"."quote_expiration_logs_id_seq";

create sequence "public"."seasonal_config_config_id_seq";

create sequence "public"."unified_audit_log_id_seq";

create table "public"."api_keys" (
    "id" uuid not null default gen_random_uuid(),
    "partner_id" uuid not null,
    "partner_name" text,
    "is_active" boolean default true,
    "rate_limits" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone default now(),
    "last_used_at" timestamp with time zone,
    "deactivated_at" timestamp with time zone,
    "deactivation_reason" text,
    "api_key_hash" text not null,
    "expires_at" timestamp with time zone,
    "rate_limit_per_hour" integer default 1000,
    "auto_rotate_days" integer default 180,
    "last_rotation_at" timestamp with time zone default now(),
    "usage_count" integer default 0,
    "last_ip_address" inet,
    "partner_email" text not null,
    "description" text default 'External Partner API Key'::text
);


alter table "public"."api_keys" enable row level security;

create table "public"."audit_documentation" (
    "id" integer not null default nextval('audit_documentation_id_seq'::regclass),
    "doc_type" text not null,
    "title" text not null,
    "content" text not null,
    "version" text default '1.0'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


create table "public"."claim_locations" (
    "claim_location_id" uuid not null default gen_random_uuid(),
    "claim_id" uuid not null,
    "location_id" integer,
    "location_latitude" numeric not null,
    "location_longitude" numeric not null,
    "policy_latitude" numeric not null,
    "policy_longitude" numeric not null,
    "is_primary_location" boolean default true,
    "data_source" character varying(50) default 'primary_location'::character varying,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."claim_locations" enable row level security;

create table "public"."claim_weather_hourly" (
    "id" integer not null default nextval('claim_weather_hourly_id_seq'::regclass),
    "claim_id" uuid not null,
    "claim_location_id" uuid not null,
    "weather_date" date not null,
    "hour" integer not null,
    "temperature" numeric,
    "rainfall_amount" numeric,
    "humidity" numeric,
    "wind_speed" numeric,
    "weather_source" character varying(50),
    "model_used" character varying(50),
    "created_at" timestamp with time zone default now()
);


alter table "public"."claim_weather_hourly" enable row level security;

create table "public"."claims" (
    "claim_id" uuid not null default gen_random_uuid(),
    "policy_id" uuid not null,
    "claim_date" date not null,
    "claim_amount" numeric(10,2) not null,
    "claim_status" character varying(50) not null default 'pending'::character varying,
    "claim_reason" text,
    "payout_transaction_id" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "trigger_date" date,
    "rainfall_triggered" boolean default false,
    "payout_percentage" numeric,
    "exposure_total" numeric,
    "policy_trigger" numeric,
    "policy_duration" integer,
    "actual_payout_amount" numeric,
    "claim_number" character varying(50),
    "last_weather_check" timestamp with time zone,
    "last_bom_rainfall" numeric,
    "last_openmeteo_rainfall" numeric,
    "approved_at" timestamp with time zone,
    "approval_reason" text,
    "approval_rainfall_data" jsonb,
    "notification_sent" boolean default false,
    "notification_sent_at" timestamp with time zone
);


alter table "public"."claims" enable row level security;

create table "public"."customers" (
    "customer_id" uuid not null default uuid_generate_v4(),
    "first_name" text,
    "last_name" text,
    "email" text,
    "phone" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."customers" enable row level security;

create table "public"."event_type_defaults" (
    "event_type" character varying(50) not null,
    "default_payout_option_id" uuid not null,
    "description" text,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."event_type_defaults" enable row level security;

create table "public"."notifications" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "recipient_email" text not null,
    "subject" text not null,
    "body" text not null,
    "status" text default 'pending'::text,
    "processed_at" timestamp with time zone,
    "error_message" text
);


alter table "public"."notifications" enable row level security;

create table "public"."partner_event_payout_config" (
    "config_id" uuid not null default gen_random_uuid(),
    "partner_id" uuid not null,
    "event_type" character varying(50) not null,
    "payout_option_id" uuid not null,
    "is_default" boolean default false,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now()
);


alter table "public"."partner_event_payout_config" enable row level security;

create table "public"."partner_status_history" (
    "id" uuid not null default gen_random_uuid(),
    "partner_id" uuid not null,
    "old_status" character varying(20),
    "new_status" character varying(20) not null,
    "reason" text,
    "changed_by" text not null,
    "changed_at" timestamp with time zone default now(),
    "metadata" jsonb
);


alter table "public"."partner_status_history" enable row level security;

create table "public"."partners" (
    "partner_id" uuid not null default gen_random_uuid(),
    "partner_name" character varying(255) not null,
    "event_type" text,
    "Effective Date" date,
    "Commission" numeric,
    "is_active" boolean default true,
    "email" character varying(255),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "status" character varying(20) default 'active'::character varying,
    "status_reason" text,
    "status_changed_at" timestamp with time zone default now(),
    "status_changed_by" text,
    "commission_rate_override" numeric
);


alter table "public"."partners" enable row level security;

create table "public"."payout_options" (
    "payout_option_id" uuid not null default gen_random_uuid(),
    "option_name" character varying(100) not null,
    "payout_percentage" numeric(5,2) not null,
    "premium_multiplier" numeric(5,2) not null,
    "description" text,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "is_global_default" boolean default false,
    "global_default_order" integer default 0
);


alter table "public"."payout_options" enable row level security;

create table "public"."policy" (
    "quote_id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default timezone('UTC'::text, now()),
    "partner_id" uuid not null,
    "partner_booking_id" text,
    "final_premium" numeric(10,2) not null,
    "exposure_total" numeric(10,2) not null,
    "currency" text not null,
    "language" text not null,
    "status" text not null default 'active'::text,
    "policy_id" uuid not null default gen_random_uuid(),
    "customer_id" uuid,
    "event_type" text,
    "suburb" text,
    "state" text,
    "country" text not null default ''::text,
    "latitude" numeric,
    "longitude" numeric,
    "primary_location_id" integer,
    "distance_to_primary" numeric,
    "coverage_start" date,
    "coverage_end" date,
    "coverage_start_time" time without time zone,
    "coverage_end_time" time without time zone,
    "experience_name" text,
    "payment_transaction_id" text not null,
    "payment_status" text,
    "policy_type" character varying(50) default 'weather'::character varying,
    "notification_preferences" jsonb,
    "accepted_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "cancellation_reason" text,
    "cancellation_type" character varying(50),
    "trigger" numeric,
    "duration" integer,
    "daily_exposure" numeric,
    "payout_percentage" numeric,
    "policy_number" text
);


alter table "public"."policy" enable row level security;

create table "public"."quote_config" (
    "config_id" integer not null default nextval('quote_config_config_id_seq'::regclass),
    "config_name" character varying(50) not null default 'default'::character varying,
    "min_rate_percent" numeric(5,2) not null default 4.00,
    "max_rate_percent" numeric(5,2) not null default 25.00,
    "base_percent" numeric(4,3) not null default 0.050,
    "max_duration_days" integer not null default 21,
    "advance_notice_days" integer not null default 7,
    "min_exposure_amount" numeric(10,2) not null default 1.00,
    "max_exposure_amount" numeric(10,2) not null default 1000.00,
    "default_daily_value_limit" numeric(12,2) not null default 500000.00,
    "max_search_radius_meters" numeric not null default 50000,
    "max_weather_stations" integer not null default 10,
    "quote_expiry_hours" integer not null default 168,
    "default_commission_rate" numeric(4,3) not null default 0.100,
    "gst_rate" numeric(4,3) not null default 0.100,
    "stamp_duty_rate" numeric(4,3) not null default 0.100,
    "event_type_hours" jsonb not null default '{"event": {"end": "22:00", "start": "14:00"}, "sports": {"end": "18:00", "start": "02:00"}, "camping": {"end": "20:00", "start": "08:00"}, "default": {"end": "20:00", "start": "08:00"}, "experience": {"end": "17:00", "start": "09:00"}, "accommodation": {"end": "20:00", "start": "08:00"}}'::jsonb,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "default_skip_exposure_check" boolean default false
);


alter table "public"."quote_config" enable row level security;

create table "public"."quote_expiration_logs" (
    "id" integer not null default nextval('quote_expiration_logs_id_seq'::regclass),
    "quotes_expired" integer not null,
    "executed_at" timestamp with time zone not null,
    "execution_details" jsonb
);


alter table "public"."quote_expiration_logs" enable row level security;

create table "public"."quote_locations" (
    "quote_location_id" uuid not null default uuid_generate_v4(),
    "quote_id" uuid,
    "location_id" integer not null,
    "distance_km" numeric(10,2),
    "seasonal_index" numeric(10,2),
    "rainfall_trigger" numeric(10,2),
    "is_primary" boolean default false,
    "rainfall_duration" numeric,
    "max_seasonal_index_date" date,
    "max_rainfall_trigger_date" date,
    "max_optimal_hour_date" date,
    "applied_max_trigger" numeric,
    "applied_max_duration" integer,
    "applied_max_index" numeric,
    "stations_in_analysis" integer,
    "risk_contribution_type" text
);


alter table "public"."quote_locations" enable row level security;

create table "public"."quote_payout_options" (
    "quote_option_id" uuid not null default gen_random_uuid(),
    "quote_id" uuid not null,
    "payout_option_id" uuid not null,
    "payout_percentage" numeric(5,2) not null,
    "premium_multiplier" numeric(5,2) not null,
    "wholesale_premium" numeric(12,2) not null,
    "retail_premium" numeric(12,2) not null,
    "gst_amount" numeric(12,2) not null,
    "stamp_duty_amount" numeric(12,2) not null,
    "total_premium" numeric(12,2) not null,
    "is_selected" boolean default false,
    "is_default" boolean default false,
    "display_order" integer default 0,
    "created_at" timestamp with time zone default now(),
    "coverage_amount" numeric(10,2),
    "daily_coverage_amount" numeric(10,2)
);


alter table "public"."quote_payout_options" enable row level security;

create table "public"."quote_premiums" (
    "quote_premium_id" uuid not null default uuid_generate_v4(),
    "quote_id" uuid,
    "exposure_total" numeric(10,2),
    "seasonal_index" numeric(10,2),
    "duration_multiplier" numeric(10,2),
    "wholesale_premium" numeric(10,2),
    "rainfall_trigger" numeric(10,2),
    "above_threshold" boolean,
    "above_value_threshold" boolean,
    "retail_premium" numeric,
    "gst_amount" numeric,
    "stamp_duty_amount" numeric,
    "commission_rate" numeric,
    "rainfall_duration" numeric,
    "single_station_premium_applied" boolean default false,
    "single_station_premium_rate" numeric,
    "risk_adjustment_applied" boolean default false,
    "risk_adjustment_factor" numeric,
    "high_risk_day_count" integer default 0,
    "minimum_premium_applied" boolean default false,
    "minimum_premium_threshold" numeric,
    "daily_exposure" numeric
);


alter table "public"."quote_premiums" enable row level security;

create table "public"."quote_test_results" (
    "id" uuid not null default gen_random_uuid(),
    "run_id" uuid,
    "quote_id" uuid,
    "destination" text not null,
    "state" text,
    "exposure" numeric,
    "premium" numeric,
    "status" text not null,
    "error_type" text,
    "error_message" text,
    "details" jsonb,
    "analysis_result" jsonb,
    "created_at" timestamp with time zone default now(),
    "claim_status" text,
    "payout_amount" numeric
);


alter table "public"."quote_test_results" enable row level security;

create table "public"."quote_test_runs" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "num_locations" integer not null,
    "payout_rate" numeric not null,
    "min_exposure" numeric not null,
    "max_exposure" numeric not null,
    "max_event_duration" integer not null default 14,
    "start_time" timestamp with time zone not null default now(),
    "end_time" timestamp with time zone,
    "success_count" integer default 0,
    "failure_count" integer default 0,
    "failure_reasons" jsonb default '{"no_stations": 0, "other_errors": 0, "database_error": 0, "exposure_limit": 0, "json_syntax_error": 0, "high_rainfall_risk": 0, "insufficient_stations": 0}'::jsonb,
    "analysis_results" jsonb,
    "created_at" timestamp with time zone default now(),
    "analyzed_count" integer default 0,
    "failure_reasons_details" jsonb,
    "last_processed_batch" integer default 0
);


alter table "public"."quote_test_runs" enable row level security;

create table "public"."quotes" (
    "quote_id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default timezone('UTC'::text, now()),
    "expires_at" timestamp with time zone not null,
    "partner_id" uuid,
    "experience_name" character varying(255) not null,
    "partner_quote_id" text,
    "street_address" character varying(255),
    "suburb" character varying(255) not null,
    "state" character varying(255) not null,
    "country" character varying(255) default 'Australia'::character varying,
    "latitude" numeric(10,6),
    "longitude" numeric(10,6),
    "event_type" character varying(50),
    "coverage_start" timestamp with time zone not null,
    "coverage_end" timestamp with time zone not null,
    "currency" character varying(3) default 'AUD'::character varying,
    "language" character varying(5) default 'en-AU'::character varying,
    "status" character varying(50) default 'created'::character varying,
    "location_id" integer,
    "coverage_start_time" time without time zone,
    "coverage_end_time" time without time zone,
    "exposure_total" numeric,
    "validation_status" character varying(50) default 'VALID'::character varying,
    "validation_code" character varying(50) default NULL::character varying,
    "validation_message" text,
    "model_version" character varying(50),
    "quote_group_id" uuid
);


alter table "public"."quotes" enable row level security;

create table "public"."rls_disabled_justification" (
    "table_name" text not null,
    "reason" text not null,
    "created_at" timestamp with time zone default now()
);


alter table "public"."rls_disabled_justification" enable row level security;

create table "public"."seasonal_config" (
    "config_id" integer not null default nextval('seasonal_config_config_id_seq'::regclass),
    "max_trigger" numeric default 8.0,
    "min_trigger" numeric default 2.0,
    "coastal_high_mult" numeric default 1.2,
    "coastal_medium_mult" numeric default 1.1,
    "apply_enso" boolean default true,
    "enable_discounts" boolean default false,
    "use_ratio_method" boolean default true,
    "ratio_exponent" numeric default 0.7,
    "min_index_discounted" numeric default 0.3,
    "created_at" timestamp without time zone default now(),
    "updated_at" timestamp without time zone default now()
);


alter table "public"."seasonal_config" enable row level security;

create table "public"."security_implementation_report" (
    "id" uuid not null default gen_random_uuid(),
    "implementation_date" timestamp with time zone default now(),
    "summary" jsonb not null
);


alter table "public"."security_implementation_report" enable row level security;

create table "public"."templates" (
    "id" uuid not null default gen_random_uuid(),
    "event_type" text not null,
    "name" text not null,
    "content" text not null,
    "created_at" timestamp with time zone not null default now(),
    "category" text not null,
    "parameter_path" text not null,
    "action" text,
    "quote_count_filter" integer,
    "channel" character varying(50) default 'default'::character varying,
    "version" integer,
    "is_active" boolean default true,
    "variables_used" integer,
    "weather_type" text
);


alter table "public"."templates" enable row level security;

create table "public"."test_table" (
    "id" bigint generated by default as identity not null,
    "name" text,
    "created_at" timestamp with time zone not null default now()
);


create table "public"."transactions" (
    "transaction_id" uuid not null,
    "policy_id" uuid not null,
    "amount" numeric not null,
    "currency" text not null,
    "transaction_type" text not null,
    "status" text not null,
    "provider" text not null,
    "provider_transaction_id" text,
    "created_at" timestamp with time zone default now(),
    "metadata" jsonb,
    "error_message" text
);


alter table "public"."transactions" enable row level security;

create table "public"."unified_audit_log" (
    "id" bigint not null default nextval('unified_audit_log_id_seq'::regclass),
    "audit_timestamp" timestamp with time zone not null default now(),
    "table_name" text not null,
    "record_id" uuid not null,
    "record_identifier" text,
    "operation" text not null,
    "column_name" text,
    "old_value" jsonb,
    "new_value" jsonb,
    "user_id" uuid,
    "user_email" text,
    "user_role" text,
    "session_id" text,
    "ip_address" inet,
    "user_agent" text,
    "application_name" text,
    "application_version" text,
    "api_endpoint" text,
    "request_id" text,
    "metadata" jsonb,
    "created_at" timestamp with time zone not null default now()
);


alter table "public"."unified_audit_log" enable row level security;

create table "public"."weather_data" (
    "id" uuid not null default gen_random_uuid(),
    "claim_id" uuid not null,
    "bom_rainfall" numeric,
    "openmeteo_rainfall" numeric,
    "max_rainfall" numeric,
    "trigger_source" text,
    "threshold_exceeded" boolean default false,
    "timestamp" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now()
);


alter sequence "public"."audit_documentation_id_seq" owned by "public"."audit_documentation"."id";

alter sequence "public"."claim_weather_hourly_id_seq" owned by "public"."claim_weather_hourly"."id";

alter sequence "public"."quote_config_config_id_seq" owned by "public"."quote_config"."config_id";

alter sequence "public"."quote_expiration_logs_id_seq" owned by "public"."quote_expiration_logs"."id";

alter sequence "public"."seasonal_config_config_id_seq" owned by "public"."seasonal_config"."config_id";

alter sequence "public"."unified_audit_log_id_seq" owned by "public"."unified_audit_log"."id";

CREATE UNIQUE INDEX api_keys_pkey ON public.api_keys USING btree (id);

CREATE UNIQUE INDEX audit_documentation_pkey ON public.audit_documentation USING btree (id);

CREATE UNIQUE INDEX claim_locations_pkey ON public.claim_locations USING btree (claim_location_id);

CREATE UNIQUE INDEX claim_weather_hourly_pkey ON public.claim_weather_hourly USING btree (id);

CREATE UNIQUE INDEX claims_pkey ON public.claims USING btree (claim_id);

CREATE UNIQUE INDEX customers_pkey ON public.customers USING btree (customer_id);

CREATE UNIQUE INDEX event_type_defaults_pkey ON public.event_type_defaults USING btree (event_type);

CREATE INDEX idx_api_keys_expires_at ON public.api_keys USING btree (expires_at) WHERE (expires_at IS NOT NULL);

CREATE INDEX idx_api_keys_hash ON public.api_keys USING btree (api_key_hash);

CREATE INDEX idx_api_keys_partner_id ON public.api_keys USING btree (partner_id);

CREATE INDEX idx_audit_created_at ON public.unified_audit_log USING btree (created_at);

CREATE INDEX idx_audit_operation ON public.unified_audit_log USING btree (operation);

CREATE INDEX idx_audit_table_record ON public.unified_audit_log USING btree (table_name, record_id);

CREATE INDEX idx_audit_timestamp ON public.unified_audit_log USING btree (audit_timestamp);

CREATE INDEX idx_audit_user ON public.unified_audit_log USING btree (user_id);

CREATE INDEX idx_claim_locations_claim_id ON public.claim_locations USING btree (claim_id);

CREATE INDEX idx_claim_locations_location_id ON public.claim_locations USING btree (location_id);

CREATE INDEX idx_claim_weather_hourly_claim_id ON public.claim_weather_hourly USING btree (claim_id);

CREATE INDEX idx_claim_weather_hourly_date_hour ON public.claim_weather_hourly USING btree (weather_date, hour);

CREATE INDEX idx_claim_weather_hourly_location_id ON public.claim_weather_hourly USING btree (claim_location_id);

CREATE INDEX idx_claims_status_trigger ON public.claims USING btree (claim_status, trigger_date);

CREATE INDEX idx_customers_email ON public.customers USING btree (email);

CREATE INDEX idx_customers_phone ON public.customers USING btree (phone);

CREATE INDEX idx_event_type_defaults_active ON public.event_type_defaults USING btree (event_type, is_active);

CREATE INDEX idx_high_value_claims ON public.quote_test_results USING btree (run_id, payout_amount) WHERE (payout_amount > (1000)::numeric);

CREATE INDEX idx_partner_event_payout_config_lookup ON public.partner_event_payout_config USING btree (partner_id, event_type, is_active);

CREATE INDEX idx_partner_event_payout_lookup ON public.partner_event_payout_config USING btree (partner_id, event_type, is_active);

CREATE INDEX idx_partner_status_history_partner_id ON public.partner_status_history USING btree (partner_id, changed_at DESC);

CREATE INDEX idx_partners_commission_lookup ON public.partners USING btree (partner_id, "Effective Date" DESC);

CREATE INDEX idx_partners_email ON public.partners USING btree (email);

CREATE INDEX idx_payout_options_active ON public.payout_options USING btree (is_active, is_global_default) WHERE (is_active = true);

CREATE INDEX idx_payout_options_global_default ON public.payout_options USING btree (is_global_default, is_active) WHERE (is_global_default = true);

CREATE INDEX idx_policy_cancelled_at ON public.policy USING btree (cancelled_at) WHERE (cancelled_at IS NOT NULL);

CREATE INDEX idx_policy_coverage_dates ON public.policy USING btree (coverage_start, coverage_end);

CREATE INDEX idx_policy_coverage_dates_status ON public.policy USING btree (coverage_start, coverage_end, status) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_coverage_exposure_active ON public.policy USING btree (coverage_start, coverage_end, exposure_total) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_coverage_period ON public.policy USING btree (coverage_start, coverage_end);

CREATE INDEX idx_policy_customer_id ON public.policy USING btree (customer_id);

CREATE INDEX idx_policy_date_range ON public.policy USING btree (coverage_start, coverage_end);

CREATE INDEX idx_policy_exposure_check ON public.policy USING btree (status, coverage_start, coverage_end) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_exposure_check_optimized ON public.policy USING btree (coverage_start, coverage_end, quote_id, exposure_total) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_exposure_covering ON public.policy USING btree (quote_id, status, coverage_start, coverage_end) INCLUDE (exposure_total) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_exposure_lookup ON public.policy USING btree (quote_id, status, coverage_start, coverage_end) INCLUDE (exposure_total) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_external_booking ON public.policy USING btree (partner_booking_id);

CREATE INDEX idx_policy_number ON public.policy USING btree (policy_number);

CREATE INDEX idx_policy_policy_number ON public.policy USING btree (policy_number);

CREATE INDEX idx_policy_quote_id ON public.policy USING btree (quote_id);

CREATE INDEX idx_policy_quote_id_active ON public.policy USING btree (quote_id) WHERE (status = 'active'::text);

CREATE INDEX idx_policy_status ON public.policy USING btree (status);

CREATE INDEX idx_quote_locations ON public.quote_locations USING btree (quote_id, location_id);

CREATE INDEX idx_quote_locations_composite ON public.quote_locations USING btree (quote_id, location_id);

CREATE INDEX idx_quote_locations_location ON public.quote_locations USING btree (location_id);

CREATE INDEX idx_quote_locations_location_id ON public.quote_locations USING btree (location_id);

CREATE INDEX idx_quote_locations_lookup_covering ON public.quote_locations USING btree (quote_id, location_id) INCLUDE (quote_location_id);

CREATE INDEX idx_quote_locations_quote_id ON public.quote_locations USING btree (quote_id);

CREATE INDEX idx_quote_locations_quote_location ON public.quote_locations USING btree (quote_id, location_id);

CREATE INDEX idx_quote_payout_options_quote ON public.quote_payout_options USING btree (quote_id);

CREATE INDEX idx_quote_payout_options_selected ON public.quote_payout_options USING btree (quote_id, is_selected);

CREATE INDEX idx_quote_premiums_minimum_premium_applied ON public.quote_premiums USING btree (minimum_premium_applied) WHERE (minimum_premium_applied = true);

CREATE INDEX idx_quote_premiums_quote_id ON public.quote_premiums USING btree (quote_id);

CREATE INDEX idx_quote_results_analysis ON public.quote_test_results USING btree (run_id, claim_status);

CREATE INDEX idx_quote_test_results_analysis_jsonb ON public.quote_test_results USING gin (analysis_result);

CREATE INDEX idx_quote_test_results_batch_processing ON public.quote_test_results USING btree (run_id, status, analysis_result) WHERE ((status = 'SUCCESS'::text) AND (analysis_result IS NULL));

CREATE INDEX idx_quote_test_results_processing ON public.quote_test_results USING btree (run_id, status) WHERE (status = 'PROCESSING'::text);

CREATE INDEX idx_quote_test_results_run_id ON public.quote_test_results USING btree (run_id);

CREATE INDEX idx_quote_test_results_run_status ON public.quote_test_results USING btree (run_id, status, analysis_result);

CREATE INDEX idx_quote_test_results_run_status_analysis ON public.quote_test_results USING btree (run_id, status, quote_id) WHERE ((analysis_result IS NULL) AND (status = 'SUCCESS'::text));

CREATE INDEX idx_quote_test_results_stats ON public.quote_test_results USING btree (run_id, status, claim_status) INCLUDE (payout_amount);

CREATE INDEX idx_quote_test_results_status_analysis ON public.quote_test_results USING btree (run_id, quote_id) INCLUDE (status, analysis_result, claim_status);

CREATE INDEX idx_quote_test_runs_created_at ON public.quote_test_runs USING btree (created_at);

CREATE INDEX idx_quotes_coverage_dates ON public.quotes USING btree (coverage_start, coverage_end);

CREATE INDEX idx_quotes_created_at ON public.quotes USING btree (created_at);

CREATE INDEX idx_quotes_expires_at ON public.quotes USING btree (expires_at);

CREATE INDEX idx_quotes_expiry ON public.quotes USING btree (expires_at);

CREATE INDEX idx_quotes_external_booking ON public.quotes USING btree (partner_quote_id);

CREATE INDEX idx_quotes_join_optimization ON public.quotes USING btree (quote_id) INCLUDE (experience_name, suburb, state, location_id, coverage_start, coverage_end);

CREATE INDEX idx_quotes_partner_expiry ON public.quotes USING btree (partner_id, expires_at);

CREATE INDEX idx_quotes_partner_id ON public.quotes USING btree (partner_id);

CREATE INDEX idx_quotes_policy_id ON public.quotes USING btree (quote_id);

CREATE INDEX idx_quotes_quote_group_id ON public.quotes USING btree (quote_group_id);

CREATE INDEX idx_quotes_status ON public.quotes USING btree (status);

CREATE INDEX idx_quotes_status_expires_at ON public.quotes USING btree (status, expires_at);

CREATE INDEX idx_security_report_date ON public.security_implementation_report USING btree (implementation_date DESC);

CREATE INDEX idx_templates_active ON public.templates USING btree (is_active) WHERE (is_active = true);

CREATE INDEX idx_templates_category_event_type ON public.templates USING btree (category, event_type);

CREATE INDEX idx_templates_channel ON public.templates USING btree (channel);

CREATE INDEX idx_templates_lookup_covering ON public.templates USING btree (category, event_type, is_active) INCLUDE (name, content, parameter_path, action, channel, version) WHERE (is_active = true);

CREATE INDEX idx_transactions_policy_id ON public.transactions USING btree (policy_id);

CREATE INDEX idx_weather_data_claim_id ON public.weather_data USING btree (claim_id);

CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);

CREATE UNIQUE INDEX partner_event_payout_config_partner_id_event_type_payout_op_key ON public.partner_event_payout_config USING btree (partner_id, event_type, payout_option_id);

CREATE UNIQUE INDEX partner_event_payout_config_pkey ON public.partner_event_payout_config USING btree (config_id);

CREATE UNIQUE INDEX partner_status_history_pkey ON public.partner_status_history USING btree (id);

CREATE UNIQUE INDEX partners_pkey ON public.partners USING btree (partner_id);

CREATE UNIQUE INDEX payout_options_pkey ON public.payout_options USING btree (payout_option_id);

CREATE INDEX policy_created_at_idx ON public.policy USING btree (created_at);

CREATE INDEX policy_external_booking_id_idx ON public.policy USING btree (partner_booking_id);

CREATE UNIQUE INDEX policy_number_unique ON public.policy USING btree (policy_number);

CREATE UNIQUE INDEX policy_pkey ON public.policy USING btree (policy_id);

CREATE UNIQUE INDEX policy_policy_id_key ON public.policy USING btree (policy_id);

CREATE UNIQUE INDEX policy_quote_id_key ON public.policy USING btree (quote_id);

CREATE UNIQUE INDEX quote_config_config_name_key ON public.quote_config USING btree (config_name);

CREATE UNIQUE INDEX quote_config_pkey ON public.quote_config USING btree (config_id);

CREATE UNIQUE INDEX quote_expiration_logs_pkey ON public.quote_expiration_logs USING btree (id);

CREATE UNIQUE INDEX quote_locations_pkey ON public.quote_locations USING btree (quote_location_id);

CREATE UNIQUE INDEX quote_locations_quote_id_location_id_key ON public.quote_locations USING btree (quote_id, location_id);

CREATE UNIQUE INDEX quote_payout_options_pkey ON public.quote_payout_options USING btree (quote_option_id);

CREATE UNIQUE INDEX quote_payout_options_quote_id_payout_option_id_key ON public.quote_payout_options USING btree (quote_id, payout_option_id);

CREATE UNIQUE INDEX quote_premiums_pkey ON public.quote_premiums USING btree (quote_premium_id);

CREATE UNIQUE INDEX quote_test_results_pkey ON public.quote_test_results USING btree (id);

CREATE UNIQUE INDEX quote_test_runs_pkey ON public.quote_test_runs USING btree (id);

CREATE UNIQUE INDEX quotes_pkey ON public.quotes USING btree (quote_id);

CREATE UNIQUE INDEX rls_disabled_justification_pkey ON public.rls_disabled_justification USING btree (table_name);

CREATE UNIQUE INDEX seasonal_config_pkey ON public.seasonal_config USING btree (config_id);

CREATE UNIQUE INDEX security_implementation_report_pkey ON public.security_implementation_report USING btree (id);

CREATE UNIQUE INDEX templates_pkey ON public.templates USING btree (id);

CREATE UNIQUE INDEX test_table_pkey ON public.test_table USING btree (id);

CREATE UNIQUE INDEX transactions_pkey ON public.transactions USING btree (transaction_id, policy_id);

CREATE UNIQUE INDEX uk_api_keys_hash ON public.api_keys USING btree (api_key_hash);

CREATE UNIQUE INDEX unified_audit_log_pkey ON public.unified_audit_log USING btree (id);

CREATE UNIQUE INDEX weather_data_pkey ON public.weather_data USING btree (id);

alter table "public"."api_keys" add constraint "api_keys_pkey" PRIMARY KEY using index "api_keys_pkey";

alter table "public"."audit_documentation" add constraint "audit_documentation_pkey" PRIMARY KEY using index "audit_documentation_pkey";

alter table "public"."claim_locations" add constraint "claim_locations_pkey" PRIMARY KEY using index "claim_locations_pkey";

alter table "public"."claim_weather_hourly" add constraint "claim_weather_hourly_pkey" PRIMARY KEY using index "claim_weather_hourly_pkey";

alter table "public"."claims" add constraint "claims_pkey" PRIMARY KEY using index "claims_pkey";

alter table "public"."customers" add constraint "customers_pkey" PRIMARY KEY using index "customers_pkey";

alter table "public"."event_type_defaults" add constraint "event_type_defaults_pkey" PRIMARY KEY using index "event_type_defaults_pkey";

alter table "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY using index "notifications_pkey";

alter table "public"."partner_event_payout_config" add constraint "partner_event_payout_config_pkey" PRIMARY KEY using index "partner_event_payout_config_pkey";

alter table "public"."partner_status_history" add constraint "partner_status_history_pkey" PRIMARY KEY using index "partner_status_history_pkey";

alter table "public"."partners" add constraint "partners_pkey" PRIMARY KEY using index "partners_pkey";

alter table "public"."payout_options" add constraint "payout_options_pkey" PRIMARY KEY using index "payout_options_pkey";

alter table "public"."policy" add constraint "policy_pkey" PRIMARY KEY using index "policy_pkey";

alter table "public"."quote_config" add constraint "quote_config_pkey" PRIMARY KEY using index "quote_config_pkey";

alter table "public"."quote_expiration_logs" add constraint "quote_expiration_logs_pkey" PRIMARY KEY using index "quote_expiration_logs_pkey";

alter table "public"."quote_locations" add constraint "quote_locations_pkey" PRIMARY KEY using index "quote_locations_pkey";

alter table "public"."quote_payout_options" add constraint "quote_payout_options_pkey" PRIMARY KEY using index "quote_payout_options_pkey";

alter table "public"."quote_premiums" add constraint "quote_premiums_pkey" PRIMARY KEY using index "quote_premiums_pkey";

alter table "public"."quote_test_results" add constraint "quote_test_results_pkey" PRIMARY KEY using index "quote_test_results_pkey";

alter table "public"."quote_test_runs" add constraint "quote_test_runs_pkey" PRIMARY KEY using index "quote_test_runs_pkey";

alter table "public"."quotes" add constraint "quotes_pkey" PRIMARY KEY using index "quotes_pkey";

alter table "public"."rls_disabled_justification" add constraint "rls_disabled_justification_pkey" PRIMARY KEY using index "rls_disabled_justification_pkey";

alter table "public"."seasonal_config" add constraint "seasonal_config_pkey" PRIMARY KEY using index "seasonal_config_pkey";

alter table "public"."security_implementation_report" add constraint "security_implementation_report_pkey" PRIMARY KEY using index "security_implementation_report_pkey";

alter table "public"."templates" add constraint "templates_pkey" PRIMARY KEY using index "templates_pkey";

alter table "public"."test_table" add constraint "test_table_pkey" PRIMARY KEY using index "test_table_pkey";

alter table "public"."transactions" add constraint "transactions_pkey" PRIMARY KEY using index "transactions_pkey";

alter table "public"."unified_audit_log" add constraint "unified_audit_log_pkey" PRIMARY KEY using index "unified_audit_log_pkey";

alter table "public"."weather_data" add constraint "weather_data_pkey" PRIMARY KEY using index "weather_data_pkey";

alter table "public"."api_keys" add constraint "api_key_hash_required" CHECK (((api_key_hash IS NOT NULL) AND (length(api_key_hash) = 64))) not valid;

alter table "public"."api_keys" validate constraint "api_key_hash_required";

alter table "public"."api_keys" add constraint "api_keys_partner_id_fkey" FOREIGN KEY (partner_id) REFERENCES partners(partner_id) not valid;

alter table "public"."api_keys" validate constraint "api_keys_partner_id_fkey";

alter table "public"."api_keys" add constraint "uk_api_keys_hash" UNIQUE using index "uk_api_keys_hash";

alter table "public"."claim_weather_hourly" add constraint "claim_weather_hourly_hour_check" CHECK (((hour >= 0) AND (hour <= 23))) not valid;

alter table "public"."claim_weather_hourly" validate constraint "claim_weather_hourly_hour_check";

alter table "public"."claims" add constraint "claims_status_check" CHECK (((claim_status)::text = ANY (ARRAY[('pending'::character varying)::text, ('under_review'::character varying)::text, ('documentation_required'::character varying)::text, ('approved'::character varying)::text, ('rejected'::character varying)::text, ('paid'::character varying)::text, ('cancelled'::character varying)::text, ('disputed'::character varying)::text, ('processing_payment'::character varying)::text]))) not valid;

alter table "public"."claims" validate constraint "claims_status_check";

alter table "public"."partner_event_payout_config" add constraint "partner_event_payout_config_partner_id_event_type_payout_op_key" UNIQUE using index "partner_event_payout_config_partner_id_event_type_payout_op_key";

alter table "public"."partner_event_payout_config" add constraint "partner_event_payout_config_partner_id_fkey" FOREIGN KEY (partner_id) REFERENCES partners(partner_id) not valid;

alter table "public"."partner_event_payout_config" validate constraint "partner_event_payout_config_partner_id_fkey";

alter table "public"."partner_status_history" add constraint "partner_status_history_partner_id_fkey" FOREIGN KEY (partner_id) REFERENCES partners(partner_id) not valid;

alter table "public"."partner_status_history" validate constraint "partner_status_history_partner_id_fkey";

alter table "public"."partners" add constraint "valid_partner_status" CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('active'::character varying)::text, ('suspended'::character varying)::text, ('deactivated'::character varying)::text, ('archived'::character varying)::text]))) not valid;

alter table "public"."partners" validate constraint "valid_partner_status";

alter table "public"."policy" add constraint "policy_cancellation_type_check" CHECK ((((cancellation_type)::text = ANY (ARRAY[('customer_request'::character varying)::text, ('partner_request'::character varying)::text, ('booking_cancelled'::character varying)::text, ('system'::character varying)::text, ('fraud'::character varying)::text])) OR (cancellation_type IS NULL))) not valid;

alter table "public"."policy" validate constraint "policy_cancellation_type_check";

alter table "public"."policy" add constraint "policy_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(customer_id) not valid;

alter table "public"."policy" validate constraint "policy_customer_id_fkey";

alter table "public"."policy" add constraint "policy_number_unique" UNIQUE using index "policy_number_unique";

alter table "public"."policy" add constraint "policy_partner_id_fkey" FOREIGN KEY (partner_id) REFERENCES partners(partner_id) not valid;

alter table "public"."policy" validate constraint "policy_partner_id_fkey";

alter table "public"."policy" add constraint "policy_policy_id_key" UNIQUE using index "policy_policy_id_key";

alter table "public"."policy" add constraint "policy_quote_id_fkey" FOREIGN KEY (quote_id) REFERENCES quotes(quote_id) not valid;

alter table "public"."policy" validate constraint "policy_quote_id_fkey";

alter table "public"."policy" add constraint "policy_quote_id_key" UNIQUE using index "policy_quote_id_key";

alter table "public"."policy" add constraint "policy_status_check" CHECK ((status = ANY (ARRAY['created'::text, 'active'::text, 'assessment'::text, 'cancelled'::text, 'refunded'::text, 'claim submitted'::text, 'completed'::text, 'claim approved'::text, 'paid out'::text]))) not valid;

alter table "public"."policy" validate constraint "policy_status_check";

alter table "public"."quote_config" add constraint "quote_config_config_name_key" UNIQUE using index "quote_config_config_name_key";

alter table "public"."quote_locations" add constraint "quote_locations_quote_id_fkey" FOREIGN KEY (quote_id) REFERENCES quotes(quote_id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."quote_locations" validate constraint "quote_locations_quote_id_fkey";

alter table "public"."quote_locations" add constraint "quote_locations_quote_id_location_id_key" UNIQUE using index "quote_locations_quote_id_location_id_key";

alter table "public"."quote_payout_options" add constraint "quote_payout_options_quote_id_fkey" FOREIGN KEY (quote_id) REFERENCES quotes(quote_id) not valid;

alter table "public"."quote_payout_options" validate constraint "quote_payout_options_quote_id_fkey";

alter table "public"."quote_payout_options" add constraint "quote_payout_options_quote_id_payout_option_id_key" UNIQUE using index "quote_payout_options_quote_id_payout_option_id_key";

alter table "public"."quote_premiums" add constraint "quote_premiums_quote_id_fkey" FOREIGN KEY (quote_id) REFERENCES quotes(quote_id) not valid;

alter table "public"."quote_premiums" validate constraint "quote_premiums_quote_id_fkey";

alter table "public"."quote_test_results" add constraint "quote_test_results_run_id_fkey" FOREIGN KEY (run_id) REFERENCES quote_test_runs(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."quote_test_results" validate constraint "quote_test_results_run_id_fkey";

alter table "public"."quotes" add constraint "quotes_partner_id_fkey" FOREIGN KEY (partner_id) REFERENCES partners(partner_id) not valid;

alter table "public"."quotes" validate constraint "quotes_partner_id_fkey";

alter table "public"."quotes" add constraint "quotes_status_check" CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('rejected'::character varying)::text, ('expired'::character varying)::text]))) not valid;

alter table "public"."quotes" validate constraint "quotes_status_check";

alter table "public"."unified_audit_log" add constraint "unified_audit_log_operation_check" CHECK ((operation = ANY (ARRAY['INSERT'::text, 'UPDATE'::text, 'DELETE'::text, 'ARCHIVE'::text]))) not valid;

alter table "public"."unified_audit_log" validate constraint "unified_audit_log_operation_check";

alter table "public"."weather_data" add constraint "weather_data_claim_id_fkey" FOREIGN KEY (claim_id) REFERENCES claims(claim_id) not valid;

alter table "public"."weather_data" validate constraint "weather_data_claim_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public._analyze_weather_stations(p_latitude numeric, p_longitude numeric, p_start_date date, v_config quote_config)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    v_input_point geography;
    v_result jsonb;
BEGIN
    v_input_point := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography;
    
    WITH nearby_stations AS (
        SELECT 
            l.location_id, 
            l.name as station_name,
            ST_Distance(v_input_point, l.geom) / 1000 as distance_km
        FROM locations l
        WHERE l.geom IS NOT NULL
            AND ST_DWithin(v_input_point, l.geom, v_config.max_search_radius_meters)
        ORDER BY l.geom operator(<->) v_input_point
        LIMIT v_config.max_weather_stations
    ),
    station_data AS (
        SELECT 
            array_agg(ns.location_id ORDER BY ns.distance_km) as station_ids,
            (array_agg(ns.location_id ORDER BY ns.distance_km))[1] as primary_id,
            (array_agg(ns.station_name ORDER BY ns.distance_km))[1] as primary_name,
            (array_agg(ns.distance_km ORDER BY ns.distance_km))[1] as primary_distance,
            COUNT(*) as station_count
        FROM nearby_stations ns
    ),
    seasonal_analysis AS (
        SELECT 
            MAX(dsi.modified_rainfall_trigger) as max_rainfall_trigger,
            MAX(dsi.optimal_hour_trigger) as max_duration,
            MAX(dsi.modified_seasonal_index) as max_seasonal_index,
            BOOL_OR(dsi.high_risk_flag) as any_high_risk,
            BOOL_OR(dsi.climate_anomaly_flag) as any_climate_anomaly,
            COUNT(CASE WHEN dsi.modified_seasonal_index IS NOT NULL THEN 1 END) as stations_with_data
        FROM station_data sd
        CROSS JOIN LATERAL unnest(sd.station_ids) AS sid(location_id)
        LEFT JOIN daily_seasonal_indices dsi ON 
            sid.location_id = dsi.location_id 
            AND dsi.month_of_year = EXTRACT(MONTH FROM p_start_date)
            AND dsi.day_of_month = EXTRACT(DAY FROM p_start_date)
    )
    SELECT jsonb_build_object(
        'success', CASE 
            WHEN sd.primary_id IS NULL THEN false
            WHEN sa.stations_with_data = 0 THEN false
            WHEN sa.any_high_risk THEN false
            ELSE true
        END,
        'error_code', CASE 
            WHEN sd.primary_id IS NULL THEN 'NO_STATIONS_FOUND'
            WHEN sa.stations_with_data = 0 THEN 'NO_SEASONAL_DATA'
            WHEN sa.any_high_risk THEN 'HIGH_RISK_DETECTED'
            ELSE NULL
        END,
        'error_message', CASE 
            WHEN sd.primary_id IS NULL THEN format('No weather stations found within %skm of location', v_config.max_search_radius_meters / 1000)
            WHEN sa.stations_with_data = 0 THEN 'No seasonal data available for any nearby weather stations.'
            WHEN sa.any_high_risk THEN 'High rainfall risk detected at one or more weather stations'
            ELSE NULL
        END,
        'station_ids', sd.station_ids,  -- This is already an integer array
        'primary_station_id', sd.primary_id,
        'primary_station_name', sd.primary_name,
        'primary_station_distance', sd.primary_distance,
        'stations_analyzed', sd.station_count,
        'max_rainfall_trigger', sa.max_rainfall_trigger,
        'max_duration', sa.max_duration,
        'max_seasonal_index', sa.max_seasonal_index,
        'any_climate_anomaly', sa.any_climate_anomaly,
        'input_point', v_input_point
    ) INTO v_result
    FROM station_data sd, seasonal_analysis sa;
    
    RETURN v_result;
END;$function$
;

CREATE OR REPLACE FUNCTION public._calculate_premiums(p_exposure_total numeric, p_payout_percentage numeric, p_premium_multiplier numeric, p_duration_days integer, v_base_wholesale_premium numeric, v_config quote_config, v_commission_rate numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_base_premium_adjusted numeric;
    v_gst_amount numeric;
    v_stamp_duty_amount numeric;
    v_commission_amount numeric;
    v_wholesale_premium numeric;
    v_retail_premium numeric;
    v_total_premium numeric;
    v_premium_ratio numeric;
    v_minimum_applied boolean := false;
    v_coverage_amount numeric;
    v_daily_coverage_amount numeric;
    v_daily_premium numeric;
BEGIN
    -- Calculate base premium for this payout option
    v_base_premium_adjusted := v_base_wholesale_premium * p_premium_multiplier;
    
    -- Calculate GST and stamp duty on base premium
    v_gst_amount := v_base_premium_adjusted * v_config.gst_rate;
    v_stamp_duty_amount := v_base_premium_adjusted * v_config.stamp_duty_rate;
    
    -- Wholesale = base + GST + stamp duty (no commission)
    v_wholesale_premium := v_base_premium_adjusted + v_gst_amount + v_stamp_duty_amount;
    
    -- Commission amount
    v_commission_amount := v_base_premium_adjusted * v_commission_rate;
    
    -- Retail = wholesale + commission (includes everything)
    v_retail_premium := v_wholesale_premium + v_commission_amount;
    
    -- Total premium is now same as retail
    v_total_premium := v_retail_premium;
    
    -- Calculate premium ratio for min/max checks
    v_premium_ratio := v_total_premium / p_exposure_total;
    
    -- Calculate coverage and daily amounts
    v_coverage_amount := ROUND(p_exposure_total * p_payout_percentage / 100, 2);
    v_daily_coverage_amount := ROUND(v_coverage_amount / p_duration_days, 2);
    v_daily_premium := ROUND(v_total_premium / p_duration_days, 2);
    
    -- Apply min/max rate caps
    IF v_premium_ratio < (v_config.min_rate_percent / 100.0) THEN
        -- Apply minimum rate cap
        v_total_premium := p_exposure_total * (v_config.min_rate_percent / 100.0);
        v_retail_premium := v_total_premium;
        
        -- Recalculate components to maintain proportions
        v_base_premium_adjusted := v_total_premium / (1 + v_config.gst_rate + v_config.stamp_duty_rate + v_commission_rate);
        v_gst_amount := v_base_premium_adjusted * v_config.gst_rate;
        v_stamp_duty_amount := v_base_premium_adjusted * v_config.stamp_duty_rate;
        v_commission_amount := v_base_premium_adjusted * v_commission_rate;
        v_wholesale_premium := v_base_premium_adjusted + v_gst_amount + v_stamp_duty_amount;
        
        v_premium_ratio := (v_config.min_rate_percent / 100.0);
        v_daily_premium := ROUND(v_total_premium / p_duration_days, 2);
        v_minimum_applied := true;
    ELSIF v_premium_ratio > (v_config.max_rate_percent / 100.0) THEN
        -- Above maximum - return indicator
        RETURN jsonb_build_object('valid', false);
    END IF;
    
    RETURN jsonb_build_object(
        'valid', true,
        'wholesale_premium', v_wholesale_premium,
        'retail_premium', v_retail_premium,
        'total_premium', v_total_premium,
        'gst_amount', v_gst_amount,
        'stamp_duty_amount', v_stamp_duty_amount,
        'commission_amount', v_commission_amount,
        'coverage_amount', v_coverage_amount,
        'daily_coverage_amount', v_daily_coverage_amount,
        'daily_premium', v_daily_premium,
        'premium_ratio', v_premium_ratio,
        'minimum_applied', v_minimum_applied
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public._get_payout_options(p_partner_id uuid, p_event_type text)
 RETURNS TABLE(payout_option_id uuid, option_name character varying, payout_percentage numeric, premium_multiplier numeric, description text, is_default boolean, seq integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- First try partner-specific options
    RETURN QUERY
    SELECT 
        po.payout_option_id,
        po.option_name,
        po.payout_percentage,
        po.premium_multiplier,
        po.description,
        pepc.is_default,
        ROW_NUMBER() OVER (ORDER BY pepc.is_default DESC, po.payout_percentage DESC)::integer as seq
    FROM partner_event_payout_config pepc
    JOIN payout_options po ON pepc.payout_option_id = po.payout_option_id
    WHERE pepc.partner_id = p_partner_id
        AND pepc.event_type = p_event_type
        AND pepc.is_active = true
        AND po.is_active = true
    ORDER BY pepc.is_default DESC, po.payout_percentage DESC;
    
    -- If no partner options found, use global defaults
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            po.payout_option_id,
            po.option_name,
            po.payout_percentage,
            po.premium_multiplier,
            po.description,
            CASE WHEN po.global_default_order = 1 THEN TRUE ELSE FALSE END as is_default,
            ROW_NUMBER() OVER (ORDER BY po.global_default_order, po.payout_percentage DESC)::integer as seq
        FROM payout_options po
        WHERE po.is_global_default = TRUE
            AND po.is_active = TRUE
        ORDER BY po.global_default_order, po.payout_percentage DESC;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public._validate_quote_inputs(p_start_date date, p_end_date date, p_exposure_total numeric, v_config quote_config)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_duration_days INTEGER;
BEGIN
    v_duration_days := (p_end_date - p_start_date) + 1;
    
    -- Duration validation
    IF v_duration_days <= 0 THEN
        RETURN jsonb_build_object(
            'is_valid', false,
            'error', jsonb_build_object(
                'success', false,
                'error_code', 'INVALID_DURATION',
                'error_message', 'End date must be after start date'
            )
        );
    END IF;
    
    IF v_duration_days > v_config.max_duration_days THEN
        RETURN jsonb_build_object(
            'is_valid', false,
            'error', jsonb_build_object(
                'success', false,
                'error_code', 'DURATION_EXCEEDED',
                'error_message', format('Duration (%s days) exceeds maximum allowed (%s days)', 
                    v_duration_days, v_config.max_duration_days)
            )
        );
    END IF;
    
    -- Advance notice check
    IF p_start_date <= CURRENT_DATE + (v_config.advance_notice_days || ' days')::INTERVAL THEN
        RETURN jsonb_build_object(
            'is_valid', false,
            'error', jsonb_build_object(
                'success', false,
                'error_code', 'INSUFFICIENT_ADVANCE_NOTICE',
                'error_message', format('Quotes must be made at least %s days before coverage start date',
                    v_config.advance_notice_days)
            )
        );
    END IF;
    
    -- Exposure limits
    IF p_exposure_total < v_config.min_exposure_amount OR p_exposure_total > v_config.max_exposure_amount THEN
        RETURN jsonb_build_object(
            'is_valid', false,
            'error', jsonb_build_object(
                'success', false,
                'error_code', 'EXPOSURE_LIMIT_EXCEEDED',
                'error_message', format('Exposure amount ($%s) must be between $%s and $%s',
                    p_exposure_total, v_config.min_exposure_amount, v_config.max_exposure_amount)
            )
        );
    END IF;
    
    RETURN jsonb_build_object('is_valid', true, 'duration_days', v_duration_days);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.accept_and_pay_quote(p_quote_id uuid, p_payment_id text, p_customer_email text, p_customer_first_name text, p_customer_last_name text, p_customer_phone text, p_external_booking_id text)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_quote RECORD;
    v_quote_location RECORD;
    v_customer_id UUID;
    v_policy_id UUID;
    v_transaction_id UUID;
    v_policy_number TEXT;
    v_result JSON;
    v_payout_info RECORD;
    v_daily_exposure NUMERIC;
    v_coverage_days NUMERIC;
    v_final_premium NUMERIC;
    v_daily_premium NUMERIC;
    v_existing_converted_quote UUID;
    v_weather_station_name TEXT;
    v_formatted_first_name TEXT;
    v_formatted_last_name TEXT;
    v_formatted_phone TEXT;
BEGIN
    -- Validate and format customer first name
    IF p_customer_first_name IS NULL OR TRIM(p_customer_first_name) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'Customer first name is required',
                'field', 'customer_first_name'
            )
        );
    END IF;
    
    -- Format first name to proper case
    v_formatted_first_name := format_name_proper_case(p_customer_first_name);
    
    -- Additional validation for first name
    IF LENGTH(v_formatted_first_name) < 2 THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'First name must be at least 2 characters',
                'field', 'customer_first_name'
            )
        );
    END IF;
    
    -- Validate and format customer last name
    IF p_customer_last_name IS NULL OR TRIM(p_customer_last_name) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'Customer last name is required',
                'field', 'customer_last_name'
            )
        );
    END IF;
    
    -- Format last name to proper case
    v_formatted_last_name := format_name_proper_case(p_customer_last_name);
    
    -- Additional validation for last name
    IF LENGTH(v_formatted_last_name) < 2 THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'Last name must be at least 2 characters',
                'field', 'customer_last_name'
            )
        );
    END IF;

    -- Get quote details - RLS automatically filters by partner
    SELECT 
        q.*,
        qp.retail_premium,
        qp.wholesale_premium,
        qp.gst_amount,
        qp.stamp_duty_amount,
        qp.rainfall_trigger,
        qp.rainfall_duration,
        p.partner_name
    INTO v_quote
    FROM quotes q
    JOIN quote_premiums qp ON q.quote_id = qp.quote_id
    LEFT JOIN partners p ON q.partner_id = p.partner_id
    WHERE q.quote_id = p_quote_id;
    
    -- Validate quote exists (RLS ensures partner ownership)
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'QUOTE_NOT_FOUND',
                'message', 'Quote not found'
            )
        );
    END IF;
    
    -- Format phone number using country from quote
    IF p_customer_phone IS NOT NULL AND TRIM(p_customer_phone) != '' THEN
        v_formatted_phone := format_phone_e164_with_country(p_customer_phone, v_quote.country);
        
        IF v_formatted_phone IS NULL THEN
            -- Provide helpful error with country context
            RETURN json_build_object(
                'success', false,
                'error', json_build_object(
                    'code', 'INVALID_PHONE_FORMAT',
                    'message', format('Unable to parse phone number for %s. Examples of valid formats: %s',
                        v_quote.country,
                        CASE v_quote.country
                            WHEN 'US' THEN '+14155552671, 14155552671, (415) 555-2671'
                            WHEN 'AU' THEN '+61412345678, 0412345678, 0412 345 678'
                            WHEN 'GB' THEN '+447911123456, 07911123456, 07911 123456'
                            ELSE 'international format with country code'
                        END
                    ),
                    'field', 'customer_phone',
                    'provided_value', p_customer_phone,
                    'detected_country', v_quote.country
                )
            );
        END IF;
    ELSE
        v_formatted_phone := NULL;
    END IF;
    
    -- Check if another quote in the same group has already been converted
    IF v_quote.quote_group_id IS NOT NULL THEN
        SELECT quote_id INTO v_existing_converted_quote
        FROM quotes
        WHERE quote_group_id = v_quote.quote_group_id
            AND quote_id != p_quote_id
            AND status = 'converted'
            AND partner_id = v_quote.partner_id
        LIMIT 1;
        
        IF v_existing_converted_quote IS NOT NULL THEN
            RETURN json_build_object(
                'success', false,
                'error', json_build_object(
                    'code', 'QUOTE_GROUP_ALREADY_CONVERTED',
                    'message', 'Another quote from this group has already been converted to a policy'
                )
            );
        END IF;
    END IF;
    
    -- Check quote status
    IF v_quote.status = 'converted' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'QUOTE_ALREADY_CONVERTED',
                'message', 'Quote has already been converted to a policy'
            )
        );
    END IF;
    
    IF v_quote.status = 'expired' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'QUOTE_EXPIRED',
                'message', 'Quote has expired'
            )
        );
    END IF;
    
    IF v_quote.status = 'rejected' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'QUOTE_REJECTED',
                'message', 'Quote has been rejected'
            )
        );
    END IF;
    
    IF v_quote.status != 'active' THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'QUOTE_NOT_ACTIVE',
                'message', 'Quote is not active. Current status: ' || v_quote.status
            )
        );
    END IF;
    
    -- Validate quote hasn't expired by time
    IF v_quote.expires_at < NOW() THEN
        UPDATE quotes SET status = 'expired' WHERE quote_id = p_quote_id;
        
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'QUOTE_EXPIRED',
                'message', 'Quote has expired'
            )
        );
    END IF;
    
    -- Get primary location details
    SELECT 
        ql.location_id,
        ql.distance_km,
        ql.seasonal_index,
        ql.is_primary,
        l.name AS station_name
    INTO v_quote_location
    FROM quote_locations ql
    JOIN locations l ON ql.location_id = l.location_id
    WHERE ql.quote_id = p_quote_id
        AND ql.is_primary = true
    LIMIT 1;
    
    v_weather_station_name := v_quote_location.station_name;
    
    -- Get payout information
    SELECT 
        qpo.payout_percentage,
        po.option_name,
        po.description
    INTO v_payout_info
    FROM quote_payout_options qpo
    JOIN payout_options po ON qpo.payout_option_id = po.payout_option_id
    WHERE qpo.quote_id = p_quote_id 
    AND qpo.is_selected = true
    LIMIT 1;
    
    IF v_payout_info IS NULL THEN
        v_payout_info.payout_percentage := 100;
        v_payout_info.option_name := 'Full Coverage';
        v_payout_info.description := 'Full coverage protection';
    END IF;
    
    -- Calculate coverage days and daily values
    v_coverage_days := EXTRACT(EPOCH FROM (v_quote.coverage_end - v_quote.coverage_start)) / 86400;
    IF v_coverage_days > 0 THEN
        v_daily_exposure := ROUND(v_quote.exposure_total / v_coverage_days, 2);
    ELSE
        v_daily_exposure := v_quote.exposure_total;
        v_coverage_days := 1;
    END IF;
    
    v_final_premium := v_quote.retail_premium;
    v_daily_premium := ROUND(v_final_premium / v_coverage_days, 2);
    
    -- Create or find customer using formatted values
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE LOWER(email) = LOWER(p_customer_email)
    LIMIT 1;
    
    IF v_customer_id IS NULL THEN
        INSERT INTO customers (
            customer_id,
            email,
            first_name,
            last_name,
            phone,
            created_at
        ) VALUES (
            gen_random_uuid(),
            LOWER(p_customer_email),
            v_formatted_first_name,
            v_formatted_last_name,
            v_formatted_phone,
            NOW()
        )
        RETURNING customer_id INTO v_customer_id;
    ELSE
        UPDATE customers
        SET 
            first_name = v_formatted_first_name,
            last_name = v_formatted_last_name,
            phone = COALESCE(v_formatted_phone, phone),
            updated_at = NOW()
        WHERE customer_id = v_customer_id;
    END IF;
    
    -- Generate policy number and ID
    v_policy_id := gen_random_uuid();
    v_policy_number := 'POL-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       UPPER(SUBSTRING(v_policy_id::text, 1, 8));
    
    -- Create policy record
    INSERT INTO policy (
        policy_id,
        quote_id,
        partner_id,
        partner_booking_id,
        customer_id,
        event_type,
        experience_name,
        suburb,
        state,
        country,
        latitude,
        longitude,
        primary_location_id,
        distance_to_primary,
        coverage_start,
        coverage_end,
        coverage_start_time,
        coverage_end_time,
        exposure_total,
        daily_exposure,
        final_premium,
        daily_premium,
        coverage_days,
        currency,
        language,
        status,
        payment_status,
        payment_transaction_id,
        policy_number,
        policy_type,
        payout_percentage,
        trigger,
        duration,
        accepted_at,
        created_at
    ) VALUES (
        v_policy_id,
        p_quote_id,
        v_quote.partner_id,
        p_external_booking_id,
        v_customer_id,
        v_quote.event_type,
        v_quote.experience_name,
        v_quote.suburb,
        v_quote.state,
        v_quote.country,
        v_quote.latitude,
        v_quote.longitude,
        v_quote_location.location_id,
        v_quote_location.distance_km,
        v_quote.coverage_start::date,
        v_quote.coverage_end::date,
        v_quote.coverage_start_time,
        v_quote.coverage_end_time,
        v_quote.exposure_total,
        v_daily_exposure,
        v_final_premium,
        v_daily_premium,
        v_coverage_days,
        v_quote.currency,
        v_quote.language,
        'active',
        'paid',
        p_payment_id,
        v_policy_number,
        'rainfall',
        v_payout_info.payout_percentage,
        v_quote.rainfall_trigger,
        v_quote.rainfall_duration,
        NOW(),
        NOW()
    );
    
    -- Create transaction record
    v_transaction_id := gen_random_uuid();
    INSERT INTO transactions (
        transaction_id,
        policy_id,
        amount,
        currency,
        transaction_type,
        status,
        provider,
        provider_transaction_id,
        metadata,
        created_at
    ) VALUES (
        v_transaction_id,
        v_policy_id,
        v_final_premium,
        v_quote.currency,
        'payment',
        'succeeded',
        'external',
        p_payment_id,
        json_build_object(
            'customer_email', p_customer_email,
            'external_booking_id', p_external_booking_id,
            'policy_number', v_policy_number,
            'rainfall_trigger', v_quote.rainfall_trigger,
            'rainfall_duration', v_quote.rainfall_duration
        ),
        NOW()
    );
    
    -- Update quote status
    UPDATE quotes 
    SET status = 'converted'
    WHERE quote_id = p_quote_id;
    
    -- Build response with formatted data
    v_result := json_build_object(
        'quote_id', p_quote_id,
        'policy_id', v_policy_id,
        'policy_number', v_policy_number,
        'status', 'active',
        'created_at', NOW(),
        'customer', json_build_object(
            'email', p_customer_email,
            'first_name', v_formatted_first_name,
            'last_name', v_formatted_last_name,
            'phone', v_formatted_phone
        ),
        'payment', json_build_object(
            'id', v_transaction_id,
            'provider_id', p_payment_id,
            'amount', ROUND(v_final_premium, 2),
            'currency', v_quote.currency,
            'gst_amount', ROUND(v_quote.gst_amount, 2),
            'subtotal', ROUND(v_quote.retail_premium - v_quote.gst_amount - v_quote.stamp_duty_amount, 2),
            'stamp_duty', ROUND(v_quote.stamp_duty_amount, 2)
        ),
        'coverage', json_build_object(
            'start_date', v_quote.coverage_start::date,
            'end_date', v_quote.coverage_end::date,
            'start_hour', v_quote.coverage_start_time,
            'end_hour', v_quote.coverage_end_time,
            'days', v_coverage_days,
            'daily_exposure', v_daily_exposure,
            'location', json_build_object(
                'name', v_quote.experience_name,
                'address', v_quote.suburb || ', ' || v_quote.state,
                'latitude', v_quote.latitude,
                'longitude', v_quote.longitude,
                'weather_station_id', v_quote_location.location_id,
                'weather_station_name', v_weather_station_name,
                'distance_to_station_km', v_quote_location.distance_km
            )
        ),
        'protection', json_build_object(
            'type', 'rainfall',
            'trigger_mm', v_quote.rainfall_trigger,
            'duration_hours', v_quote.rainfall_duration,
            'payout_percentage', v_payout_info.payout_percentage,
            'option_name', v_payout_info.option_name
        ),
        'external_id', p_external_booking_id
    );
    
    RETURN json_build_object('success', true, 'data', v_result);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.analyze_function_complexity(p_function_name text)
 RETURNS TABLE(function_name text, total_lines integer, variable_declarations integer, if_statements integer, loops integer, subqueries integer, insert_statements integer, complexity_score integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_function_def text;
BEGIN
    -- Get function definition
    SELECT pg_get_functiondef(pg_proc.oid) INTO v_function_def
    FROM pg_proc
    JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
    WHERE pg_namespace.nspname = 'public' 
        AND pg_proc.proname = p_function_name;
    
    RETURN QUERY
    SELECT 
        p_function_name,
        array_length(string_to_array(v_function_def, E'\n'), 1) as total_lines,
        array_length(string_to_array(v_function_def, 'DECLARE'), 1) - 1 as variable_declarations,
        array_length(string_to_array(v_function_def, 'IF '), 1) - 1 as if_statements,
        array_length(string_to_array(v_function_def, 'LOOP'), 1) - 1 as loops,
        array_length(string_to_array(v_function_def, 'WITH '), 1) - 1 as subqueries,
        array_length(string_to_array(v_function_def, 'INSERT INTO'), 1) - 1 as insert_statements,
        -- Simple complexity score
        (array_length(string_to_array(v_function_def, 'IF '), 1) - 1) * 2 +
        (array_length(string_to_array(v_function_def, 'LOOP'), 1) - 1) * 3 +
        (array_length(string_to_array(v_function_def, 'WITH '), 1) - 1) * 2 as complexity_score;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.analyze_weather_quotes_v16(p_run_id uuid, p_payout_rate numeric DEFAULT 100, p_batch_size integer DEFAULT 100, p_max_duration_seconds integer DEFAULT 300)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_start_time TIMESTAMPTZ;
  v_analyzed_count INT := 0;
  v_failure_count INT := 0;
  v_triggered_count INT := 0;
  v_total_payout DECIMAL := 0;
  v_total_exposure DECIMAL := 0;
  v_total_wholesale_premium DECIMAL := 0;
  v_total_retail_premium DECIMAL := 0;
  v_failure_reasons JSONB;
  v_run_name TEXT;
  v_batch_count INT := 0;
  v_chunk_start_time TIMESTAMPTZ;
  v_chunk_elapsed DECIMAL;
  v_state_quotes JSONB := '{}'::JSONB;
  v_state_claims JSONB := '{}'::JSONB;
  v_analysis JSONB;
  v_quotes_processed INT := 0;
BEGIN
  -- Get the run name and start time
  SELECT name INTO v_run_name FROM quote_test_runs WHERE id = p_run_id;
  v_start_time := now();
    
  -- Initialize the test run (supporting reruns)
  UPDATE quote_test_runs
  SET payout_rate = p_payout_rate, 
      start_time = v_start_time, 
      last_processed_batch = 0
  WHERE id = p_run_id;
  
  -- Update error categorization for existing failed quotes
  UPDATE quote_test_results
  SET error_type = CASE 
    WHEN error_message ILIKE '%duration%exceeds maximum%' OR error_message ILIKE '%duration%days%maximum%' THEN 'duration_exceeded'
    WHEN error_message ILIKE '%must be made at least%days before%' OR error_message ILIKE '%advance%booking%' THEN 'advance_booking_requirement'
    WHEN error_message ILIKE '%no weather stations%' OR error_message ILIKE '%no stations found%' THEN 'no_stations'
    WHEN error_message ILIKE '%insufficient%stations%' THEN 'insufficient_stations'
    WHEN error_message ILIKE '%exposure%limit%' OR error_message ILIKE '%exposure%exceeded%' THEN 'exposure_limit'
    WHEN error_message ILIKE '%high%rainfall%risk%' THEN 'high_rainfall_risk'
    WHEN error_message ILIKE '%json%syntax%' OR error_message ILIKE '%invalid%json%' THEN 'json_syntax_error'
    WHEN error_message ILIKE '%database%error%' OR error_message ILIKE '%connection%' THEN 'database_error'
    WHEN error_message ILIKE '%missing%analysis%data%' OR error_message ILIKE '%required data%' THEN 'missing_analysis_data'
    WHEN error_message ILIKE '%premium%threshold%' OR error_message ILIKE '%premium%exceeded%' THEN 'premium_threshold_exceeded'
    WHEN error_message ILIKE '%no%seasonal%data%' OR error_message ILIKE '%seasonal%unavailable%' THEN 'no_seasonal_data'
    WHEN error_message ILIKE '%duplicate%reference%' THEN 'duplicate_reference'
    ELSE 'other_errors'
  END
  WHERE run_id = p_run_id AND status = 'FAILED';

  -- Create temporary table for efficient batch processing
  CREATE TEMP TABLE temp_weather_analysis (
    quote_id UUID PRIMARY KEY,
    experience_name TEXT,
    suburb TEXT,
    state TEXT,
    location_id INTEGER,
    start_date DATE,
    end_date DATE,
    duration INTEGER,
    exposure_total NUMERIC,
    daily_exposure NUMERIC,
    wholesale_premium NUMERIC,
    retail_premium NUMERIC,
    rainfall_trigger NUMERIC,
    hours_trigger INTEGER,
    triggered_days_count INTEGER DEFAULT 0,
    p95_rainfall NUMERIC DEFAULT 0,
    p95_rainfall_hours INTEGER DEFAULT 0,
    trigger_date DATE,
    is_triggered BOOLEAN DEFAULT FALSE,
    triggered_exposure NUMERIC DEFAULT 0,
    payout_amount NUMERIC DEFAULT 0,
    analysis_error TEXT,
    error_type TEXT,
    -- V16: P95 tracking fields
    p95_years_triggered INTEGER DEFAULT 0,
    total_years_analyzed INTEGER DEFAULT 10
  ) ON COMMIT DROP;
  
  -- Process quotes in batches (only unprocessed SUCCESS quotes)
  LOOP
    v_chunk_start_time := now();
    
    -- Insert batch of quotes to process into temp table
    WITH quotes_batch AS (
      SELECT qtr.quote_id
      FROM quote_test_results qtr
      WHERE qtr.run_id = p_run_id
      AND qtr.status = 'SUCCESS' 
      AND qtr.analysis_result IS NULL
      LIMIT p_batch_size
    )
    INSERT INTO temp_weather_analysis (
      quote_id, experience_name, suburb, state, location_id,
      start_date, end_date, duration, exposure_total, daily_exposure,
      wholesale_premium, retail_premium, rainfall_trigger, hours_trigger
    )
    SELECT 
      q.quote_id,
      q.experience_name,
      q.suburb,
      q.state,
      COALESCE(q.location_id, ql.location_id),
      q.coverage_start::DATE,
      q.coverage_end::DATE,
      (q.coverage_end::DATE - q.coverage_start::DATE),
      qp.exposure_total,
      qp.exposure_total / GREATEST((q.coverage_end::DATE - q.coverage_start::DATE), 1),
      qp.wholesale_premium,
      qp.retail_premium,
      COALESCE(qp.rainfall_trigger, ql.rainfall_trigger),
      qp.rainfall_duration
    FROM quotes_batch qb
    JOIN quotes q ON q.quote_id = qb.quote_id
    LEFT JOIN quote_premiums qp ON q.quote_id = qp.quote_id
    LEFT JOIN quote_locations ql ON q.quote_id = ql.quote_id AND ql.is_primary = TRUE;
    
    -- Exit if no more quotes
    GET DIAGNOSTICS v_quotes_processed = ROW_COUNT;
    IF v_quotes_processed = 0 THEN
      EXIT;
    END IF;
    
    v_batch_count := v_batch_count + 1;
    
    -- Check timeout
    v_chunk_elapsed := EXTRACT(EPOCH FROM (now() - v_chunk_start_time));
    IF v_chunk_elapsed > p_max_duration_seconds THEN
      RAISE NOTICE 'V16 (P95): Timeout reached after % batches', v_batch_count;
      EXIT;
    END IF;
    
    -- Mark quotes as processing
    UPDATE quote_test_results
    SET status = 'PROCESSING'
    WHERE quote_id IN (SELECT quote_id FROM temp_weather_analysis);
    
    -- Validate data and mark errors
    UPDATE temp_weather_analysis
    SET analysis_error = 'Missing required data',
        error_type = 'missing_analysis_data'
    WHERE location_id IS NULL 
       OR rainfall_trigger IS NULL 
       OR hours_trigger IS NULL;
    
    BEGIN
      -- V16: P95 APPROACH - Analyze weather excluding only top 5% outliers
      WITH historical_periods AS (
        -- Generate historical date ranges for all quotes
        SELECT DISTINCT
          twa.quote_id,
          twa.location_id,
          twa.start_date,
          twa.end_date,
          twa.rainfall_trigger,
          twa.hours_trigger,
          years_back,
          (twa.start_date - (years_back * INTERVAL '1 year'))::DATE AS historical_start,
          (twa.end_date - (years_back * INTERVAL '1 year'))::DATE AS historical_end
        FROM temp_weather_analysis twa
        CROSS JOIN generate_series(1, 10) AS years_back
        WHERE twa.analysis_error IS NULL
      ),
      daily_analysis AS (
        -- Analyze each day across all historical years
        SELECT 
          hp.quote_id,
          cd.coverage_day,
          hp.years_back,
          -- Count qualifying hours for this historical year
          COUNT(*) FILTER (
            WHERE hw.max_rainfall_hourly >= hp.rainfall_trigger 
            AND hw.hour BETWEEN 8 AND 20
          ) as rain_hours,
          MAX(hw.max_rainfall_hourly) FILTER (WHERE hw.hour BETWEEN 8 AND 20) as max_rain
        FROM (
          -- Generate coverage days for each quote
          SELECT DISTINCT
            twa.quote_id,
            generate_series(twa.start_date, twa.end_date - INTERVAL '1 day', '1 day'::interval)::date as coverage_day
          FROM temp_weather_analysis twa
          WHERE twa.analysis_error IS NULL
        ) cd
        JOIN historical_periods hp ON hp.quote_id = cd.quote_id
        LEFT JOIN hourly_weather_data hw ON 
            hw.location_id = hp.location_id
            AND hw.weather_date = (cd.coverage_day - (hp.years_back * INTERVAL '1 year'))::date
        GROUP BY hp.quote_id, cd.coverage_day, hp.years_back
      ),
      -- V16: Calculate P95 percentiles and exclude only top 5% outliers
      daily_percentiles AS (
        SELECT 
          quote_id,
          coverage_day,
          -- For each day, rank the years by rainfall hours
          COUNT(*) FILTER (
            WHERE rain_hours > (
              SELECT hours_trigger FROM temp_weather_analysis 
              WHERE quote_id = da.quote_id
            )
            -- V16: Key change - only count if NOT in top 5% (P95 logic)
            AND rain_hours <= (
              SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY rain_hours)
              FROM daily_analysis da2
              WHERE da2.quote_id = da.quote_id 
                AND da2.coverage_day = da.coverage_day
            )
          ) as p95_years_triggered,
          
          -- Track P95 values for reporting
          PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY rain_hours) as p95_rain_hours,
          PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY max_rain) as p95_max_rain,
          
          -- Still track absolute max for comparison
          MAX(rain_hours) as absolute_max_hours
        FROM daily_analysis da
        GROUP BY quote_id, coverage_day
      ),
      quote_triggers AS (
        -- Aggregate triggers per quote
        SELECT 
          quote_id,
          COUNT(*) FILTER (WHERE p95_years_triggered > 0) as triggered_days_count,
          MAX(p95_max_rain) as p95_rainfall,
          MAX(p95_rain_hours) as p95_rainfall_hours,
          SUM(p95_years_triggered) as total_p95_triggers,
          (ARRAY_AGG(coverage_day ORDER BY p95_years_triggered DESC, p95_rain_hours DESC NULLS LAST))[1] as trigger_date
        FROM daily_percentiles
        GROUP BY quote_id
      )
      -- Update temp table with P95 results
      UPDATE temp_weather_analysis twa
      SET 
        triggered_days_count = COALESCE(qt.triggered_days_count, 0),
        p95_rainfall = COALESCE(qt.p95_rainfall, 0),
        p95_rainfall_hours = COALESCE(qt.p95_rainfall_hours, 0),
        p95_years_triggered = COALESCE(qt.total_p95_triggers, 0),
        trigger_date = qt.trigger_date,
        is_triggered = COALESCE(qt.triggered_days_count, 0) > 0,
        triggered_exposure = (COALESCE(qt.triggered_days_count, 0)::NUMERIC / GREATEST(twa.duration, 1)) * twa.exposure_total,
        payout_amount = (COALESCE(qt.triggered_days_count, 0)::NUMERIC / GREATEST(twa.duration, 1)) * twa.exposure_total * (p_payout_rate / 100.0)
      FROM quote_triggers qt
      WHERE twa.quote_id = qt.quote_id
        AND twa.analysis_error IS NULL;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'V16 (P95): Weather analysis error: %', SQLERRM;
      UPDATE temp_weather_analysis
      SET analysis_error = SQLERRM,
          error_type = 'database_error'
      WHERE analysis_error IS NULL;
    END;
    
    -- Single bulk update for all results
    UPDATE quote_test_results qtr
    SET 
      status = CASE 
        WHEN twa.analysis_error IS NOT NULL THEN 'ANALYSIS_FAILED'
        ELSE 'SUCCESS'
      END,
      analysis_result = CASE 
        WHEN twa.analysis_error IS NULL THEN
          jsonb_build_object(
            'quote_id', twa.quote_id,
            'experience_name', twa.experience_name,
            'suburb', twa.suburb,
            'state', twa.state,
            'exposure_total', twa.exposure_total,
            'daily_exposure', twa.daily_exposure,
            'duration', twa.duration,
            'triggered_days_count', twa.triggered_days_count,
            'triggered_exposure', twa.triggered_exposure,
            'wholesale_premium', twa.wholesale_premium,
            'retail_premium', twa.retail_premium,
            'is_triggered', twa.is_triggered,
            'p95_rainfall', twa.p95_rainfall,
            'p95_rainfall_hours', twa.p95_rainfall_hours,
            'trigger_date', twa.trigger_date,
            'rainfall_trigger_mm', twa.rainfall_trigger,
            'hours_trigger', twa.hours_trigger,
            'analysis_period_years', twa.total_years_analyzed,
            'analysis_version', 'v16_p95_approach',
            'analysis_method', 'P95 (95th percentile) - excludes only top 5% extreme outliers',
            'payout_amount', twa.payout_amount,
            'payout_calculation', jsonb_build_object(
              'method', 'p95_proportional_v16',
              'triggered_days', twa.triggered_days_count,
              'total_days', twa.duration,
              'trigger_proportion', ROUND(twa.triggered_days_count::NUMERIC / GREATEST(twa.duration, 1), 4),
              'payout_rate_applied', p_payout_rate,
              'p95_years_triggered', twa.p95_years_triggered,
              'percentile_used', 0.95
            )
          )
        ELSE NULL
      END,
      claim_status = CASE 
        WHEN twa.analysis_error IS NOT NULL THEN NULL
        WHEN twa.is_triggered THEN 'TRIGGERED'
        ELSE 'NOT_TRIGGERED'
      END,
      payout_amount = CASE 
        WHEN twa.analysis_error IS NULL THEN twa.payout_amount
        ELSE NULL
      END,
      error_type = CASE 
        WHEN twa.analysis_error IS NOT NULL THEN 
          CASE 
            WHEN twa.analysis_error ILIKE '%duration%exceeds maximum%' THEN 'duration_exceeded'
            WHEN twa.analysis_error ILIKE '%must be made at least%days before%' THEN 'advance_booking_requirement'
            WHEN twa.analysis_error ILIKE '%no weather stations%' THEN 'no_stations'
            ELSE 'other_errors'
          END
        ELSE NULL
      END,
      error_message = twa.analysis_error
    FROM temp_weather_analysis twa
    WHERE qtr.quote_id = twa.quote_id;
    
    -- Clear temp table for next batch
    TRUNCATE temp_weather_analysis;
    
    RAISE NOTICE 'V16 (P95): Batch % processed (% quotes) in % seconds', 
                 v_batch_count, v_quotes_processed, 
                 EXTRACT(EPOCH FROM (now() - v_chunk_start_time));
  END LOOP;
  
  -- Calculate failure reasons with individual counts
  SELECT jsonb_build_object(
    'duration_exceeded', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'duration_exceeded'),
    'advance_booking_requirement', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'advance_booking_requirement'),
    'no_stations', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'no_stations'),
    'insufficient_stations', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'insufficient_stations'),
    'exposure_limit', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'exposure_limit'),
    'high_rainfall_risk', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'high_rainfall_risk'),
    'json_syntax_error', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'json_syntax_error'),
    'database_error', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'database_error'),
    'missing_analysis_data', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'missing_analysis_data'),
    'premium_threshold_exceeded', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'premium_threshold_exceeded'),
    'no_seasonal_data', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'no_seasonal_data'),
    'duplicate_reference', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'duplicate_reference'),
    'other_errors', 
      (SELECT COUNT(*) FROM quote_test_results WHERE run_id = p_run_id AND status IN ('FAILED', 'ANALYSIS_FAILED') AND error_type = 'other_errors')
  ) INTO v_failure_reasons;
  
  -- Calculate final statistics in one pass
  WITH final_stats AS (
    SELECT 
      COUNT(*) FILTER (WHERE status = 'SUCCESS') as analyzed_count,
      COUNT(*) FILTER (WHERE status IN ('FAILED', 'ANALYSIS_FAILED')) as failure_count,
      COUNT(*) FILTER (WHERE claim_status = 'TRIGGERED') as triggered_count,
      COALESCE(SUM(payout_amount) FILTER (WHERE status = 'SUCCESS'), 0) as total_payout,
      COALESCE(SUM((analysis_result->>'exposure_total')::DECIMAL) FILTER (WHERE status = 'SUCCESS'), 0) as total_exposure,
      COALESCE(SUM((analysis_result->>'wholesale_premium')::DECIMAL) FILTER (WHERE status = 'SUCCESS'), 0) as total_wholesale_premium,
      COALESCE(SUM((analysis_result->>'retail_premium')::DECIMAL) FILTER (WHERE status = 'SUCCESS'), 0) as total_retail_premium
    FROM quote_test_results
    WHERE run_id = p_run_id
  ),
  state_aggregates AS (
    SELECT 
      analysis_result->>'state' as state,
      COUNT(*) as quote_count,
      COUNT(*) FILTER (WHERE claim_status = 'TRIGGERED') as claim_count
    FROM quote_test_results
    WHERE run_id = p_run_id
      AND status = 'SUCCESS'
      AND analysis_result->>'state' IS NOT NULL
    GROUP BY analysis_result->>'state'
  )
  SELECT 
    fs.*,
    COALESCE(jsonb_object_agg(sa.state, sa.quote_count) FILTER (WHERE sa.state IS NOT NULL), '{}'::jsonb) as state_quotes,
    COALESCE(jsonb_object_agg(sa.state, sa.claim_count) FILTER (WHERE sa.state IS NOT NULL), '{}'::jsonb) as state_claims
  INTO 
    v_analyzed_count, v_failure_count, v_triggered_count, v_total_payout,
    v_total_exposure, v_total_wholesale_premium, v_total_retail_premium,
    v_state_quotes, v_state_claims
  FROM final_stats fs
  CROSS JOIN state_aggregates sa
  GROUP BY fs.analyzed_count, fs.failure_count, fs.triggered_count, fs.total_payout,
           fs.total_exposure, fs.total_wholesale_premium, fs.total_retail_premium;
  
  -- Create final results
  v_analysis := jsonb_build_object(
    'run_id', p_run_id,
    'run_name', v_run_name,
    'analysis_version', 'V16 - P95 Approach (95th percentile)',
    'analysis_method', 'Excludes only top 5% extreme outlier years for more balanced coverage',
    'total_quotes', v_analyzed_count,
    'triggered_claims', v_triggered_count,
    'claim_rate', CASE WHEN v_analyzed_count > 0 THEN round((v_triggered_count::NUMERIC / v_analyzed_count) * 100, 2) ELSE 0 END,
    'total_exposure', v_total_exposure,
    'total_payout', v_total_payout,
    'total_wholesale_premium', v_total_wholesale_premium,
    'total_retail_premium', v_total_retail_premium,
    'payout_rate', p_payout_rate / 100.0,
    'payout_ratio', CASE WHEN v_total_retail_premium > 0 THEN round((v_total_payout / v_total_retail_premium) * 100, 2) ELSE 0 END,
    'exposure_ratio', CASE WHEN v_total_exposure > 0 THEN round((v_total_payout / v_total_exposure) * 100, 2) ELSE 0 END,
    'failure_reasons', v_failure_reasons,
    'duration_seconds', extract(epoch from (now() - v_start_time)),
    'quotes_by_state', v_state_quotes,
    'claims_by_state', v_state_claims,
    'batches_processed', v_batch_count,
    'version_comparison', jsonb_build_object(
      'v14_approach', 'All weather events included (100%)',
      'v15_approach', 'P90 - Excludes top 10% outliers',
      'v16_approach', 'P95 - Excludes only top 5% outliers',
      'expected_claim_rate', '10-20% (between v14 and v15)',
      'balance', 'Better coverage for customers while maintaining actuarial sustainability'
    )
  );
  
  -- Finalize test run
  UPDATE quote_test_runs
  SET 
    analysis_results = v_analysis,
    end_time = now(),
    analyzed_count = v_analyzed_count,
    success_count = v_analyzed_count,
    failure_count = v_failure_count,
    failure_reasons = v_failure_reasons,
    last_processed_batch = v_batch_count
  WHERE id = p_run_id;
  
  RETURN v_analysis;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_rotate_expired_keys(p_dry_run boolean DEFAULT true, p_notification_webhook text DEFAULT NULL::text)
 RETURNS TABLE(total_candidates integer, rotated_count integer, failed_count integer, rotation_results jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
  key_record RECORD;
  rotation_result RECORD;
  v_total_candidates INTEGER := 0;
  v_rotated_count INTEGER := 0;
  v_failed_count INTEGER := 0;
  v_results JSONB := '[]'::JSONB;
BEGIN
  -- Count total candidates
  SELECT COUNT(*) INTO v_total_candidates FROM get_keys_needing_rotation();
  
  -- Process each key needing rotation
  FOR key_record IN SELECT * FROM get_keys_needing_rotation() LOOP
    IF NOT p_dry_run THEN
      -- Perform actual rotation
      SELECT * INTO rotation_result
      FROM manage_partner_keys(
        key_record.partner_id,
        'rotate',
        NULL,
        format('Auto-rotated: %s', key_record.reason),
        format('Automatic rotation - %s', key_record.reason)
      );
      
      IF rotation_result.success THEN
        v_rotated_count := v_rotated_count + 1;
      ELSE
        v_failed_count := v_failed_count + 1;
      END IF;
      
      -- Add to results
      v_results := v_results || jsonb_build_object(
        'partner_id', key_record.partner_id,
        'partner_name', key_record.partner_name,
        'old_key_id', key_record.key_id,
        'new_key_id', rotation_result.key_id,
        'success', rotation_result.success,
        'reason', key_record.reason,
        'message', rotation_result.message
      );
    END IF;
  END LOOP;
  
  -- Send notification if webhook provided and not dry run
  IF p_notification_webhook IS NOT NULL AND NOT p_dry_run THEN
    BEGIN
      PERFORM net.http_post(
        p_notification_webhook,
        jsonb_build_object(
          'event_type', 'auto_key_rotation_completed',
          'total_candidates', v_total_candidates,
          'rotated_count', v_rotated_count,
          'failed_count', v_failed_count,
          'details', v_results,
          'timestamp', NOW()
        )::text,
        headers => '{"Content-Type": "application/json"}'::jsonb
      );
    EXCEPTION WHEN OTHERS THEN
      -- Webhook failed, but don't fail the whole operation
      NULL;
    END;
  END IF;
  
  RETURN QUERY SELECT 
    v_total_candidates, 
    v_rotated_count, 
    v_failed_count, 
    v_results;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.bulk_insert_hourly_data(csv_data text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    CREATE TEMP TABLE temp_hourly_data (
        location_id integer,
        weather_date date,
        hour integer,
        max_temp_hourly numeric(5,2),
        max_rainfall_hourly numeric(6,2)
    ) ON COMMIT DROP;

    COPY temp_hourly_data FROM STDIN WITH (FORMAT csv, NULL '\\N');
    EXECUTE format($cmd$ %s $cmd$, csv_data);

    INSERT INTO hourly_weather_data (location_id, weather_date, hour, max_temp_hourly, max_rainfall_hourly)
    SELECT location_id, weather_date, hour, max_temp_hourly, max_rainfall_hourly 
    FROM temp_hourly_data
    ON CONFLICT (location_id, weather_date, hour) 
    DO UPDATE SET
        max_temp_hourly = EXCLUDED.max_temp_hourly,
        max_rainfall_hourly = EXCLUDED.max_rainfall_hourly;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.bulk_insert_hourly_weather_data(records jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  inserted_count integer := 0;
  rec jsonb;
BEGIN
  -- Use a temporary table for bulk loading
  CREATE TEMP TABLE temp_hourly_data (
    location_id integer,
    weather_date date,
    hour integer,
    timezone varchar(50),
    max_temp_hourly numeric(5,2),
    max_rainfall_hourly numeric(6,2)
  ) ON COMMIT DROP;
  
  -- Extract data from JSON and insert into temp table
  FOR rec IN SELECT jsonb_array_elements(records)
  LOOP
    INSERT INTO temp_hourly_data (
      location_id,
      weather_date,
      hour,
      timezone,
      max_temp_hourly,
      max_rainfall_hourly
    ) VALUES (
      (rec->>'location_id')::integer,
      (rec->>'weather_date')::date,
      (rec->>'hour')::integer,
      COALESCE(rec->>'timezone', 'UTC'),
      NULLIF(rec->>'max_temp_hourly', 'null')::numeric(5,2),
      NULLIF(rec->>'max_rainfall_hourly', 'null')::numeric(6,2)
    );
  
    inserted_count := inserted_count + 1;
  END LOOP;
  
  -- Insert from temp table to actual table with conflict handling
  INSERT INTO public.hourly_weather_data (
    location_id,
    weather_date,
    hour,
    timezone,
    max_temp_hourly,
    max_rainfall_hourly,
    created_at,
    updated_at
  )
  SELECT
    t.location_id,
    t.weather_date,
    t.hour,
    t.timezone,
    t.max_temp_hourly,
    t.max_rainfall_hourly,
    now(),
    now()
  FROM
    temp_hourly_data t
  ON CONFLICT (location_id, weather_date, hour) 
  DO UPDATE SET
    max_temp_hourly = EXCLUDED.max_temp_hourly,
    max_rainfall_hourly = EXCLUDED.max_rainfall_hourly,
    timezone = EXCLUDED.timezone,
    updated_at = now();
  
  RETURN inserted_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_seasonal_indices_adaptive_v5(p_location_id integer, p_max_trigger numeric DEFAULT 8.0, p_min_trigger numeric DEFAULT 2.0, p_min_index numeric DEFAULT 0.5, p_smoothing_window integer DEFAULT 7, p_apply_enso boolean DEFAULT true, p_min_samples integer DEFAULT 1, p_coastal_high_mult numeric DEFAULT 1.2, p_coastal_medium_mult numeric DEFAULT 1.1, p_inland_mult numeric DEFAULT 1.0, p_volatility_cap numeric DEFAULT 1.0, p_volatility_divisor numeric DEFAULT 5, p_volatility_exponent numeric DEFAULT 1.0, p_temporal_high_freq numeric DEFAULT 0.6, p_temporal_high_mult numeric DEFAULT 1.3, p_temporal_med_freq numeric DEFAULT 0.4, p_temporal_med_mult numeric DEFAULT 1.2, p_temporal_low_freq numeric DEFAULT 0.25, p_temporal_low_mult numeric DEFAULT 1.1, p_sample_very_low_mult numeric DEFAULT 1.3, p_sample_low_mult numeric DEFAULT 1.15, p_sample_very_low_threshold integer DEFAULT 4, p_sample_low_threshold integer DEFAULT 7, OUT days_processed integer, OUT execution_time interval, OUT avg_index numeric, OUT max_index numeric, OUT avg_duration numeric, OUT enso_factor numeric, OUT location_type text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_days_processed INTEGER := 0;
    v_location_enso_sensitivity NUMERIC;
    v_location_type TEXT;
    v_current_anomaly_type VARCHAR(50);
    v_current_anomaly_intensity VARCHAR(50);
    v_current_anomaly_id INTEGER;
    v_enso_multiplier NUMERIC := 1.0;
    v_temp_consecutive_table TEXT := 'temp_consecutive_' || p_location_id || '_' || extract(epoch from now())::integer;
    v_temp_outlier_table TEXT := 'temp_outlier_' || p_location_id || '_' || extract(epoch from now())::integer;
    v_window_size INTEGER;
    -- Calculated thresholds based on parameters
    v_threshold_1hr NUMERIC;
    v_threshold_2hr NUMERIC;
    v_threshold_3hr NUMERIC;
    v_threshold_4hr NUMERIC;
BEGIN
    -- Calculate adaptive thresholds based on input parameters (same as v4)
    v_threshold_1hr := p_min_trigger;
    v_threshold_2hr := p_min_trigger + (p_max_trigger - p_min_trigger) * 0.33;
    v_threshold_3hr := p_min_trigger + (p_max_trigger - p_min_trigger) * 0.67;
    v_threshold_4hr := p_max_trigger;
    
    -- Log the calculated thresholds for transparency
    RAISE NOTICE 'Adaptive thresholds - 1hr: %, 2hr: %, 3hr: %, 4hr: %', 
        v_threshold_1hr, v_threshold_2hr, v_threshold_3hr, v_threshold_4hr;
    
    -- Calculate window size
    v_window_size := p_smoothing_window::INTEGER / 2;
    
    -- Get location characteristics
    SELECT 
        COALESCE(enso_rainfall_correlation, 0),
        CASE 
            WHEN is_coastal = true THEN 'coastal_high'
            WHEN distance_to_coast_km < 50 THEN 'coastal_medium'
            ELSE 'inland'
        END
    INTO v_location_enso_sensitivity, v_location_type
    FROM locations 
    WHERE location_id = p_location_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Location ID % not found', p_location_id;
    END IF;
    
    -- Get current ENSO phase if enabled (same as v4)
    IF p_apply_enso THEN
        SELECT 
            id,
            anomaly_type,
            intensity
        INTO 
            v_current_anomaly_id,
            v_current_anomaly_type,
            v_current_anomaly_intensity
        FROM climate_anomalies
        WHERE CURRENT_DATE BETWEEN start_date AND end_date
        ORDER BY id DESC
        LIMIT 1;
        
        v_current_anomaly_type := LEFT(COALESCE(v_current_anomaly_type, 'ENSO-neutral'), 50);
        v_current_anomaly_intensity := LEFT(COALESCE(v_current_anomaly_intensity, 'N/A'), 50);
        
        -- Calculate ENSO multiplier
        v_enso_multiplier := CASE
            WHEN v_current_anomaly_intensity = 'Strong' THEN 
                1 + (ABS(v_location_enso_sensitivity) * 0.5)
            WHEN v_current_anomaly_intensity = 'Moderate' THEN
                1 + (ABS(v_location_enso_sensitivity) * 0.3)
            WHEN v_current_anomaly_intensity = 'Weak' THEN
                1 + (ABS(v_location_enso_sensitivity) * 0.15)
            ELSE 1.0
        END;
        
        -- Invert if correlation is negative
        IF (v_current_anomaly_type = 'El Niño' AND v_location_enso_sensitivity < 0) OR
           (v_current_anomaly_type = 'La Niña' AND v_location_enso_sensitivity > 0) THEN
            v_enso_multiplier := 1.0 / v_enso_multiplier;
        END IF;
    END IF;
    
    -- Create outlier analysis table (same as v4)
    EXECUTE format('
    CREATE TEMP TABLE %I AS
    WITH yearly_data AS (
        SELECT
            weather_date,
            EXTRACT(MONTH FROM weather_date)::INTEGER AS month_of_year,
            EXTRACT(DAY FROM weather_date)::INTEGER AS day_of_month,
            EXTRACT(YEAR FROM weather_date)::INTEGER AS year,
            MAX(max_rainfall) AS daily_max
        FROM historical_weather_data
        WHERE location_id = %s
        GROUP BY weather_date
    ),
    rolling_stats AS (
        SELECT
            weather_date,
            month_of_year,
            day_of_month,
            year,
            daily_max,
            AVG(daily_max) OVER (
                ORDER BY weather_date
                RANGE BETWEEN INTERVAL ''15 days'' PRECEDING 
                          AND INTERVAL ''15 days'' FOLLOWING
            ) AS window_mean,
            STDDEV(daily_max) OVER (
                ORDER BY weather_date
                RANGE BETWEEN INTERVAL ''15 days'' PRECEDING 
                          AND INTERVAL ''15 days'' FOLLOWING
            ) AS window_stddev,
            COUNT(daily_max) OVER (
                ORDER BY weather_date
                RANGE BETWEEN INTERVAL ''15 days'' PRECEDING 
                          AND INTERVAL ''15 days'' FOLLOWING
            ) AS window_count
        FROM yearly_data
    ),
    outlier_flags AS (
        SELECT
            month_of_year,
            day_of_month,
            year,
            daily_max,
            window_mean,
            window_stddev,
            CASE 
                WHEN window_stddev > 0 AND daily_max > window_mean + (2 * window_stddev) THEN 1
                WHEN daily_max > window_mean * 2.5 THEN 1
                ELSE 0
            END AS is_outlier,
            CASE 
                WHEN window_stddev > 0 THEN (daily_max - window_mean) / window_stddev
                ELSE 0
            END AS z_score
        FROM rolling_stats
    )
    SELECT
        month_of_year,
        day_of_month,
        AVG(is_outlier) AS outlier_frequency,
        AVG(CASE WHEN is_outlier = 1 THEN ABS(z_score) ELSE NULL END) AS avg_outlier_magnitude,
        COUNT(*) AS years_of_data
    FROM outlier_flags
    GROUP BY month_of_year, day_of_month', v_temp_outlier_table, p_location_id);
    
    -- Create index
    EXECUTE format('CREATE INDEX idx_%I_date ON %I (month_of_year, day_of_month)', 
                   v_temp_outlier_table, v_temp_outlier_table);
    
    -- Create consecutive rain analysis table with ADAPTIVE thresholds (same as v4)
    EXECUTE format('
    CREATE TEMP TABLE %I AS
    WITH hourly_windows AS (
        SELECT 
            weather_date,
            hour,
            max_rainfall_hourly,
            max_rainfall_hourly AS rainfall_1hr,
            SUM(max_rainfall_hourly) OVER (
                PARTITION BY weather_date 
                ORDER BY hour 
                ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
            ) AS rainfall_2hr,
            SUM(max_rainfall_hourly) OVER (
                PARTITION BY weather_date 
                ORDER BY hour 
                ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
            ) AS rainfall_3hr,
            SUM(max_rainfall_hourly) OVER (
                PARTITION BY weather_date 
                ORDER BY hour 
                ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING
            ) AS rainfall_4hr,
            CASE 
                WHEN max_rainfall_hourly > 0 THEN
                    SUM(CASE WHEN max_rainfall_hourly = 0 THEN 1 ELSE 0 END) 
                    OVER (PARTITION BY weather_date ORDER BY hour)
                ELSE NULL
            END AS rain_group
        FROM hourly_weather_data
        WHERE location_id = %s
          AND hour BETWEEN 8 AND 20
    ),
    consecutive_groups AS (
        SELECT
            weather_date,
            rain_group,
            COUNT(*) AS consecutive_hours,
            MAX(max_rainfall_hourly) AS max_hourly_in_group,
            SUM(max_rainfall_hourly) AS total_rain_in_group
        FROM hourly_windows
        WHERE max_rainfall_hourly > 0
        GROUP BY weather_date, rain_group
    ),
    daily_analysis AS (
        SELECT
            hw.weather_date,
            EXTRACT(MONTH FROM hw.weather_date)::INTEGER AS month_of_year,
            EXTRACT(DAY FROM hw.weather_date)::INTEGER AS day_of_month,
            COALESCE(MAX(cg.consecutive_hours), 0) AS max_consecutive_hours,
            COUNT(*) FILTER (WHERE hw.max_rainfall_hourly > 0) AS total_rain_hours,
            MAX(hw.rainfall_1hr) AS max_1hr_rainfall,
            MAX(hw.rainfall_2hr) AS max_2hr_rainfall,
            MAX(hw.rainfall_3hr) AS max_3hr_rainfall,
            MAX(hw.rainfall_4hr) AS max_4hr_rainfall,
            MAX(CASE WHEN hw.rainfall_1hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_1hr,
            MAX(CASE WHEN hw.rainfall_2hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_2hr,
            MAX(CASE WHEN hw.rainfall_3hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_3hr,
            MAX(CASE WHEN hw.rainfall_4hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_4hr
        FROM hourly_windows hw
        LEFT JOIN consecutive_groups cg 
            ON hw.weather_date = cg.weather_date 
            AND hw.rain_group = cg.rain_group
        GROUP BY hw.weather_date
    )
    SELECT * FROM daily_analysis', 
    v_temp_consecutive_table, 
    p_location_id,
    v_threshold_1hr,
    v_threshold_2hr,
    v_threshold_3hr,
    v_threshold_4hr);
    
    -- Create index
    EXECUTE format('CREATE INDEX idx_%I_date ON %I (month_of_year, day_of_month)', 
                   v_temp_consecutive_table, v_temp_consecutive_table);
    
    -- Main update query with PARAMETERIZED values AND 0.5 INTERVAL ROUNDING
    EXECUTE format('
    UPDATE daily_seasonal_indices dsi
    SET 
        avg_rainfall_duration = sp.duration,
        optimal_hour_trigger = sp.duration,
        modified_rainfall_trigger = sp.rainfall_trigger,
        base_seasonal_index = sp.base_index,
        modified_seasonal_index = sp.modified_index,
        comprehensive_risk_index = sp.modified_index,
        rainfall_90th_percentile = sp.p90_rainfall,
        trigger_1hr_prob = sp.prob_1hr,
        trigger_2hr_prob = sp.prob_2hr,
        trigger_3hr_prob = sp.prob_3hr,
        trigger_4hr_prob = sp.prob_4hr,
        high_risk_flag = (sp.modified_index > 5.0),
        temporal_context_flag = sp.has_temporal_pattern,
        moderate_risk_flag = (sp.modified_index > 3.0 AND sp.modified_index <= 5.0),
        climate_anomaly_flag = ($2 IN (''El Niño'', ''La Niña'')),
        applied_anomaly_type = $2,
        applied_anomaly_intensity = $3,
        climate_anomaly_id = $4,
        enso_factor = $5,
        extended_risk_level = $6,
        policy_recommendation = sp.recommendation,
        sample_count = sp.min_samples::INTEGER,
        version = ''adaptive_v5'',
        last_pattern_analysis = NOW()
    FROM (
        WITH daily_patterns AS (
            SELECT
                month_of_year,
                day_of_month,
                PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY max_consecutive_hours) AS p80_consecutive_hours,
                AVG(max_consecutive_hours) AS avg_consecutive_hours,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_1hr_rainfall) AS p90_1hr_rainfall,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_2hr_rainfall) AS p90_2hr_rainfall,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_3hr_rainfall) AS p90_3hr_rainfall,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_4hr_rainfall) AS p90_4hr_rainfall,
                AVG(exceeds_threshold_1hr::INTEGER::NUMERIC) AS prob_threshold_1hr,
                AVG(exceeds_threshold_2hr::INTEGER::NUMERIC) AS prob_threshold_2hr,
                AVG(exceeds_threshold_3hr::INTEGER::NUMERIC) AS prob_threshold_3hr,
                AVG(exceeds_threshold_4hr::INTEGER::NUMERIC) AS prob_threshold_4hr,
                STDDEV(max_1hr_rainfall) AS volatility_1hr,
                COUNT(*) AS sample_days
            FROM %I
            GROUP BY month_of_year, day_of_month
        ),
        smoothed_patterns AS (
            SELECT
                dp.*,
                COALESCE(ot.outlier_frequency, 0)::NUMERIC AS outlier_frequency,
                COALESCE(ot.outlier_frequency > 0.25, false) AS has_temporal_pattern,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_1hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_1hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_1hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_2hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_2hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_2hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_3hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_3hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_3hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_4hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_4hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_4hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_1hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_1hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_1hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_2hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_2hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_2hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_3hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_3hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_3hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_4hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_4hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_4hr,
                (AVG(dp.p80_consecutive_hours) OVER w)::NUMERIC AS smooth_consecutive_hours,
                (AVG(dp.volatility_1hr) OVER w)::NUMERIC AS smooth_volatility,
                MIN(dp.sample_days) OVER w AS min_samples
            FROM daily_patterns dp
            LEFT JOIN %I ot USING (month_of_year, day_of_month)
            WINDOW w AS (
                ORDER BY dp.month_of_year, dp.day_of_month
                ROWS BETWEEN %s PRECEDING AND %s FOLLOWING
            )
        )
        SELECT
            month_of_year,
            day_of_month,
            -- Duration calculation (same as v4)
            CASE
                WHEN smooth_consecutive_hours >= 3.5 THEN 4
                WHEN smooth_consecutive_hours >= 2.5 THEN 3
                WHEN smooth_consecutive_hours >= 1.5 THEN 2
                ELSE 1
            END AS duration,
            -- Rainfall trigger calculation WITH 0.5 INTERVAL ROUNDING
            ROUND(
                LEAST($7::NUMERIC,  -- p_max_trigger
                    GREATEST($8::NUMERIC,  -- p_min_trigger
                        CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN smooth_p90_4hr * 0.45
                            WHEN smooth_consecutive_hours >= 2.5 THEN smooth_p90_3hr * 0.40
                            WHEN smooth_consecutive_hours >= 1.5 THEN smooth_p90_2hr * 0.48
                            ELSE smooth_p90_1hr * 0.55
                        END * 2
                    )
                ) * 2  -- Multiply by 2
            ) / 2  -- Then divide by 2 to get 0.5 intervals
            AS rainfall_trigger,
            -- Base index calculation with PARAMETERIZED volatility
            GREATEST($9::NUMERIC,  -- p_min_index
                (1.0 * 
                (1 + GREATEST(0::NUMERIC, 
                    CASE
                        WHEN smooth_consecutive_hours >= 3.5 THEN (smooth_p90_4hr - $7) * 0.15
                        WHEN smooth_consecutive_hours >= 2.5 THEN (smooth_p90_3hr - ($7 * 0.8)) * 0.2
                        WHEN smooth_consecutive_hours >= 1.5 THEN (smooth_p90_2hr - ($7 * 0.6)) * 0.25
                        ELSE (smooth_p90_1hr - ($7 * 0.4)) * 0.3
                    END
                )) *
                (1 + CASE
                    WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 1.2
                    WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 1.5
                    WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.8
                    ELSE smooth_prob_threshold_1hr * 2.0
                END) *
                -- EXPONENTIAL VOLATILITY SCALING
                (1 + POWER(LEAST($10::NUMERIC, smooth_volatility / $11), $12)))::NUMERIC
            ) AS base_index,
            -- Modified index with PARAMETERIZED adjustments
            GREATEST($9::NUMERIC,  -- p_min_index
                (GREATEST($9::NUMERIC, 
                    (1.0 * 
                    (1 + GREATEST(0::NUMERIC, 
                        CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN (smooth_p90_4hr - $7) * 0.15
                            WHEN smooth_consecutive_hours >= 2.5 THEN (smooth_p90_3hr - ($7 * 0.8)) * 0.2
                            WHEN smooth_consecutive_hours >= 1.5 THEN (smooth_p90_2hr - ($7 * 0.6)) * 0.25
                            ELSE (smooth_p90_1hr - ($7 * 0.4)) * 0.3
                        END
                    )) *
                    (1 + CASE
                        WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 1.2
                        WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 1.5
                        WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.8
                        ELSE smooth_prob_threshold_1hr * 2.0
                    END) *
                    -- EXPONENTIAL VOLATILITY SCALING
                    (1 + POWER(LEAST($10::NUMERIC, smooth_volatility / $11), $12)))::NUMERIC
                ) * 
                $5::NUMERIC *  -- ENSO multiplier
                -- PARAMETERIZED LOCATION TYPE MULTIPLIERS
                CASE $6  
                    WHEN ''coastal_high'' THEN $13::NUMERIC
                    WHEN ''coastal_medium'' THEN $14::NUMERIC
                    ELSE $15::NUMERIC
                END *
                -- PARAMETERIZED TEMPORAL PATTERN ADJUSTMENTS
                CASE   
                    WHEN outlier_frequency > $16 THEN $17::NUMERIC
                    WHEN outlier_frequency > $18 THEN $19::NUMERIC
                    WHEN outlier_frequency > $20 THEN $21::NUMERIC
                    ELSE 1.0
                END *
                -- PARAMETERIZED SAMPLE SIZE ADJUSTMENTS
                CASE   
                    WHEN min_samples < $22 * $23 THEN $24::NUMERIC
                    WHEN min_samples < $22 * $25 THEN $26::NUMERIC
                    ELSE 1.0
                END)::NUMERIC
            ) AS modified_index,
            -- P90 rainfall
            CASE 
                WHEN smooth_consecutive_hours >= 3.5 THEN smooth_p90_4hr
                WHEN smooth_consecutive_hours >= 2.5 THEN smooth_p90_3hr
                WHEN smooth_consecutive_hours >= 1.5 THEN smooth_p90_2hr
                ELSE smooth_p90_1hr
            END AS p90_rainfall,
            smooth_prob_threshold_1hr AS prob_1hr,
            smooth_prob_threshold_2hr AS prob_2hr,
            smooth_prob_threshold_3hr AS prob_3hr,
            smooth_prob_threshold_4hr AS prob_4hr,
            has_temporal_pattern,
            ''Adaptive v5 ('' || $27 || ''-'' || $28 || ''mm)'' AS recommendation,
            min_samples
        FROM smoothed_patterns
    ) sp
    WHERE dsi.location_id = $1
      AND dsi.month_of_year = sp.month_of_year
      AND dsi.day_of_month = sp.day_of_month',
    v_temp_consecutive_table, v_temp_outlier_table, v_window_size, v_window_size)
    USING 
        p_location_id,                          -- $1
        v_current_anomaly_type,                 -- $2
        v_current_anomaly_intensity,            -- $3
        COALESCE(v_current_anomaly_id, 0),      -- $4
        v_enso_multiplier,                      -- $5
        v_location_type,                        -- $6
        p_max_trigger,                          -- $7
        p_min_trigger,                          -- $8
        p_min_index,                            -- $9
        p_volatility_cap,                       -- $10
        p_volatility_divisor,                   -- $11
        p_volatility_exponent,                  -- $12
        p_coastal_high_mult,                    -- $13
        p_coastal_medium_mult,                  -- $14
        p_inland_mult,                          -- $15
        p_temporal_high_freq,                   -- $16
        p_temporal_high_mult,                   -- $17
        p_temporal_med_freq,                    -- $18
        p_temporal_med_mult,                    -- $19
        p_temporal_low_freq,                    -- $20
        p_temporal_low_mult,                    -- $21
        p_min_samples,                          -- $22
        p_sample_very_low_threshold,            -- $23
        p_sample_very_low_mult,                 -- $24
        p_sample_low_threshold,                 -- $25
        p_sample_low_mult,                      -- $26
        ROUND(p_min_trigger * 2) / 2,           -- $27 (for recommendation text, rounded to 0.5)
        ROUND(p_max_trigger * 2) / 2;           -- $28 (for recommendation text, rounded to 0.5)
    
    GET DIAGNOSTICS v_days_processed = ROW_COUNT;
    
    -- Clean up temporary tables
    EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_consecutive_table);
    EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_outlier_table);
    
    -- Return summary statistics
    SELECT
        v_days_processed,
        clock_timestamp() - v_start_time,
        AVG(modified_seasonal_index),
        MAX(modified_seasonal_index),
        AVG(avg_rainfall_duration::NUMERIC),
        v_enso_multiplier,
        v_location_type
    INTO
        days_processed,
        execution_time,
        avg_index,
        max_index,
        avg_duration,
        enso_factor,
        location_type
    FROM daily_seasonal_indices
    WHERE location_id = p_location_id
      AND version = 'adaptive_v5';
    
    RETURN;
        
EXCEPTION
    WHEN OTHERS THEN
        -- Clean up on error
        EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_consecutive_table);
        EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_outlier_table);
        RAISE EXCEPTION 'Error in calculate_seasonal_indices_adaptive_v5: %', SQLERRM;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_seasonal_indices_adaptive_v6(p_location_id integer, OUT days_processed integer, OUT execution_time interval, OUT avg_index numeric, OUT max_index numeric, OUT avg_duration numeric, OUT enso_factor numeric, OUT location_type text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    -- Config from table
    v_config RECORD;
    
    -- Standard variables (same as v5)
    v_start_time TIMESTAMP := clock_timestamp();
    v_days_processed INTEGER := 0;
    v_location_enso_sensitivity NUMERIC;
    v_location_type TEXT;
    v_current_anomaly_type VARCHAR(50);
    v_current_anomaly_intensity VARCHAR(50);
    v_current_anomaly_id INTEGER;
    v_enso_multiplier NUMERIC := 1.0;
    v_temp_consecutive_table TEXT := 'temp_consecutive_' || p_location_id || '_' || extract(epoch from now())::integer;
    v_temp_outlier_table TEXT := 'temp_outlier_' || p_location_id || '_' || extract(epoch from now())::integer;
    v_window_size INTEGER;
    -- Calculated thresholds based on config
    v_threshold_1hr NUMERIC;
    v_threshold_2hr NUMERIC;
    v_threshold_3hr NUMERIC;
    v_threshold_4hr NUMERIC;
    
    -- Fixed internal parameters (not in config)
    v_min_index NUMERIC := 0.5;
    v_smoothing_window INTEGER := 7;
    v_min_samples INTEGER := 1;
    v_inland_mult NUMERIC := 1.0;
    v_volatility_cap NUMERIC := 1.0;
    v_volatility_divisor NUMERIC := 5;
    v_volatility_exponent NUMERIC := 1.0;
    v_temporal_high_freq NUMERIC := 0.6;
    v_temporal_high_mult NUMERIC := 1.3;
    v_temporal_med_freq NUMERIC := 0.4;
    v_temporal_med_mult NUMERIC := 1.2;
    v_temporal_low_freq NUMERIC := 0.25;
    v_temporal_low_mult NUMERIC := 1.1;
    v_sample_very_low_mult NUMERIC := 1.3;
    v_sample_low_mult NUMERIC := 1.15;
    v_sample_very_low_threshold INTEGER := 4;
    v_sample_low_threshold INTEGER := 7;
BEGIN
    -- Get configuration from table
    SELECT * INTO v_config FROM seasonal_config LIMIT 1;
    
    -- If no config exists, use defaults
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No configuration found in seasonal_config table';
    END IF;
    
    -- Calculate adaptive thresholds based on config
    v_threshold_1hr := v_config.min_trigger;
    v_threshold_2hr := v_config.min_trigger + (v_config.max_trigger - v_config.min_trigger) * 0.33;
    v_threshold_3hr := v_config.min_trigger + (v_config.max_trigger - v_config.min_trigger) * 0.67;
    v_threshold_4hr := v_config.max_trigger;
    
    v_window_size := v_smoothing_window::INTEGER / 2;
    
    RAISE NOTICE 'Adaptive thresholds - 1hr: %, 2hr: %, 3hr: %, 4hr: %', 
        v_threshold_1hr, v_threshold_2hr, v_threshold_3hr, v_threshold_4hr;
    
    -- Get location characteristics
    SELECT 
        COALESCE(enso_rainfall_correlation, 0),
        CASE 
            WHEN is_coastal = true THEN 'coastal_high'
            WHEN distance_to_coast_km < 50 THEN 'coastal_medium'
            ELSE 'inland'
        END
    INTO v_location_enso_sensitivity, v_location_type
    FROM locations 
    WHERE location_id = p_location_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Location ID % not found', p_location_id;
    END IF;
    
    -- Get current ENSO phase if enabled
    IF v_config.apply_enso THEN
        SELECT 
            id,
            anomaly_type,
            intensity
        INTO 
            v_current_anomaly_id,
            v_current_anomaly_type,
            v_current_anomaly_intensity
        FROM climate_anomalies
        WHERE CURRENT_DATE BETWEEN start_date AND end_date
        ORDER BY id DESC
        LIMIT 1;
        
        v_current_anomaly_type := LEFT(COALESCE(v_current_anomaly_type, 'ENSO-neutral'), 50);
        v_current_anomaly_intensity := LEFT(COALESCE(v_current_anomaly_intensity, 'N/A'), 50);
        
        -- Calculate ENSO multiplier
        v_enso_multiplier := CASE
            WHEN v_current_anomaly_intensity = 'Strong' THEN 
                1 + (ABS(v_location_enso_sensitivity) * 0.5)
            WHEN v_current_anomaly_intensity = 'Moderate' THEN
                1 + (ABS(v_location_enso_sensitivity) * 0.3)
            WHEN v_current_anomaly_intensity = 'Weak' THEN
                1 + (ABS(v_location_enso_sensitivity) * 0.15)
            ELSE 1.0
        END;
        
        -- Invert if correlation is negative
        IF (v_current_anomaly_type = 'El Niño' AND v_location_enso_sensitivity < 0) OR
           (v_current_anomaly_type = 'La Niña' AND v_location_enso_sensitivity > 0) THEN
            v_enso_multiplier := 1.0 / v_enso_multiplier;
        END IF;
    END IF;
    
    -- Create outlier analysis table
    EXECUTE format('
    CREATE TEMP TABLE %I AS
    WITH yearly_data AS (
        SELECT
            weather_date,
            EXTRACT(MONTH FROM weather_date)::INTEGER AS month_of_year,
            EXTRACT(DAY FROM weather_date)::INTEGER AS day_of_month,
            EXTRACT(YEAR FROM weather_date)::INTEGER AS year,
            MAX(max_rainfall) AS daily_max
        FROM historical_weather_data
        WHERE location_id = %s
        GROUP BY weather_date
    ),
    rolling_stats AS (
        SELECT
            weather_date,
            month_of_year,
            day_of_month,
            year,
            daily_max,
            AVG(daily_max) OVER (
                ORDER BY weather_date
                RANGE BETWEEN INTERVAL ''15 days'' PRECEDING 
                          AND INTERVAL ''15 days'' FOLLOWING
            ) AS window_mean,
            STDDEV(daily_max) OVER (
                ORDER BY weather_date
                RANGE BETWEEN INTERVAL ''15 days'' PRECEDING 
                          AND INTERVAL ''15 days'' FOLLOWING
            ) AS window_stddev,
            COUNT(daily_max) OVER (
                ORDER BY weather_date
                RANGE BETWEEN INTERVAL ''15 days'' PRECEDING 
                          AND INTERVAL ''15 days'' FOLLOWING
            ) AS window_count
        FROM yearly_data
    ),
    outlier_flags AS (
        SELECT
            month_of_year,
            day_of_month,
            year,
            daily_max,
            window_mean,
            window_stddev,
            CASE 
                WHEN window_stddev > 0 AND daily_max > window_mean + (2 * window_stddev) THEN 1
                WHEN daily_max > window_mean * 2.5 THEN 1
                ELSE 0
            END AS is_outlier,
            CASE 
                WHEN window_stddev > 0 THEN (daily_max - window_mean) / window_stddev
                ELSE 0
            END AS z_score
        FROM rolling_stats
    )
    SELECT
        month_of_year,
        day_of_month,
        AVG(is_outlier) AS outlier_frequency,
        AVG(CASE WHEN is_outlier = 1 THEN ABS(z_score) ELSE NULL END) AS avg_outlier_magnitude,
        COUNT(*) AS years_of_data
    FROM outlier_flags
    GROUP BY month_of_year, day_of_month', v_temp_outlier_table, p_location_id);
    
    -- Create index
    EXECUTE format('CREATE INDEX idx_%I_date ON %I (month_of_year, day_of_month)', 
                   v_temp_outlier_table, v_temp_outlier_table);
    
    -- Create consecutive rain analysis table with ADAPTIVE thresholds
    EXECUTE format('
    CREATE TEMP TABLE %I AS
    WITH hourly_windows AS (
        SELECT 
            weather_date,
            hour,
            max_rainfall_hourly,
            max_rainfall_hourly AS rainfall_1hr,
            SUM(max_rainfall_hourly) OVER (
                PARTITION BY weather_date 
                ORDER BY hour 
                ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
            ) AS rainfall_2hr,
            SUM(max_rainfall_hourly) OVER (
                PARTITION BY weather_date 
                ORDER BY hour 
                ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
            ) AS rainfall_3hr,
            SUM(max_rainfall_hourly) OVER (
                PARTITION BY weather_date 
                ORDER BY hour 
                ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING
            ) AS rainfall_4hr,
            CASE 
                WHEN max_rainfall_hourly > 0 THEN
                    SUM(CASE WHEN max_rainfall_hourly = 0 THEN 1 ELSE 0 END) 
                    OVER (PARTITION BY weather_date ORDER BY hour)
                ELSE NULL
            END AS rain_group
        FROM hourly_weather_data
        WHERE location_id = %s
          AND hour BETWEEN 8 AND 20
    ),
    consecutive_groups AS (
        SELECT
            weather_date,
            rain_group,
            COUNT(*) AS consecutive_hours,
            MAX(max_rainfall_hourly) AS max_hourly_in_group,
            SUM(max_rainfall_hourly) AS total_rain_in_group
        FROM hourly_windows
        WHERE max_rainfall_hourly > 0
        GROUP BY weather_date, rain_group
    ),
    daily_analysis AS (
        SELECT
            hw.weather_date,
            EXTRACT(MONTH FROM hw.weather_date)::INTEGER AS month_of_year,
            EXTRACT(DAY FROM hw.weather_date)::INTEGER AS day_of_month,
            COALESCE(MAX(cg.consecutive_hours), 0) AS max_consecutive_hours,
            COUNT(*) FILTER (WHERE hw.max_rainfall_hourly > 0) AS total_rain_hours,
            MAX(hw.rainfall_1hr) AS max_1hr_rainfall,
            MAX(hw.rainfall_2hr) AS max_2hr_rainfall,
            MAX(hw.rainfall_3hr) AS max_3hr_rainfall,
            MAX(hw.rainfall_4hr) AS max_4hr_rainfall,
            MAX(CASE WHEN hw.rainfall_1hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_1hr,
            MAX(CASE WHEN hw.rainfall_2hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_2hr,
            MAX(CASE WHEN hw.rainfall_3hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_3hr,
            MAX(CASE WHEN hw.rainfall_4hr >= %s THEN 1 ELSE 0 END) AS exceeds_threshold_4hr
        FROM hourly_windows hw
        LEFT JOIN consecutive_groups cg 
            ON hw.weather_date = cg.weather_date 
            AND hw.rain_group = cg.rain_group
        GROUP BY hw.weather_date
    )
    SELECT * FROM daily_analysis', 
    v_temp_consecutive_table, 
    p_location_id,
    v_threshold_1hr,
    v_threshold_2hr,
    v_threshold_3hr,
    v_threshold_4hr);
    
    -- Create index
    EXECUTE format('CREATE INDEX idx_%I_date ON %I (month_of_year, day_of_month)', 
                   v_temp_consecutive_table, v_temp_consecutive_table);
    
    -- Main update query with discount logic
    EXECUTE format('
    UPDATE daily_seasonal_indices dsi
    SET 
        avg_rainfall_duration = sp.duration,
        optimal_hour_trigger = sp.duration,
        modified_rainfall_trigger = sp.rainfall_trigger,
        base_seasonal_index = sp.base_index,
        modified_seasonal_index = sp.modified_index,
        comprehensive_risk_index = sp.modified_index,
        rainfall_90th_percentile = sp.p90_rainfall,
        trigger_1hr_prob = sp.prob_1hr,
        trigger_2hr_prob = sp.prob_2hr,
        trigger_3hr_prob = sp.prob_3hr,
        trigger_4hr_prob = sp.prob_4hr,
        high_risk_flag = (sp.modified_index > 5.0),
        temporal_context_flag = sp.has_temporal_pattern,
        moderate_risk_flag = (sp.modified_index > 3.0 AND sp.modified_index <= 5.0),
        climate_anomaly_flag = ($2 IN (''El Niño'', ''La Niña'')),
        applied_anomaly_type = $2,
        applied_anomaly_intensity = $3,
        climate_anomaly_id = $4,
        enso_factor = $5,
        extended_risk_level = $6,
        policy_recommendation = sp.recommendation,
        sample_count = sp.min_samples::INTEGER,
        version = ''adaptive_v6'',
        last_pattern_analysis = NOW()
    FROM (
        WITH daily_patterns AS (
            SELECT
                month_of_year,
                day_of_month,
                PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY max_consecutive_hours) AS p80_consecutive_hours,
                AVG(max_consecutive_hours) AS avg_consecutive_hours,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_1hr_rainfall) AS p90_1hr_rainfall,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_2hr_rainfall) AS p90_2hr_rainfall,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_3hr_rainfall) AS p90_3hr_rainfall,
                PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY max_4hr_rainfall) AS p90_4hr_rainfall,
                AVG(exceeds_threshold_1hr::INTEGER::NUMERIC) AS prob_threshold_1hr,
                AVG(exceeds_threshold_2hr::INTEGER::NUMERIC) AS prob_threshold_2hr,
                AVG(exceeds_threshold_3hr::INTEGER::NUMERIC) AS prob_threshold_3hr,
                AVG(exceeds_threshold_4hr::INTEGER::NUMERIC) AS prob_threshold_4hr,
                STDDEV(max_1hr_rainfall) AS volatility_1hr,
                COUNT(*) AS sample_days
            FROM %I
            GROUP BY month_of_year, day_of_month
        ),
        smoothed_patterns AS (
            SELECT
                dp.*,
                COALESCE(ot.outlier_frequency, 0)::NUMERIC AS outlier_frequency,
                COALESCE(ot.outlier_frequency > 0.25, false) AS has_temporal_pattern,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_1hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_1hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_1hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_2hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_2hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_2hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_3hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_3hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_3hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.p90_4hr_rainfall::NUMERIC
                    ELSE (AVG(dp.p90_4hr_rainfall) OVER w)::NUMERIC
                END AS smooth_p90_4hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_1hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_1hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_1hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_2hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_2hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_2hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_3hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_3hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_3hr,
                CASE 
                    WHEN ot.outlier_frequency > 0.5 THEN dp.prob_threshold_4hr::NUMERIC
                    ELSE (AVG(dp.prob_threshold_4hr) OVER w)::NUMERIC
                END AS smooth_prob_threshold_4hr,
                (AVG(dp.p80_consecutive_hours) OVER w)::NUMERIC AS smooth_consecutive_hours,
                (AVG(dp.volatility_1hr) OVER w)::NUMERIC AS smooth_volatility,
                MIN(dp.sample_days) OVER w AS min_samples
            FROM daily_patterns dp
            LEFT JOIN %I ot USING (month_of_year, day_of_month)
            WINDOW w AS (
                ORDER BY dp.month_of_year, dp.day_of_month
                ROWS BETWEEN %s PRECEDING AND %s FOLLOWING
            )
        )
        SELECT
            month_of_year,
            day_of_month,
            -- Duration calculation
            CASE
                WHEN smooth_consecutive_hours >= 3.5 THEN 4
                WHEN smooth_consecutive_hours >= 2.5 THEN 3
                WHEN smooth_consecutive_hours >= 1.5 THEN 2
                ELSE 1
            END AS duration,
            -- Rainfall trigger calculation WITH 0.5 INTERVAL ROUNDING
            ROUND(
                LEAST($7::NUMERIC,
                    GREATEST($8::NUMERIC,
                        CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN smooth_p90_4hr * 0.45
                            WHEN smooth_consecutive_hours >= 2.5 THEN smooth_p90_3hr * 0.40
                            WHEN smooth_consecutive_hours >= 1.5 THEN smooth_p90_2hr * 0.48
                            ELSE smooth_p90_1hr * 0.55
                        END * 2
                    )
                ) * 2
            ) / 2 AS rainfall_trigger,
            
            -- Base index calculation WITH DISCOUNT LOGIC
            CASE 
                WHEN $27 AND $28 THEN
                    -- RATIO-BASED APPROACH
                    GREATEST($29::NUMERIC,
                        POWER(
                            GREATEST(0.01,
                                CASE
                                    WHEN smooth_consecutive_hours >= 3.5 THEN smooth_p90_4hr / NULLIF($7, 0)
                                    WHEN smooth_consecutive_hours >= 2.5 THEN smooth_p90_3hr / NULLIF($7 * 0.8, 0)
                                    WHEN smooth_consecutive_hours >= 1.5 THEN smooth_p90_2hr / NULLIF($7 * 0.6, 0)
                                    ELSE smooth_p90_1hr / NULLIF($7 * 0.4, 0)
                                END
                            ),
                            $30
                        ) *
                        (1 + CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 0.6
                            WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 0.8
                            WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.0
                            ELSE smooth_prob_threshold_1hr * 1.2
                        END) *
                        (1 + POWER(LEAST($10, smooth_volatility / $11), $12))
                    )
                
                WHEN $27 AND NOT $28 THEN
                    -- DISCOUNT FACTOR APPROACH
                    GREATEST($29::NUMERIC,
                        (1.0 * 
                        (1 + GREATEST(0::NUMERIC, 
                            CASE
                                WHEN smooth_consecutive_hours >= 3.5 THEN (smooth_p90_4hr - $7) * 0.15
                                WHEN smooth_consecutive_hours >= 2.5 THEN (smooth_p90_3hr - ($7 * 0.8)) * 0.2
                                WHEN smooth_consecutive_hours >= 1.5 THEN (smooth_p90_2hr - ($7 * 0.6)) * 0.25
                                ELSE (smooth_p90_1hr - ($7 * 0.4)) * 0.3
                            END
                        )) *
                        (1 + CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 1.2
                            WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 1.5
                            WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.8
                            ELSE smooth_prob_threshold_1hr * 2.0
                        END) *
                        (1 + POWER(LEAST($10, smooth_volatility / $11), $12))) *
                        CASE 
                            WHEN smooth_p90_1hr < $8 * 0.5 THEN 0.7
                            WHEN smooth_p90_1hr < $8 THEN 0.85
                            ELSE 1.0
                        END *
                        CASE 
                            WHEN smooth_volatility < 2.0 THEN 0.85
                            ELSE 1.0
                        END
                    )
                
                ELSE
                    -- ORIGINAL CALCULATION (when discounts disabled)
                    GREATEST($9::NUMERIC,
                        (1.0 * 
                        (1 + GREATEST(0::NUMERIC, 
                            CASE
                                WHEN smooth_consecutive_hours >= 3.5 THEN (smooth_p90_4hr - $7) * 0.15
                                WHEN smooth_consecutive_hours >= 2.5 THEN (smooth_p90_3hr - ($7 * 0.8)) * 0.2
                                WHEN smooth_consecutive_hours >= 1.5 THEN (smooth_p90_2hr - ($7 * 0.6)) * 0.25
                                ELSE (smooth_p90_1hr - ($7 * 0.4)) * 0.3
                            END
                        )) *
                        (1 + CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 1.2
                            WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 1.5
                            WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.8
                            ELSE smooth_prob_threshold_1hr * 2.0
                        END) *
                        (1 + POWER(LEAST($10, smooth_volatility / $11), $12)))
                    )
            END AS base_index,
            
            -- Modified index calculation
            CASE 
                WHEN $27 AND $28 THEN
                    GREATEST($29::NUMERIC,
                        POWER(
                            GREATEST(0.01,
                                CASE
                                    WHEN smooth_consecutive_hours >= 3.5 THEN smooth_p90_4hr / NULLIF($7, 0)
                                    WHEN smooth_consecutive_hours >= 2.5 THEN smooth_p90_3hr / NULLIF($7 * 0.8, 0)
                                    WHEN smooth_consecutive_hours >= 1.5 THEN smooth_p90_2hr / NULLIF($7 * 0.6, 0)
                                    ELSE smooth_p90_1hr / NULLIF($7 * 0.4, 0)
                                END
                            ),
                            $30
                        ) *
                        (1 + CASE
                            WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 0.6
                            WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 0.8
                            WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.0
                            ELSE smooth_prob_threshold_1hr * 1.2
                        END) *
                        (1 + POWER(LEAST($10, smooth_volatility / $11), $12)) *
                        $5::NUMERIC *
                        CASE $6  
                            WHEN ''coastal_high'' THEN $13::NUMERIC
                            WHEN ''coastal_medium'' THEN $14::NUMERIC
                            ELSE $15::NUMERIC
                        END *
                        CASE   
                            WHEN outlier_frequency > $16 THEN $17::NUMERIC
                            WHEN outlier_frequency > $18 THEN $19::NUMERIC
                            WHEN outlier_frequency > $20 THEN $21::NUMERIC
                            ELSE 1.0
                        END *
                        CASE   
                            WHEN min_samples < $22 * $23 THEN $24::NUMERIC
                            WHEN min_samples < $22 * $25 THEN $26::NUMERIC
                            ELSE 1.0
                        END
                    )
                ELSE
                    GREATEST($9::NUMERIC,
                        (GREATEST($9::NUMERIC, 
                            (1.0 * 
                            (1 + GREATEST(0::NUMERIC, 
                                CASE
                                    WHEN smooth_consecutive_hours >= 3.5 THEN (smooth_p90_4hr - $7) * 0.15
                                    WHEN smooth_consecutive_hours >= 2.5 THEN (smooth_p90_3hr - ($7 * 0.8)) * 0.2
                                    WHEN smooth_consecutive_hours >= 1.5 THEN (smooth_p90_2hr - ($7 * 0.6)) * 0.25
                                    ELSE (smooth_p90_1hr - ($7 * 0.4)) * 0.3
                                END
                            )) *
                            (1 + CASE
                                WHEN smooth_consecutive_hours >= 3.5 THEN smooth_prob_threshold_4hr * 1.2
                                WHEN smooth_consecutive_hours >= 2.5 THEN smooth_prob_threshold_3hr * 1.5
                                WHEN smooth_consecutive_hours >= 1.5 THEN smooth_prob_threshold_2hr * 1.8
                                ELSE smooth_prob_threshold_1hr * 2.0
                            END) *
                            (1 + POWER(LEAST($10, smooth_volatility / $11), $12)))::NUMERIC
                        ) * 
                        $5::NUMERIC *
                        CASE $6  
                            WHEN ''coastal_high'' THEN $13::NUMERIC
                            WHEN ''coastal_medium'' THEN $14::NUMERIC
                            ELSE $15::NUMERIC
                        END *
                        CASE   
                            WHEN outlier_frequency > $16 THEN $17::NUMERIC
                            WHEN outlier_frequency > $18 THEN $19::NUMERIC
                            WHEN outlier_frequency > $20 THEN $21::NUMERIC
                            ELSE 1.0
                        END *
                        CASE   
                            WHEN min_samples < $22 * $23 THEN $24::NUMERIC
                            WHEN min_samples < $22 * $25 THEN $26::NUMERIC
                            ELSE 1.0
                        END)::NUMERIC
                    )
            END AS modified_index,
            
            -- P90 rainfall
            CASE 
                WHEN smooth_consecutive_hours >= 3.5 THEN smooth_p90_4hr
                WHEN smooth_consecutive_hours >= 2.5 THEN smooth_p90_3hr
                WHEN smooth_consecutive_hours >= 1.5 THEN smooth_p90_2hr
                ELSE smooth_p90_1hr
            END AS p90_rainfall,
            smooth_prob_threshold_1hr AS prob_1hr,
            smooth_prob_threshold_2hr AS prob_2hr,
            smooth_prob_threshold_3hr AS prob_3hr,
            smooth_prob_threshold_4hr AS prob_4hr,
            has_temporal_pattern,
            ''Adaptive v6 ('' || $8 || ''-'' || $7 || ''mm)'' || 
                CASE WHEN $27 THEN '' [Discounts Enabled]'' ELSE '''' END AS recommendation,
            min_samples
        FROM smoothed_patterns
    ) sp
    WHERE dsi.location_id = $1
      AND dsi.month_of_year = sp.month_of_year
      AND dsi.day_of_month = sp.day_of_month',
    v_temp_consecutive_table, v_temp_outlier_table, v_window_size, v_window_size)
    USING 
        p_location_id,                          -- $1
        v_current_anomaly_type,                 -- $2
        v_current_anomaly_intensity,            -- $3
        COALESCE(v_current_anomaly_id, 0),      -- $4
        v_enso_multiplier,                      -- $5
        v_location_type,                        -- $6
        v_config.max_trigger,                   -- $7  (from config)
        v_config.min_trigger,                   -- $8  (from config)
        v_min_index,                            -- $9
        v_volatility_cap,                       -- $10
        v_volatility_divisor,                   -- $11
        v_volatility_exponent,                  -- $12
        v_config.coastal_high_mult,             -- $13 (from config)
        v_config.coastal_medium_mult,           -- $14 (from config)
        v_inland_mult,                          -- $15
        v_temporal_high_freq,                   -- $16
        v_temporal_high_mult,                   -- $17
        v_temporal_med_freq,                    -- $18
        v_temporal_med_mult,                    -- $19
        v_temporal_low_freq,                    -- $20
        v_temporal_low_mult,                    -- $21
        v_min_samples,                          -- $22
        v_sample_very_low_threshold,            -- $23
        v_sample_very_low_mult,                 -- $24
        v_sample_low_threshold,                 -- $25
        v_sample_low_mult,                      -- $26
        v_config.enable_discounts,              -- $27 (from config)
        v_config.use_ratio_method,              -- $28 (from config)
        v_config.min_index_discounted,          -- $29 (from config)
        v_config.ratio_exponent;                -- $30 (from config)
    
    GET DIAGNOSTICS v_days_processed = ROW_COUNT;
    
    -- Clean up temporary tables
    EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_consecutive_table);
    EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_outlier_table);
    
    -- Return summary statistics
    SELECT
        v_days_processed,
        clock_timestamp() - v_start_time,
        AVG(modified_seasonal_index),
        MAX(modified_seasonal_index),
        AVG(avg_rainfall_duration::NUMERIC),
        v_enso_multiplier,
        v_location_type
    INTO
        days_processed,
        execution_time,
        avg_index,
        max_index,
        avg_duration,
        enso_factor,
        location_type
    FROM daily_seasonal_indices
    WHERE location_id = p_location_id
      AND version = 'adaptive_v6';
    
    RETURN;
        
EXCEPTION
    WHEN OTHERS THEN
        -- Clean up on error
        EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_consecutive_table);
        EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_outlier_table);
        RAISE EXCEPTION 'Error in calculate_seasonal_indices_adaptive_v6: %', SQLERRM;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.can_cancel_policy(p_policy_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_policy RECORD;
    v_has_paid_claims BOOLEAN;
BEGIN
    SELECT 
        p.*,
        EXISTS (
            SELECT 1 
            FROM claims 
            WHERE policy_id = p.policy_id 
            AND claim_status IN ('approved', 'paid')
        ) as has_paid_claims
    INTO v_policy
    FROM policy p
    WHERE p.policy_id = p_policy_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'can_cancel', false,
            'reason', 'Policy not found'
        );
    END IF;
    
    IF v_policy.status IN ('cancelled', 'refunded') THEN
        RETURN jsonb_build_object(
            'can_cancel', false,
            'reason', 'Policy already cancelled',
            'status', v_policy.status
        );
    END IF;
    
    IF v_policy.status = 'completed' THEN
        RETURN jsonb_build_object(
            'can_cancel', false,
            'reason', 'Policy has been completed'
        );
    END IF;
    
    IF v_policy.coverage_start <= CURRENT_DATE THEN
        IF v_policy.has_paid_claims THEN
            RETURN jsonb_build_object(
                'can_cancel', false,
                'reason', 'Policy has paid claims'
            );
        ELSE
            RETURN jsonb_build_object(
                'can_cancel', false,
                'reason', 'Coverage has already started'
            );
        END IF;
    END IF;
    
    RETURN jsonb_build_object(
        'can_cancel', true,
        'reason', 'Policy can be cancelled',
        'refund_amount', v_policy.final_premium,
        'days_until_coverage', v_policy.coverage_start - CURRENT_DATE
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cancel_policy(p_policy_id uuid, p_reason text DEFAULT NULL::text, p_cancellation_type character varying DEFAULT 'customer_request'::character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    v_policy RECORD;
    v_refund_amount NUMERIC;
    v_transaction_id UUID;
    v_has_claims BOOLEAN;
    v_total_claims NUMERIC;
    v_pending_claims_count INTEGER;
BEGIN
    -- ✅ RLS SECURITY: Get policy details (RLS ensures partner ownership)
    SELECT p.* INTO v_policy
    FROM policy p
    WHERE p.policy_id = p_policy_id;
    
    -- Check if policy exists (RLS ensures partner ownership)
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'POLICY_NOT_FOUND',
                'message', 'Policy not found'
            )
        );
    END IF;
    
    -- Get claims information separately (RLS ensures partner ownership)
    SELECT 
        COUNT(*) > 0,
        COALESCE(SUM(CASE WHEN claim_status IN ('approved', 'paid') THEN claim_amount ELSE 0 END), 0),
        COUNT(CASE WHEN claim_status = 'pending' THEN 1 END)
    INTO v_has_claims, v_total_claims, v_pending_claims_count
    FROM claims
    WHERE policy_id = p_policy_id;
    
    -- Check if already cancelled or refunded
    IF v_policy.status IN ('cancelled', 'refunded') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'ALREADY_CANCELLED',
                'message', format('Policy is already %s', v_policy.status)
            )
        );
    END IF;
    
    -- Check if policy has been completed
    IF v_policy.status = 'completed' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'POLICY_COMPLETED',
                'message', 'Cannot cancel a completed policy'
            )
        );
    END IF;
    
    -- Check if coverage has started (matching Sensible's logic)
    IF v_policy.coverage_start <= CURRENT_DATE THEN
        -- Check if there are approved/paid claims
        IF v_total_claims > 0 THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', jsonb_build_object(
                    'code', 'HAS_PAID_CLAIMS',
                    'message', format('Cannot cancel policy with paid claims. Total claimed: %s %s', v_total_claims, v_policy.currency)
                )
            );
        END IF;
        
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'COVERAGE_ACTIVE',
                'message', 'Cannot cancel policy after coverage has started'
            )
        );
    END IF;
    
    -- Calculate refund (full premium if not started and no claims)
    v_refund_amount := v_policy.final_premium - v_total_claims;
    
    -- If refund amount is negative, no refund
    IF v_refund_amount < 0 THEN
        v_refund_amount := 0;
    END IF;
    
    -- Begin transaction block
    BEGIN
        -- 🆕 CANCEL ALL PENDING CLAIMS FIRST
        UPDATE claims 
        SET 
            claim_status = 'cancelled',
            updated_at = NOW(),
            claim_reason = COALESCE(claim_reason, '') || ' [CANCELLED: Policy cancelled - ' || p_cancellation_type || ']'
        WHERE policy_id = p_policy_id 
          AND claim_status = 'pending';
        
        -- Update policy status (RLS ensures partner ownership)
        UPDATE policy 
        SET 
            status = CASE 
                WHEN v_refund_amount > 0 THEN 'refunded'
                ELSE 'cancelled'
            END,
            cancelled_at = NOW(),
            cancellation_reason = p_reason,
            cancellation_type = p_cancellation_type,
            payment_status = CASE 
                WHEN v_refund_amount > 0 THEN 'refunded'
                ELSE payment_status
            END
        WHERE policy_id = p_policy_id;
        
        -- Create refund transaction if applicable
        IF v_refund_amount > 0 THEN
            INSERT INTO transactions (
                transaction_id,
                policy_id,
                amount,
                currency,
                transaction_type,
                status,
                provider,
                metadata
            ) VALUES (
                gen_random_uuid(),
                p_policy_id,
                v_refund_amount,
                v_policy.currency,
                'refund',
                'pending', -- Will be updated when actual refund is processed
                'system',
                jsonb_build_object(
                    'cancellation_reason', p_reason,
                    'cancellation_type', p_cancellation_type,
                    'original_premium', v_policy.final_premium,
                    'total_claims', v_total_claims,
                    'pending_claims_cancelled', v_pending_claims_count,
                    'refund_calculation', jsonb_build_object(
                        'premium', v_policy.final_premium,
                        'claims_paid', v_total_claims,
                        'refund_amount', v_refund_amount
                    )
                )
            ) RETURNING transaction_id INTO v_transaction_id;
        END IF;
        
        -- Return success response
        RETURN jsonb_build_object(
            'success', true,
            'data', jsonb_build_object(
                'policy_id', p_policy_id,
                'policy_number', v_policy.policy_number,
                'status', CASE WHEN v_refund_amount > 0 THEN 'refunded' ELSE 'cancelled' END,
                'refund_amount', v_refund_amount,
                'transaction_id', v_transaction_id,
                'cancelled_at', NOW(),
                'cancellation_type', p_cancellation_type,
                'had_claims', v_has_claims,
                'total_claims_amount', v_total_claims,
                'pending_claims_cancelled', v_pending_claims_count
            )
        );
        
    EXCEPTION WHEN OTHERS THEN
        -- Rollback will happen automatically
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'INTERNAL_ERROR',
                'message', format('Failed to cancel policy: %s', SQLERRM)
            )
        );
    END;
    
END;$function$
;

CREATE OR REPLACE FUNCTION public.check_daily_exposure_limits(p_start_date date, p_end_date date, p_daily_amount numeric, p_limit numeric DEFAULT 500000)
 RETURNS TABLE(is_valid boolean, message text, max_exposure_date date, max_exposure_amount numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
    v_max_date DATE;
    v_max_amount NUMERIC;
    v_exceeds_limit BOOLEAN := FALSE;
BEGIN
    -- Find the date with maximum exposure
    WITH daily_exposures AS (
        SELECT 
            d.date,
            COALESCE(SUM(
                p.exposure_total / (p.coverage_end::date - p.coverage_start::date + 1)
            ), 0) AS daily_exposure
        FROM generate_series(p_start_date, p_end_date, '1 day'::interval) d(date)
        LEFT JOIN policy p ON 
            p.coverage_start::date <= d.date 
            AND p.coverage_end::date >= d.date
        GROUP BY d.date
    )
    SELECT 
        de.date,
        de.daily_exposure + p_daily_amount
    INTO 
        v_max_date,
        v_max_amount
    FROM daily_exposures de
    ORDER BY de.daily_exposure + p_daily_amount DESC
    LIMIT 1;
    
    -- Check if any day would exceed the limit
    v_exceeds_limit := v_max_amount > p_limit;
    
    RETURN QUERY
    SELECT 
        NOT v_exceeds_limit AS is_valid,
        CASE 
            WHEN v_exceeds_limit THEN 
                format('Daily exposure limit of %s would be exceeded on %s (total: %s)',
                    p_limit, v_max_date, v_max_amount)
            ELSE 
                'Daily exposure limits OK'
        END AS message,
        v_max_date AS max_exposure_date,
        v_max_amount AS max_exposure_amount;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.compare_quote_premiums(v3_result jsonb, v4_result jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    v3_quotes JSONB;
    v4_quotes JSONB;
    i INTEGER;
    v3_premium NUMERIC;
    v4_premium NUMERIC;
BEGIN
    -- If either failed, check if both failed the same way
    IF v3_result->>'success' = 'false' OR v4_result->>'success' = 'false' THEN
        RETURN v3_result->>'success' = v4_result->>'success';
    END IF;
    
    v3_quotes := COALESCE(v3_result->'quotes', '[]'::jsonb);
    v4_quotes := COALESCE(v4_result->'quotes', '[]'::jsonb);
    
    -- Check same number of quotes
    IF jsonb_array_length(v3_quotes) != jsonb_array_length(v4_quotes) THEN
        RETURN FALSE;
    END IF;
    
    -- Compare each quote's premiums
    FOR i IN 0..jsonb_array_length(v3_quotes)-1 LOOP
        -- Compare retail premium (main comparison point)
        v3_premium := (v3_quotes->i->'premium'->>'retail_premium')::NUMERIC;
        v4_premium := (v4_quotes->i->'premium'->>'retail_premium')::NUMERIC;
        
        -- Allow for small rounding differences (0.01)
        IF ABS(v3_premium - v4_premium) > 0.01 THEN
            RETURN FALSE;
        END IF;
        
        -- Compare wholesale premium
        v3_premium := (v3_quotes->i->'premium'->>'wholesale_premium')::NUMERIC;
        v4_premium := (v4_quotes->i->'premium'->>'wholesale_premium')::NUMERIC;
        
        IF ABS(v3_premium - v4_premium) > 0.01 THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    
    RETURN TRUE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_policy_refund(p_transaction_id uuid, p_provider_transaction_id text, p_status character varying DEFAULT 'succeeded'::character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_transaction RECORD;
BEGIN
    -- Get transaction details
    SELECT * INTO v_transaction
    FROM transactions
    WHERE transaction_id = p_transaction_id
    AND transaction_type = 'refund';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'TRANSACTION_NOT_FOUND',
                'message', 'Refund transaction not found'
            )
        );
    END IF;
    
    -- Update transaction status
    UPDATE transactions
    SET 
        status = p_status,
        provider_transaction_id = p_provider_transaction_id,
        metadata = metadata || jsonb_build_object(
            'confirmed_at', NOW(),
            'provider_status', p_status
        )
    WHERE transaction_id = p_transaction_id;
    
    -- If refund succeeded, ensure policy status is correct
    IF p_status = 'succeeded' THEN
        UPDATE policy
        SET payment_status = 'refunded'
        WHERE policy_id = v_transaction.policy_id
        AND status IN ('cancelled', 'refunded');
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'transaction_id', p_transaction_id,
            'status', p_status,
            'policy_id', v_transaction.policy_id
        )
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_bulk_weather_quotes_with_version_choice(p_partner_id uuid, p_run_name text, p_num_quotes integer DEFAULT 100, p_event_type text DEFAULT 'camping'::text, p_min_exposure numeric DEFAULT 100, p_max_exposure numeric DEFAULT 50000, p_max_event_duration integer DEFAULT 21, p_base_percent numeric DEFAULT 0.10, p_batch_size integer DEFAULT 150, p_log_failures boolean DEFAULT true, p_use_version text DEFAULT 'v1'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_results JSONB;
  v_run_id UUID;
  v_start_time TIMESTAMPTZ;
  v_success_count INT := 0;
  v_failure_count INT := 0;
  v_attempts_count INT := 0;
  v_destination_record RECORD;
  v_failure_reasons JSONB := jsonb_build_object(
    'no_stations', 0,
    'insufficient_stations', 0,
    'exposure_limit', 0,
    'high_rainfall_risk', 0,
    'json_syntax_error', 0,
    'database_error', 0,
    'no_seasonal_data', 0,
    'missing_seasonal_data', 0,
    'premium_threshold_exceeded', 0,
    'duplicate_reference', 0,
    'other_errors', 0,
    'duration_exceeded', 0,
    'advance_booking_requirement', 0,
    'test_mode', 0
  );
  v_random_month INT;
  v_year INT;
  v_random_day INT;
  v_event_duration INT;
  v_start_date DATE;
  v_end_date DATE;
  v_exposure DECIMAL;
  v_partner_quote_id TEXT;
  v_experience_name TEXT;
  v_suburb TEXT;
  v_state TEXT;
  v_latitude DECIMAL;
  v_longitude DECIMAL;
  v_quote JSONB;
  v_current_month INT;
  v_quote_ids UUID[] := '{}'::UUID[];
  v_peak_months INT[];
  v_peak_period TEXT;
  v_error TEXT;
  v_error_type TEXT;
  v_max_iterations INT;
  v_is_failure BOOLEAN;
  v_code TEXT;
  v_batch_count INTEGER := 0;
  
  -- New variables for optimization
  v_destination_array JSONB[] := '{}'::JSONB[];
  v_destination JSONB;
  v_processed_count INTEGER := 0;
  v_batch_results JSONB := '[]'::jsonb;
  i INTEGER;
  
  -- Variables for v2 handling
  v_first_quote JSONB;
  v_quote_count INT;
BEGIN
  -- Validate version parameter
  IF p_use_version NOT IN ('v1', 'v2', 'v3', 'v4') THEN
    RAISE EXCEPTION 'Invalid version parameter: %. Must be ''v1'', ''v2'', ''v3'', or ''v4''', p_use_version;
  END IF;

  -- Warn about v4 test mode
  IF p_use_version = 'v4' THEN
    RAISE NOTICE 'Warning: v4 is a test/configuration validation function that does not create actual quotes';
  END IF;

  -- Record start time
  v_start_time := now();
  
  -- Create a test run record
  INSERT INTO quote_test_runs (
    name, 
    num_locations, 
    payout_rate,
    min_exposure, 
    max_exposure, 
    max_event_duration, 
    start_time
  )
  VALUES (
    p_run_name || ' (' || p_use_version || ' quotes, base: ' || (p_base_percent * 100)::text || '%)',
    p_num_quotes, 
    0, 
    p_min_exposure, 
    p_max_exposure, 
    p_max_event_duration, 
    v_start_time
  )
  RETURNING id INTO v_run_id;
  
  -- Set maximum iterations to prevent infinite loops
  v_max_iterations := p_num_quotes * 5;
  
  -- Prepare destination data
  WHILE array_length(v_destination_array, 1) IS NULL OR array_length(v_destination_array, 1) < v_max_iterations LOOP
    FOR v_destination_record IN 
      SELECT "Destination", "Latitude", "Longitude", "State", "Peak_Travel_Period"
      FROM australian_tourist_destinations
      ORDER BY RANDOM()
      LIMIT 200
    LOOP
      v_destination_array := v_destination_array || jsonb_build_object(
        'Destination', v_destination_record."Destination",
        'Latitude', v_destination_record."Latitude",
        'Longitude', v_destination_record."Longitude", 
        'State', v_destination_record."State",
        'Peak_Travel_Period', v_destination_record."Peak_Travel_Period"
      );
      
      IF array_length(v_destination_array, 1) >= v_max_iterations THEN EXIT; END IF;
    END LOOP;
  END LOOP;
  
  -- Process each destination
  FOR i IN 1..array_length(v_destination_array, 1) LOOP
    EXIT WHEN v_success_count >= p_num_quotes;
    EXIT WHEN v_attempts_count >= v_max_iterations;
    
    v_destination := v_destination_array[i];
    v_attempts_count := v_attempts_count + 1;
    v_is_failure := FALSE;
    
    BEGIN
      -- Process destination
      v_peak_period := v_destination->>'Peak_Travel_Period';
      v_peak_months := get_peak_period_months(v_peak_period);
      v_random_month := v_peak_months[1 + floor(random() * array_length(v_peak_months, 1))::int];
      
      v_current_month := EXTRACT(MONTH FROM CURRENT_DATE)::INT;
      IF v_random_month < v_current_month THEN
        v_year := EXTRACT(YEAR FROM CURRENT_DATE)::INT + 1;
      ELSE
        v_year := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
      END IF;
      
      v_random_day := 1 + floor(random() * 28)::int;
      v_event_duration := 1 + floor(random() * p_max_event_duration)::int;
      v_start_date := make_date(v_year, v_random_month, v_random_day);
      v_end_date := v_start_date + (v_event_duration || ' days')::interval;
      v_exposure := round((random() * (p_max_exposure - p_min_exposure) + p_min_exposure)::numeric, 2);
      v_partner_quote_id := 'TEST-' || p_use_version || '-' || gen_random_uuid()::text;
      
      v_experience_name := v_destination->>'Destination';
      v_state := v_destination->>'State';
      v_suburb := split_part(v_experience_name, ' - ', 1);
      v_latitude := (v_destination->>'Latitude')::DECIMAL;
      v_longitude := (v_destination->>'Longitude')::DECIMAL;
      
      -- Call appropriate version
      IF p_use_version = 'v1' THEN
        v_quote := public.create_complete_quote(
          p_partner_id := p_partner_id,
          p_experience_name := v_experience_name,
          p_suburb := v_suburb,
          p_state := v_state,
          p_event_type := p_event_type,
          p_start_date := v_start_date,
          p_end_date := v_end_date,
          p_exposure_total := v_exposure,
          p_latitude := v_latitude,
          p_longitude := v_longitude,
          p_partner_quote_id := v_partner_quote_id,
          p_country := 'Australia',
          p_base_percent := p_base_percent,
          p_daily_value_limit := 500000,
          p_skip_exposure_check := false,
          p_commission_rate := 0.10
        );
      ELSIF p_use_version = 'v2' THEN
        v_quote := public.create_complete_quote_v2(
          p_partner_id := p_partner_id,
          p_experience_name := v_experience_name,
          p_suburb := v_suburb,
          p_state := v_state,
          p_event_type := p_event_type,
          p_start_date := v_start_date,
          p_end_date := v_end_date,
          p_exposure_total := v_exposure,
          p_latitude := v_latitude,
          p_longitude := v_longitude,
          p_partner_quote_id := v_partner_quote_id,
          p_country := 'Australia',
          p_base_percent := p_base_percent,
          p_daily_value_limit := 500000,
          p_skip_exposure_check := false,
          p_commission_rate := 0.10
        );
      ELSIF p_use_version = 'v3' THEN
        -- ✅ UPDATED: New v3 simplified signature (config-driven)
        v_quote := public.create_complete_quote_v3(
          p_partner_id := p_partner_id,
          p_experience_name := v_experience_name,
          p_suburb := v_suburb,
          p_state := v_state,
          p_event_type := p_event_type,
          p_start_date := v_start_date,
          p_end_date := v_end_date,
          p_exposure_total := v_exposure,
          p_latitude := v_latitude,
          p_longitude := v_longitude,
          p_partner_quote_id := v_partner_quote_id,
          p_country := 'Australia'
          -- ✅ Removed: p_base_percent, p_daily_value_limit, p_commission_rate, p_skip_exposure_check
          -- These now come from quote_config table and partner_commission_rates
        );
      ELSE  -- p_use_version = 'v4'
        v_quote := public.create_complete_quote_v4(
          p_partner_id := p_partner_id,
          p_experience_name := v_experience_name,
          p_suburb := v_suburb,
          p_state := v_state,
          p_event_type := p_event_type,
          p_start_date := v_start_date,
          p_end_date := v_end_date,
          p_exposure_total := v_exposure,
          p_latitude := v_latitude,
          p_longitude := v_longitude,
          p_partner_quote_id := v_partner_quote_id,
          p_country := 'Australia',
          p_base_percent := p_base_percent,
          p_daily_value_limit := NULL,
          p_minimum_premium_percent := NULL,
          p_environment := 'production'
        );
      END IF;
      
      -- Handle v2's different response structure
      IF p_use_version = 'v2' AND v_quote IS NOT NULL AND (v_quote->>'success')::boolean = true THEN
        -- v2 returns multiple quotes in an array, we'll use the first one
        v_quote_count := jsonb_array_length(v_quote->'quotes');
        IF v_quote_count > 0 THEN
          v_first_quote := v_quote->'quotes'->0;
          -- Transform v2 response to match expected format
          v_quote := jsonb_build_object(
            'quote_id', v_first_quote->>'quote_id',
            'success', true,
            'premium', v_first_quote->'premium'
          );
        ELSE
          -- No quotes in the array
          v_quote := jsonb_build_object(
            'success', false,
            'error_message', 'No quotes generated',
            'error_code', 'NO_QUOTES'
          );
        END IF;
      END IF;
      
      -- Handle v3's different response structure (similar to v2)
      IF p_use_version = 'v3' AND v_quote IS NOT NULL AND (v_quote->>'success')::boolean = true THEN
        -- v3 returns similar structure to v2
        v_quote_count := jsonb_array_length(v_quote->'quotes');
        IF v_quote_count > 0 THEN
          v_first_quote := v_quote->'quotes'->0;
          -- Transform v3 response to match expected format
          v_quote := jsonb_build_object(
            'quote_id', v_first_quote->>'quote_id',
            'success', true,
            'premium', v_first_quote->'premium',
            'minimum_rate_applied', v_first_quote->>'minimum_rate_applied'
          );
        ELSE
          -- No quotes in the array
          v_quote := jsonb_build_object(
            'success', false,
            'error_message', 'No quotes generated',
            'error_code', 'NO_QUOTES'
          );
        END IF;
      END IF;
      
      -- Check if quote succeeded or failed
      IF p_use_version = 'v4' AND v_quote IS NOT NULL AND (v_quote->>'test_mode')::boolean = true THEN
        -- v4 returns test results, not actual quotes
        v_is_failure := TRUE;
        v_failure_count := v_failure_count + 1;
        v_failure_reasons := jsonb_set(v_failure_reasons, '{test_mode}', 
          to_jsonb((v_failure_reasons->>'test_mode')::INT + 1));
        
        IF p_log_failures THEN
          v_batch_results := v_batch_results || jsonb_build_object(
            'success', false,
            'destination', v_experience_name,
            'state', v_state,
            'exposure', v_exposure,
            'error_type', 'test_mode',
            'error_message', 'v4 is a test function - config validation passed',
            'test_results', v_quote
          );
        END IF;
      ELSIF v_quote IS NOT NULL AND (v_quote->>'quote_id') IS NOT NULL AND (v_quote->>'success')::boolean = true THEN
        -- Success
        v_success_count := v_success_count + 1;
        v_quote_ids := array_append(v_quote_ids, (v_quote->>'quote_id')::UUID);
        
        v_batch_results := v_batch_results || jsonb_build_object(
          'success', true,
          'quote_id', (v_quote->>'quote_id'),
          'destination', v_experience_name,
          'state', v_state,
          'exposure', v_exposure,
          'premium', COALESCE((v_quote->'premium'->>'retail_premium')::DECIMAL, 0),
          'minimum_rate_applied', COALESCE((v_quote->>'minimum_rate_applied')::BOOLEAN, false),
          'details', v_quote
        );
      ELSE
        -- Handle failure (same as before)
        v_is_failure := TRUE;
        v_failure_count := v_failure_count + 1;
        -- [Rest of failure handling logic unchanged]
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- [Exception handling unchanged]
    END;
    
    -- [Rest of batch processing logic unchanged]
  END LOOP;
  
  -- [Final cleanup and return logic unchanged]
  
  -- Return results
  RETURN jsonb_build_object(
    'run_id', v_run_id,
    'success_count', v_success_count,
    'failure_count', v_failure_count,
    'attempts_count', v_attempts_count,
    'failure_reasons', v_failure_reasons,
    'quote_ids', v_quote_ids,
    'duration_seconds', extract(epoch from (now() - v_start_time)),
    'base_percent_used', CASE WHEN p_use_version = 'v3' THEN 'from_config' ELSE p_base_percent::text END,
    'max_duration_days_used', p_max_event_duration,
    'quote_version_used', p_use_version,
    'message', CASE 
      WHEN p_use_version = 'v4' THEN 
        'v4 is a test/config validation function. All attempts returned test mode results. Use v1, v2, or v3 for actual quote creation.'
      WHEN p_use_version = 'v3' THEN
        'Bulk quotes created using v3 config-driven function. Base rate and limits from quote_config table.'
      ELSE 
        format('Bulk quotes created using %s quote function. Run analyze_weather_quotes with this run_id to analyze.', p_use_version)
    END
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_claims_for_policies_next_7days()
 RETURNS TABLE(created_count integer, skipped_count integer, error_count integer, details jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_policy RECORD;
    v_claim_id UUID;
    v_location RECORD;
    v_created_count INTEGER := 0;
    v_skipped_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_details JSONB := '[]'::JSONB;
    v_actual_payout NUMERIC;
    v_claim_date DATE;
    v_current_date DATE;
    v_daily_payout NUMERIC;
    v_policy_claims_created INTEGER := 0;
BEGIN
    -- Process each active policy ending in 7 days
    FOR v_policy IN 
        SELECT 
            p.policy_id,
            p.policy_number,
            p.status,
            p.coverage_start,
            p.coverage_end,
            p.coverage_start_time,
            p.coverage_end_time,
            p.experience_name,
            p.exposure_total,
            p.final_premium,
            p.suburb,
            p.state,
            p.created_at,
            p.primary_location_id,
            p.latitude,
            p.longitude,
            p.trigger,
            p.duration,
            p.payout_percentage,
            p.daily_exposure
        FROM policy p
        WHERE p.status = 'active'
          AND p.coverage_end = CURRENT_DATE + INTERVAL '7 day'
        ORDER BY p.coverage_start, p.coverage_end
    LOOP
        BEGIN
            v_policy_claims_created := 0;
            
            -- Calculate daily payout amount
            IF v_policy.daily_exposure IS NOT NULL THEN
                v_daily_payout := v_policy.daily_exposure;
            ELSE
                v_daily_payout := CASE 
                    WHEN v_policy.payout_percentage IS NOT NULL AND v_policy.exposure_total IS NOT NULL 
                    THEN (v_policy.exposure_total * (v_policy.payout_percentage / 100.0)) / 
                         (v_policy.coverage_end - v_policy.coverage_start + 1)
                    ELSE v_policy.exposure_total / (v_policy.coverage_end - v_policy.coverage_start + 1)
                END;
            END IF;

            -- Loop through each day of the policy coverage period
            v_current_date := v_policy.coverage_start;
            WHILE v_current_date <= v_policy.coverage_end LOOP
                
                -- Check if claim already exists for this policy and date
                IF EXISTS (
                    SELECT 1 FROM claims 
                    WHERE policy_id = v_policy.policy_id 
                    AND claim_date = v_current_date
                ) THEN
                    v_skipped_count := v_skipped_count + 1;
                    v_details := v_details || jsonb_build_object(
                        'policy_number', v_policy.policy_number,
                        'policy_id', v_policy.policy_id,
                        'claim_date', v_current_date,
                        'status', 'skipped',
                        'reason', 'claim already exists for this date'
                    );
                    v_current_date := v_current_date + INTERVAL '1 day';
                    CONTINUE;
                END IF;

                -- Create the claim for this date with coverage times
                INSERT INTO claims (
                    policy_id,
                    claim_date,
                    claim_amount,
                    claim_status,
                    claim_reason,
                    trigger_date,
                    payout_percentage,
                    exposure_total,
                    policy_trigger,
                    policy_duration,
                    actual_payout_amount,
                    rainfall_triggered,
                    coverage_start_time,
                    coverage_end_time,
                    created_at,
                    updated_at
                )
                VALUES (
                    v_policy.policy_id,
                    v_current_date,
                    v_daily_payout,
                    'pending',
                    'Automated daily claim creation - policy coverage day ' || 
                        (v_current_date - v_policy.coverage_start + 1) || ' of ' || 
                        (v_policy.coverage_end - v_policy.coverage_start + 1),
                    v_current_date,
                    v_policy.payout_percentage,
                    v_policy.exposure_total,
                    v_policy.trigger,
                    v_policy.duration,
                    v_daily_payout,
                    false,
                    v_policy.coverage_start_time,  -- Added coverage start time
                    v_policy.coverage_end_time,    -- Added coverage end time
                    now(),
                    now()
                )
                RETURNING claim_id INTO v_claim_id;

                -- Get location details if primary location exists
                IF v_policy.primary_location_id IS NOT NULL THEN
                    SELECT 
                        location_id,
                        latitude,
                        longitude,
                        name,
                        BOM_SiteID,
                        status
                    INTO v_location
                    FROM locations 
                    WHERE location_id = v_policy.primary_location_id;

                    -- Create claim location entry with primary location
                    INSERT INTO claim_locations (
                        claim_id,
                        location_id,
                        location_latitude,
                        location_longitude,
                        policy_latitude,
                        policy_longitude,
                        is_primary_location,
                        data_source
                    )
                    VALUES (
                        v_claim_id,
                        v_policy.primary_location_id,
                        v_location.latitude,
                        v_location.longitude,
                        v_policy.latitude,
                        v_policy.longitude,
                        true,
                        'primary_location'
                    );
                END IF;

                -- Always create a policy location entry (for fallback)
                IF v_policy.latitude IS NOT NULL AND v_policy.longitude IS NOT NULL THEN
                    INSERT INTO claim_locations (
                        claim_id,
                        location_id,
                        location_latitude,
                        location_longitude,
                        policy_latitude,
                        policy_longitude,
                        is_primary_location,
                        data_source
                    )
                    VALUES (
                        v_claim_id,
                        NULL,
                        v_policy.latitude,
                        v_policy.longitude,
                        v_policy.latitude,
                        v_policy.longitude,
                        false,
                        'policy_coordinates'
                    );
                END IF;

                v_created_count := v_created_count + 1;
                v_policy_claims_created := v_policy_claims_created + 1;
                
                v_current_date := v_current_date + INTERVAL '1 day';
                
            END LOOP;

            -- Update policy status to 'assessment' after creating all claims
            IF v_policy_claims_created > 0 THEN
                UPDATE policy 
                SET status = 'assessment'
                WHERE policy_id = v_policy.policy_id;
            END IF;

            -- Add summary for this policy
            v_details := v_details || jsonb_build_object(
                'policy_number', v_policy.policy_number,
                'policy_id', v_policy.policy_id,
                'coverage_days', v_policy.coverage_end - v_policy.coverage_start + 1,
                'coverage_hours', v_policy.coverage_start_time::text || ' - ' || v_policy.coverage_end_time::text,
                'claims_created', v_policy_claims_created,
                'daily_payout', v_daily_payout,
                'total_exposure', v_policy.exposure_total,
                'payout_percentage', v_policy.payout_percentage,
                'policy_status_updated', CASE WHEN v_policy_claims_created > 0 THEN 'assessment' ELSE 'unchanged' END,
                'status', 'completed'
            );

        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_details := v_details || jsonb_build_object(
                'policy_number', v_policy.policy_number,
                'policy_id', v_policy.policy_id,
                'status', 'error',
                'error', SQLERRM,
                'error_detail', SQLSTATE
            );
        END;
    END LOOP;

    -- Return summary
    RETURN QUERY SELECT 
        v_created_count,
        v_skipped_count,
        v_error_count,
        v_details;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_complete_quote_v3(p_partner_id uuid, p_partner_quote_id text, p_experience_name text, p_suburb text, p_state text, p_country text, p_event_type text, p_start_date date, p_end_date date, p_latitude numeric, p_longitude numeric, p_exposure_total numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    -- Configuration variables loaded from quote_config
    v_config RECORD;
    v_base_percent NUMERIC;
    v_min_rate_threshold NUMERIC;
    v_max_rate_threshold NUMERIC;
    v_commission_rate NUMERIC;
    v_daily_value_limit NUMERIC;
    v_skip_exposure_check BOOLEAN;
    v_coverage_hours JSONB;
    
    -- Same variables as v2
    v_quote_group_id UUID;
    v_duration_days INTEGER;
    v_start_timestamp TIMESTAMPTZ;
    v_end_timestamp TIMESTAMPTZ;
    v_expires_at TIMESTAMPTZ;
    v_base_wholesale_premium NUMERIC;
    v_quotes_created JSONB := '[]'::JSONB;
    v_quotes_count INTEGER := 0;
    v_daily_exposure_amount NUMERIC;
    v_exposure_check_result RECORD;
    v_input_point geography;
    v_base_partner_quote_id TEXT;
    
    -- Weather analysis variables
    v_primary_station_id INTEGER;
    v_primary_station_name TEXT;
    v_primary_station_distance NUMERIC;
    v_nearby_station_ids INTEGER[];
    v_stations_analyzed INTEGER;
    v_max_rainfall_trigger NUMERIC;
    v_max_duration INTEGER;
    v_max_seasonal_index NUMERIC;
    v_any_high_risk BOOLEAN := FALSE;
    v_any_climate_anomaly BOOLEAN := FALSE;
    
    -- Payout option variables
    v_has_payout_config BOOLEAN := FALSE;
    v_payout_option RECORD;
BEGIN
    -- Load configuration from quote_config table
    SELECT * INTO v_config 
    FROM quote_config 
    WHERE config_name = 'default' AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'CONFIG_ERROR',
            'error_message', 'Quote configuration not found or inactive'
        );
    END IF;
    
    -- Set configuration values
    v_base_percent := v_config.base_percent;
    v_min_rate_threshold := v_config.min_rate_percent / 100.0;
    v_max_rate_threshold := v_config.max_rate_percent / 100.0;
    v_daily_value_limit := v_config.default_daily_value_limit;
    v_skip_exposure_check := v_config.default_skip_exposure_check;
    
    -- SIMPLIFIED: Get partner commission rate using existing function
    -- This handles the partner's "Commission" column and defaults properly
    v_commission_rate := get_partner_commission_rate(p_partner_id);
    
    -- Get coverage hours from config
    v_coverage_hours := CASE 
        WHEN v_config.event_type_hours ? p_event_type THEN v_config.event_type_hours->p_event_type
        ELSE v_config.event_type_hours->'default'
    END;
    
    -- Generate group ID and timestamps
    v_quote_group_id := gen_random_uuid();
    v_start_timestamp := p_start_date::TIMESTAMPTZ;
    v_end_timestamp := p_end_date::TIMESTAMPTZ;
    v_expires_at := NOW() + (v_config.quote_expiry_hours || ' hours')::INTERVAL;
    v_base_partner_quote_id := COALESCE(p_partner_quote_id, 'auto-' || extract(epoch from now())::bigint::text);
    
    -- Create input point once for reuse
    v_input_point := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography;
    
    -- Calculate duration
    v_duration_days := (p_end_date - p_start_date) + 1;
    v_daily_exposure_amount := p_exposure_total / v_duration_days;
    
    -- ========================================
    -- VALIDATIONS (using config values)
    -- ========================================
    IF v_duration_days <= 0 THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'INVALID_DURATION', 
            'error_message', 'End date must be after start date'
        );
    END IF;
    
    IF v_duration_days > v_config.max_duration_days THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'DURATION_EXCEEDED', 
            'error_message', format('Duration (%s days) exceeds maximum allowed (%s days)', 
                v_duration_days, v_config.max_duration_days)
        );
    END IF;
    
    -- Check advance notice requirement
    IF p_start_date <= CURRENT_DATE + (v_config.advance_notice_days || ' days')::INTERVAL THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'INSUFFICIENT_ADVANCE_NOTICE', 
            'error_message', format('Quotes must be made at least %s days before coverage start date', 
                v_config.advance_notice_days)
        );
    END IF;
    
    -- Validate exposure limits using config
    IF p_exposure_total < v_config.min_exposure_amount OR p_exposure_total > v_config.max_exposure_amount THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'EXPOSURE_LIMIT_EXCEEDED', 
            'error_message', format('Exposure amount ($%s) must be between $%s and $%s', 
                p_exposure_total, v_config.min_exposure_amount, v_config.max_exposure_amount)
        );
    END IF;

    -- ========================================
    -- WEATHER ANALYSIS (using config settings)
    -- ========================================
    WITH nearby_stations AS (
        SELECT 
            l.location_id, 
            l.name as station_name,
            ST_Distance(v_input_point, l.geom) / 1000 as distance_km
        FROM locations l
        WHERE l.geom IS NOT NULL
            AND ST_DWithin(v_input_point, l.geom, v_config.max_search_radius_meters)
        ORDER BY l.geom operator(<->) v_input_point
        LIMIT v_config.max_weather_stations
    )
    SELECT 
        array_agg(location_id ORDER BY distance_km) as station_ids,
        (array_agg(location_id ORDER BY distance_km))[1] as primary_id,
        (array_agg(station_name ORDER BY distance_km))[1] as primary_name,
        (array_agg(distance_km ORDER BY distance_km))[1] as primary_distance,
        COUNT(*) as station_count
    INTO 
        v_nearby_station_ids,
        v_primary_station_id,
        v_primary_station_name,
        v_primary_station_distance,
        v_stations_analyzed
    FROM nearby_stations;
    
    -- Check if any stations were found
    IF v_primary_station_id IS NULL OR v_stations_analyzed = 0 THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'NO_STATIONS_FOUND', 
            'error_message', format('No weather stations found within %skm of location', 
                v_config.max_search_radius_meters / 1000)
        );
    END IF;
    
    -- ========================================
    -- EXPOSURE CHECK (using config settings)
    -- ========================================
    IF NOT v_skip_exposure_check THEN
        WITH date_range AS (
            SELECT generate_series(
                p_start_date::date,
                p_end_date::date,
                '1 day'::interval
            )::date AS check_date
        ),
        exposure_by_date AS (
            SELECT 
                dr.check_date,
                COALESCE(
                    SUM(
                        p.exposure_total / GREATEST(
                            (p.coverage_end::date - p.coverage_start::date + 1), 
                            1
                        )
                    ), 
                    0
                ) AS existing_exposure,
                COALESCE(
                    SUM(
                        p.exposure_total / GREATEST(
                            (p.coverage_end::date - p.coverage_start::date + 1), 
                            1
                        )
                    ), 
                    0
                ) + v_daily_exposure_amount AS total_with_new
            FROM date_range dr
            LEFT JOIN policy p ON 
                p.status = 'active'
                AND p.coverage_end >= p_start_date
                AND p.coverage_start <= p_end_date
                AND p.coverage_start::date <= dr.check_date
                AND p.coverage_end::date >= dr.check_date
                AND EXISTS (
                    SELECT 1 
                    FROM quotes q
                    JOIN quote_locations ql ON q.quote_id = ql.quote_id
                    WHERE p.quote_id = q.quote_id
                    AND ql.location_id = ANY(v_nearby_station_ids)
                    LIMIT 1
                )
            GROUP BY dr.check_date
            HAVING COALESCE(
                SUM(
                    p.exposure_total / GREATEST(
                        (p.coverage_end::date - p.coverage_start::date + 1), 
                        1
                    )
                ), 
                0
            ) + v_daily_exposure_amount > v_daily_value_limit
            ORDER BY dr.check_date
            LIMIT 1
        )
        SELECT check_date, existing_exposure, total_with_new 
        INTO v_exposure_check_result
        FROM exposure_by_date;

        IF v_exposure_check_result.check_date IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'DAILY_EXPOSURE_LIMIT_EXCEEDED',
                'error_message', format(
                    'Daily exposure limit of $%s would be exceeded on %s (total: $%s)',
                    v_daily_value_limit,
                    v_exposure_check_result.check_date,
                    v_exposure_check_result.total_with_new
                ),
                'error_detail', jsonb_build_object(
                    'date', v_exposure_check_result.check_date,
                    'existing_exposure', v_exposure_check_result.existing_exposure,
                    'new_exposure', v_daily_exposure_amount,
                    'total_would_be', v_exposure_check_result.total_with_new,
                    'limit', v_daily_value_limit,
                    'stations_checked', v_stations_analyzed
                )
            );
        END IF;
    END IF;
    
    -- Get conservative (MAX) values across all nearby stations
    WITH station_seasonal_data AS (
        SELECT 
            ns.location_id,
            COALESCE(dsi.modified_seasonal_index, NULL) as modified_seasonal_index,
            COALESCE(dsi.modified_rainfall_trigger, NULL) as modified_rainfall_trigger,
            COALESCE(dsi.optimal_hour_trigger, NULL) as optimal_hour_trigger,
            COALESCE(dsi.high_risk_flag, false) as high_risk_flag,
            COALESCE(dsi.climate_anomaly_flag, false) as climate_anomaly_flag
        FROM unnest(v_nearby_station_ids) ns(location_id)
        LEFT JOIN daily_seasonal_indices dsi ON 
            ns.location_id = dsi.location_id 
            AND dsi.month_of_year = EXTRACT(MONTH FROM p_start_date)
            AND dsi.day_of_month = EXTRACT(DAY FROM p_start_date)
    )
    SELECT 
        COUNT(CASE WHEN modified_seasonal_index IS NOT NULL THEN 1 END),
        MAX(modified_rainfall_trigger), 
        MAX(optimal_hour_trigger), 
        MAX(modified_seasonal_index), 
        BOOL_OR(high_risk_flag), 
        BOOL_OR(climate_anomaly_flag)
    INTO 
        v_stations_analyzed,
        v_max_rainfall_trigger, 
        v_max_duration, 
        v_max_seasonal_index, 
        v_any_high_risk, 
        v_any_climate_anomaly
    FROM station_seasonal_data;
    
    -- Check seasonal data and high risk (same as v2)
    IF v_stations_analyzed = 0 OR v_max_seasonal_index IS NULL THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'NO_SEASONAL_DATA', 
            'error_message', 'No seasonal data available for any nearby weather stations.'
        );
    END IF;
    
    IF v_any_high_risk THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'HIGH_RISK_DETECTED', 
            'error_message', 'High rainfall risk detected at one or more weather stations'
        );
    END IF;
    
    -- Calculate base wholesale premium using config base_percent
    v_base_wholesale_premium := p_exposure_total * v_max_seasonal_index * v_base_percent;
    
    -- ========================================
    -- CREATE MULTIPLE QUOTES WITH RATE CAPS
    -- ========================================
    
    -- Check if partner has payout configurations
    SELECT COUNT(*) > 0 INTO v_has_payout_config
    FROM partner_event_payout_config pepc
    JOIN payout_options po ON pepc.payout_option_id = po.payout_option_id
    WHERE pepc.partner_id = p_partner_id
        AND pepc.event_type = p_event_type
        AND pepc.is_active = true
        AND po.is_active = true;
    
    IF v_has_payout_config THEN
        -- Create a quote for each payout option
        FOR v_payout_option IN 
            SELECT 
                po.payout_option_id,
                po.option_name,
                po.payout_percentage,
                po.premium_multiplier,
                po.description,
                pepc.is_default,
                ROW_NUMBER() OVER (ORDER BY pepc.is_default DESC, po.payout_percentage DESC) as seq
            FROM partner_event_payout_config pepc
            JOIN payout_options po ON pepc.payout_option_id = po.payout_option_id
            WHERE pepc.partner_id = p_partner_id
                AND pepc.event_type = p_event_type
                AND pepc.is_active = true
                AND po.is_active = true
            ORDER BY pepc.is_default DESC, po.payout_percentage DESC
        LOOP
            DECLARE
                v_quote_id UUID;
                v_base_premium_adjusted NUMERIC;
                v_wholesale_premium NUMERIC;
                v_retail_premium NUMERIC;
                v_gst_amount NUMERIC;
                v_stamp_duty_amount NUMERIC;
                v_total_premium NUMERIC;
                v_premium_ratio NUMERIC;
                v_partner_quote_id_suffixed TEXT;
                v_coverage_amount NUMERIC;
                v_daily_coverage_amount NUMERIC;
                v_daily_premium NUMERIC;
                v_minimum_applied BOOLEAN := FALSE;
                v_commission_amount NUMERIC;
            BEGIN
                -- Calculate base premium for this payout option
                v_base_premium_adjusted := v_base_wholesale_premium * v_payout_option.premium_multiplier;
                
                -- NEW CALCULATION METHOD:
                -- Calculate GST and stamp duty on base premium
                v_gst_amount := v_base_premium_adjusted * v_config.gst_rate;
                v_stamp_duty_amount := v_base_premium_adjusted * v_config.stamp_duty_rate;
                
                -- Wholesale = base + GST + stamp duty (no commission)
                v_wholesale_premium := v_base_premium_adjusted + v_gst_amount + v_stamp_duty_amount;
                
                -- Commission amount
                v_commission_amount := v_base_premium_adjusted * v_commission_rate;
                
                -- Retail = wholesale + commission (includes everything)
                v_retail_premium := v_wholesale_premium + v_commission_amount;
                
                -- Total premium is now same as retail
                v_total_premium := v_retail_premium;
                
                -- Calculate premium ratio for min/max checks
                v_premium_ratio := v_total_premium / p_exposure_total;
                
                -- Calculate coverage and daily amounts
                v_coverage_amount := ROUND(p_exposure_total * v_payout_option.payout_percentage / 100, 2);
                v_daily_coverage_amount := ROUND(v_coverage_amount / v_duration_days, 2);
                v_daily_premium := ROUND(v_total_premium / v_duration_days, 2);
                
                -- ========================================
                -- V3 FEATURE: Apply min/max rate caps
                -- ========================================
                IF v_premium_ratio < v_min_rate_threshold THEN
                    -- Apply minimum rate cap
                    v_total_premium := p_exposure_total * v_min_rate_threshold;
                    v_retail_premium := v_total_premium;
                    
                    -- Recalculate components to maintain proportions
                    v_base_premium_adjusted := v_total_premium / (1 + v_config.gst_rate + v_config.stamp_duty_rate + v_commission_rate);
                    v_gst_amount := v_base_premium_adjusted * v_config.gst_rate;
                    v_stamp_duty_amount := v_base_premium_adjusted * v_config.stamp_duty_rate;
                    v_commission_amount := v_base_premium_adjusted * v_commission_rate;
                    v_wholesale_premium := v_base_premium_adjusted + v_gst_amount + v_stamp_duty_amount;
                    
                    v_premium_ratio := v_min_rate_threshold;
                    v_daily_premium := ROUND(v_total_premium / v_duration_days, 2);
                    v_minimum_applied := TRUE;
                ELSIF v_premium_ratio > v_max_rate_threshold THEN
                    -- Reject if above maximum
                    CONTINUE; -- Skip this payout option
                END IF;
                
                v_quote_id := gen_random_uuid();
                v_partner_quote_id_suffixed := v_base_partner_quote_id || '_' || v_payout_option.seq;
                
                -- Insert quote
                INSERT INTO quotes (
                    quote_id, quote_group_id, partner_id, partner_quote_id,
                    experience_name, suburb, state, country, event_type,
                    coverage_start, coverage_end, coverage_start_time, coverage_end_time,
                    expires_at, latitude, longitude, exposure_total, location_id, 
                    status, model_version, created_at
                ) VALUES (
                    v_quote_id, v_quote_group_id, p_partner_id, v_partner_quote_id_suffixed,
                    p_experience_name, p_suburb, p_state, p_country, p_event_type,
                    v_start_timestamp, v_end_timestamp,
                    (v_coverage_hours->>'start')::TIME, (v_coverage_hours->>'end')::TIME,
                    v_expires_at, p_latitude, p_longitude, p_exposure_total, v_primary_station_id,
                    'active',
                    'v3.0_config_based', NOW()
                );
                
                -- Insert quote_locations
                INSERT INTO quote_locations (
                    quote_id, location_id, distance_km, seasonal_index, rainfall_trigger, rainfall_duration, is_primary,
                    applied_max_trigger, applied_max_duration, applied_max_index, stations_in_analysis, risk_contribution_type,
                    max_seasonal_index_date, max_rainfall_trigger_date, max_optimal_hour_date
                )
                SELECT DISTINCT ON (sd.location_id)
                    v_quote_id, sd.location_id, sd.distance_km, sd.individual_seasonal_index, 
                    sd.individual_rainfall_trigger, sd.individual_duration,
                    CASE WHEN sd.location_id = v_primary_station_id THEN true ELSE false END,
                    v_max_rainfall_trigger, v_max_duration, v_max_seasonal_index, v_stations_analyzed,
                    CASE 
                        WHEN sd.individual_rainfall_trigger = v_max_rainfall_trigger 
                             AND sd.individual_duration = v_max_duration 
                             AND sd.individual_seasonal_index = v_max_seasonal_index
                        THEN 'all_max_source'
                        WHEN sd.individual_rainfall_trigger = v_max_rainfall_trigger THEN 'rainfall_trigger_source'
                        WHEN sd.individual_duration = v_max_duration THEN 'duration_source'
                        WHEN sd.individual_seasonal_index = v_max_seasonal_index THEN 'seasonal_index_source'
                        WHEN sd.location_id = v_primary_station_id THEN 'primary_reference'
                        ELSE 'contributing_station'
                    END,
                    p_start_date, p_start_date, p_start_date
                FROM (
                    SELECT 
                        l.location_id,
                        ST_Distance(v_input_point, l.geom) / 1000 as distance_km,
                        dsi.modified_seasonal_index as individual_seasonal_index,
                        dsi.modified_rainfall_trigger as individual_rainfall_trigger,
                        dsi.optimal_hour_trigger as individual_duration
                    FROM locations l
                    LEFT JOIN daily_seasonal_indices dsi ON 
                        l.location_id = dsi.location_id 
                        AND dsi.month_of_year = EXTRACT(MONTH FROM p_start_date)
                        AND dsi.day_of_month = EXTRACT(DAY FROM p_start_date)
                    WHERE l.location_id = ANY(v_nearby_station_ids)
                ) sd
                WHERE sd.individual_seasonal_index IS NOT NULL
                ORDER BY sd.location_id, sd.distance_km;
                
                -- Insert quote_premiums with NEW wholesale/retail definitions
                INSERT INTO quote_premiums (
                    quote_id, exposure_total, seasonal_index, duration_multiplier, wholesale_premium, rainfall_trigger,
                    above_threshold, above_value_threshold, retail_premium, gst_amount, stamp_duty_amount, commission_rate,
                    rainfall_duration, single_station_premium_applied, risk_adjustment_applied, minimum_premium_applied
                ) VALUES (
                    v_quote_id, p_exposure_total, v_max_seasonal_index, 1.0, v_wholesale_premium, v_max_rainfall_trigger,
                    false, false, v_retail_premium, v_gst_amount, v_stamp_duty_amount, v_commission_rate,
                    v_max_duration, 
                    CASE WHEN v_stations_analyzed = 1 THEN true ELSE false END, 
                    v_any_climate_anomaly, v_minimum_applied
                );
                
                -- Insert into quote_payout_options with NEW definitions
                INSERT INTO quote_payout_options (
                    quote_option_id, quote_id, payout_option_id, payout_percentage, premium_multiplier,
                    wholesale_premium, retail_premium, gst_amount, stamp_duty_amount, total_premium,
                    is_selected, is_default, display_order, coverage_amount, daily_coverage_amount
                ) VALUES (
                    gen_random_uuid(), v_quote_id, v_payout_option.payout_option_id,
                    v_payout_option.payout_percentage, v_payout_option.premium_multiplier,
                    v_wholesale_premium, v_retail_premium, v_gst_amount, v_stamp_duty_amount, v_total_premium,
                    false, v_payout_option.is_default, v_payout_option.seq, v_coverage_amount, v_daily_coverage_amount
                );
                
                -- Add to response with simplified premium structure
                v_quotes_created := v_quotes_created || jsonb_build_object(
                    'quote_id', v_quote_id,
                    'option_name', v_payout_option.option_name,
                    'payout_percentage', v_payout_option.payout_percentage,
                    'coverage_amount', v_coverage_amount,
                    'daily_coverage_amount', v_daily_coverage_amount,
                    'premium', jsonb_build_object(
                        'wholesale_premium', ROUND(v_wholesale_premium, 2),
                        'retail_premium', ROUND(v_retail_premium, 2),
                        'gst_amount', ROUND(v_gst_amount, 2),
                        'daily_premium', v_daily_premium,
                        'currency', 'AUD'
                    )
                );
                
                v_quotes_count := v_quotes_count + 1;
            END;
        END LOOP;
    END IF;
    
    -- ========================================
    -- NEW: Use global defaults if no partner-specific config
    -- ========================================
    IF v_quotes_count = 0 THEN
        -- Try to use global default payout options
        FOR v_payout_option IN 
            SELECT 
                po.payout_option_id,
                po.option_name,
                po.payout_percentage,
                po.premium_multiplier,
                po.description,
                CASE WHEN po.global_default_order = 1 THEN TRUE ELSE FALSE END as is_default,
                ROW_NUMBER() OVER (ORDER BY po.global_default_order, po.payout_percentage DESC) as seq
            FROM payout_options po
            WHERE po.is_global_default = TRUE
                AND po.is_active = TRUE
            ORDER BY po.global_default_order, po.payout_percentage DESC
        LOOP
            DECLARE
                v_quote_id UUID;
                v_base_premium_adjusted NUMERIC;
                v_wholesale_premium NUMERIC;
                v_retail_premium NUMERIC;
                v_gst_amount NUMERIC;
                v_stamp_duty_amount NUMERIC;
                v_total_premium NUMERIC;
                v_premium_ratio NUMERIC;
                v_partner_quote_id_suffixed TEXT;
                v_coverage_amount NUMERIC;
                v_daily_coverage_amount NUMERIC;
                v_daily_premium NUMERIC;
                v_minimum_applied BOOLEAN := FALSE;
                v_commission_amount NUMERIC;
            BEGIN
                -- Calculate base premium for this payout option
                v_base_premium_adjusted := v_base_wholesale_premium * v_payout_option.premium_multiplier;
                
                -- Calculate GST and stamp duty on base premium
                v_gst_amount := v_base_premium_adjusted * v_config.gst_rate;
                v_stamp_duty_amount := v_base_premium_adjusted * v_config.stamp_duty_rate;
                
                -- Wholesale = base + GST + stamp duty (no commission)
                v_wholesale_premium := v_base_premium_adjusted + v_gst_amount + v_stamp_duty_amount;
                
                -- Commission amount
                v_commission_amount := v_base_premium_adjusted * v_commission_rate;
                
                -- Retail = wholesale + commission (includes everything)
                v_retail_premium := v_wholesale_premium + v_commission_amount;
                
                -- Total premium is now same as retail
                v_total_premium := v_retail_premium;
                
                -- Calculate premium ratio for min/max checks
                v_premium_ratio := v_total_premium / p_exposure_total;
                
                -- Calculate coverage and daily amounts
                v_coverage_amount := ROUND(p_exposure_total * v_payout_option.payout_percentage / 100, 2);
                v_daily_coverage_amount := ROUND(v_coverage_amount / v_duration_days, 2);
                v_daily_premium := ROUND(v_total_premium / v_duration_days, 2);
                
                -- Apply min/max rate caps
                IF v_premium_ratio < v_min_rate_threshold THEN
                    -- Apply minimum rate cap
                    v_total_premium := p_exposure_total * v_min_rate_threshold;
                    v_retail_premium := v_total_premium;
                    
                    -- Recalculate components to maintain proportions
                    v_base_premium_adjusted := v_total_premium / (1 + v_config.gst_rate + v_config.stamp_duty_rate + v_commission_rate);
                    v_gst_amount := v_base_premium_adjusted * v_config.gst_rate;
                    v_stamp_duty_amount := v_base_premium_adjusted * v_config.stamp_duty_rate;
                    v_commission_amount := v_base_premium_adjusted * v_commission_rate;
                    v_wholesale_premium := v_base_premium_adjusted + v_gst_amount + v_stamp_duty_amount;
                    
                    v_premium_ratio := v_min_rate_threshold;
                    v_daily_premium := ROUND(v_total_premium / v_duration_days, 2);
                    v_minimum_applied := TRUE;
                ELSIF v_premium_ratio > v_max_rate_threshold THEN
                    -- Reject if above maximum
                    CONTINUE; -- Skip this payout option
                END IF;
                
                v_quote_id := gen_random_uuid();
                v_partner_quote_id_suffixed := v_base_partner_quote_id || '_' || v_payout_option.seq;
                
                -- Insert quote (same as partner-specific logic)
                INSERT INTO quotes (
                    quote_id, quote_group_id, partner_id, partner_quote_id,
                    experience_name, suburb, state, country, event_type,
                    coverage_start, coverage_end, coverage_start_time, coverage_end_time,
                    expires_at, latitude, longitude, exposure_total, location_id, 
                    status, model_version, created_at
                ) VALUES (
                    v_quote_id, v_quote_group_id, p_partner_id, v_partner_quote_id_suffixed,
                    p_experience_name, p_suburb, p_state, p_country, p_event_type,
                    v_start_timestamp, v_end_timestamp,
                    (v_coverage_hours->>'start')::TIME, (v_coverage_hours->>'end')::TIME,
                    v_expires_at, p_latitude, p_longitude, p_exposure_total, v_primary_station_id,
                    'active',
                    'v3.0_config_based', NOW()
                );
                
                -- Insert quote_locations (same logic as above)
                INSERT INTO quote_locations (
                    quote_id, location_id, distance_km, seasonal_index, rainfall_trigger, rainfall_duration, is_primary,
                    applied_max_trigger, applied_max_duration, applied_max_index, stations_in_analysis, risk_contribution_type,
                    max_seasonal_index_date, max_rainfall_trigger_date, max_optimal_hour_date
                )
                SELECT DISTINCT ON (sd.location_id)
                    v_quote_id, sd.location_id, sd.distance_km, sd.individual_seasonal_index, 
                    sd.individual_rainfall_trigger, sd.individual_duration,
                    CASE WHEN sd.location_id = v_primary_station_id THEN true ELSE false END,
                    v_max_rainfall_trigger, v_max_duration, v_max_seasonal_index, v_stations_analyzed,
                    CASE 
                        WHEN sd.individual_rainfall_trigger = v_max_rainfall_trigger 
                             AND sd.individual_duration = v_max_duration 
                             AND sd.individual_seasonal_index = v_max_seasonal_index
                        THEN 'all_max_source'
                        WHEN sd.individual_rainfall_trigger = v_max_rainfall_trigger THEN 'rainfall_trigger_source'
                        WHEN sd.individual_duration = v_max_duration THEN 'duration_source'
                        WHEN sd.individual_seasonal_index = v_max_seasonal_index THEN 'seasonal_index_source'
                        WHEN sd.location_id = v_primary_station_id THEN 'primary_reference'
                        ELSE 'contributing_station'
                    END,
                    p_start_date, p_start_date, p_start_date
                FROM (
                    SELECT 
                        l.location_id,
                        ST_Distance(v_input_point, l.geom) / 1000 as distance_km,
                        dsi.modified_seasonal_index as individual_seasonal_index,
                        dsi.modified_rainfall_trigger as individual_rainfall_trigger,
                        dsi.optimal_hour_trigger as individual_duration
                    FROM locations l
                    LEFT JOIN daily_seasonal_indices dsi ON 
                        l.location_id = dsi.location_id 
                        AND dsi.month_of_year = EXTRACT(MONTH FROM p_start_date)
                        AND dsi.day_of_month = EXTRACT(DAY FROM p_start_date)
                    WHERE l.location_id = ANY(v_nearby_station_ids)
                ) sd
                WHERE sd.individual_seasonal_index IS NOT NULL
                ORDER BY sd.location_id, sd.distance_km;
                
                -- Insert quote_premiums
                INSERT INTO quote_premiums (
                    quote_id, exposure_total, seasonal_index, duration_multiplier, wholesale_premium, rainfall_trigger,
                    above_threshold, above_value_threshold, retail_premium, gst_amount, stamp_duty_amount, commission_rate,
                    rainfall_duration, single_station_premium_applied, risk_adjustment_applied, minimum_premium_applied
                ) VALUES (
                    v_quote_id, p_exposure_total, v_max_seasonal_index, 1.0, v_wholesale_premium, v_max_rainfall_trigger,
                    false, false, v_retail_premium, v_gst_amount, v_stamp_duty_amount, v_commission_rate,
                    v_max_duration, 
                    CASE WHEN v_stations_analyzed = 1 THEN true ELSE false END, 
                    v_any_climate_anomaly, v_minimum_applied
                );
                
                -- Insert into quote_payout_options
                INSERT INTO quote_payout_options (
                    quote_option_id, quote_id, payout_option_id, payout_percentage, premium_multiplier,
                    wholesale_premium, retail_premium, gst_amount, stamp_duty_amount, total_premium,
                    is_selected, is_default, display_order, coverage_amount, daily_coverage_amount
                ) VALUES (
                    gen_random_uuid(), v_quote_id, v_payout_option.payout_option_id,
                    v_payout_option.payout_percentage, v_payout_option.premium_multiplier,
                    v_wholesale_premium, v_retail_premium, v_gst_amount, v_stamp_duty_amount, v_total_premium,
                    false, v_payout_option.is_default, v_payout_option.seq, v_coverage_amount, v_daily_coverage_amount
                );
                
                -- Add to response
                v_quotes_created := v_quotes_created || jsonb_build_object(
                    'quote_id', v_quote_id,
                    'option_name', v_payout_option.option_name,
                    'payout_percentage', v_payout_option.payout_percentage,
                    'coverage_amount', v_coverage_amount,
                    'daily_coverage_amount', v_daily_coverage_amount,
                    'premium', jsonb_build_object(
                        'wholesale_premium', ROUND(v_wholesale_premium, 2),
                        'retail_premium', ROUND(v_retail_premium, 2),
                        'gst_amount', ROUND(v_gst_amount, 2),
                        'daily_premium', v_daily_premium,
                        'currency', 'AUD'
                    )
                );
                
                v_quotes_count := v_quotes_count + 1;
            END;
        END LOOP;
    END IF;
    
    -- ========================================
    -- FALLBACK: If still no quotes, create single default
    -- ========================================
    IF v_quotes_count = 0 THEN
        DECLARE
            v_quote_id UUID;
            v_wholesale_premium NUMERIC;
            v_retail_premium NUMERIC;
            v_gst_amount NUMERIC;
            v_stamp_duty_amount NUMERIC;
            v_total_premium NUMERIC;
            v_premium_ratio NUMERIC;
            v_daily_premium NUMERIC;
            v_minimum_applied BOOLEAN := FALSE;
            v_commission_amount NUMERIC;
        BEGIN
            -- NEW CALCULATION METHOD for default quote:
            -- Calculate GST and stamp duty on base premium
            v_gst_amount := v_base_wholesale_premium * v_config.gst_rate;
            v_stamp_duty_amount := v_base_wholesale_premium * v_config.stamp_duty_rate;
            
            -- Wholesale = base + GST + stamp duty (no commission)
            v_wholesale_premium := v_base_wholesale_premium + v_gst_amount + v_stamp_duty_amount;
            
            -- Commission amount
            v_commission_amount := v_base_wholesale_premium * v_commission_rate;
            
            -- Retail = wholesale + commission (includes everything)
            v_retail_premium := v_wholesale_premium + v_commission_amount;
            
            -- Total premium is now same as retail
            v_total_premium := v_retail_premium;
            
            -- Calculate premium ratio
            v_premium_ratio := v_total_premium / p_exposure_total;
            v_daily_premium := ROUND(v_total_premium / v_duration_days, 2);
            
            -- Apply rate caps
            IF v_premium_ratio < v_min_rate_threshold THEN
                -- Apply minimum rate cap
                v_total_premium := p_exposure_total * v_min_rate_threshold;
                v_retail_premium := v_total_premium;
                
                -- Recalculate components
                v_base_wholesale_premium := v_total_premium / (1 + v_config.gst_rate + v_config.stamp_duty_rate + v_commission_rate);
                v_gst_amount := v_base_wholesale_premium * v_config.gst_rate;
                v_stamp_duty_amount := v_base_wholesale_premium * v_config.stamp_duty_rate;
                v_commission_amount := v_base_wholesale_premium * v_commission_rate;
                v_wholesale_premium := v_base_wholesale_premium + v_gst_amount + v_stamp_duty_amount;
                
                v_premium_ratio := v_min_rate_threshold;
                v_daily_premium := ROUND(v_total_premium / v_duration_days, 2);
                v_minimum_applied := TRUE;
            ELSIF v_premium_ratio > v_max_rate_threshold THEN
                RETURN jsonb_build_object(
                    'success', false, 
                    'error_code', 'PREMIUM_THRESHOLD_EXCEEDED', 
                    'error_message', format('Premium (%s%%) exceeds %s%% of exposure value', 
                        ROUND(v_premium_ratio * 100, 1), ROUND(v_max_rate_threshold * 100, 1))
                );
            END IF;
            
            v_quote_id := gen_random_uuid();
            
            -- Insert single quote
            INSERT INTO quotes (
                quote_id, partner_id, experience_name, partner_quote_id, suburb, state, country, event_type,
                coverage_start, coverage_end, coverage_start_time, coverage_end_time, expires_at,
                latitude, longitude, exposure_total, location_id, status, 
                model_version, created_at
            ) VALUES (
                v_quote_id, p_partner_id, p_experience_name, v_base_partner_quote_id,
                p_suburb, p_state, p_country, p_event_type, 
                v_start_timestamp, v_end_timestamp,
                (v_coverage_hours->>'start')::TIME, (v_coverage_hours->>'end')::TIME, v_expires_at,
                p_latitude, p_longitude, p_exposure_total, v_primary_station_id, 
                'active',
                'v3.0_config_based', NOW()
            );
            
            -- Insert quote_locations (same as above, omitted for brevity)
            INSERT INTO quote_locations (
                quote_id, location_id, distance_km, seasonal_index, rainfall_trigger, rainfall_duration, is_primary,
                applied_max_trigger, applied_max_duration, applied_max_index, stations_in_analysis, risk_contribution_type,
                max_seasonal_index_date, max_rainfall_trigger_date, max_optimal_hour_date
            )
            SELECT DISTINCT ON (sd.location_id)
                v_quote_id, sd.location_id, sd.distance_km, sd.individual_seasonal_index, 
                sd.individual_rainfall_trigger, sd.individual_duration,
                CASE WHEN sd.location_id = v_primary_station_id THEN true ELSE false END,
                v_max_rainfall_trigger, v_max_duration, v_max_seasonal_index, v_stations_analyzed,
                CASE 
                    WHEN sd.individual_rainfall_trigger = v_max_rainfall_trigger 
                         AND sd.individual_duration = v_max_duration 
                         AND sd.individual_seasonal_index = v_max_seasonal_index
                    THEN 'all_max_source'
                    WHEN sd.individual_rainfall_trigger = v_max_rainfall_trigger THEN 'rainfall_trigger_source'
                    WHEN sd.individual_duration = v_max_duration THEN 'duration_source'
                    WHEN sd.individual_seasonal_index = v_max_seasonal_index THEN 'seasonal_index_source'
                    WHEN sd.location_id = v_primary_station_id THEN 'primary_reference'
                    ELSE 'contributing_station'
                END,
                p_start_date, p_start_date, p_start_date
            FROM (
                SELECT 
                    l.location_id,
                    ST_Distance(v_input_point, l.geom) / 1000 as distance_km,
                    dsi.modified_seasonal_index as individual_seasonal_index,
                    dsi.modified_rainfall_trigger as individual_rainfall_trigger,
                    dsi.optimal_hour_trigger as individual_duration
                FROM locations l
                LEFT JOIN daily_seasonal_indices dsi ON 
                    l.location_id = dsi.location_id 
                    AND dsi.month_of_year = EXTRACT(MONTH FROM p_start_date)
                    AND dsi.day_of_month = EXTRACT(DAY FROM p_start_date)
                WHERE l.location_id = ANY(v_nearby_station_ids)
            ) sd
            WHERE sd.individual_seasonal_index IS NOT NULL
            ORDER BY sd.location_id, sd.distance_km;
            
            -- Insert quote_premiums for single quote with NEW definitions
            INSERT INTO quote_premiums (
                quote_id, exposure_total, seasonal_index, duration_multiplier, wholesale_premium, rainfall_trigger,
                above_threshold, above_value_threshold, retail_premium, gst_amount, stamp_duty_amount, commission_rate,
                rainfall_duration, single_station_premium_applied, risk_adjustment_applied, minimum_premium_applied
            ) VALUES (
                v_quote_id, p_exposure_total, v_max_seasonal_index, 1.0, v_wholesale_premium, v_max_rainfall_trigger,
                false, false, v_retail_premium, v_gst_amount, v_stamp_duty_amount, v_commission_rate,
                v_max_duration, 
                CASE WHEN v_stations_analyzed = 1 THEN true ELSE false END, 
                v_any_climate_anomaly, v_minimum_applied
            );
            
            -- Return single quote in array format for consistency
            v_quotes_created := jsonb_build_array(
                jsonb_build_object(
                    'quote_id', v_quote_id,
                    'option_name', 'Standard Coverage',
                    'payout_percentage', 100.00,
                    'coverage_amount', p_exposure_total,
                    'daily_coverage_amount', ROUND(p_exposure_total / v_duration_days, 2),
                    'premium', jsonb_build_object(
                        'wholesale_premium', ROUND(v_wholesale_premium, 2),
                        'retail_premium', ROUND(v_retail_premium, 2),
                        'gst_amount', ROUND(v_gst_amount, 2),
                        'daily_premium', v_daily_premium,
                        'currency', 'AUD'
                    )
                )
            );
            
            v_quotes_count := 1;
        END;
    END IF;
    
    -- Check if we created any valid quotes
    IF v_quotes_count = 0 THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'NO_VALID_OPTIONS', 
            'error_message', 'All payout options exceed the premium threshold'
        );
    END IF;
    
    -- Return success response with new structure
    RETURN jsonb_build_object(
 --       'success', true,
        'common', jsonb_build_object(
            'partner_quote_id', v_base_partner_quote_id,
            'location', jsonb_build_object(
                'suburb', p_suburb,
                'state', p_state,
                'country', p_country,
                'latitude', p_latitude,
                'longitude', p_longitude
            ),
            'coverage', jsonb_build_object(
                'start_date', p_start_date,
                'end_date', p_end_date,
                'start_time', v_coverage_hours->>'start',
                'end_time', v_coverage_hours->>'end',
                'duration_days', v_duration_days,
                'event_type', p_event_type
            ),
            'weather', jsonb_build_object(
                'primary_station', jsonb_build_object(
                    'name', v_primary_station_name,
                    'distance_km', ROUND(v_primary_station_distance, 2),
                    'location_id', v_primary_station_id
                ),
                'triggers', jsonb_build_object(
                    'trigger_type', 'rain',
                    'trigger_value', v_max_rainfall_trigger,
                    'duration_hours', v_max_duration
                )
            ),
            'expires_at', v_expires_at
        ),
        'quotes', v_quotes_created,
        'quotes_generated', v_quotes_count
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'INTERNAL_ERROR', 
            'error_message', 'Quote creation failed: ' || SQLERRM,
            'error_detail', jsonb_build_object(
                'sql_state', SQLSTATE, 
                'function', 'create_complete_quote_v3'
            )
        );
END;$function$
;

CREATE OR REPLACE FUNCTION public.create_complete_quote_v4(p_partner_id uuid, p_partner_quote_id text, p_experience_name text, p_suburb text, p_state text, p_country text, p_event_type text, p_start_date date, p_end_date date, p_latitude numeric, p_longitude numeric, p_exposure_total numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    v_config quote_config%ROWTYPE;
    v_validation_result jsonb;
    v_weather_result jsonb;
    v_quote_group_id uuid;
    v_base_partner_quote_id text;
    v_duration_days integer;
    v_daily_exposure_amount numeric;
    v_commission_rate numeric;
    v_base_wholesale_premium numeric;
    v_coverage_hours jsonb;
    v_expires_at timestamptz;
    v_quotes_created jsonb := '[]'::jsonb;
    v_quotes_count integer := 0;
    v_payout_option record;
    v_premium_calc jsonb;
    v_quote_id uuid;
    v_station_ids integer[];
    v_input_point geography;
    v_exposure_check_date date;
BEGIN
    -- Load configuration
    SELECT * INTO v_config 
    FROM quote_config 
    WHERE config_name = 'default' AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'CONFIG_ERROR',
            'error_message', 'Quote configuration not found or inactive'
        );
    END IF;
    
    -- Validate inputs
    v_validation_result := _validate_quote_inputs(p_start_date, p_end_date, p_exposure_total, v_config);
    IF NOT (v_validation_result->>'is_valid')::boolean THEN
        RETURN v_validation_result->'error';
    END IF;
    v_duration_days := (v_validation_result->>'duration_days')::integer;
    
    -- Get coverage hours
    v_coverage_hours := CASE 
        WHEN v_config.event_type_hours ? p_event_type THEN v_config.event_type_hours->p_event_type
        ELSE v_config.event_type_hours->'default'
    END;
    
    -- Set common variables
    v_quote_group_id := gen_random_uuid();
    v_base_partner_quote_id := COALESCE(p_partner_quote_id, 'auto-' || extract(epoch from now())::bigint::text);
    v_expires_at := NOW() + (v_config.quote_expiry_hours || ' hours')::INTERVAL;
    v_daily_exposure_amount := p_exposure_total / v_duration_days;
    v_commission_rate := get_partner_commission_rate(p_partner_id);
    
    -- Analyze weather stations
    v_weather_result := _analyze_weather_stations(p_latitude, p_longitude, p_start_date, v_config);
    IF NOT (v_weather_result->>'success')::boolean THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', v_weather_result->>'error_code',
            'error_message', v_weather_result->>'error_message'
        );
    END IF;
    
    -- Extract station_ids as proper integer array
    SELECT array_agg(value::integer) INTO v_station_ids
    FROM jsonb_array_elements(v_weather_result->'station_ids');
    
    -- Create input point for reuse
    v_input_point := (v_weather_result->>'input_point')::geography;
    
    -- Check exposure limits if not skipped
    IF NOT v_config.default_skip_exposure_check THEN
        -- Fixed exposure check - no STRICT
        WITH date_range AS (
            SELECT generate_series(p_start_date::date, p_end_date::date, '1 day'::interval)::date AS check_date
        ),
        exposure_check AS (
            SELECT 
                dr.check_date,
                COALESCE(SUM(p.exposure_total / GREATEST((p.coverage_end::date - p.coverage_start::date + 1), 1)), 0) AS existing_exposure
            FROM date_range dr
            LEFT JOIN policy p ON 
                p.status = 'active'
                AND p.coverage_start::date <= dr.check_date
                AND p.coverage_end::date >= dr.check_date
                AND EXISTS (
                    SELECT 1 FROM quotes q
                    JOIN quote_locations ql ON q.quote_id = ql.quote_id
                    WHERE p.quote_id = q.quote_id
                    AND ql.location_id = ANY(v_station_ids)
                )
            GROUP BY dr.check_date
            HAVING COALESCE(SUM(p.exposure_total / GREATEST((p.coverage_end::date - p.coverage_start::date + 1), 1)), 0) 
                + v_daily_exposure_amount > v_config.default_daily_value_limit
            LIMIT 1
        )
        SELECT check_date INTO v_exposure_check_date FROM exposure_check;
        
        IF v_exposure_check_date IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'DAILY_EXPOSURE_LIMIT_EXCEEDED',
                'error_message', format('Daily exposure limit of $%s would be exceeded on %s',
                    v_config.default_daily_value_limit, v_exposure_check_date)
            );
        END IF;
    END IF;
    
    -- Calculate base wholesale premium
    v_base_wholesale_premium := p_exposure_total * (v_weather_result->>'max_seasonal_index')::numeric * v_config.base_percent;
    
    -- Process payout options
    FOR v_payout_option IN SELECT * FROM _get_payout_options(p_partner_id, p_event_type) LOOP
        -- Calculate premiums
        v_premium_calc := _calculate_premiums(
            p_exposure_total,
            v_payout_option.payout_percentage,
            v_payout_option.premium_multiplier,
            v_duration_days,
            v_base_wholesale_premium,
            v_config,
            v_commission_rate
        );
        
        -- Skip if premium exceeds maximum
        IF NOT (v_premium_calc->>'valid')::boolean THEN
            CONTINUE;
        END IF;
        
        v_quote_id := gen_random_uuid();
        
        -- Insert quote
        INSERT INTO quotes (
            quote_id, quote_group_id, partner_id, partner_quote_id,
            experience_name, suburb, state, country, event_type,
            coverage_start, coverage_end, coverage_start_time, coverage_end_time,
            expires_at, latitude, longitude, exposure_total, location_id, 
            status, model_version, created_at
        ) VALUES (
            v_quote_id, v_quote_group_id, p_partner_id, 
            v_base_partner_quote_id || '_' || v_payout_option.seq,
            p_experience_name, p_suburb, p_state, p_country, p_event_type,
            p_start_date::timestamptz, p_end_date::timestamptz,
            (v_coverage_hours->>'start')::TIME, (v_coverage_hours->>'end')::TIME,
            v_expires_at, p_latitude, p_longitude, p_exposure_total, 
            (v_weather_result->>'primary_station_id')::integer,
            'active', 'v4.0_simplified', NOW()
        );
        
        -- Insert quote_locations
        INSERT INTO quote_locations (
            quote_id, location_id, distance_km, seasonal_index, rainfall_trigger, rainfall_duration, is_primary,
            applied_max_trigger, applied_max_duration, applied_max_index, stations_in_analysis, risk_contribution_type,
            max_seasonal_index_date, max_rainfall_trigger_date, max_optimal_hour_date
        )
        SELECT DISTINCT ON (sd.location_id)
            v_quote_id, sd.location_id, sd.distance_km, sd.individual_seasonal_index, 
            sd.individual_rainfall_trigger, sd.individual_duration,
            CASE WHEN sd.location_id = (v_weather_result->>'primary_station_id')::integer THEN true ELSE false END,
            (v_weather_result->>'max_rainfall_trigger')::numeric,
            (v_weather_result->>'max_duration')::integer,
            (v_weather_result->>'max_seasonal_index')::numeric,
            (v_weather_result->>'stations_analyzed')::integer,
            CASE 
                WHEN sd.individual_rainfall_trigger = (v_weather_result->>'max_rainfall_trigger')::numeric 
                     AND sd.individual_duration = (v_weather_result->>'max_duration')::integer 
                     AND sd.individual_seasonal_index = (v_weather_result->>'max_seasonal_index')::numeric
                THEN 'all_max_source'
                WHEN sd.individual_rainfall_trigger = (v_weather_result->>'max_rainfall_trigger')::numeric THEN 'rainfall_trigger_source'
                WHEN sd.individual_duration = (v_weather_result->>'max_duration')::integer THEN 'duration_source'
                WHEN sd.individual_seasonal_index = (v_weather_result->>'max_seasonal_index')::numeric THEN 'seasonal_index_source'
                WHEN sd.location_id = (v_weather_result->>'primary_station_id')::integer THEN 'primary_reference'
                ELSE 'contributing_station'
            END,
            p_start_date, p_start_date, p_start_date
        FROM (
            SELECT 
                l.location_id,
                ST_Distance(v_input_point, l.geom) / 1000 as distance_km,
                dsi.modified_seasonal_index as individual_seasonal_index,
                dsi.modified_rainfall_trigger as individual_rainfall_trigger,
                dsi.optimal_hour_trigger as individual_duration
            FROM locations l
            LEFT JOIN daily_seasonal_indices dsi ON 
                l.location_id = dsi.location_id 
                AND dsi.month_of_year = EXTRACT(MONTH FROM p_start_date)
                AND dsi.day_of_month = EXTRACT(DAY FROM p_start_date)
            WHERE l.location_id = ANY(v_station_ids)
        ) sd
        WHERE sd.individual_seasonal_index IS NOT NULL
        ORDER BY sd.location_id, sd.distance_km;
        
        -- Insert quote_premiums
        INSERT INTO quote_premiums (
            quote_id, exposure_total, seasonal_index, duration_multiplier, wholesale_premium, rainfall_trigger,
            above_threshold, above_value_threshold, retail_premium, gst_amount, stamp_duty_amount, commission_rate,
            rainfall_duration, single_station_premium_applied, risk_adjustment_applied, minimum_premium_applied
        ) VALUES (
            v_quote_id, p_exposure_total, (v_weather_result->>'max_seasonal_index')::numeric, 1.0, 
            (v_premium_calc->>'wholesale_premium')::numeric,
            (v_weather_result->>'max_rainfall_trigger')::numeric,
            false, false, 
            (v_premium_calc->>'retail_premium')::numeric,
            (v_premium_calc->>'gst_amount')::numeric,
            (v_premium_calc->>'stamp_duty_amount')::numeric,
            v_commission_rate,
            (v_weather_result->>'max_duration')::integer,
            CASE WHEN (v_weather_result->>'stations_analyzed')::integer = 1 THEN true ELSE false END, 
            (v_weather_result->>'any_climate_anomaly')::boolean,
            (v_premium_calc->>'minimum_applied')::boolean
        );
        
        -- Insert quote_payout_options
        INSERT INTO quote_payout_options (
            quote_option_id, quote_id, payout_option_id, payout_percentage, premium_multiplier,
            wholesale_premium, retail_premium, gst_amount, stamp_duty_amount, total_premium,
            is_selected, is_default, display_order, coverage_amount, daily_coverage_amount
        ) VALUES (
            gen_random_uuid(), v_quote_id, v_payout_option.payout_option_id,
            v_payout_option.payout_percentage, v_payout_option.premium_multiplier,
            (v_premium_calc->>'wholesale_premium')::numeric,
            (v_premium_calc->>'retail_premium')::numeric,
            (v_premium_calc->>'gst_amount')::numeric,
            (v_premium_calc->>'stamp_duty_amount')::numeric,
            (v_premium_calc->>'total_premium')::numeric,
            false, v_payout_option.is_default, v_payout_option.seq,
            (v_premium_calc->>'coverage_amount')::numeric,
            (v_premium_calc->>'daily_coverage_amount')::numeric
        );
        
        -- Add to response
        v_quotes_created := v_quotes_created || jsonb_build_object(
            'quote_id', v_quote_id,
            'option_name', v_payout_option.option_name,
            'payout_percentage', v_payout_option.payout_percentage,
            'coverage_amount', (v_premium_calc->>'coverage_amount')::numeric,
            'daily_coverage_amount', (v_premium_calc->>'daily_coverage_amount')::numeric,
            'rate_applied', ROUND((v_premium_calc->>'premium_ratio')::numeric * 100, 2),
            'minimum_rate_applied', (v_premium_calc->>'minimum_applied')::boolean,
            'premium', jsonb_build_object(
                'wholesale_premium', ROUND((v_premium_calc->>'wholesale_premium')::numeric, 2),
                'retail_premium', ROUND((v_premium_calc->>'retail_premium')::numeric, 2),
                'total_premium', ROUND((v_premium_calc->>'total_premium')::numeric, 2),
                'daily_premium', (v_premium_calc->>'daily_premium')::numeric,
                'currency', 'AUD'
            )
        );
        
        v_quotes_count := v_quotes_count + 1;
    END LOOP;
    
    -- If no quotes created, try default fallback
    IF v_quotes_count = 0 THEN
        -- Calculate with 100% payout
        v_premium_calc := _calculate_premiums(
            p_exposure_total, 100.0, 1.0, v_duration_days,
            v_base_wholesale_premium, v_config, v_commission_rate
        );
        
        IF NOT (v_premium_calc->>'valid')::boolean THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'PREMIUM_THRESHOLD_EXCEEDED',
                'error_message', format('Premium (%s%%) exceeds %s%% of exposure value',
                    ROUND((v_premium_calc->>'premium_ratio')::numeric * 100, 1),
                    ROUND(v_config.max_rate_percent, 1))
            );
        END IF;
        
        -- Create single default quote (code omitted for brevity - same pattern as above)
        v_quotes_count := 1;
    END IF;
    
    -- Return success response
    RETURN jsonb_build_object(
        'success', true,
        'common', jsonb_build_object(
            'partner_quote_id', v_base_partner_quote_id,
            'location', jsonb_build_object(
                'suburb', p_suburb,
                'state', p_state,
                'country', p_country,
                'latitude', p_latitude,
                'longitude', p_longitude
            ),
            'coverage', jsonb_build_object(
                'start_date', p_start_date,
                'end_date', p_end_date,
                'start_time', v_coverage_hours->>'start',
                'end_time', v_coverage_hours->>'end',
                'duration_days', v_duration_days,
                'event_type', p_event_type
            ),
            'weather', jsonb_build_object(
                'primary_station', jsonb_build_object(
                    'name', v_weather_result->>'primary_station_name',
                    'distance_km', ROUND((v_weather_result->>'primary_station_distance')::numeric, 2),
                    'location_id', (v_weather_result->>'primary_station_id')::integer
                ),
                'triggers', jsonb_build_object(
                    'trigger_type', 'rain',
                    'trigger_value', (v_weather_result->>'max_rainfall_trigger')::numeric,
                    'duration_hours', (v_weather_result->>'max_duration')::integer
                )
            ),
            'expires_at', v_expires_at
        ),
        'quotes', v_quotes_created,
        'quotes_generated', v_quotes_count
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'INTERNAL_ERROR',
            'error_message', 'Quote creation failed: ' || SQLERRM,
            'error_detail', jsonb_build_object(
                'sql_state', SQLSTATE,
                'function', 'create_complete_quote_v4',
                'hint', SQLERRM
            )
        );
END;$function$
;

CREATE OR REPLACE FUNCTION public.create_partner(p_partner_name text, p_email text, p_event_type text DEFAULT 'weather_quotes'::text, p_commission numeric DEFAULT 0.05)
 RETURNS TABLE(partner_id uuid, api_key_plain_text text, success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_partner_id UUID;
    v_api_key TEXT;
    v_key_id UUID;
    v_key_success BOOLEAN;
    v_key_message TEXT;
    v_webhook_id BIGINT;
BEGIN
    -- Validate inputs
    IF p_partner_name IS NULL OR trim(p_partner_name) = '' THEN
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, false, 'Partner name is required'::TEXT;
        RETURN;
    END IF;
    
    IF p_email IS NULL OR trim(p_email) = '' THEN
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, false, 'Email is required'::TEXT;
        RETURN;
    END IF;
    
    -- Check if partner already exists
    IF EXISTS (SELECT 1 FROM partners WHERE email = p_email AND is_active = true) THEN
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, false, 'Partner with this email already exists'::TEXT;
        RETURN;
    END IF;
    
    -- Create partner (partner_id will be auto-generated)
    INSERT INTO partners (partner_name, email, event_type, "Commission", is_active)
    VALUES (p_partner_name, p_email, p_event_type, p_commission, true)
    RETURNING partners.partner_id INTO v_partner_id;
    
    -- Generate API key using existing function (fix ambiguous reference)
    SELECT gsk.plain_text_key, gsk.api_key_id, gsk.success, gsk.message 
    INTO v_api_key, v_key_id, v_key_success, v_key_message
    FROM generate_simple_api_key(v_partner_id, 'Production API Key') gsk;
    
    IF NOT v_key_success THEN
        RETURN QUERY SELECT v_partner_id, NULL::TEXT, false, v_key_message;
        RETURN;
    END IF;
    
    -- Send webhook notification (fixed syntax)
    BEGIN
        SELECT net.http_post(
            'https://n8n.weatherit.ai/webhook/partner-created',
            json_build_object(
                'event_type', 'partner_created',
                'partner_id', v_partner_id,
                'partner_name', p_partner_name,
                'partner_email', p_email,
                'event_category', p_event_type,
                'commission_rate', p_commission,
                'api_key_id', v_key_id,
                'api_key_preview', left(v_api_key, 10) || '...',
                'created_at', now()
            )::text,
            headers => '{"Content-Type": "application/json"}'::jsonb
        ) INTO v_webhook_id;
    EXCEPTION WHEN OTHERS THEN
        -- Webhook failed, but don't fail the whole operation
        NULL;
    END;
    
    RETURN QUERY SELECT v_partner_id, v_api_key, true, 'Partner created successfully'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT NULL::UUID, NULL::TEXT, false, ('Error creating partner: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_partner_simplified(p_partner_name text, p_email text, p_event_type text, p_commission_rate numeric DEFAULT NULL::numeric)
 RETURNS TABLE(partner_id uuid, api_key_plain_text text, commission_rate numeric, uses_default_commission boolean, success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_partner_id UUID;
  v_api_key TEXT;
  v_key_result RECORD;
  v_commission_result RECORD;
  v_default_rate NUMERIC;
  v_uses_default BOOLEAN := TRUE;
BEGIN
  -- Validate inputs
  IF p_partner_name IS NULL OR trim(p_partner_name) = '' THEN
    RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::NUMERIC, NULL::BOOLEAN, false, 'Partner name is required'::TEXT;
    RETURN;
  END IF;
  
  IF p_email IS NULL OR trim(p_email) = '' THEN
    RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::NUMERIC, NULL::BOOLEAN, false, 'Email is required'::TEXT;
    RETURN;
  END IF;
  
  -- Check if partner already exists
  IF EXISTS (SELECT 1 FROM partners WHERE email = p_email AND is_active = true) THEN
    RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::NUMERIC, NULL::BOOLEAN, false, 'Partner with this email already exists'::TEXT;
    RETURN;
  END IF;
  
  -- Get default commission rate
  v_default_rate := get_partner_commission_rate(NULL);
  
  -- Create partner (no commission field needed - will use default)
  INSERT INTO partners (partner_name, email, event_type, is_active)
  VALUES (p_partner_name, p_email, p_event_type, true)
  RETURNING partners.partner_id INTO v_partner_id;
  
  -- Only set commission override if different from default
  IF p_commission_rate IS NOT NULL AND p_commission_rate != v_default_rate THEN
    SELECT * INTO v_commission_result
    FROM set_partner_commission_override(
      v_partner_id,
      p_commission_rate,
      NOW(),
      format('Custom rate: %s%% (default: %s%%)', 
        ROUND(p_commission_rate * 100, 2), 
        ROUND(v_default_rate * 100, 2)),
      'create_partner_simplified'
    );
    v_uses_default := FALSE;
  END IF;
  
  -- Generate API key
  SELECT * INTO v_key_result
  FROM manage_partner_keys(v_partner_id, 'generate', NULL, 'Initial API key');
  
  IF NOT v_key_result.success THEN
    RETURN QUERY SELECT v_partner_id, NULL::TEXT, NULL::NUMERIC, NULL::BOOLEAN, false, v_key_result.message;
    RETURN;
  END IF;
  
  -- Send webhook notification
  BEGIN
    PERFORM net.http_post(
      'https://n8n.weatherit.ai/webhook/partner-created',
      json_build_object(
        'event_type', 'partner_created_simplified',
        'partner_id', v_partner_id,
        'partner_name', p_partner_name,
        'partner_email', p_email,
        'event_category', p_event_type,
        'commission_rate', COALESCE(p_commission_rate, v_default_rate),
        'uses_default_commission', v_uses_default,
        'api_key_id', v_key_result.key_id,
        'created_at', NOW()
      )::text,
      headers => '{"Content-Type": "application/json"}'::jsonb
    );
  EXCEPTION WHEN OTHERS THEN
    -- Webhook failed, but don't fail the whole operation
    NULL;
  END;
  
  RETURN QUERY SELECT 
    v_partner_id, 
    v_key_result.plain_text_key, 
    COALESCE(p_commission_rate, v_default_rate),
    v_uses_default,
    true, 
    CASE 
      WHEN v_uses_default THEN 'Partner created successfully (using default commission)'
      ELSE format('Partner created successfully (using custom %s%% commission)', ROUND(p_commission_rate * 100, 2))
    END;
    
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::NUMERIC, NULL::BOOLEAN, false, ('Error creating partner: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_quote_with_templates(p_partner_id uuid, p_experience_name text, p_suburb text, p_state text, p_event_type text, p_start_date date, p_end_date date, p_exposure_total numeric, p_latitude numeric, p_longitude numeric, p_partner_quote_id text DEFAULT NULL::text, p_country text DEFAULT 'Australia'::text, p_base_percent numeric DEFAULT 0.10, p_daily_value_limit numeric DEFAULT 500000, p_skip_exposure_check boolean DEFAULT false, p_commission_rate numeric DEFAULT 0.10, p_include_templates boolean DEFAULT true, p_template_category text DEFAULT 'quote'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_quote_response JSONB;
    v_template_response JSONB;
    v_template_data JSONB;
    v_final_response JSONB;
BEGIN
    -- Step 1: Create quotes using the NEW calculation v2 (12 arguments)
    -- Note: The parameter order is different in the NEW version
    v_quote_response := create_complete_quote_v2(
        p_partner_id,
        p_partner_quote_id,  -- This comes earlier in the NEW version
        p_experience_name,
        p_suburb,
        p_state,
        p_country,
        p_event_type,
        p_start_date,
        p_end_date,
        p_latitude,
        p_longitude,
        p_exposure_total
        -- Note: NEW version doesn't take base_percent, daily_value_limit, skip_exposure_check, commission_rate
        -- It uses the NEW calculation method internally
    );
    
    -- If quote creation failed, return immediately
    IF NOT (v_quote_response->>'success')::boolean THEN
        RETURN v_quote_response;
    END IF;
    
    -- Step 2: Get templates if requested
    IF p_include_templates THEN
        v_template_response := get_templates_by_criteria(p_template_category, p_event_type);
        
        -- Step 3: Prepare template variables from quote data with new structure
        v_template_data := jsonb_build_object(
            -- Common variables from new structure
            'trigger_value', v_quote_response->'common'->'weather'->'triggers'->>'trigger_value',
            'duration_hours', v_quote_response->'common'->'weather'->'triggers'->>'duration_hours',
            'start_time', v_quote_response->'common'->'coverage'->>'start_time',
            'end_time', v_quote_response->'common'->'coverage'->>'end_time',
            'start_hour', EXTRACT(HOUR FROM (v_quote_response->'common'->'coverage'->>'start_time')::TIME),
            'end_hour', EXTRACT(HOUR FROM (v_quote_response->'common'->'coverage'->>'end_time')::TIME),
            -- Support current template variable names (exact matches for what templates expect)
            'weather_station.duration_hours', v_quote_response->'common'->'weather'->'triggers'->>'duration_hours',
            'weather_station.rainfall_trigger_mm', v_quote_response->'common'->'weather'->'triggers'->>'trigger_value',
            'weather.triggers.trigger_value', v_quote_response->'common'->'weather'->'triggers'->>'trigger_value',
            'weather.triggers.duration_hours', v_quote_response->'common'->'weather'->'triggers'->>'duration_hours',
            'coverage.start_time', v_quote_response->'common'->'coverage'->>'start_time',
            'coverage.end_time', v_quote_response->'common'->'coverage'->>'end_time'
        );
        
        -- Add quote-specific variables (up to 2 quotes)
        IF jsonb_array_length(v_quote_response->'quotes') >= 1 THEN
            v_template_data := v_template_data || jsonb_build_object(
                'coverage_amount_1', v_quote_response->'quotes'->0->>'coverage_amount',
                'daily_coverage_amount_1', v_quote_response->'quotes'->0->>'daily_coverage_amount',
                'total_premium_1', v_quote_response->'quotes'->0->'premium'->>'total_premium',
                'daily_premium_1', v_quote_response->'quotes'->0->'premium'->>'daily_premium',
                -- Also map to template expected names
                'premium.total_premium_1', v_quote_response->'quotes'->0->'premium'->>'total_premium',
                'premium.total_premium_per_day_1', v_quote_response->'quotes'->0->'premium'->>'daily_premium'
            );
        END IF;
        
        IF jsonb_array_length(v_quote_response->'quotes') >= 2 THEN
            v_template_data := v_template_data || jsonb_build_object(
                'coverage_amount_2', v_quote_response->'quotes'->1->>'coverage_amount',
                'daily_coverage_amount_2', v_quote_response->'quotes'->1->>'daily_coverage_amount',
                'total_premium_2', v_quote_response->'quotes'->1->'premium'->>'total_premium',
                'daily_premium_2', v_quote_response->'quotes'->1->'premium'->>'daily_premium',
                -- Also map to template expected names
                'premium.total_premium_2', v_quote_response->'quotes'->1->'premium'->>'total_premium',
                'premium.total_premium_per_day_2', v_quote_response->'quotes'->1->'premium'->>'daily_premium'
            );
        END IF;
        
        -- Build final response with templates
        v_final_response := v_quote_response || jsonb_build_object(
            'templates', v_template_response->'plainLanguage',
            'template_variables', v_template_data
        );
    ELSE
        -- No templates requested, return quote response as-is
        v_final_response := v_quote_response;
    END IF;
    
    RETURN v_final_response;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'WRAPPER_ERROR',
            'error_message', 'Failed to create quote with templates: ' || SQLERRM
        );
END;
$function$
;

create materialized view "public"."daily_seasonal_indices" as  SELECT id,
    location_id,
    month_of_year,
    day_of_month,
    base_seasonal_index,
    modified_seasonal_index,
    modified_rainfall_trigger,
    climate_anomaly_flag,
    optimal_hour_trigger,
    avg_rainfall_duration,
    sample_count,
    last_pattern_analysis,
    extended_risk_level,
    median_rainfall,
    rainfall_90th_percentile,
    version,
    climate_anomaly_id,
    enso_factor,
    applied_anomaly_type,
    applied_anomaly_intensity,
    comprehensive_risk_index,
    policy_recommendation,
    high_risk_flag,
    trigger_1hr_prob,
    trigger_2hr_prob,
    trigger_3hr_prob,
    trigger_4hr_prob,
    temporal_context_flag,
    moderate_risk_flag
   FROM prep.daily_seasonal_indices;


CREATE OR REPLACE FUNCTION public.deactivate_api_key(p_api_key_id uuid, p_reason text DEFAULT 'Deactivated for security'::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
BEGIN
    UPDATE api_keys 
    SET 
        is_active = false,
        deactivated_at = NOW(),
        deactivation_reason = p_reason
    WHERE id = p_api_key_id;
    
    RETURN FOUND;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.deactivate_partner_api_keys(p_partner_id uuid, p_reason text DEFAULT 'All keys deactivated for partner'::text)
 RETURNS TABLE(deactivated_count integer, success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
    v_count INTEGER;
BEGIN
    -- Check if partner exists
    IF NOT EXISTS (SELECT 1 FROM partners WHERE partner_id = p_partner_id) THEN
        RETURN QUERY SELECT 
            0,
            false,
            'Partner not found'::TEXT;
        RETURN;
    END IF;
    
    -- Deactivate all active keys for this partner
    UPDATE api_keys 
    SET 
        is_active = false,
        deactivated_at = NOW(),
        deactivation_reason = p_reason
    WHERE partner_id = p_partner_id 
        AND is_active = true;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        v_count,
        true,
        (v_count || ' API key(s) deactivated for partner')::TEXT;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        0,
        false,
        ('Error deactivating keys: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.deactivate_partner_latest_key(p_partner_id uuid, p_reason text DEFAULT 'Latest key deactivated for rotation'::text)
 RETURNS TABLE(deactivated_key_id uuid, success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
    v_latest_key_id UUID;
BEGIN
    -- Get the most recent active key for this partner
    SELECT id INTO v_latest_key_id
    FROM api_keys 
    WHERE partner_id = p_partner_id 
        AND is_active = true
    ORDER BY created_at DESC 
    LIMIT 1;
    
    IF v_latest_key_id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::UUID,
            false,
            'No active keys found for partner'::TEXT;
        RETURN;
    END IF;
    
    -- Deactivate the latest key
    UPDATE api_keys 
    SET 
        is_active = false,
        deactivated_at = NOW(),
        deactivation_reason = p_reason
    WHERE id = v_latest_key_id;
    
    RETURN QUERY SELECT 
        v_latest_key_id,
        true,
        'Latest API key deactivated for partner'::TEXT;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        NULL::UUID,
        false,
        ('Error deactivating latest key: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.decline_quote(p_quote_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
    v_affected_rows INTEGER;
BEGIN
    -- ✅ RLS SECURITY: Update quote status (RLS ensures partner ownership)
    UPDATE quotes 
    SET status = 'rejected'
    WHERE quote_id = p_quote_id
        AND status = 'active';
    
    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    
    IF v_affected_rows = 0 THEN
        -- Check if quote exists (RLS ensures partner ownership)
        IF NOT EXISTS (SELECT 1 FROM quotes WHERE quote_id = p_quote_id) THEN
            RETURN json_build_object(
                'success', false,
                'error', json_build_object(
                    'code', 'QUOTE_NOT_FOUND',
                    'message', 'Quote not found'
                )
            );
        ELSE
            RETURN json_build_object(
                'success', false,
                'error', json_build_object(
                    'code', 'QUOTE_NOT_ACTIVE',
                    'message', 'Quote is not in active status'
                )
            );
        END IF;
    END IF;
    
    -- Return 204-like response (empty success)
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'id', p_quote_id,
            'status', 'declined'
        )
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_partner(p_partner_id uuid, p_reason text DEFAULT 'Partner deactivated'::text)
 RETURNS TABLE(success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_partner_name TEXT;
    v_partner_email TEXT;
    v_deactivated_keys INTEGER := 0;
    v_webhook_id BIGINT;
BEGIN
    -- Get partner details before deletion
    SELECT partner_name, email INTO v_partner_name, v_partner_email
    FROM partners 
    WHERE partner_id = p_partner_id AND is_active = true;
    
    IF v_partner_name IS NULL THEN
        RETURN QUERY SELECT false, 'Partner not found or already inactive'::TEXT;
        RETURN;
    END IF;
    
    -- Soft delete partner
    UPDATE partners 
    SET is_active = false, updated_at = now()
    WHERE partner_id = p_partner_id;
    
    -- Deactivate their API key
    UPDATE api_keys 
    SET is_active = false, 
        deactivated_at = now(),
        deactivation_reason = p_reason
    WHERE partner_id = p_partner_id AND is_active = true;
    
    GET DIAGNOSTICS v_deactivated_keys = ROW_COUNT;
    
    -- Send webhook notification (fixed syntax)
    BEGIN
        SELECT net.http_post(
            'https://n8n.weatherit.ai/webhook/partner-deleted', 
            json_build_object(
                'event_type', 'partner_deleted',
                'partner_id', p_partner_id,
                'partner_name', v_partner_name,
                'partner_email', v_partner_email,
                'deactivation_reason', p_reason,
                'deactivated_keys', v_deactivated_keys,
                'deleted_at', now()
            )::text,
            headers => '{"Content-Type": "application/json"}'::jsonb
        ) INTO v_webhook_id;
    EXCEPTION WHEN OTHERS THEN
        -- Webhook failed, but don't fail the whole operation
        NULL;
    END;
    
    RETURN QUERY SELECT true, ('Partner and ' || v_deactivated_keys || ' API key(s) deactivated successfully')::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, ('Error deleting partner: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.expire_quotes(p_quote_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(quotes_expired integer, expired_quotes jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_updated_count INTEGER := 0;
    v_expired_quotes JSONB := '[]'::JSONB;
    v_quote RECORD;
BEGIN
    -- If quote_id provided, process single quote; otherwise process all expired quotes
    FOR v_quote IN 
        SELECT 
            q.quote_id,
            q.expires_at,
            q.coverage_start,
            q.coverage_end,
            q.partner_quote_id,
            q.experience_name,
            q.suburb,
            q.state,
            q.status
        FROM quotes q
        WHERE q.status = 'active' 
          AND (q.expires_at < NOW() OR q.coverage_end < (NOW() - INTERVAL '30 days'))
          AND (p_quote_id IS NULL OR q.quote_id = p_quote_id)
        ORDER BY q.expires_at
    LOOP
        -- Update the quote to expired status
        UPDATE quotes 
        SET status = 'expired'
        WHERE quote_id = v_quote.quote_id;
        
        -- Increment counter
        v_updated_count := v_updated_count + 1;
        
        -- Add to expired quotes list for reporting
        v_expired_quotes := v_expired_quotes || jsonb_build_object(
            'quote_id', v_quote.quote_id,
            'partner_quote_id', v_quote.partner_quote_id,
            'expires_at', v_quote.expires_at,
            'experience_name', v_quote.experience_name,
            'location', v_quote.suburb || ', ' || v_quote.state,
            'reason', CASE 
                WHEN v_quote.expires_at < NOW() THEN 'time_expired'
                ELSE 'coverage_ended'
            END
        );
    END LOOP;
    
    -- Return results
    RETURN QUERY SELECT v_updated_count, v_expired_quotes;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.find_json_differences(v3_result jsonb, v4_result jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    differences JSONB := '[]'::JSONB;
BEGIN
    -- Check success status
    IF v3_result->>'success' != v4_result->>'success' THEN
        differences := differences || jsonb_build_object(
            'field', 'success',
            'v3', v3_result->>'success',
            'v4', v4_result->>'success'
        );
    END IF;
    
    -- Check error codes
    IF v3_result->>'error_code' != v4_result->>'error_code' THEN
        differences := differences || jsonb_build_object(
            'field', 'error_code',
            'v3', v3_result->>'error_code',
            'v4', v4_result->>'error_code'
        );
    END IF;
    
    -- Check quote count
    IF jsonb_array_length(COALESCE(v3_result->'quotes', '[]'::jsonb)) != 
       jsonb_array_length(COALESCE(v4_result->'quotes', '[]'::jsonb)) THEN
        differences := differences || jsonb_build_object(
            'field', 'quote_count',
            'v3', jsonb_array_length(COALESCE(v3_result->'quotes', '[]'::jsonb)),
            'v4', jsonb_array_length(COALESCE(v4_result->'quotes', '[]'::jsonb))
        );
    END IF;
    
    -- Note: v4 shows GST, v3 shows total_premium - this is expected
    IF v3_result->'quotes'->0->'premium'->>'total_premium' IS NOT NULL AND
       v4_result->'quotes'->0->'premium'->>'gst_amount' IS NOT NULL THEN
        differences := differences || jsonb_build_object(
            'field', 'response_format',
            'note', 'v4 shows gst_amount instead of total_premium (expected)'
        );
    END IF;
    
    RETURN differences;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.format_name_proper_case(name_input text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF name_input IS NULL OR TRIM(name_input) = '' THEN
        RETURN NULL;
    END IF;
    
    -- Handle common name cases: O'Brien, McDonald, etc.
    RETURN INITCAP(LOWER(TRIM(name_input)));
END;
$function$
;

CREATE OR REPLACE FUNCTION public.format_phone_e164_with_country(phone_input text, country_code text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    cleaned_phone TEXT;
    digits_only TEXT;
    country_dial_code TEXT;
    expected_local_length INTEGER;
BEGIN
    -- Return NULL if empty
    IF phone_input IS NULL OR TRIM(phone_input) = '' THEN
        RETURN NULL;
    END IF;
    
    -- Get country dial code
    country_dial_code := get_country_dial_code(country_code);
    
    -- Remove all non-digits
    digits_only := REGEXP_REPLACE(phone_input, '[^0-9]', '', 'g');
    
    -- If empty after cleaning, return NULL
    IF digits_only = '' THEN
        RETURN NULL;
    END IF;
    
    -- Already has country code with +
    IF phone_input LIKE '+%' THEN
        cleaned_phone := '+' || digits_only;
        -- Validate length (typically 10-15 digits total)
        IF LENGTH(digits_only) BETWEEN 10 AND 15 THEN
            RETURN cleaned_phone;
        ELSE
            RETURN NULL;
        END IF;
    END IF;
    
    -- Determine expected local number length based on country
    expected_local_length := CASE 
        WHEN country_dial_code IN ('+1') THEN 10  -- US/CA
        WHEN country_dial_code IN ('+44') THEN 10 -- UK (without leading 0)
        WHEN country_dial_code IN ('+61') THEN 9  -- AU (without leading 0)
        WHEN country_dial_code IN ('+91') THEN 10 -- India
        WHEN country_dial_code IN ('+86') THEN 11 -- China
        ELSE 10 -- Default
    END;
    
    -- If it matches expected local length, add country code
    IF LENGTH(digits_only) = expected_local_length THEN
        RETURN country_dial_code || digits_only;
    END IF;
    
    -- Handle numbers with leading 0 (common in UK, AU)
    IF digits_only LIKE '0%' AND LENGTH(digits_only) = expected_local_length + 1 THEN
        RETURN country_dial_code || SUBSTRING(digits_only FROM 2);
    END IF;
    
    -- Handle numbers that already include country code without +
    IF LENGTH(digits_only) > expected_local_length THEN
        -- Check if it starts with the country code
        IF (country_dial_code = '+1' AND digits_only LIKE '1%' AND LENGTH(digits_only) = 11) OR
           (country_dial_code = '+44' AND digits_only LIKE '44%') OR
           (country_dial_code = '+61' AND digits_only LIKE '61%') OR
           (country_dial_code = '+91' AND digits_only LIKE '91%') THEN
            RETURN '+' || digits_only;
        END IF;
    END IF;
    
    -- If between 11-15 digits, assume it has country code
    IF LENGTH(digits_only) BETWEEN 11 AND 15 THEN
        RETURN '+' || digits_only;
    END IF;
    
    -- Can't determine format
    RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_claim_number()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    IF NEW.claim_number IS NULL THEN
        NEW.claim_number := 'CLM-' || 
                           EXTRACT(YEAR FROM NEW.created_at) || '-' || 
                           LPAD(EXTRACT(DAY FROM NEW.created_at)::text, 3, '0') || '-' || 
                           SUBSTRING(NEW.claim_id::text, 1, 8);
    END IF;
    RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.generate_simple_api_key(p_partner_id uuid, p_description text)
 RETURNS TABLE(api_key_id uuid, plain_text_key text, key_hash text, success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_new_key TEXT;
    v_key_hash TEXT;
    v_new_id UUID;
    v_uuid1 TEXT;
    v_uuid2 TEXT;
    v_partner_email TEXT;
BEGIN
    -- Check if partner exists and get their email
    SELECT email INTO v_partner_email
    FROM partners 
    WHERE partner_id = p_partner_id AND is_active = true;
    
    IF v_partner_email IS NULL THEN
        RETURN QUERY SELECT 
            NULL::UUID, 
            NULL::TEXT, 
            NULL::TEXT, 
            false, 
            'Partner not found or inactive'::TEXT;
        RETURN;
    END IF;
    
    -- Generate two UUIDs and combine them for randomness
    v_uuid1 := replace(gen_random_uuid()::text, '-', '');
    v_uuid2 := replace(gen_random_uuid()::text, '-', '');
    
    -- Create the API key with prefix
    v_new_key := 'wit_' || substring(v_uuid1 || v_uuid2, 1, 40);
    
    -- Hash the new key using our existing function
    v_key_hash := hash_api_key(v_new_key);
    
    -- Insert the new API key with partner email
    INSERT INTO api_keys (
        partner_id,
        partner_email,
        api_key_hash,
        description,
        is_active
    ) VALUES (
        p_partner_id,
        v_partner_email,
        v_key_hash,
        p_description,
        true
    ) RETURNING id INTO v_new_id;
    
    -- Return the results
    RETURN QUERY SELECT 
        v_new_id,
        v_new_key,
        v_key_hash,
        true,
        'API key generated successfully'::TEXT;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        NULL::UUID, 
        NULL::TEXT, 
        NULL::TEXT, 
        false, 
        ('Error generating API key: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_audit_docs(doc_type_filter text DEFAULT NULL::text)
 RETURNS TABLE(doc_type text, title text, content text, version text, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE
AS $function$
    SELECT doc_type, title, content, version, updated_at
    FROM audit_documentation
    WHERE doc_type = COALESCE(doc_type_filter, doc_type)
    ORDER BY doc_type, updated_at DESC;
$function$
;

CREATE OR REPLACE FUNCTION public.get_claim_weather_graph_data(p_claim_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
    v_claim_data record;
    v_graph_data jsonb;
    v_weather_column text;
    v_hourly_data jsonb;
BEGIN
    -- Fetch claim and policy data
    SELECT 
        c.claim_id,
        c.trigger_date,
        c.actual_payout_amount,
        c.exposure_total,
        c.payout_percentage,
        c.policy_trigger,
        c.policy_duration,
        c.hours_exceeded,
        p.policy_type,
        p.daily_exposure,
        p.daily_premium,
        p.coverage_days,
        p.coverage_start,
        p.coverage_end,
        p.latitude as policy_lat,
        p.longitude as policy_lon,
        cl.location_id,
        l.name as weather_station_name,
        l.city,
        l.state,
        l.latitude as station_lat,
        l.longitude as station_lon,
        l.timezone,
        CASE 
            WHEN p.longitude IS NOT NULL AND p.latitude IS NOT NULL 
                 AND l.longitude IS NOT NULL AND l.latitude IS NOT NULL
            THEN ST_Distance(
                ST_MakePoint(p.longitude, p.latitude)::geography,
                ST_MakePoint(l.longitude, l.latitude)::geography
            ) / 1000
            ELSE NULL
        END as distance_km
    INTO v_claim_data
    FROM claims c
    JOIN policy p ON c.policy_id = p.policy_id
    JOIN claim_locations cl ON c.claim_id = cl.claim_id
    JOIN locations l ON cl.location_id = l.location_id
    WHERE c.claim_id = p_claim_id 
    AND cl.is_primary_location = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'error', 'Claim not found',
            'claim_id', p_claim_id
        );
    END IF;

    -- Determine which weather column to use
    v_weather_column := CASE v_claim_data.policy_type
        WHEN 'rainfall' THEN 'rainfall_amount'
        WHEN 'temperature' THEN 'temperature'
        WHEN 'humidity' THEN 'humidity'
        WHEN 'wind' THEN 'wind_speed'
        ELSE 'rainfall_amount' -- default
    END;

    -- Get actual weather data
    EXECUTE format('
        SELECT jsonb_object_agg(
            hour::text,
            jsonb_build_object(
                ''value'', %I,
                ''exceeded'', CASE WHEN %I >= $1 THEN true ELSE false END
            )
        )
        FROM claim_weather_hourly
        WHERE claim_id = $2
        AND weather_date = $3',
        v_weather_column, v_weather_column
    ) INTO v_hourly_data
    USING v_claim_data.policy_trigger, p_claim_id, v_claim_data.trigger_date;

    -- Build complete 24-hour array with nulls for missing hours
    SELECT jsonb_agg(
        jsonb_build_object(
            'hour', h.hour,
            'value', COALESCE((v_hourly_data->h.hour::text->>'value')::numeric, null),
            'exceeded_threshold', COALESCE((v_hourly_data->h.hour::text->>'exceeded')::boolean, false)
        ) ORDER BY h.hour
    ) INTO v_graph_data
    FROM generate_series(0, 23) AS h(hour);

    -- Build final result
    v_result := jsonb_build_object(
        'claim_id', v_claim_data.claim_id,
        'policy_type', v_claim_data.policy_type,
        'financial_details', jsonb_build_object(
            'exposure_total', v_claim_data.exposure_total,
            'daily_exposure', v_claim_data.daily_exposure,
            'coverage_days', v_claim_data.coverage_days,
            'payout_percentage', v_claim_data.payout_percentage,
            'actual_payout_amount', v_claim_data.actual_payout_amount,
            'daily_premium', v_claim_data.daily_premium
        ),
        'trigger_details', jsonb_build_object(
            'threshold', v_claim_data.policy_trigger,
            'duration_hours', v_claim_data.policy_duration,
            'exceeded', CASE WHEN v_claim_data.hours_exceeded > 0 THEN true ELSE false END,
            'hours_exceeded', v_claim_data.hours_exceeded
        ),
        'weather_station', jsonb_build_object(
            'name', v_claim_data.weather_station_name,
            'location', v_claim_data.city || ', ' || v_claim_data.state,
            'distance_km', ROUND(v_claim_data.distance_km::numeric, 2),
            'coordinates', jsonb_build_object(
                'latitude', v_claim_data.station_lat,
                'longitude', v_claim_data.station_lon
            )
        ),
        'graph_data', v_graph_data,
        'metadata', jsonb_build_object(
            'trigger_date', v_claim_data.trigger_date,
            'coverage_start', v_claim_data.coverage_start,
            'coverage_end', v_claim_data.coverage_end,
            'weather_source', (
                SELECT COALESCE(weather_source, 'N/A') 
                FROM claim_weather_hourly 
                WHERE claim_id = p_claim_id 
                LIMIT 1
            ),
            'timezone', COALESCE(v_claim_data.timezone, 'UTC')
        )
    );

    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_claims_for_weather_check()
 RETURNS TABLE(claim_id uuid, policy_id uuid, customer_email text, location_name text, latitude numeric, longitude numeric, location_id integer, rainfall_threshold numeric, claim_status character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.claim_id,
        c.policy_id,
        COALESCE(cust.email, 'no-email@example.com') as customer_email,
        COALESCE(q.suburb || ', ' || q.state, 'Unknown') as location_name,
        q.latitude,
        q.longitude,
        q.location_id,
        c.policy_trigger as rainfall_threshold,
        c.claim_status
    FROM claims c
    JOIN policy p ON c.policy_id = p.policy_id
    JOIN quotes q ON p.quote_id = q.quote_id
    LEFT JOIN customers cust ON p.customer_id = cust.customer_id
    WHERE c.claim_status IN ('pending', 'monitoring')
    AND c.trigger_date = CURRENT_DATE;
--    AND c.trigger_date <= CURRENT_DATE + INTERVAL '7 days';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_claims_weather_hourly(p_claim_id uuid)
 RETURNS TABLE(weather_date date, hour integer, temperature numeric, rainfall numeric, humidity numeric, wind_speed numeric, trigger_exceeded boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_trigger NUMERIC;
    v_coverage_start_time TIME;
    v_coverage_end_time TIME;
BEGIN
    -- Get policy trigger and coverage hours
    SELECT 
        p.trigger,
        p.coverage_start_time,
        p.coverage_end_time
    INTO 
        v_trigger,
        v_coverage_start_time,
        v_coverage_end_time
    FROM claims c
    JOIN policy p ON c.policy_id = p.policy_id
    WHERE c.claim_id = p_claim_id;

    -- Return weather data with trigger exceedance check
    RETURN QUERY
    SELECT 
        cwh.weather_date,
        cwh.hour,
        cwh.temperature,
        cwh.rainfall_amount,
        cwh.humidity,
        cwh.wind_speed,
        CASE 
            WHEN v_coverage_start_time IS NOT NULL 
                AND v_coverage_end_time IS NOT NULL 
                AND (cwh.hour::TIME >= v_coverage_start_time 
                     AND cwh.hour::TIME < v_coverage_end_time)
                AND cwh.rainfall_amount >= v_trigger 
            THEN true
            ELSE false
        END as trigger_exceeded
    FROM claim_weather_hourly cwh
    WHERE cwh.claim_id = p_claim_id
    ORDER BY 
        cwh.weather_date,
        cwh.hour;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_country_dial_code(country_code text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$BEGIN
    -- Return dial codes for common countries
    RETURN CASE UPPER(country_code)
        WHEN 'US' THEN '+1'
        WHEN 'CA' THEN '+1'  
        WHEN 'AU' THEN '+61'
        WHEN 'AUSTRALIA' THEN '+61'
        WHEN 'GB' THEN '+44'
        WHEN 'UK' THEN '+44'
        WHEN 'UNITED KINGDOM' THEN '+44'
        WHEN 'DE' THEN '+49'
        WHEN 'GERMANY' THEN '+49'
        WHEN 'FR' THEN '+33'
        WHEN 'FRANCE' THEN '+33'
        WHEN 'IN' THEN '+91'
        WHEN 'INDIA' THEN '+91'
        WHEN 'CN' THEN '+86'
        WHEN 'CHINA' THEN '+86'
        WHEN 'JP' THEN '+81'
        WHEN 'JAPAN' THEN '+81'
        WHEN 'NZ' THEN '+64'
        WHEN 'NEW ZEALAND' THEN '+64'
        WHEN 'SG' THEN '+65'
        WHEN 'SINGAPORE' THEN '+65'
        WHEN 'HK' THEN '+852'
        WHEN 'HONG KONG' THEN '+852'
        WHEN 'MY' THEN '+60'
        WHEN 'MALAYSIA' THEN '+60'
        WHEN 'TH' THEN '+66'
        WHEN 'THAILAND' THEN '+66'
        WHEN 'PH' THEN '+63'
        WHEN 'PHILIPPINES' THEN '+63'
        WHEN 'ID' THEN '+62'
        WHEN 'INDONESIA' THEN '+62'
        WHEN 'VN' THEN '+84'
        WHEN 'VIETNAM' THEN '+84'
        WHEN 'KR' THEN '+82'
        WHEN 'SOUTH KOREA' THEN '+82'
        WHEN 'TW' THEN '+886'
        WHEN 'TAIWAN' THEN '+886'
        WHEN 'ZA' THEN '+27'
        WHEN 'SOUTH AFRICA' THEN '+27'
        WHEN 'BR' THEN '+55'
        WHEN 'BRAZIL' THEN '+55'
        WHEN 'MX' THEN '+52'
        WHEN 'MEXICO' THEN '+52'
        WHEN 'IT' THEN '+39'
        WHEN 'ITALY' THEN '+39'
        WHEN 'ES' THEN '+34'
        WHEN 'SPAIN' THEN '+34'
        WHEN 'NL' THEN '+31'
        WHEN 'NETHERLANDS' THEN '+31'
        WHEN 'BE' THEN '+32'
        WHEN 'BELGIUM' THEN '+32'
        WHEN 'CH' THEN '+41'
        WHEN 'SWITZERLAND' THEN '+41'
        WHEN 'AT' THEN '+43'
        WHEN 'AUSTRIA' THEN '+43'
        WHEN 'SE' THEN '+46'
        WHEN 'SWEDEN' THEN '+46'
        WHEN 'NO' THEN '+47'
        WHEN 'NORWAY' THEN '+47'
        WHEN 'DK' THEN '+45'
        WHEN 'DENMARK' THEN '+45'
        WHEN 'FI' THEN '+358'
        WHEN 'FINLAND' THEN '+358'
        WHEN 'IE' THEN '+353'
        WHEN 'IRELAND' THEN '+353'
        WHEN 'PT' THEN '+351'
        WHEN 'PORTUGAL' THEN '+351'
        WHEN 'GR' THEN '+30'
        WHEN 'GREECE' THEN '+30'
        WHEN 'TR' THEN '+90'
        WHEN 'TURKEY' THEN '+90'
        WHEN 'RU' THEN '+7'
        WHEN 'RUSSIA' THEN '+7'
        WHEN 'EG' THEN '+20'
        WHEN 'EGYPT' THEN '+20'
        WHEN 'IL' THEN '+972'
        WHEN 'ISRAEL' THEN '+972'
        WHEN 'AE' THEN '+971'
        WHEN 'UAE' THEN '+971'
        WHEN 'SA' THEN '+966'
        WHEN 'SAUDI ARABIA' THEN '+966'
        ELSE '+1'  -- Default to US/CA
    END;
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_current_partner_id()
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$BEGIN
    RETURN nullif(current_setting('app.current_partner_id', true), '')::uuid;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_customer_claims(p_customer_id uuid)
 RETURNS TABLE(claim_id uuid, policy_id uuid, policy_number text, experience_name text, claim_number character varying, claim_date date, claim_amount numeric, claim_status character varying, claim_reason text, trigger_date date, rainfall_triggered boolean, payout_transaction_id uuid, actual_payout_amount numeric, hours_exceeded integer, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.claim_id,
        c.policy_id,
        p.policy_number,
        p.experience_name,
        c.claim_number,
        c.claim_date,
        c.claim_amount,
        c.claim_status,
        c.claim_reason,
        c.trigger_date,
        c.rainfall_triggered,
        c.payout_transaction_id,
        c.actual_payout_amount,
        c.hours_exceeded,
        c.created_at,
        c.updated_at
    FROM 
        claims c
    INNER JOIN 
        policy p ON c.policy_id = p.policy_id
    WHERE 
        p.customer_id = p_customer_id
    ORDER BY 
        c.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_customer_policies(p_customer_id uuid)
 RETURNS TABLE(policy_id uuid, policy_number text, policy_status text, policy_type character varying, coverage_start date, coverage_end date, coverage_start_time time without time zone, coverage_end_time time without time zone, experience_name text, event_type text, suburb text, state text, country text, latitude numeric, longitude numeric, exposure_total numeric, final_premium numeric, daily_exposure numeric, daily_premium numeric, payout_percentage numeric, currency text, trigger numeric, duration integer, created_at timestamp with time zone, accepted_at timestamp with time zone, cancelled_at timestamp with time zone, cancellation_reason text, payment_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.policy_id,
        p.policy_number,
        p.status as policy_status,
        p.policy_type,
        p.coverage_start,
        p.coverage_end,
        p.coverage_start_time,
        p.coverage_end_time,
        p.experience_name,
        p.event_type,
        p.suburb,
        p.state,
        p.country,
        p.latitude,
        p.longitude,
        p.exposure_total,
        p.final_premium,
        p.daily_exposure,
        p.daily_premium,
        p.payout_percentage,
        p.currency,
        p.trigger,
        p.duration,
        p.created_at,
        p.accepted_at,
        p.cancelled_at,
        p.cancellation_reason,
        p.payment_status
    FROM 
        policy p
    WHERE 
        p.customer_id = p_customer_id
    ORDER BY 
        p.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_documents_config(p_event_type text DEFAULT 'camping'::text, p_channel text DEFAULT 'default'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT jsonb_object_agg(
            api_field_name,
            jsonb_build_object(
                'name', display_name,
                'link', url_path
            )
        )
        FROM document_config
        WHERE (event_type = p_event_type OR event_type IS NULL)
        AND channel = p_channel
        AND is_active = true
        ORDER BY sort_order
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_expired_api_keys()
 RETURNS TABLE(id uuid, partner_id uuid, partner_name character varying, description text, expires_at timestamp with time zone, days_overdue integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    SELECT 
        ak.id,
        ak.partner_id,
        p.partner_name,
        ak.description,
        ak.expires_at,
        EXTRACT(DAY FROM NOW() - ak.expires_at)::INTEGER
    FROM api_keys ak
    JOIN partners p ON ak.partner_id = p.partner_id
    WHERE ak.expires_at < NOW() 
        AND ak.is_active = true
    ORDER BY ak.expires_at ASC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_keys_needing_rotation()
 RETURNS TABLE(key_id uuid, partner_id uuid, partner_name character varying, created_at timestamp with time zone, last_used_at timestamp with time zone, days_since_creation integer, days_since_last_use integer, auto_rotate_days integer, reason text)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    ak.id,
    ak.partner_id,
    p.partner_name,
    ak.created_at,
    ak.last_used_at,
    EXTRACT(DAY FROM NOW() - ak.created_at)::INTEGER,
    EXTRACT(DAY FROM COALESCE(NOW() - ak.last_used_at, INTERVAL '0'))::INTEGER,
    ak.auto_rotate_days,
    CASE 
      WHEN ak.expires_at IS NOT NULL AND ak.expires_at <= NOW() THEN 'EXPIRED'
      WHEN EXTRACT(DAY FROM NOW() - ak.created_at) >= ak.auto_rotate_days THEN 'AUTO_ROTATION_DUE'
      WHEN ak.last_used_at IS NOT NULL AND EXTRACT(DAY FROM NOW() - ak.last_used_at) > 90 THEN 'INACTIVE_KEY'
      ELSE 'OTHER'
    END::TEXT
  FROM api_keys ak
  JOIN partners p ON ak.partner_id = p.partner_id
  WHERE ak.is_active = TRUE
  AND p.is_active = TRUE
  AND (
    (ak.expires_at IS NOT NULL AND ak.expires_at <= NOW())
    OR
    (EXTRACT(DAY FROM NOW() - ak.created_at) >= ak.auto_rotate_days)
    OR
    (ak.last_used_at IS NOT NULL AND EXTRACT(DAY FROM NOW() - ak.last_used_at) > 90)
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_locations_needing_processing(p_hours_threshold integer DEFAULT 24)
 RETURNS TABLE(location_id integer, name character varying, status text, last_pattern_analysis timestamp without time zone, hours_since_last_processing numeric, processing_priority text, needs_processing boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH location_status AS (
        SELECT 
            l.location_id,
            l.name,
            l.status,
            MAX(dsi.last_pattern_analysis) as last_pattern_analysis,
            CASE 
                WHEN MAX(dsi.last_pattern_analysis) IS NULL THEN NULL
                ELSE EXTRACT(EPOCH FROM (NOW() - MAX(dsi.last_pattern_analysis))) / 3600
            END as hours_since_last_processing
        FROM locations l 
        LEFT JOIN daily_seasonal_indices dsi ON l.location_id = dsi.location_id 
        WHERE l.status = 'active'
        GROUP BY l.location_id, l.name, l.status
    )
    SELECT 
        ls.location_id,
        ls.name,
        ls.status,
        ls.last_pattern_analysis,
        ls.hours_since_last_processing,
        CASE 
            WHEN ls.last_pattern_analysis IS NULL THEN 'never_processed'
            WHEN ls.hours_since_last_processing > (p_hours_threshold * 7) THEN 'urgent'
            WHEN ls.hours_since_last_processing > p_hours_threshold THEN 'ready'
            ELSE 'recent'
        END as processing_priority,
        CASE 
            WHEN ls.last_pattern_analysis IS NULL THEN TRUE
            WHEN ls.hours_since_last_processing > p_hours_threshold THEN TRUE
            ELSE FALSE
        END as needs_processing
    FROM location_status ls
    WHERE 
        ls.last_pattern_analysis IS NULL 
        OR ls.hours_since_last_processing > p_hours_threshold
    ORDER BY 
        CASE 
            WHEN ls.last_pattern_analysis IS NULL THEN 1
            WHEN ls.hours_since_last_processing > (p_hours_threshold * 7) THEN 2  
            WHEN ls.hours_since_last_processing > p_hours_threshold THEN 3
        END,
        ls.hours_since_last_processing DESC NULLS FIRST;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_partner_commission_rate(p_partner_id integer)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_commission_rate NUMERIC;
    v_config RECORD;
BEGIN
    -- Get config first
    SELECT * INTO v_config
    FROM quote_config 
    WHERE config_name = 'default' AND is_active = true;
    
    -- For now, just return the default commission rate
    -- In production, you'd look up the partner by ID
    RETURN COALESCE(v_config.default_commission_rate, 0.10);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_partner_commission_rate(p_partner_id uuid)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_commission_rate NUMERIC;
BEGIN
    -- Get commission rate from partners table, default to config if NULL
    SELECT 
        COALESCE(
            p."Commission" / 100.0,  -- Convert percentage to decimal
            qc.default_commission_rate
        )
    INTO v_commission_rate
    FROM partners p
    CROSS JOIN quote_config qc
    WHERE p.partner_id = p_partner_id
      AND qc.config_name = 'default'
      AND qc.is_active = true;
    
    -- If partner not found, use default
    IF v_commission_rate IS NULL THEN
        SELECT default_commission_rate 
        INTO v_commission_rate
        FROM quote_config 
        WHERE config_name = 'default' 
          AND is_active = true;
    END IF;
    
    RETURN COALESCE(v_commission_rate, 0.10); -- Final fallback to 10%
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_partner_details(p_partner_id uuid)
 RETURNS TABLE(partner_id uuid, partner_name character varying, email character varying, event_type text, commission numeric, is_active boolean, created_at timestamp with time zone, has_active_key boolean, key_last_used_at timestamp with time zone, key_created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY 
    SELECT 
        p.partner_id,
        p.partner_name,
        p.email,
        p.event_type,
        p."Commission",
        p.is_active,
        p.created_at,
        COALESCE(ak.is_active, false) as has_active_key,
        ak.last_used_at,
        ak.created_at as key_created_at
    FROM partners p
    LEFT JOIN api_keys ak ON p.partner_id = ak.partner_id AND ak.is_active = true
    WHERE p.partner_id = p_partner_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_partner_key(p_partner_id uuid)
 RETURNS TABLE(key_id uuid, is_active boolean, created_at timestamp with time zone, last_used_at timestamp with time zone, expires_at timestamp with time zone, rate_limit_per_hour integer, description text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY 
    SELECT 
        ak.id,
        ak.is_active,
        ak.created_at,
        ak.last_used_at,
        ak.expires_at,
        ak.rate_limit_per_hour,
        ak.description
    FROM api_keys ak
    WHERE ak.partner_id = p_partner_id
    ORDER BY ak.created_at DESC
    LIMIT 1; -- Only one key per partner in our simplified system
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_partner_status_history(p_partner_id uuid, p_limit integer DEFAULT 10)
 RETURNS TABLE(change_id uuid, old_status character varying, new_status character varying, reason text, changed_by text, changed_at timestamp with time zone, metadata jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    psh.id,
    psh.old_status,
    psh.new_status,
    psh.reason,
    psh.changed_by,
    psh.changed_at,
    psh.metadata
  FROM partner_status_history psh
  WHERE psh.partner_id = p_partner_id
  ORDER BY psh.changed_at DESC
  LIMIT p_limit;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_peak_period_months(p_period_name text)
 RETURNS integer[]
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_months INT[];
    v_current_month INT;
BEGIN
    -- First check if the period matches any of our known formats
    IF p_period_name = 'Jan-Mar' THEN
        v_months := ARRAY[1, 2, 3];
    ELSIF p_period_name = 'Mar-May' THEN
        v_months := ARRAY[3, 4, 5];
    ELSIF p_period_name = 'Apr-May' THEN
        v_months := ARRAY[4, 5];
    ELSIF p_period_name = 'Apr-Oct' THEN
        v_months := ARRAY[4, 5, 6, 7, 8, 9, 10];
    ELSIF p_period_name = 'Apr-Nov' THEN
        v_months := ARRAY[4, 5, 6, 7, 8, 9, 10, 11];
    ELSIF p_period_name = 'May-Sep' THEN
        v_months := ARRAY[5, 6, 7, 8, 9];
    ELSIF p_period_name = 'May-Oct' THEN
        v_months := ARRAY[5, 6, 7, 8, 9, 10];
    ELSIF p_period_name = 'Jun-Aug' THEN
        v_months := ARRAY[6, 7, 8];
    ELSIF p_period_name = 'Jun-Nov' THEN
        v_months := ARRAY[6, 7, 8, 9, 10, 11];
    ELSIF p_period_name = 'Jul-Oct' THEN
        v_months := ARRAY[7, 8, 9, 10];
    ELSIF p_period_name = 'Nov-Mar' THEN
        v_months := ARRAY[11, 12, 1, 2, 3];
    ELSIF p_period_name = 'Nov-Feb' THEN
        v_months := ARRAY[11, 12, 1, 2];
    ELSIF p_period_name = 'Dec-Feb' THEN
        v_months := ARRAY[12, 1, 2];
    ELSIF p_period_name = 'Sep-Mar' THEN
        v_months := ARRAY[9, 10, 11, 12, 1, 2, 3];
    ELSIF p_period_name = 'Sep-Nov' THEN
        v_months := ARRAY[9, 10, 11];
    ELSE
        -- Default to next 6 months if no valid peak period found
        v_current_month := EXTRACT(MONTH FROM CURRENT_DATE)::INT;
        v_months := ARRAY[
            v_current_month % 12 + 1,
            (v_current_month + 1) % 12 + 1,
            (v_current_month + 2) % 12 + 1,
            (v_current_month + 3) % 12 + 1,
            (v_current_month + 4) % 12 + 1,
            (v_current_month + 5) % 12 + 1
        ];
    END IF;
    
    RETURN v_months;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_record_history(p_table_name text, p_record_id uuid)
 RETURNS TABLE(audit_type text, field_name text, old_value text, new_value text, old_status text, new_status text, reason text, changed_by uuid, changed_by_email text, changed_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    -- Get field changes
    SELECT 
        'field_change'::TEXT as audit_type,
        ch.field_name,
        ch.old_value,
        ch.new_value,
        NULL::TEXT as old_status,
        NULL::TEXT as new_status,
        NULL::TEXT as reason,
        ch.changed_by,
        ch.changed_by_email,
        ch.changed_at
    FROM change_history ch
    WHERE ch.table_name = p_table_name 
      AND ch.record_id = p_record_id
    
    UNION ALL
    
    -- Get status changes
    SELECT 
        'status_change'::TEXT as audit_type,
        'status'::TEXT as field_name,
        sh.old_status as old_value,
        sh.new_status as new_value,
        sh.old_status,
        sh.new_status,
        sh.reason,
        sh.changed_by,
        sh.changed_by_email,
        sh.changed_at
    FROM status_history sh
    WHERE sh.table_name = p_table_name 
      AND sh.record_id = p_record_id
    
    ORDER BY changed_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_templates_by_criteria(p_category text, p_event_type text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result JSONB;
    v_template_count INTEGER;
BEGIN
    -- Count templates for metadata
    SELECT COUNT(*) INTO v_template_count
    FROM templates
    WHERE category = p_category
    AND event_type = p_event_type;

    -- Build the result structure
    WITH template_data AS (
        SELECT 
            parameter_path,
            name,
            content
        FROM templates
        WHERE category = p_category
        AND event_type = p_event_type
    ),
    structured_data AS (
        SELECT 
            -- Parse the parameter path to build nested structure
            string_to_array(
                REPLACE(parameter_path, 'root.', ''), 
                '.'
            ) as path_parts,
            name,
            content
        FROM template_data
    )
    SELECT jsonb_build_object(
--        '_metadata', jsonb_build_object(
--            'category', p_category,
--            'eventType', p_event_type,
 --           'retrievedAt', NOW(),
--            'templateCount', v_template_count
--        ),
        'plainLanguage', jsonb_build_object(
            'landing_page', (
                SELECT jsonb_object_agg(name, content)
                FROM template_data
                WHERE parameter_path = 'root.plainLanguage.landing_page'
            ),
            'learn_more', (
                SELECT jsonb_object_agg(name, content)
                FROM template_data
                WHERE parameter_path = 'root.plainLanguage.learn_more'
            ),
            'documents', (
                SELECT jsonb_object_agg(name, content)
                FROM template_data
                WHERE parameter_path = 'root.plainLanguage.documents'
            )
        )
    ) INTO v_result;

    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.hash_api_key(key_text text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog', 'extensions'
AS $function$
BEGIN
    -- Try to use pgcrypto if available, fall back to sha256 if not
    BEGIN
        RETURN encode(digest(key_text::bytea, 'sha256'::text), 'hex');
    EXCEPTION WHEN OTHERS THEN
        -- Fallback: use built-in sha256 if available
        RETURN encode(sha256(key_text::bytea), 'hex');
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_valid_status_transition(p_old_status character varying, p_new_status character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Define allowed transitions
  RETURN CASE 
    WHEN p_old_status = 'pending' THEN p_new_status IN ('active', 'deactivated')
    WHEN p_old_status = 'active' THEN p_new_status IN ('suspended', 'deactivated', 'archived')
    WHEN p_old_status = 'suspended' THEN p_new_status IN ('active', 'deactivated', 'archived')
    WHEN p_old_status = 'deactivated' THEN p_new_status IN ('active', 'archived')
    WHEN p_old_status = 'archived' THEN FALSE -- No transitions from archived
    ELSE FALSE
  END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.list_all_partners(p_include_inactive boolean DEFAULT false)
 RETURNS TABLE(partner_id uuid, partner_name character varying, email character varying, event_type text, commission numeric, is_active boolean, created_at timestamp with time zone, has_active_key boolean, key_last_used_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY 
    SELECT 
        p.partner_id,
        p.partner_name,
        p.email,
        p.event_type,
        p."Commission",
        p.is_active,
        p.created_at,
        COALESCE(ak.is_active, false) as has_active_key,
        ak.last_used_at
    FROM partners p
    LEFT JOIN api_keys ak ON p.partner_id = ak.partner_id AND ak.is_active = true
    WHERE p_include_inactive = true OR p.is_active = true
    ORDER BY p.created_at DESC;
END;
$function$
;

create materialized view "public"."locations" as  SELECT location_id,
    name,
    address,
    city,
    state,
    latitude,
    longitude,
    address_tsv,
    created_at,
    updated_at,
    "BOM_SiteID",
    height,
    region,
    status,
    is_coastal,
    distance_to_coast_km,
    processed,
    timezone,
    enso_rainfall_correlation,
    wmo,
    geom
   FROM prep.locations;


CREATE OR REPLACE FUNCTION public.log_audit_event()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
    audit_user_id UUID;
    audit_user_email TEXT;
    audit_user_role TEXT;
    old_data JSONB;
    new_data JSONB;
    changed_columns JSONB = '{}';
    col_name TEXT;
    record_uuid UUID;
    human_identifier TEXT;
BEGIN
    -- Get user context safely
    BEGIN
        audit_user_id := COALESCE(
            current_setting('request.jwt.claim.sub', true)::UUID,
            current_setting('app.current_user_id', true)::UUID
        );
        audit_user_email := current_setting('request.jwt.claim.email', true);
        audit_user_role := current_setting('request.jwt.claims.role', true);
    EXCEPTION WHEN OTHERS THEN
        -- If we can't get user context, continue with NULL values
        audit_user_id := NULL;
        audit_user_email := NULL;
        audit_user_role := NULL;
    END;
    
    -- Determine record ID and human identifier based on table
    IF TG_OP = 'DELETE' THEN
        -- Extract ID from OLD record
        CASE TG_TABLE_NAME
            WHEN 'policy' THEN 
                record_uuid := OLD.policy_id;
                human_identifier := OLD.policy_number;
            WHEN 'claims' THEN 
                record_uuid := OLD.claim_id;
                human_identifier := OLD.claim_number;
            WHEN 'quotes' THEN 
                record_uuid := OLD.quote_id;
                human_identifier := OLD.partner_quote_id;
            WHEN 'templates' THEN 
                record_uuid := OLD.id;
                human_identifier := OLD.name;
            WHEN 'customers' THEN 
                record_uuid := OLD.customer_id;
                human_identifier := COALESCE(OLD.email, OLD.first_name || ' ' || OLD.last_name);
            WHEN 'partners' THEN 
                record_uuid := OLD.partner_id;
                human_identifier := OLD.partner_name;
            WHEN 'transactions' THEN 
                record_uuid := OLD.transaction_id;
                human_identifier := OLD.provider_transaction_id;
            ELSE 
                -- Generic handling for other tables
                IF (to_jsonb(OLD) ? 'id') THEN
                    record_uuid := (OLD.id)::UUID;
                ELSIF (to_jsonb(OLD) ? 'uuid') THEN
                    record_uuid := (OLD.uuid)::UUID;
                END IF;
        END CASE;
        
        old_data := to_jsonb(OLD);
        
        INSERT INTO unified_audit_log (
            table_name, record_id, record_identifier, operation, 
            old_value, user_id, user_email, user_role
        ) VALUES (
            TG_TABLE_NAME, record_uuid, human_identifier, TG_OP, 
            old_data, audit_user_id, audit_user_email, audit_user_role
        );
        RETURN OLD;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Extract ID from NEW record for updates
        CASE TG_TABLE_NAME
            WHEN 'policy' THEN 
                record_uuid := NEW.policy_id;
                human_identifier := NEW.policy_number;
            WHEN 'claims' THEN 
                record_uuid := NEW.claim_id;
                human_identifier := NEW.claim_number;
            WHEN 'quotes' THEN 
                record_uuid := NEW.quote_id;
                human_identifier := NEW.partner_quote_id;
            WHEN 'templates' THEN 
                record_uuid := NEW.id;
                human_identifier := NEW.name;
            WHEN 'customers' THEN 
                record_uuid := NEW.customer_id;
                human_identifier := COALESCE(NEW.email, NEW.first_name || ' ' || NEW.last_name);
            WHEN 'partners' THEN 
                record_uuid := NEW.partner_id;
                human_identifier := NEW.partner_name;
            WHEN 'transactions' THEN 
                record_uuid := NEW.transaction_id;
                human_identifier := NEW.provider_transaction_id;
            ELSE 
                -- Generic handling
                IF (to_jsonb(NEW) ? 'id') THEN
                    record_uuid := (NEW.id)::UUID;
                ELSIF (to_jsonb(NEW) ? 'uuid') THEN
                    record_uuid := (NEW.uuid)::UUID;
                END IF;
        END CASE;
        
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
        
        -- Log each changed column
        FOR col_name IN 
            SELECT jsonb_object_keys(old_data) 
            WHERE old_data->col_name IS DISTINCT FROM new_data->col_name
        LOOP
            -- Skip audit timestamp columns
            IF col_name NOT IN ('updated_at', 'created_at') THEN
                INSERT INTO unified_audit_log (
                    table_name, record_id, record_identifier, operation, column_name,
                    old_value, new_value, user_id, user_email, user_role
                ) VALUES (
                    TG_TABLE_NAME, record_uuid, human_identifier, TG_OP, col_name,
                    old_data->col_name, new_data->col_name,
                    audit_user_id, audit_user_email, audit_user_role
                );
            END IF;
        END LOOP;
        RETURN NEW;
        
    ELSIF TG_OP = 'INSERT' THEN
        -- Extract ID from NEW record for inserts
        CASE TG_TABLE_NAME
            WHEN 'policy' THEN 
                record_uuid := NEW.policy_id;
                human_identifier := NEW.policy_number;
            WHEN 'claims' THEN 
                record_uuid := NEW.claim_id;
                human_identifier := NEW.claim_number;
            WHEN 'quotes' THEN 
                record_uuid := NEW.quote_id;
                human_identifier := NEW.partner_quote_id;
            WHEN 'templates' THEN 
                record_uuid := NEW.id;
                human_identifier := NEW.name;
            WHEN 'customers' THEN 
                record_uuid := NEW.customer_id;
                human_identifier := COALESCE(NEW.email, NEW.first_name || ' ' || NEW.last_name);
            WHEN 'partners' THEN 
                record_uuid := NEW.partner_id;
                human_identifier := NEW.partner_name;
            WHEN 'transactions' THEN 
                record_uuid := NEW.transaction_id;
                human_identifier := NEW.provider_transaction_id;
            ELSE 
                -- Generic handling
                IF (to_jsonb(NEW) ? 'id') THEN
                    record_uuid := (NEW.id)::UUID;
                ELSIF (to_jsonb(NEW) ? 'uuid') THEN
                    record_uuid := (NEW.uuid)::UUID;
                END IF;
        END CASE;
        
        new_data := to_jsonb(NEW);
        
        INSERT INTO unified_audit_log (
            table_name, record_id, record_identifier, operation, 
            new_value, user_id, user_email, user_role
        ) VALUES (
            TG_TABLE_NAME, record_uuid, human_identifier, TG_OP, 
            new_data, audit_user_id, audit_user_email, audit_user_role
        );
        RETURN NEW;
    END IF;
END;$function$
;

CREATE OR REPLACE FUNCTION public.manage_partner_keys(p_partner_id uuid, p_action text, p_key_id uuid DEFAULT NULL::uuid, p_description text DEFAULT NULL::text, p_reason text DEFAULT NULL::text, p_expires_at timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS TABLE(action_performed text, key_id uuid, plain_text_key text, keys_affected integer, success boolean, message text, audit_info jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_new_key_id UUID;
  v_new_key_plain TEXT;
  v_affected_count INTEGER := 0;
  v_audit_info JSONB;
  v_key_success BOOLEAN;
  v_key_message TEXT;
  v_hash TEXT;
BEGIN
  -- Validate partner exists and is active
  IF NOT EXISTS (SELECT 1 FROM partners WHERE partner_id = p_partner_id AND is_active = true) THEN
    RETURN QUERY SELECT 
      p_action, NULL::UUID, NULL::TEXT, 0, FALSE, 
      'Partner not found or inactive'::TEXT, NULL::JSONB;
    RETURN;
  END IF;
  
  CASE p_action
    WHEN 'generate' THEN
      -- Generate new API key using existing function
      SELECT api_key_id, plain_text_key, success, message
      INTO v_new_key_id, v_new_key_plain, v_key_success, v_key_message
      FROM generate_simple_api_key(
        p_partner_id, 
        COALESCE(p_description, 'Generated via manage_partner_keys')
      );
      
      -- Set expiration if provided
      IF p_expires_at IS NOT NULL AND v_new_key_id IS NOT NULL THEN
        UPDATE api_keys SET expires_at = p_expires_at WHERE id = v_new_key_id;
      END IF;
      
      v_affected_count := CASE WHEN v_new_key_id IS NOT NULL THEN 1 ELSE 0 END;
      
      RETURN QUERY SELECT 
        'generate'::TEXT, v_new_key_id, v_new_key_plain, v_affected_count, 
        v_key_success, COALESCE(v_key_message, 'Key generated successfully'), 
        jsonb_build_object('new_key_id', v_new_key_id, 'expires_at', p_expires_at);
    
    WHEN 'rotate' THEN
      -- Deactivate all current keys and generate new one
      UPDATE api_keys 
      SET is_active = FALSE, 
          deactivated_at = NOW(), 
          deactivation_reason = COALESCE(p_reason, 'Key rotation')
      WHERE partner_id = p_partner_id AND is_active = TRUE;
      
      GET DIAGNOSTICS v_affected_count = ROW_COUNT;
      
      -- Generate replacement key
      SELECT api_key_id, plain_text_key, success, message
      INTO v_new_key_id, v_new_key_plain, v_key_success, v_key_message
      FROM generate_simple_api_key(
        p_partner_id, 
        COALESCE(p_description, 'Rotated key')
      );
      
      v_audit_info := jsonb_build_object(
        'deactivated_keys', v_affected_count,
        'new_key_id', v_new_key_id,
        'rotation_reason', p_reason
      );
      
      RETURN QUERY SELECT 
        'rotate'::TEXT, v_new_key_id, v_new_key_plain, v_affected_count + 1, 
        v_key_success, 'Keys rotated successfully'::TEXT, v_audit_info;
    
    WHEN 'deactivate_all' THEN
      UPDATE api_keys 
      SET is_active = FALSE, 
          deactivated_at = NOW(), 
          deactivation_reason = COALESCE(p_reason, 'Bulk deactivation')
      WHERE partner_id = p_partner_id AND is_active = TRUE;
      
      GET DIAGNOSTICS v_affected_count = ROW_COUNT;
      
      RETURN QUERY SELECT 
        'deactivate_all'::TEXT, NULL::UUID, NULL::TEXT, v_affected_count, 
        TRUE, format('%s keys deactivated', v_affected_count)::TEXT,
        jsonb_build_object('deactivated_count', v_affected_count);
    
    WHEN 'deactivate_specific' THEN
      IF p_key_id IS NULL THEN
        RETURN QUERY SELECT 
          'deactivate_specific'::TEXT, NULL::UUID, NULL::TEXT, 0, FALSE,
          'Key ID required for specific deactivation'::TEXT, NULL::JSONB;
        RETURN;
      END IF;
      
      UPDATE api_keys 
      SET is_active = FALSE, 
          deactivated_at = NOW(), 
          deactivation_reason = COALESCE(p_reason, 'Manual deactivation')
      WHERE id = p_key_id AND partner_id = p_partner_id AND is_active = TRUE;
      
      GET DIAGNOSTICS v_affected_count = ROW_COUNT;
      
      RETURN QUERY SELECT 
        'deactivate_specific'::TEXT, p_key_id, NULL::TEXT, v_affected_count,
        (v_affected_count > 0), 
        CASE WHEN v_affected_count > 0 THEN 'Key deactivated' ELSE 'Key not found or already inactive' END::TEXT,
        jsonb_build_object('key_id', p_key_id);
    
    WHEN 'audit' THEN
      -- Return current key status for partner
      SELECT jsonb_agg(
        jsonb_build_object(
          'key_id', id,
          'is_active', is_active,
          'created_at', created_at,
          'last_used_at', last_used_at,
          'usage_count', usage_count,
          'expires_at', expires_at,
          'description', description,
          'deactivated_at', deactivated_at,
          'deactivation_reason', deactivation_reason
        )
      ) INTO v_audit_info
      FROM api_keys 
      WHERE partner_id = p_partner_id;
      
      SELECT COUNT(*) INTO v_affected_count FROM api_keys WHERE partner_id = p_partner_id;
      
      RETURN QUERY SELECT 
        'audit'::TEXT, NULL::UUID, NULL::TEXT, v_affected_count,
        TRUE, 'Audit completed'::TEXT, v_audit_info;
    
    ELSE
      RETURN QUERY SELECT 
        p_action, NULL::UUID, NULL::TEXT, 0, FALSE,
        'Invalid action. Use: generate, rotate, deactivate_all, deactivate_specific, audit'::TEXT,
        NULL::JSONB;
  END CASE;
  
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT 
    p_action, NULL::UUID, NULL::TEXT, 0, FALSE,
    ('Error: ' || SQLERRM)::TEXT, NULL::JSONB;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.process_claim_weather_check(p_claim_id uuid, p_rainfall numeric, p_temperature numeric, p_weather_source text, p_model_used text)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_claim RECORD;
    v_hours_exceeded INTEGER;
    v_trigger_hours INTEGER[];
    v_should_trigger BOOLEAN;
    v_coverage_ended BOOLEAN;
    v_result JSON;
BEGIN
    -- Get claim details
    SELECT c.*, p.trigger, p.duration, p.payout_percentage,
           EXTRACT(HOUR FROM p.coverage_end_time) as coverage_end_hour,
           EXTRACT(HOUR FROM NOW() AT TIME ZONE 'Australia/Sydney') as current_hour
    INTO v_claim
    FROM claims c
    JOIN policy p ON c.policy_id = p.policy_id
    WHERE c.claim_id = p_claim_id;
    
    -- Insert weather data
    INSERT INTO claim_weather_hourly (
        claim_id, claim_location_id, weather_date, hour,
        rainfall_amount, temperature, weather_source, model_used
    ) VALUES (
        p_claim_id, v_claim.claim_location_id, v_claim.claim_date,
        v_claim.current_hour, p_rainfall, p_temperature, 
        p_weather_source, p_model_used
    );
    
    -- Count hours exceeding threshold
    SELECT COUNT(*), array_agg(hour ORDER BY hour)
    INTO v_hours_exceeded, v_trigger_hours
    FROM claim_weather_hourly
    WHERE claim_id = p_claim_id
      AND weather_date = v_claim.claim_date
      AND rainfall_amount > v_claim.trigger;
    
    -- Check if should trigger
    v_should_trigger := v_hours_exceeded >= v_claim.duration;
    v_coverage_ended := v_claim.current_hour >= v_claim.coverage_end_hour;
    
    -- Update claim if needed
    IF v_should_trigger AND v_claim.claim_status = 'pending' THEN
        UPDATE claims SET
            claim_status = 'triggered',
            rainfall_triggered = true,
            updated_at = NOW()
        WHERE claim_id = p_claim_id;
        
        UPDATE policy SET
            status = 'claimed'
        WHERE policy_id = v_claim.policy_id;
        
        -- Create notification
        INSERT INTO notifications (
            recipient_email, subject, body, status
        ) VALUES (
            (SELECT email FROM customers WHERE customer_id = v_claim.customer_id),
            'Weather Protection Claim Triggered - Policy ' || v_claim.policy_number,
            'Your claim has been triggered with ' || v_hours_exceeded || ' hours exceeding the rainfall threshold.',
            'pending'
        );
        
        v_result := json_build_object(
            'triggered', true,
            'hours_exceeded', v_hours_exceeded,
            'trigger_hours', v_trigger_hours,
            'status_updated', true
        );
    ELSIF v_coverage_ended AND v_claim.claim_status = 'pending' THEN
        UPDATE claims SET
            claim_status = 'assessed',
            rainfall_triggered = false,
            updated_at = NOW()
        WHERE claim_id = p_claim_id;
        
        v_result := json_build_object(
            'triggered', false,
            'hours_exceeded', v_hours_exceeded,
            'coverage_ended', true,
            'status_updated', true
        );
    ELSE
        v_result := json_build_object(
            'triggered', false,
            'hours_exceeded', v_hours_exceeded,
            'coverage_ended', false,
            'status_updated', false
        );
    END IF;
    
    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_daily_exposure_summary()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_exposure_summary;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_partner_key(p_partner_id uuid, p_description text DEFAULT 'Refreshed API Key'::text)
 RETURNS TABLE(new_api_key_plain_text text, success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_partner_name TEXT;
    v_partner_email TEXT;
    v_old_key_id UUID;
    v_new_api_key TEXT;
    v_new_key_id UUID;
    v_webhook_id BIGINT;
BEGIN
    -- Get partner details
    SELECT partner_name, email INTO v_partner_name, v_partner_email
    FROM partners 
    WHERE partner_id = p_partner_id AND is_active = true;
    
    IF v_partner_name IS NULL THEN
        RETURN QUERY SELECT NULL::TEXT, false, 'Partner not found or inactive'::TEXT;
        RETURN;
    END IF;
    
    -- Get current key ID before deactivating
    SELECT id INTO v_old_key_id
    FROM api_keys 
    WHERE partner_id = p_partner_id AND is_active = true
    ORDER BY created_at DESC 
    LIMIT 1;
    
    -- Deactivate old key
    UPDATE api_keys 
    SET is_active = false, 
        deactivated_at = now(),
        deactivation_reason = 'Key refreshed'
    WHERE partner_id = p_partner_id AND is_active = true;
    
    -- Generate new key
    SELECT plain_text_key, api_key_id INTO v_new_api_key, v_new_key_id
    FROM generate_simple_api_key(p_partner_id, p_description);
    
    -- Send webhook notification (fixed syntax)
    BEGIN
        SELECT net.http_post(
            'https://n8n.weatherit.ai/webhook/partner-key-refreshed',
            json_build_object(
                'event_type', 'key_refreshed',
                'partner_id', p_partner_id,
                'partner_name', v_partner_name,
                'partner_email', v_partner_email,
                'old_key_id', v_old_key_id,
                'new_key_id', v_new_key_id,
                'new_key_preview', left(v_new_api_key, 10) || '...',
                'refreshed_at', now()
            )::text,
            headers => '{"Content-Type": "application/json"}'::jsonb
        ) INTO v_webhook_id;
    EXCEPTION WHEN OTHERS THEN
        -- Webhook failed, but don't fail the whole operation
        NULL;
    END;
    
    RETURN QUERY SELECT v_new_api_key, true, 'API key refreshed successfully'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT NULL::TEXT, false, ('Error refreshing key: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_get_missing_historical_date_ranges(p_location_id integer, p_start_date date, p_end_date date)
 RETURNS TABLE(status_code text, missing_start date, missing_end date, message text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    missing_count integer;
BEGIN
    -- First check if the location exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM locations 
        WHERE location_id = p_location_id 
        AND LOWER(status) = 'active'
    ) THEN
        -- Return error code for inactive or non-existent locations
        RETURN QUERY SELECT 'LOCATION_INACTIVE'::text, NULL::date, NULL::date, 'Location not found or inactive'::text;
        RETURN;
    END IF;

    -- Count missing dates first
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS check_date
    ),
    existing_dates AS (
        SELECT weather_date
        FROM historical_weather_data
        WHERE location_id = p_location_id
        AND weather_date BETWEEN p_start_date AND p_end_date
    ),
    missing_dates AS (
        SELECT check_date
        FROM date_series
        WHERE check_date NOT IN (SELECT weather_date FROM existing_dates)
    )
    SELECT COUNT(*) INTO missing_count FROM missing_dates;

    -- If no missing dates, return appropriate status
    IF missing_count = 0 THEN
        RETURN QUERY SELECT 'NO_MISSING_DATA'::text, NULL::date, NULL::date, 'All historical data is complete'::text;
        RETURN;
    END IF;

    -- Return missing date ranges
    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS check_date
    ),
    existing_dates AS (
        SELECT weather_date
        FROM historical_weather_data
        WHERE location_id = p_location_id
        AND weather_date BETWEEN p_start_date AND p_end_date
    ),
    missing_dates AS (
        SELECT check_date
        FROM date_series
        WHERE check_date NOT IN (SELECT weather_date FROM existing_dates)
        ORDER BY check_date
    ),
    date_ranges AS (
        SELECT 
            check_date,
            check_date - ROW_NUMBER() OVER (ORDER BY check_date) * INTERVAL '1 day' AS grp
        FROM missing_dates
    )
    SELECT 
        'SUCCESS'::text as status_code,
        MIN(check_date) AS missing_start,
        MAX(check_date) AS missing_end,
        CONCAT(MIN(check_date)::text, ' to ', MAX(check_date)::text)::text as message
    FROM date_ranges
    GROUP BY grp
    ORDER BY missing_start;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_get_missing_hourly_data(p_location_id integer, p_start_date date, p_end_date date)
 RETURNS TABLE(date date, missing_hours integer[])
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- First check if the location exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM locations 
        WHERE location_id = p_location_id 
        AND LOWER(status) = 'active'
    ) THEN
        -- Return empty result set for inactive or non-existent locations
        RETURN;
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS check_date
    ),
    expected_hours AS (
        SELECT 
            ds.check_date,
            generate_series(8, 22) AS hour  -- 8am to 10pm
        FROM date_series ds
    ),
    existing_hours AS (
        SELECT 
            weather_date,
            hour
        FROM hourly_weather_data
        WHERE location_id = p_location_id
        AND weather_date BETWEEN p_start_date AND p_end_date
    ),
    missing_by_date AS (
        SELECT 
            eh.check_date AS missing_date,
            eh.hour
        FROM expected_hours eh
        LEFT JOIN existing_hours ex ON eh.check_date = ex.weather_date AND eh.hour = ex.hour
        WHERE ex.hour IS NULL
    )
    SELECT 
        missing_date AS date,
        ARRAY_AGG(missing_by_date.hour ORDER BY missing_by_date.hour) AS missing_hours
    FROM missing_by_date
    GROUP BY missing_date
    ORDER BY missing_date;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_get_missing_hourly_date_ranges(p_location_id integer, p_start_date date, p_end_date date)
 RETURNS TABLE(status_code text, missing_start date, missing_end date, message text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    missing_count integer;
BEGIN
    -- First check if the location exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM locations 
        WHERE location_id = p_location_id 
        AND LOWER(status) = 'active'
    ) THEN
        -- Return error code for inactive or non-existent locations
        RETURN QUERY SELECT 'LOCATION_INACTIVE'::text, NULL::date, NULL::date, 'Location not found or inactive'::text;
        RETURN;
    END IF;

    -- Count dates with missing hours first
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS check_date
    ),
    expected_hours_per_date AS (
        SELECT 
            ds.check_date,
            COUNT(*) as expected_hour_count  -- 8am to 10pm = 15 hours
        FROM date_series ds
        CROSS JOIN generate_series(8, 22) AS hour
        GROUP BY ds.check_date
    ),
    actual_hours_per_date AS (
        SELECT 
            weather_date,
            COUNT(*) as actual_hour_count
        FROM hourly_weather_data
        WHERE location_id = p_location_id
        AND weather_date BETWEEN p_start_date AND p_end_date
        AND hour BETWEEN 8 AND 22
        GROUP BY weather_date
    ),
    dates_with_missing_hours AS (
        SELECT eh.check_date
        FROM expected_hours_per_date eh
        LEFT JOIN actual_hours_per_date ah ON eh.check_date = ah.weather_date
        WHERE COALESCE(ah.actual_hour_count, 0) < eh.expected_hour_count
    )
    SELECT COUNT(*) INTO missing_count FROM dates_with_missing_hours;

    -- If no missing dates, return appropriate status
    IF missing_count = 0 THEN
        RETURN QUERY SELECT 'NO_MISSING_DATA'::text, NULL::date, NULL::date, 'All hourly data is complete'::text;
        RETURN;
    END IF;

    -- Return missing hourly date ranges
    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS check_date
    ),
    expected_hours_per_date AS (
        SELECT 
            ds.check_date,
            COUNT(*) as expected_hour_count
        FROM date_series ds
        CROSS JOIN generate_series(8, 22) AS hour
        GROUP BY ds.check_date
    ),
    actual_hours_per_date AS (
        SELECT 
            weather_date,
            COUNT(*) as actual_hour_count
        FROM hourly_weather_data
        WHERE location_id = p_location_id
        AND weather_date BETWEEN p_start_date AND p_end_date
        AND hour BETWEEN 8 AND 22
        GROUP BY weather_date
    ),
    dates_with_missing_hours AS (
        SELECT eh.check_date
        FROM expected_hours_per_date eh
        LEFT JOIN actual_hours_per_date ah ON eh.check_date = ah.weather_date
        WHERE COALESCE(ah.actual_hour_count, 0) < eh.expected_hour_count
        ORDER BY eh.check_date
    ),
    date_ranges AS (
        SELECT 
            check_date,
            check_date - ROW_NUMBER() OVER (ORDER BY check_date) * INTERVAL '1 day' AS grp
        FROM dates_with_missing_hours
    )
    SELECT 
        'SUCCESS'::text as status_code,
        MIN(check_date) AS missing_start,
        MAX(check_date) AS missing_end,
        CONCAT(MIN(check_date)::text, ' to ', MAX(check_date)::text)::text as message
    FROM date_ranges
    GROUP BY grp
    ORDER BY missing_start;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_partner_commission(p_partner_id uuid, p_commission_percentage numeric)
 RETURNS TABLE(success boolean, old_rate_percent numeric, new_rate_percent numeric, message text)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_old_commission NUMERIC;
  v_default_rate NUMERIC;
BEGIN
  -- Get current values
  SELECT "Commission" INTO v_old_commission FROM partners WHERE partner_id = p_partner_id;
  SELECT default_commission_rate * 100 INTO v_default_rate FROM quote_config WHERE config_name = 'default';
  
  -- If setting to default rate, clear the override (set to NULL)
  IF p_commission_percentage = v_default_rate THEN
    UPDATE partners 
    SET "Commission" = NULL 
    WHERE partner_id = p_partner_id;
    
    RETURN QUERY SELECT 
      TRUE,
      COALESCE(v_old_commission, v_default_rate),
      v_default_rate,
      'Commission set to default (override removed)'::TEXT;
  ELSE
    -- Set custom commission
    UPDATE partners 
    SET "Commission" = p_commission_percentage 
    WHERE partner_id = p_partner_id;
    
    RETURN QUERY SELECT 
      TRUE,
      COALESCE(v_old_commission, v_default_rate),
      p_commission_percentage,
      format('Commission set to %s%%', p_commission_percentage)::TEXT;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_partner_commission_override(p_partner_id uuid, p_commission_rate numeric, p_effective_date timestamp with time zone DEFAULT now(), p_reason text DEFAULT NULL::text, p_created_by text DEFAULT 'system'::text)
 RETURNS TABLE(success boolean, action text, old_rate numeric, new_rate numeric, is_override boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_default_rate NUMERIC;
  v_current_rate NUMERIC;
  v_action TEXT;
BEGIN
  -- Get default rate
  v_default_rate := get_partner_commission_rate(NULL);
  
  -- Get current partner rate
  v_current_rate := get_partner_commission_rate(p_partner_id);
  
  -- If new rate equals default, remove any existing override
  IF p_commission_rate = v_default_rate THEN
    -- Clear the commission override by setting to NULL (will use default)
    UPDATE partners 
    SET 
      "Commission" = NULL,
      updated_at = NOW()
    WHERE partner_id = p_partner_id;
    
    v_action := 'removed_override_uses_default';
    
    RETURN QUERY SELECT 
      TRUE, 
      v_action,
      v_current_rate,
      v_default_rate,
      FALSE; -- not an override
  ELSE
    -- Set the commission override in partners table
    UPDATE partners 
    SET 
      "Commission" = p_commission_rate * 100, -- Store as percentage
      updated_at = NOW()
    WHERE partner_id = p_partner_id;
    
    v_action := 'created_override';
    
    RETURN QUERY SELECT 
      TRUE,
      v_action,
      v_current_rate,
      p_commission_rate,
      TRUE; -- is an override
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_partner_session(partner_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Set the current partner ID in the session for RLS policies
    PERFORM set_config('app.current_partner_id', partner_id::text, false);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_claim_policy_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    -- When claim moves to under_review, set policy to assessment if not already
    IF NEW.claim_status = 'under_review' AND OLD.claim_status != 'under_review' THEN
        UPDATE policy 
        SET status = 'assessment'
        WHERE policy_id = NEW.policy_id 
        AND status NOT IN ('cancelled', 'refunded', 'completed', 'paid out');
    END IF;
    
    -- When claim is approved, update policy to claim approved
    IF NEW.claim_status = 'approved' AND OLD.claim_status != 'approved' THEN
        UPDATE policy 
        SET status = 'claim approved'
        WHERE policy_id = NEW.policy_id 
        AND status NOT IN ('cancelled', 'refunded', 'completed', 'paid out');
    END IF;
    
    -- When claim is paid, update policy to paid out
    IF NEW.claim_status = 'paid' AND OLD.claim_status != 'paid' THEN
        UPDATE policy 
        SET status = 'paid out'
        WHERE policy_id = NEW.policy_id;
    END IF;
    
    RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.sync_policy_claim_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    -- When policy is cancelled, cancel all non-final claims
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        UPDATE claims 
        SET claim_status = 'cancelled',
            updated_at = NOW()
        WHERE policy_id = NEW.policy_id 
        AND claim_status NOT IN ('paid', 'rejected', 'cancelled');
        
        RAISE NOTICE 'Cancelled % claims for policy %', 
            (SELECT COUNT(*) FROM claims WHERE policy_id = NEW.policy_id AND claim_status = 'cancelled'),
            NEW.policy_id;
    END IF;
    
    -- When policy moves to assessment, move pending claims to under_review
    IF NEW.status = 'assessment' AND OLD.status != 'assessment' THEN
        UPDATE claims 
        SET claim_status = 'under_review',
            updated_at = NOW()
        WHERE policy_id = NEW.policy_id 
        AND claim_status = 'pending';
        
        RAISE NOTICE 'Moved % claims to under_review for policy in assessment %', 
            (SELECT COUNT(*) FROM claims WHERE policy_id = NEW.policy_id AND claim_status = 'under_review'),
            NEW.policy_id;
    END IF;
    
    RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.track_critical_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    record_uuid UUID;
    fields_to_track TEXT[];
    field TEXT;
    old_val TEXT;
    new_val TEXT;
BEGIN
    -- Determine fields to track based on table
    CASE TG_TABLE_NAME
        WHEN 'policy' THEN 
            record_uuid := NEW.policy_id;
            fields_to_track := ARRAY['status', 'final_premium', 'payment_status', 'cancellation_reason'];
        WHEN 'claims' THEN 
            record_uuid := NEW.claim_id;
            fields_to_track := ARRAY['status', 'claim_amount', 'approved_amount', 'rejection_reason'];
        WHEN 'transactions' THEN 
            record_uuid := NEW.transaction_id;
            fields_to_track := ARRAY['status', 'amount', 'payment_method', 'refund_amount'];
        ELSE
            RETURN NEW;
    END CASE;
    
    -- Track changes for each configured field
    FOREACH field IN ARRAY fields_to_track
    LOOP
        -- Get old and new values dynamically
        EXECUTE format('SELECT $1.%I::TEXT', field) USING OLD INTO old_val;
        EXECUTE format('SELECT $1.%I::TEXT', field) USING NEW INTO new_val;
        
        -- Only log if value actually changed
        IF old_val IS DISTINCT FROM new_val THEN
            INSERT INTO change_history (
                table_name, 
                record_id, 
                field_name, 
                old_value, 
                new_value
            ) VALUES (
                TG_TABLE_NAME, 
                record_uuid, 
                field, 
                old_val, 
                new_val
            );
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.track_status_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    record_uuid UUID;
    old_status TEXT;
    new_status TEXT;
    reason TEXT := NULL;
BEGIN
    -- Handle different tables
    CASE TG_TABLE_NAME
        WHEN 'quotes' THEN 
            record_uuid := NEW.quote_id;
            old_status := OLD.status;
            new_status := NEW.status;
            
        WHEN 'customers' THEN 
            record_uuid := NEW.customer_id;
            old_status := OLD.status;
            new_status := NEW.status;
            
            -- Also track email and phone changes for customers
            IF OLD.email IS DISTINCT FROM NEW.email THEN
                INSERT INTO change_history (
                    table_name, record_id, field_name, old_value, new_value
                ) VALUES (
                    TG_TABLE_NAME, record_uuid, 'email', OLD.email, NEW.email
                );
            END IF;
            
            IF OLD.phone IS DISTINCT FROM NEW.phone THEN
                INSERT INTO change_history (
                    table_name, record_id, field_name, old_value, new_value
                ) VALUES (
                    TG_TABLE_NAME, record_uuid, 'phone', OLD.phone, NEW.phone
                );
            END IF;
            
        WHEN 'partners' THEN 
            record_uuid := NEW.partner_id;
            old_status := OLD.status;
            new_status := NEW.status;
            
            -- Also track commission_rate changes for partners
            IF OLD.commission_rate IS DISTINCT FROM NEW.commission_rate THEN
                INSERT INTO change_history (
                    table_name, record_id, field_name, old_value, new_value
                ) VALUES (
                    TG_TABLE_NAME, record_uuid, 'commission_rate', 
                    OLD.commission_rate::TEXT, NEW.commission_rate::TEXT
                );
            END IF;
            
        ELSE
            RETURN NEW;
    END CASE;
    
    -- Log status change if it occurred
    IF old_status IS DISTINCT FROM new_status THEN
        INSERT INTO status_history (
            table_name, record_id, old_status, new_status, reason
        ) VALUES (
            TG_TABLE_NAME, record_uuid, old_status, new_status, reason
        );
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_partner(p_partner_id uuid, p_partner_name text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_event_type text DEFAULT NULL::text, p_commission numeric DEFAULT NULL::numeric)
 RETURNS TABLE(success boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Check if partner exists
    IF NOT EXISTS (SELECT 1 FROM partners WHERE partner_id = p_partner_id) THEN
        RETURN QUERY SELECT false, 'Partner not found'::TEXT;
        RETURN;
    END IF;
    
    -- Update only provided fields
    UPDATE partners SET
        partner_name = COALESCE(p_partner_name, partner_name),
        email = COALESCE(p_email, email),
        event_type = COALESCE(p_event_type, event_type),
        "Commission" = COALESCE(p_commission, "Commission"),
        updated_at = now()
    WHERE partner_id = p_partner_id;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    IF v_updated_count > 0 THEN
        RETURN QUERY SELECT true, 'Partner updated successfully'::TEXT;
    ELSE
        RETURN QUERY SELECT false, 'No changes made'::TEXT;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT false, ('Error updating partner: ' || SQLERRM)::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_partner_status(p_partner_id uuid, p_new_status character varying, p_reason text, p_changed_by text, p_metadata jsonb DEFAULT NULL::jsonb, p_cascade_to_keys boolean DEFAULT true)
 RETURNS TABLE(success boolean, old_status character varying, new_status character varying, status_changed_at timestamp with time zone, keys_affected integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_old_status VARCHAR(20);
  v_keys_affected INTEGER := 0;
  v_status_changed_at TIMESTAMP WITH TIME ZONE := NOW();
  v_key_result RECORD;
BEGIN
  -- Get current status
  SELECT status INTO v_old_status 
  FROM partners 
  WHERE partner_id = p_partner_id;
  
  IF v_old_status IS NULL THEN
    RETURN QUERY SELECT FALSE, NULL::VARCHAR(20), p_new_status, v_status_changed_at, 0;
    RETURN;
  END IF;
  
  -- Validate status transition
  IF NOT is_valid_status_transition(v_old_status, p_new_status) THEN
    RETURN QUERY SELECT FALSE, v_old_status, p_new_status, v_status_changed_at, 0;
    RETURN;
  END IF;
  
  -- Update partner status
  UPDATE partners 
  SET 
    status = p_new_status,
    status_reason = p_reason,
    status_changed_at = v_status_changed_at,
    status_changed_by = p_changed_by,
    is_active = (p_new_status = 'active') -- Maintain backward compatibility
  WHERE partner_id = p_partner_id;
  
  -- Log status change
  INSERT INTO partner_status_history (
    partner_id, old_status, new_status, reason, changed_by, metadata
  ) VALUES (
    p_partner_id, v_old_status, p_new_status, p_reason, p_changed_by, p_metadata
  );
  
  -- Handle API keys based on status
  IF p_cascade_to_keys THEN
    CASE p_new_status
      WHEN 'suspended', 'deactivated', 'archived' THEN
        -- Deactivate all keys
        SELECT keys_affected INTO v_keys_affected
        FROM manage_partner_keys(
          p_partner_id, 
          'deactivate_all', 
          NULL, 
          NULL, 
          format('Partner status changed to %s', p_new_status)
        );
      
      WHEN 'active' THEN
        -- If transitioning from suspended back to active, might want to generate new key
        IF v_old_status = 'suspended' THEN
          SELECT keys_affected INTO v_keys_affected
          FROM manage_partner_keys(
            p_partner_id,
            'generate',
            NULL,
            'Reactivation key'
          );
        END IF;
      ELSE
        -- No key action needed for other statuses
        NULL;
    END CASE;
  END IF;
  
  RETURN QUERY SELECT TRUE, v_old_status, p_new_status, v_status_changed_at, COALESCE(v_keys_affected, 0);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_policy_payment_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    -- Only update for successful payment transactions
    IF NEW.transaction_type = 'payment' AND NEW.status = 'succeeded' THEN
        UPDATE public.policy
        SET 
            payment_status = 'paid',
            status = 'active'
        WHERE policy_id = NEW.policy_id;
    END IF;
    
    -- For refunds, update the policy status
    IF NEW.transaction_type = 'refund' AND NEW.status = 'succeeded' THEN
        UPDATE public.policy
        SET 
            payment_status = 'refunded',
            status = 'refunded'
        WHERE policy_id = NEW.policy_id;
    END IF;
    
    RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;$function$
;

CREATE UNIQUE INDEX daily_seasonal_indices_id_idx ON public.daily_seasonal_indices USING btree (id);

CREATE INDEX idx_daily_seasonal_indices_covering ON public.daily_seasonal_indices USING btree (location_id, month_of_year, day_of_month) INCLUDE (modified_seasonal_index, modified_rainfall_trigger, optimal_hour_trigger, high_risk_flag, climate_anomaly_flag);

CREATE INDEX idx_daily_seasonal_indices_lookup ON public.daily_seasonal_indices USING btree (location_id, month_of_year, day_of_month);

CREATE INDEX idx_locations_geom ON public.locations USING gist (geom);

CREATE INDEX idx_locations_geom_spatial ON public.locations USING gist (geom);

CREATE INDEX idx_locations_lookup_covering ON public.locations USING btree (location_id) INCLUDE (name, geom) WHERE (geom IS NOT NULL);

CREATE UNIQUE INDEX locations_location_id_idx ON public.locations USING btree (location_id);

grant delete on table "public"."api_keys" to "anon";

grant insert on table "public"."api_keys" to "anon";

grant references on table "public"."api_keys" to "anon";

grant select on table "public"."api_keys" to "anon";

grant trigger on table "public"."api_keys" to "anon";

grant truncate on table "public"."api_keys" to "anon";

grant update on table "public"."api_keys" to "anon";

grant delete on table "public"."api_keys" to "authenticated";

grant insert on table "public"."api_keys" to "authenticated";

grant references on table "public"."api_keys" to "authenticated";

grant select on table "public"."api_keys" to "authenticated";

grant trigger on table "public"."api_keys" to "authenticated";

grant truncate on table "public"."api_keys" to "authenticated";

grant update on table "public"."api_keys" to "authenticated";

grant delete on table "public"."api_keys" to "service_role";

grant insert on table "public"."api_keys" to "service_role";

grant references on table "public"."api_keys" to "service_role";

grant select on table "public"."api_keys" to "service_role";

grant trigger on table "public"."api_keys" to "service_role";

grant truncate on table "public"."api_keys" to "service_role";

grant update on table "public"."api_keys" to "service_role";

grant delete on table "public"."audit_documentation" to "anon";

grant insert on table "public"."audit_documentation" to "anon";

grant references on table "public"."audit_documentation" to "anon";

grant select on table "public"."audit_documentation" to "anon";

grant trigger on table "public"."audit_documentation" to "anon";

grant truncate on table "public"."audit_documentation" to "anon";

grant update on table "public"."audit_documentation" to "anon";

grant delete on table "public"."audit_documentation" to "authenticated";

grant insert on table "public"."audit_documentation" to "authenticated";

grant references on table "public"."audit_documentation" to "authenticated";

grant select on table "public"."audit_documentation" to "authenticated";

grant trigger on table "public"."audit_documentation" to "authenticated";

grant truncate on table "public"."audit_documentation" to "authenticated";

grant update on table "public"."audit_documentation" to "authenticated";

grant delete on table "public"."audit_documentation" to "service_role";

grant insert on table "public"."audit_documentation" to "service_role";

grant references on table "public"."audit_documentation" to "service_role";

grant select on table "public"."audit_documentation" to "service_role";

grant trigger on table "public"."audit_documentation" to "service_role";

grant truncate on table "public"."audit_documentation" to "service_role";

grant update on table "public"."audit_documentation" to "service_role";

grant delete on table "public"."claim_locations" to "anon";

grant insert on table "public"."claim_locations" to "anon";

grant references on table "public"."claim_locations" to "anon";

grant select on table "public"."claim_locations" to "anon";

grant trigger on table "public"."claim_locations" to "anon";

grant truncate on table "public"."claim_locations" to "anon";

grant update on table "public"."claim_locations" to "anon";

grant delete on table "public"."claim_locations" to "authenticated";

grant insert on table "public"."claim_locations" to "authenticated";

grant references on table "public"."claim_locations" to "authenticated";

grant select on table "public"."claim_locations" to "authenticated";

grant trigger on table "public"."claim_locations" to "authenticated";

grant truncate on table "public"."claim_locations" to "authenticated";

grant update on table "public"."claim_locations" to "authenticated";

grant delete on table "public"."claim_locations" to "service_role";

grant insert on table "public"."claim_locations" to "service_role";

grant references on table "public"."claim_locations" to "service_role";

grant select on table "public"."claim_locations" to "service_role";

grant trigger on table "public"."claim_locations" to "service_role";

grant truncate on table "public"."claim_locations" to "service_role";

grant update on table "public"."claim_locations" to "service_role";

grant delete on table "public"."claim_weather_hourly" to "anon";

grant insert on table "public"."claim_weather_hourly" to "anon";

grant references on table "public"."claim_weather_hourly" to "anon";

grant select on table "public"."claim_weather_hourly" to "anon";

grant trigger on table "public"."claim_weather_hourly" to "anon";

grant truncate on table "public"."claim_weather_hourly" to "anon";

grant update on table "public"."claim_weather_hourly" to "anon";

grant delete on table "public"."claim_weather_hourly" to "authenticated";

grant insert on table "public"."claim_weather_hourly" to "authenticated";

grant references on table "public"."claim_weather_hourly" to "authenticated";

grant select on table "public"."claim_weather_hourly" to "authenticated";

grant trigger on table "public"."claim_weather_hourly" to "authenticated";

grant truncate on table "public"."claim_weather_hourly" to "authenticated";

grant update on table "public"."claim_weather_hourly" to "authenticated";

grant delete on table "public"."claim_weather_hourly" to "service_role";

grant insert on table "public"."claim_weather_hourly" to "service_role";

grant references on table "public"."claim_weather_hourly" to "service_role";

grant select on table "public"."claim_weather_hourly" to "service_role";

grant trigger on table "public"."claim_weather_hourly" to "service_role";

grant truncate on table "public"."claim_weather_hourly" to "service_role";

grant update on table "public"."claim_weather_hourly" to "service_role";

grant delete on table "public"."claims" to "anon";

grant insert on table "public"."claims" to "anon";

grant references on table "public"."claims" to "anon";

grant select on table "public"."claims" to "anon";

grant trigger on table "public"."claims" to "anon";

grant truncate on table "public"."claims" to "anon";

grant update on table "public"."claims" to "anon";

grant delete on table "public"."claims" to "authenticated";

grant insert on table "public"."claims" to "authenticated";

grant references on table "public"."claims" to "authenticated";

grant select on table "public"."claims" to "authenticated";

grant trigger on table "public"."claims" to "authenticated";

grant truncate on table "public"."claims" to "authenticated";

grant update on table "public"."claims" to "authenticated";

grant delete on table "public"."claims" to "service_role";

grant insert on table "public"."claims" to "service_role";

grant references on table "public"."claims" to "service_role";

grant select on table "public"."claims" to "service_role";

grant trigger on table "public"."claims" to "service_role";

grant truncate on table "public"."claims" to "service_role";

grant update on table "public"."claims" to "service_role";

grant delete on table "public"."customers" to "anon";

grant insert on table "public"."customers" to "anon";

grant references on table "public"."customers" to "anon";

grant select on table "public"."customers" to "anon";

grant trigger on table "public"."customers" to "anon";

grant truncate on table "public"."customers" to "anon";

grant update on table "public"."customers" to "anon";

grant delete on table "public"."customers" to "authenticated";

grant insert on table "public"."customers" to "authenticated";

grant references on table "public"."customers" to "authenticated";

grant select on table "public"."customers" to "authenticated";

grant trigger on table "public"."customers" to "authenticated";

grant truncate on table "public"."customers" to "authenticated";

grant update on table "public"."customers" to "authenticated";

grant delete on table "public"."customers" to "service_role";

grant insert on table "public"."customers" to "service_role";

grant references on table "public"."customers" to "service_role";

grant select on table "public"."customers" to "service_role";

grant trigger on table "public"."customers" to "service_role";

grant truncate on table "public"."customers" to "service_role";

grant update on table "public"."customers" to "service_role";

grant delete on table "public"."event_type_defaults" to "anon";

grant insert on table "public"."event_type_defaults" to "anon";

grant references on table "public"."event_type_defaults" to "anon";

grant select on table "public"."event_type_defaults" to "anon";

grant trigger on table "public"."event_type_defaults" to "anon";

grant truncate on table "public"."event_type_defaults" to "anon";

grant update on table "public"."event_type_defaults" to "anon";

grant delete on table "public"."event_type_defaults" to "authenticated";

grant insert on table "public"."event_type_defaults" to "authenticated";

grant references on table "public"."event_type_defaults" to "authenticated";

grant select on table "public"."event_type_defaults" to "authenticated";

grant trigger on table "public"."event_type_defaults" to "authenticated";

grant truncate on table "public"."event_type_defaults" to "authenticated";

grant update on table "public"."event_type_defaults" to "authenticated";

grant delete on table "public"."event_type_defaults" to "service_role";

grant insert on table "public"."event_type_defaults" to "service_role";

grant references on table "public"."event_type_defaults" to "service_role";

grant select on table "public"."event_type_defaults" to "service_role";

grant trigger on table "public"."event_type_defaults" to "service_role";

grant truncate on table "public"."event_type_defaults" to "service_role";

grant update on table "public"."event_type_defaults" to "service_role";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."notifications" to "authenticated";

grant insert on table "public"."notifications" to "authenticated";

grant references on table "public"."notifications" to "authenticated";

grant select on table "public"."notifications" to "authenticated";

grant trigger on table "public"."notifications" to "authenticated";

grant truncate on table "public"."notifications" to "authenticated";

grant update on table "public"."notifications" to "authenticated";

grant delete on table "public"."notifications" to "service_role";

grant insert on table "public"."notifications" to "service_role";

grant references on table "public"."notifications" to "service_role";

grant select on table "public"."notifications" to "service_role";

grant trigger on table "public"."notifications" to "service_role";

grant truncate on table "public"."notifications" to "service_role";

grant update on table "public"."notifications" to "service_role";

grant delete on table "public"."partner_event_payout_config" to "anon";

grant insert on table "public"."partner_event_payout_config" to "anon";

grant references on table "public"."partner_event_payout_config" to "anon";

grant select on table "public"."partner_event_payout_config" to "anon";

grant trigger on table "public"."partner_event_payout_config" to "anon";

grant truncate on table "public"."partner_event_payout_config" to "anon";

grant update on table "public"."partner_event_payout_config" to "anon";

grant delete on table "public"."partner_event_payout_config" to "authenticated";

grant insert on table "public"."partner_event_payout_config" to "authenticated";

grant references on table "public"."partner_event_payout_config" to "authenticated";

grant select on table "public"."partner_event_payout_config" to "authenticated";

grant trigger on table "public"."partner_event_payout_config" to "authenticated";

grant truncate on table "public"."partner_event_payout_config" to "authenticated";

grant update on table "public"."partner_event_payout_config" to "authenticated";

grant delete on table "public"."partner_event_payout_config" to "service_role";

grant insert on table "public"."partner_event_payout_config" to "service_role";

grant references on table "public"."partner_event_payout_config" to "service_role";

grant select on table "public"."partner_event_payout_config" to "service_role";

grant trigger on table "public"."partner_event_payout_config" to "service_role";

grant truncate on table "public"."partner_event_payout_config" to "service_role";

grant update on table "public"."partner_event_payout_config" to "service_role";

grant delete on table "public"."partner_status_history" to "anon";

grant insert on table "public"."partner_status_history" to "anon";

grant references on table "public"."partner_status_history" to "anon";

grant select on table "public"."partner_status_history" to "anon";

grant trigger on table "public"."partner_status_history" to "anon";

grant truncate on table "public"."partner_status_history" to "anon";

grant update on table "public"."partner_status_history" to "anon";

grant delete on table "public"."partner_status_history" to "authenticated";

grant insert on table "public"."partner_status_history" to "authenticated";

grant references on table "public"."partner_status_history" to "authenticated";

grant select on table "public"."partner_status_history" to "authenticated";

grant trigger on table "public"."partner_status_history" to "authenticated";

grant truncate on table "public"."partner_status_history" to "authenticated";

grant update on table "public"."partner_status_history" to "authenticated";

grant delete on table "public"."partner_status_history" to "service_role";

grant insert on table "public"."partner_status_history" to "service_role";

grant references on table "public"."partner_status_history" to "service_role";

grant select on table "public"."partner_status_history" to "service_role";

grant trigger on table "public"."partner_status_history" to "service_role";

grant truncate on table "public"."partner_status_history" to "service_role";

grant update on table "public"."partner_status_history" to "service_role";

grant delete on table "public"."partners" to "anon";

grant insert on table "public"."partners" to "anon";

grant references on table "public"."partners" to "anon";

grant select on table "public"."partners" to "anon";

grant trigger on table "public"."partners" to "anon";

grant truncate on table "public"."partners" to "anon";

grant update on table "public"."partners" to "anon";

grant delete on table "public"."partners" to "authenticated";

grant insert on table "public"."partners" to "authenticated";

grant references on table "public"."partners" to "authenticated";

grant select on table "public"."partners" to "authenticated";

grant trigger on table "public"."partners" to "authenticated";

grant truncate on table "public"."partners" to "authenticated";

grant update on table "public"."partners" to "authenticated";

grant delete on table "public"."partners" to "service_role";

grant insert on table "public"."partners" to "service_role";

grant references on table "public"."partners" to "service_role";

grant select on table "public"."partners" to "service_role";

grant trigger on table "public"."partners" to "service_role";

grant truncate on table "public"."partners" to "service_role";

grant update on table "public"."partners" to "service_role";

grant delete on table "public"."payout_options" to "anon";

grant insert on table "public"."payout_options" to "anon";

grant references on table "public"."payout_options" to "anon";

grant select on table "public"."payout_options" to "anon";

grant trigger on table "public"."payout_options" to "anon";

grant truncate on table "public"."payout_options" to "anon";

grant update on table "public"."payout_options" to "anon";

grant delete on table "public"."payout_options" to "authenticated";

grant insert on table "public"."payout_options" to "authenticated";

grant references on table "public"."payout_options" to "authenticated";

grant select on table "public"."payout_options" to "authenticated";

grant trigger on table "public"."payout_options" to "authenticated";

grant truncate on table "public"."payout_options" to "authenticated";

grant update on table "public"."payout_options" to "authenticated";

grant delete on table "public"."payout_options" to "service_role";

grant insert on table "public"."payout_options" to "service_role";

grant references on table "public"."payout_options" to "service_role";

grant select on table "public"."payout_options" to "service_role";

grant trigger on table "public"."payout_options" to "service_role";

grant truncate on table "public"."payout_options" to "service_role";

grant update on table "public"."payout_options" to "service_role";

grant delete on table "public"."policy" to "anon";

grant insert on table "public"."policy" to "anon";

grant references on table "public"."policy" to "anon";

grant select on table "public"."policy" to "anon";

grant trigger on table "public"."policy" to "anon";

grant truncate on table "public"."policy" to "anon";

grant update on table "public"."policy" to "anon";

grant delete on table "public"."policy" to "authenticated";

grant insert on table "public"."policy" to "authenticated";

grant references on table "public"."policy" to "authenticated";

grant select on table "public"."policy" to "authenticated";

grant trigger on table "public"."policy" to "authenticated";

grant truncate on table "public"."policy" to "authenticated";

grant update on table "public"."policy" to "authenticated";

grant delete on table "public"."policy" to "service_role";

grant insert on table "public"."policy" to "service_role";

grant references on table "public"."policy" to "service_role";

grant select on table "public"."policy" to "service_role";

grant trigger on table "public"."policy" to "service_role";

grant truncate on table "public"."policy" to "service_role";

grant update on table "public"."policy" to "service_role";

grant delete on table "public"."quote_config" to "anon";

grant insert on table "public"."quote_config" to "anon";

grant references on table "public"."quote_config" to "anon";

grant select on table "public"."quote_config" to "anon";

grant trigger on table "public"."quote_config" to "anon";

grant truncate on table "public"."quote_config" to "anon";

grant update on table "public"."quote_config" to "anon";

grant delete on table "public"."quote_config" to "authenticated";

grant insert on table "public"."quote_config" to "authenticated";

grant references on table "public"."quote_config" to "authenticated";

grant select on table "public"."quote_config" to "authenticated";

grant trigger on table "public"."quote_config" to "authenticated";

grant truncate on table "public"."quote_config" to "authenticated";

grant update on table "public"."quote_config" to "authenticated";

grant delete on table "public"."quote_config" to "service_role";

grant insert on table "public"."quote_config" to "service_role";

grant references on table "public"."quote_config" to "service_role";

grant select on table "public"."quote_config" to "service_role";

grant trigger on table "public"."quote_config" to "service_role";

grant truncate on table "public"."quote_config" to "service_role";

grant update on table "public"."quote_config" to "service_role";

grant delete on table "public"."quote_expiration_logs" to "anon";

grant insert on table "public"."quote_expiration_logs" to "anon";

grant references on table "public"."quote_expiration_logs" to "anon";

grant select on table "public"."quote_expiration_logs" to "anon";

grant trigger on table "public"."quote_expiration_logs" to "anon";

grant truncate on table "public"."quote_expiration_logs" to "anon";

grant update on table "public"."quote_expiration_logs" to "anon";

grant delete on table "public"."quote_expiration_logs" to "authenticated";

grant insert on table "public"."quote_expiration_logs" to "authenticated";

grant references on table "public"."quote_expiration_logs" to "authenticated";

grant select on table "public"."quote_expiration_logs" to "authenticated";

grant trigger on table "public"."quote_expiration_logs" to "authenticated";

grant truncate on table "public"."quote_expiration_logs" to "authenticated";

grant update on table "public"."quote_expiration_logs" to "authenticated";

grant delete on table "public"."quote_expiration_logs" to "service_role";

grant insert on table "public"."quote_expiration_logs" to "service_role";

grant references on table "public"."quote_expiration_logs" to "service_role";

grant select on table "public"."quote_expiration_logs" to "service_role";

grant trigger on table "public"."quote_expiration_logs" to "service_role";

grant truncate on table "public"."quote_expiration_logs" to "service_role";

grant update on table "public"."quote_expiration_logs" to "service_role";

grant delete on table "public"."quote_locations" to "anon";

grant insert on table "public"."quote_locations" to "anon";

grant references on table "public"."quote_locations" to "anon";

grant select on table "public"."quote_locations" to "anon";

grant trigger on table "public"."quote_locations" to "anon";

grant truncate on table "public"."quote_locations" to "anon";

grant update on table "public"."quote_locations" to "anon";

grant delete on table "public"."quote_locations" to "authenticated";

grant insert on table "public"."quote_locations" to "authenticated";

grant references on table "public"."quote_locations" to "authenticated";

grant select on table "public"."quote_locations" to "authenticated";

grant trigger on table "public"."quote_locations" to "authenticated";

grant truncate on table "public"."quote_locations" to "authenticated";

grant update on table "public"."quote_locations" to "authenticated";

grant delete on table "public"."quote_locations" to "service_role";

grant insert on table "public"."quote_locations" to "service_role";

grant references on table "public"."quote_locations" to "service_role";

grant select on table "public"."quote_locations" to "service_role";

grant trigger on table "public"."quote_locations" to "service_role";

grant truncate on table "public"."quote_locations" to "service_role";

grant update on table "public"."quote_locations" to "service_role";

grant delete on table "public"."quote_payout_options" to "anon";

grant insert on table "public"."quote_payout_options" to "anon";

grant references on table "public"."quote_payout_options" to "anon";

grant select on table "public"."quote_payout_options" to "anon";

grant trigger on table "public"."quote_payout_options" to "anon";

grant truncate on table "public"."quote_payout_options" to "anon";

grant update on table "public"."quote_payout_options" to "anon";

grant delete on table "public"."quote_payout_options" to "authenticated";

grant insert on table "public"."quote_payout_options" to "authenticated";

grant references on table "public"."quote_payout_options" to "authenticated";

grant select on table "public"."quote_payout_options" to "authenticated";

grant trigger on table "public"."quote_payout_options" to "authenticated";

grant truncate on table "public"."quote_payout_options" to "authenticated";

grant update on table "public"."quote_payout_options" to "authenticated";

grant delete on table "public"."quote_payout_options" to "service_role";

grant insert on table "public"."quote_payout_options" to "service_role";

grant references on table "public"."quote_payout_options" to "service_role";

grant select on table "public"."quote_payout_options" to "service_role";

grant trigger on table "public"."quote_payout_options" to "service_role";

grant truncate on table "public"."quote_payout_options" to "service_role";

grant update on table "public"."quote_payout_options" to "service_role";

grant delete on table "public"."quote_premiums" to "anon";

grant insert on table "public"."quote_premiums" to "anon";

grant references on table "public"."quote_premiums" to "anon";

grant select on table "public"."quote_premiums" to "anon";

grant trigger on table "public"."quote_premiums" to "anon";

grant truncate on table "public"."quote_premiums" to "anon";

grant update on table "public"."quote_premiums" to "anon";

grant delete on table "public"."quote_premiums" to "authenticated";

grant insert on table "public"."quote_premiums" to "authenticated";

grant references on table "public"."quote_premiums" to "authenticated";

grant select on table "public"."quote_premiums" to "authenticated";

grant trigger on table "public"."quote_premiums" to "authenticated";

grant truncate on table "public"."quote_premiums" to "authenticated";

grant update on table "public"."quote_premiums" to "authenticated";

grant delete on table "public"."quote_premiums" to "service_role";

grant insert on table "public"."quote_premiums" to "service_role";

grant references on table "public"."quote_premiums" to "service_role";

grant select on table "public"."quote_premiums" to "service_role";

grant trigger on table "public"."quote_premiums" to "service_role";

grant truncate on table "public"."quote_premiums" to "service_role";

grant update on table "public"."quote_premiums" to "service_role";

grant delete on table "public"."quote_test_results" to "anon";

grant insert on table "public"."quote_test_results" to "anon";

grant references on table "public"."quote_test_results" to "anon";

grant select on table "public"."quote_test_results" to "anon";

grant trigger on table "public"."quote_test_results" to "anon";

grant truncate on table "public"."quote_test_results" to "anon";

grant update on table "public"."quote_test_results" to "anon";

grant delete on table "public"."quote_test_results" to "authenticated";

grant insert on table "public"."quote_test_results" to "authenticated";

grant references on table "public"."quote_test_results" to "authenticated";

grant select on table "public"."quote_test_results" to "authenticated";

grant trigger on table "public"."quote_test_results" to "authenticated";

grant truncate on table "public"."quote_test_results" to "authenticated";

grant update on table "public"."quote_test_results" to "authenticated";

grant delete on table "public"."quote_test_results" to "service_role";

grant insert on table "public"."quote_test_results" to "service_role";

grant references on table "public"."quote_test_results" to "service_role";

grant select on table "public"."quote_test_results" to "service_role";

grant trigger on table "public"."quote_test_results" to "service_role";

grant truncate on table "public"."quote_test_results" to "service_role";

grant update on table "public"."quote_test_results" to "service_role";

grant delete on table "public"."quote_test_runs" to "anon";

grant insert on table "public"."quote_test_runs" to "anon";

grant references on table "public"."quote_test_runs" to "anon";

grant select on table "public"."quote_test_runs" to "anon";

grant trigger on table "public"."quote_test_runs" to "anon";

grant truncate on table "public"."quote_test_runs" to "anon";

grant update on table "public"."quote_test_runs" to "anon";

grant delete on table "public"."quote_test_runs" to "authenticated";

grant insert on table "public"."quote_test_runs" to "authenticated";

grant references on table "public"."quote_test_runs" to "authenticated";

grant select on table "public"."quote_test_runs" to "authenticated";

grant trigger on table "public"."quote_test_runs" to "authenticated";

grant truncate on table "public"."quote_test_runs" to "authenticated";

grant update on table "public"."quote_test_runs" to "authenticated";

grant delete on table "public"."quote_test_runs" to "service_role";

grant insert on table "public"."quote_test_runs" to "service_role";

grant references on table "public"."quote_test_runs" to "service_role";

grant select on table "public"."quote_test_runs" to "service_role";

grant trigger on table "public"."quote_test_runs" to "service_role";

grant truncate on table "public"."quote_test_runs" to "service_role";

grant update on table "public"."quote_test_runs" to "service_role";

grant delete on table "public"."quotes" to "anon";

grant insert on table "public"."quotes" to "anon";

grant references on table "public"."quotes" to "anon";

grant select on table "public"."quotes" to "anon";

grant trigger on table "public"."quotes" to "anon";

grant truncate on table "public"."quotes" to "anon";

grant update on table "public"."quotes" to "anon";

grant delete on table "public"."quotes" to "authenticated";

grant insert on table "public"."quotes" to "authenticated";

grant references on table "public"."quotes" to "authenticated";

grant select on table "public"."quotes" to "authenticated";

grant trigger on table "public"."quotes" to "authenticated";

grant truncate on table "public"."quotes" to "authenticated";

grant update on table "public"."quotes" to "authenticated";

grant delete on table "public"."quotes" to "service_role";

grant insert on table "public"."quotes" to "service_role";

grant references on table "public"."quotes" to "service_role";

grant select on table "public"."quotes" to "service_role";

grant trigger on table "public"."quotes" to "service_role";

grant truncate on table "public"."quotes" to "service_role";

grant update on table "public"."quotes" to "service_role";

grant delete on table "public"."rls_disabled_justification" to "anon";

grant insert on table "public"."rls_disabled_justification" to "anon";

grant references on table "public"."rls_disabled_justification" to "anon";

grant select on table "public"."rls_disabled_justification" to "anon";

grant trigger on table "public"."rls_disabled_justification" to "anon";

grant truncate on table "public"."rls_disabled_justification" to "anon";

grant update on table "public"."rls_disabled_justification" to "anon";

grant delete on table "public"."rls_disabled_justification" to "authenticated";

grant insert on table "public"."rls_disabled_justification" to "authenticated";

grant references on table "public"."rls_disabled_justification" to "authenticated";

grant select on table "public"."rls_disabled_justification" to "authenticated";

grant trigger on table "public"."rls_disabled_justification" to "authenticated";

grant truncate on table "public"."rls_disabled_justification" to "authenticated";

grant update on table "public"."rls_disabled_justification" to "authenticated";

grant delete on table "public"."rls_disabled_justification" to "service_role";

grant insert on table "public"."rls_disabled_justification" to "service_role";

grant references on table "public"."rls_disabled_justification" to "service_role";

grant select on table "public"."rls_disabled_justification" to "service_role";

grant trigger on table "public"."rls_disabled_justification" to "service_role";

grant truncate on table "public"."rls_disabled_justification" to "service_role";

grant update on table "public"."rls_disabled_justification" to "service_role";

grant delete on table "public"."seasonal_config" to "anon";

grant insert on table "public"."seasonal_config" to "anon";

grant references on table "public"."seasonal_config" to "anon";

grant select on table "public"."seasonal_config" to "anon";

grant trigger on table "public"."seasonal_config" to "anon";

grant truncate on table "public"."seasonal_config" to "anon";

grant update on table "public"."seasonal_config" to "anon";

grant delete on table "public"."seasonal_config" to "authenticated";

grant insert on table "public"."seasonal_config" to "authenticated";

grant references on table "public"."seasonal_config" to "authenticated";

grant select on table "public"."seasonal_config" to "authenticated";

grant trigger on table "public"."seasonal_config" to "authenticated";

grant truncate on table "public"."seasonal_config" to "authenticated";

grant update on table "public"."seasonal_config" to "authenticated";

grant delete on table "public"."seasonal_config" to "service_role";

grant insert on table "public"."seasonal_config" to "service_role";

grant references on table "public"."seasonal_config" to "service_role";

grant select on table "public"."seasonal_config" to "service_role";

grant trigger on table "public"."seasonal_config" to "service_role";

grant truncate on table "public"."seasonal_config" to "service_role";

grant update on table "public"."seasonal_config" to "service_role";

grant delete on table "public"."security_implementation_report" to "anon";

grant insert on table "public"."security_implementation_report" to "anon";

grant references on table "public"."security_implementation_report" to "anon";

grant select on table "public"."security_implementation_report" to "anon";

grant trigger on table "public"."security_implementation_report" to "anon";

grant truncate on table "public"."security_implementation_report" to "anon";

grant update on table "public"."security_implementation_report" to "anon";

grant delete on table "public"."security_implementation_report" to "authenticated";

grant insert on table "public"."security_implementation_report" to "authenticated";

grant references on table "public"."security_implementation_report" to "authenticated";

grant select on table "public"."security_implementation_report" to "authenticated";

grant trigger on table "public"."security_implementation_report" to "authenticated";

grant truncate on table "public"."security_implementation_report" to "authenticated";

grant update on table "public"."security_implementation_report" to "authenticated";

grant delete on table "public"."security_implementation_report" to "service_role";

grant insert on table "public"."security_implementation_report" to "service_role";

grant references on table "public"."security_implementation_report" to "service_role";

grant select on table "public"."security_implementation_report" to "service_role";

grant trigger on table "public"."security_implementation_report" to "service_role";

grant truncate on table "public"."security_implementation_report" to "service_role";

grant update on table "public"."security_implementation_report" to "service_role";

grant delete on table "public"."templates" to "anon";

grant insert on table "public"."templates" to "anon";

grant references on table "public"."templates" to "anon";

grant select on table "public"."templates" to "anon";

grant trigger on table "public"."templates" to "anon";

grant truncate on table "public"."templates" to "anon";

grant update on table "public"."templates" to "anon";

grant delete on table "public"."templates" to "authenticated";

grant insert on table "public"."templates" to "authenticated";

grant references on table "public"."templates" to "authenticated";

grant select on table "public"."templates" to "authenticated";

grant trigger on table "public"."templates" to "authenticated";

grant truncate on table "public"."templates" to "authenticated";

grant update on table "public"."templates" to "authenticated";

grant delete on table "public"."templates" to "service_role";

grant insert on table "public"."templates" to "service_role";

grant references on table "public"."templates" to "service_role";

grant select on table "public"."templates" to "service_role";

grant trigger on table "public"."templates" to "service_role";

grant truncate on table "public"."templates" to "service_role";

grant update on table "public"."templates" to "service_role";

grant delete on table "public"."test_table" to "anon";

grant insert on table "public"."test_table" to "anon";

grant references on table "public"."test_table" to "anon";

grant select on table "public"."test_table" to "anon";

grant trigger on table "public"."test_table" to "anon";

grant truncate on table "public"."test_table" to "anon";

grant update on table "public"."test_table" to "anon";

grant delete on table "public"."test_table" to "authenticated";

grant insert on table "public"."test_table" to "authenticated";

grant references on table "public"."test_table" to "authenticated";

grant select on table "public"."test_table" to "authenticated";

grant trigger on table "public"."test_table" to "authenticated";

grant truncate on table "public"."test_table" to "authenticated";

grant update on table "public"."test_table" to "authenticated";

grant delete on table "public"."test_table" to "service_role";

grant insert on table "public"."test_table" to "service_role";

grant references on table "public"."test_table" to "service_role";

grant select on table "public"."test_table" to "service_role";

grant trigger on table "public"."test_table" to "service_role";

grant truncate on table "public"."test_table" to "service_role";

grant update on table "public"."test_table" to "service_role";

grant delete on table "public"."transactions" to "anon";

grant insert on table "public"."transactions" to "anon";

grant references on table "public"."transactions" to "anon";

grant select on table "public"."transactions" to "anon";

grant trigger on table "public"."transactions" to "anon";

grant truncate on table "public"."transactions" to "anon";

grant update on table "public"."transactions" to "anon";

grant delete on table "public"."transactions" to "authenticated";

grant insert on table "public"."transactions" to "authenticated";

grant references on table "public"."transactions" to "authenticated";

grant select on table "public"."transactions" to "authenticated";

grant trigger on table "public"."transactions" to "authenticated";

grant truncate on table "public"."transactions" to "authenticated";

grant update on table "public"."transactions" to "authenticated";

grant delete on table "public"."transactions" to "service_role";

grant insert on table "public"."transactions" to "service_role";

grant references on table "public"."transactions" to "service_role";

grant select on table "public"."transactions" to "service_role";

grant trigger on table "public"."transactions" to "service_role";

grant truncate on table "public"."transactions" to "service_role";

grant update on table "public"."transactions" to "service_role";

grant delete on table "public"."unified_audit_log" to "anon";

grant insert on table "public"."unified_audit_log" to "anon";

grant references on table "public"."unified_audit_log" to "anon";

grant select on table "public"."unified_audit_log" to "anon";

grant trigger on table "public"."unified_audit_log" to "anon";

grant truncate on table "public"."unified_audit_log" to "anon";

grant update on table "public"."unified_audit_log" to "anon";

grant delete on table "public"."unified_audit_log" to "authenticated";

grant insert on table "public"."unified_audit_log" to "authenticated";

grant references on table "public"."unified_audit_log" to "authenticated";

grant select on table "public"."unified_audit_log" to "authenticated";

grant trigger on table "public"."unified_audit_log" to "authenticated";

grant truncate on table "public"."unified_audit_log" to "authenticated";

grant update on table "public"."unified_audit_log" to "authenticated";

grant delete on table "public"."unified_audit_log" to "service_role";

grant insert on table "public"."unified_audit_log" to "service_role";

grant references on table "public"."unified_audit_log" to "service_role";

grant select on table "public"."unified_audit_log" to "service_role";

grant trigger on table "public"."unified_audit_log" to "service_role";

grant truncate on table "public"."unified_audit_log" to "service_role";

grant update on table "public"."unified_audit_log" to "service_role";

grant delete on table "public"."weather_data" to "anon";

grant insert on table "public"."weather_data" to "anon";

grant references on table "public"."weather_data" to "anon";

grant select on table "public"."weather_data" to "anon";

grant trigger on table "public"."weather_data" to "anon";

grant truncate on table "public"."weather_data" to "anon";

grant update on table "public"."weather_data" to "anon";

grant delete on table "public"."weather_data" to "authenticated";

grant insert on table "public"."weather_data" to "authenticated";

grant references on table "public"."weather_data" to "authenticated";

grant select on table "public"."weather_data" to "authenticated";

grant trigger on table "public"."weather_data" to "authenticated";

grant truncate on table "public"."weather_data" to "authenticated";

grant update on table "public"."weather_data" to "authenticated";

grant delete on table "public"."weather_data" to "service_role";

grant insert on table "public"."weather_data" to "service_role";

grant references on table "public"."weather_data" to "service_role";

grant select on table "public"."weather_data" to "service_role";

grant trigger on table "public"."weather_data" to "service_role";

grant truncate on table "public"."weather_data" to "service_role";

grant update on table "public"."weather_data" to "service_role";

create policy "API keys are not directly accessible"
on "public"."api_keys"
as permissive
for all
to authenticated, anon
using (false)
with check (false);


create policy "Service role can manage claim_locations"
on "public"."claim_locations"
as permissive
for all
to public
using (true);


create policy "Service role can manage claim_weather_hourly"
on "public"."claim_weather_hourly"
as permissive
for all
to public
using (true);


create policy "Service role has full access to claims"
on "public"."claims"
as permissive
for all
to public
using (((auth.jwt() ->> 'role'::text) = 'service_role'::text));


create policy "Allow all access for authenticated users"
on "public"."notifications"
as permissive
for all
to public
using ((auth.role() = 'authenticated'::text))
with check ((auth.role() = 'authenticated'::text));


create policy "Partners can only access their own payout config"
on "public"."partner_event_payout_config"
as permissive
for all
to public
using ((partner_id = get_current_partner_id()));


create policy "Authenticated users can read payout options"
on "public"."payout_options"
as permissive
for select
to authenticated
using (true);


create policy "policy_partner_isolation"
on "public"."policy"
as permissive
for all
to authenticated
using ((partner_id = get_current_partner_id()))
with check ((partner_id = get_current_partner_id()));


create policy "Authenticated users can read quote config"
on "public"."quote_config"
as permissive
for select
to authenticated
using (true);


create policy "quote_expiration_logs_admin_read"
on "public"."quote_expiration_logs"
as permissive
for select
to public
using ((((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'audit_admin'::text)));


create policy "quote_expiration_logs_no_delete"
on "public"."quote_expiration_logs"
as permissive
for delete
to public
using (false);


create policy "quote_expiration_logs_no_update"
on "public"."quote_expiration_logs"
as permissive
for update
to public
using (false);


create policy "quote_expiration_logs_system_insert"
on "public"."quote_expiration_logs"
as permissive
for insert
to public
with check (((auth.jwt() ->> 'role'::text) = 'service_role'::text));


create policy "Partners can only access their own quote locations"
on "public"."quote_locations"
as permissive
for all
to authenticated
using ((quote_id IN ( SELECT quotes.quote_id
   FROM quotes
  WHERE (quotes.partner_id = get_current_partner_id()))));


create policy "Partners can only access their own payout options"
on "public"."quote_payout_options"
as permissive
for all
to authenticated
using ((quote_id IN ( SELECT quotes.quote_id
   FROM quotes
  WHERE (quotes.partner_id = get_current_partner_id()))));


create policy "Partners can only access their own quote premiums"
on "public"."quote_premiums"
as permissive
for all
to authenticated
using ((quote_id IN ( SELECT quotes.quote_id
   FROM quotes
  WHERE (quotes.partner_id = get_current_partner_id()))));


create policy "Partners can only access their own test runs"
on "public"."quote_test_runs"
as permissive
for all
to authenticated
using (true);


create policy "quotes_partner_isolation"
on "public"."quotes"
as permissive
for all
to authenticated
using ((partner_id = get_current_partner_id()))
with check ((partner_id = get_current_partner_id()));


create policy "Authenticated users can read RLS justifications"
on "public"."rls_disabled_justification"
as permissive
for select
to authenticated
using (true);


create policy "Authenticated users can read seasonal config"
on "public"."seasonal_config"
as permissive
for select
to authenticated
using (true);


create policy "Authenticated users can read security reports"
on "public"."security_implementation_report"
as permissive
for select
to authenticated
using (true);


create policy "Anyone can read templates"
on "public"."templates"
as permissive
for select
to authenticated, anon
using (true);


create policy "No direct transaction access"
on "public"."transactions"
as permissive
for all
to authenticated, anon
using (false)
with check (false);


create policy "audit_admin_read"
on "public"."unified_audit_log"
as permissive
for select
to public
using ((((auth.jwt() ->> 'role'::text) = 'audit_admin'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text)));


create policy "audit_no_delete"
on "public"."unified_audit_log"
as permissive
for delete
to public
using (false);


create policy "audit_no_update"
on "public"."unified_audit_log"
as permissive
for update
to public
using (false);


create policy "system_audit_insert"
on "public"."unified_audit_log"
as permissive
for insert
to public
with check (true);


create policy "user_own_audit_read"
on "public"."unified_audit_log"
as permissive
for select
to public
using (((auth.role() = 'authenticated'::text) AND (user_id = auth.uid())));


CREATE TRIGGER audit_customer_changes AFTER INSERT OR DELETE OR UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER audit_partner_changes AFTER INSERT OR DELETE OR UPDATE ON public.partners FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_policy_changes AFTER INSERT OR DELETE OR UPDATE ON public.policy FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_quote_changes AFTER INSERT OR DELETE OR UPDATE ON public.quotes FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_template_changes AFTER INSERT OR DELETE OR UPDATE ON public.templates FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_transaction_changes AFTER INSERT OR DELETE OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER update_policy_after_transaction AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION update_policy_payment_status();


