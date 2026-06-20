-- azimutt_app."events" table maintenance
-- ---------------------------------------------------------------------------
-- Context: `events` is INSERT-ONLY. Postgres' default autovacuum is dead-tuple driven,
-- so it NEVER fires on an insert-only table, and the default insert-based trigger
-- is far too sparse. Result: the visibility map and planner stats go stale,
-- COUNT/aggregate queries degrade into full heap scans, and row estimates drift.
--
-- This script (1) does a one-off VACUUM (ANALYZE) to build the visibility map
-- and refresh stats, and (2) sets per-table insert-based autovacuum thresholds
-- so the table self-maintains from now on.
--
-- Run with psql (NOT a Phoenix/Ecto migration -- VACUUM cannot run inside a
-- transaction). Each statement below is autonomous and safe to run on prod:
--   psql "$DATABASE_URL" -f backend/priv/repo/maintenance/events-maintenance.sql
-- ---------------------------------------------------------------------------

-- 1. One-off: build the visibility map + refresh planner stats.
--    Plain VACUUM (no FULL) does not lock the table against reads/writes.
VACUUM (ANALYZE, VERBOSE) public.events;

-- 2. Self-maintenance: insert-driven autovacuum/analyze with flat thresholds
--    (scale_factor = 0 so the threshold is an absolute row count, not a % of
--    the ever-growing table). Low-traffic table (~hundreds of inserts/day), so
--    modest thresholds keep stats fresh without churn:
--      - VACUUM  every  10,000 inserts (maintains the visibility map)
--      - ANALYZE every   5,000 inserts (keeps planner row estimates accurate)
ALTER TABLE public.events SET (
  autovacuum_vacuum_insert_scale_factor = 0,
  autovacuum_vacuum_insert_threshold    = 10000,
  autovacuum_analyze_scale_factor       = 0,
  autovacuum_analyze_threshold          = 5000
);

-- ---------------------------------------------------------------------------
-- Verify (run after the above):
--
--   SELECT relname, reloptions FROM pg_class WHERE relname = 'events';
--
--   SELECT n_live_tup, n_dead_tup, n_ins_since_vacuum, n_mod_since_analyze,
--          last_vacuum, last_autovacuum, last_analyze, last_autoanalyze,
--          vacuum_count, autovacuum_count
--   FROM pg_stat_user_tables WHERE relname = 'events';
--
--   -- count should now be a fast Index Only Scan, not a full heap scan:
--   EXPLAIN SELECT count(*) FROM public.events;
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- OPTIONAL -- Only run if check shows index bloat.
-- REINDEX CONCURRENTLY avoids locking but cannot run inside a transaction and
-- must be issued one statement at a time:
--
--   REINDEX TABLE CONCURRENTLY public.events;
--
-- OPTIONAL -- If you ever to bound its growth, delete in batches
-- (insert-only table -> no bloat concern, but a single huge DELETE is I/O heavy).
-- Adjust the interval to your policy:
--
--   DELETE FROM public.events
--   WHERE created_at < (now() AT TIME ZONE 'UTC') - interval '365 days';
--   VACUUM (ANALYZE) public.events;   -- reclaim/refresh after a large delete
-- ---------------------------------------------------------------------------
