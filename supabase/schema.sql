-- Pemantau Tanah: draft schema for the pilot.
-- STALE: written before the 26 Nov 2026 concept change (GIS map first, JAIS field officers
-- instead of kariah teams, no rewards). Do not apply as is. Teams, rewards and compliance
-- bands below no longer match docs/SPEC.md; lot attributes, boundary versions and work
-- assignments are missing. To be redrafted with PostGIS and RLS.
-- Draft only. RLS policies are NOT written yet; enable RLS and add policies per role/district before any real data goes in.

create type user_role as enum ('monitor', 'officer', 'admin');
create type visit_status as enum ('due', 'in_progress', 'completed');
create type compliance_band as enum ('good', 'reduced', 'poor');
create type alert_source as enum ('monitor_report', 'ai_score', 'post_missing');
create type alert_status as enum ('open', 'acknowledged', 'false_alarm', 'escalated');
create type case_outcome as enum ('pending', 'offender_identified', 'closed_no_offender');

create table districts (
  id uuid primary key default gen_random_uuid(),
  name text not null
);

create table profiles (
  id uuid primary key references auth.users (id),
  full_name text not null,
  role user_role not null,
  district_id uuid references districts (id)
);

create table teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,              -- kariah / mosque name
  district_id uuid not null references districts (id)
);

create table team_members (
  team_id uuid not null references teams (id),
  user_id uuid not null references profiles (id),
  primary key (team_id, user_id)
);

create table lots (
  id uuid primary key default gen_random_uuid(),
  district_id uuid not null references districts (id),
  team_id uuid references teams (id),
  officer_id uuid references profiles (id),
  name text not null,
  land_type text,
  boundary jsonb not null,                       -- GeoJSON polygon, approximate
  geofence_buffer_m integer not null default 15,
  visit_interval_days integer not null default 30,
  visit_reward_rm numeric(6,2) not null check (visit_reward_rm between 10 and 50),
  ai_alert_threshold integer,                    -- phase 2
  initial_status_note text,                      -- condition recorded at onboarding
  created_at timestamptz not null default now()
);

create table boundary_stones (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references lots (id),
  label text not null,
  lat double precision not null,
  lng double precision not null,
  reference_photo_path text
);

create table posts (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references lots (id),
  seq integer not null,
  code text not null unique,                     -- value encoded on the pole (QR/NFC)
  lat double precision not null,
  lng double precision not null,
  heading_deg integer,
  baseline_photo_id uuid,                        -- set after first photo; FK added below
  unique (lot_id, seq)
);

create table visits (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references lots (id),
  team_id uuid not null references teams (id),
  monitor_id uuid references profiles (id),
  due_date date not null,
  status visit_status not null default 'due',
  checked_in_at timestamptz,
  checkin_lat double precision,
  checkin_lng double precision,
  checkin_accuracy_m real,
  completed_at timestamptz,
  days_late integer,                             -- negative = early
  band compliance_band,
  no_change boolean,
  reward_rm numeric(6,2),                        -- set when the visit qualifies
  mock_location_suspected boolean not null default false
);

create table photos (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid references visits (id),
  post_id uuid not null references posts (id),
  taken_by uuid not null references profiles (id),
  storage_path text not null,
  sha256 text not null,
  lat double precision not null,
  lng double precision not null,
  accuracy_m real not null,
  heading_deg integer,
  taken_at timestamptz not null,
  fallback boolean not null default false,       -- pole missing, taken at pin coordinate
  unique (visit_id, post_id)
);

alter table posts
  add constraint posts_baseline_photo_fk foreign key (baseline_photo_id) references photos (id);

create table baseline_resets (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts (id),
  old_photo_id uuid references photos (id),
  new_photo_id uuid not null references photos (id),
  reset_by uuid not null references profiles (id),
  reason text not null,
  reset_at timestamptz not null default now()
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references lots (id),
  visit_id uuid references visits (id),          -- null for a direct report outside a visit
  reported_by uuid not null references profiles (id),
  categories text[] not null,
  note text,
  created_at timestamptz not null default now()
);

create table ai_scores (                         -- phase 2
  id uuid primary key default gen_random_uuid(),
  photo_id uuid not null references photos (id),
  baseline_photo_id uuid not null references photos (id),
  manmade_score integer not null check (manmade_score between 0 and 10),
  nature_score integer not null check (nature_score between 0 and 10),
  summary text,
  model text not null,
  low_confidence boolean not null default false,
  created_at timestamptz not null default now()
);

create table alerts (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references lots (id),
  visit_id uuid references visits (id),
  report_id uuid references reports (id),
  source alert_source not null,
  status alert_status not null default 'open',
  officer_id uuid references profiles (id),
  acknowledged_at timestamptz,
  escalated_at timestamptz,
  outcome case_outcome not null default 'pending',
  outcome_set_by uuid references profiles (id),
  outcome_set_at timestamptz,
  created_at timestamptz not null default now()
);

create table report_rewards (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null unique references alerts (id),   -- one case, one reward
  team_id uuid not null references teams (id),
  amount_rm numeric(8,2) not null default 1000,
  eligible_at timestamptz not null default now(),
  disqualified boolean not null default false,
  disqualified_reason text
);

create table audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references profiles (id),
  action text not null,
  entity text not null,
  entity_id uuid,
  detail jsonb,
  at timestamptz not null default now()
);
