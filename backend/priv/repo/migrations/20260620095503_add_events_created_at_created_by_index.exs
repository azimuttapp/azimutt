defmodule Azimutt.Repo.Migrations.AddEventsCreatedAtCreatedByIndex do
  use Ecto.Migration

  # The /admin dashboard runs several aggregates over `events` (daily/weekly/monthly
  # connected & returning users) of the shape:
  #   SELECT to_char(created_at, ...), count(DISTINCT created_by)
  #   FROM events WHERE created_at > now() - interval '90/180/360 days' GROUP BY ...
  # With only events_created_at_index, Postgres scans the date range then fetches
  # created_by from the heap for every matching row (325k-654k random reads) -> the
  # 360-day query exceeded the 15s DB pool timeout and /admin returned 500.
  #
  # A composite (created_at, created_by) lets these run as INDEX-ONLY scans (created_by
  # comes from the index, no heap fetch). Built CONCURRENTLY so it doesn't lock event
  # ingestion while building on the ~1.5M-row / 541 MB table; that requires running
  # outside a transaction and without the migration advisory lock.
  @disable_ddl_transaction true
  @disable_migration_lock true

  # create_if_not_exists so the index can be created by hand first (to fix prod
  # immediately) and this migration is then a safe no-op on the next deploy.
  def change do
    create_if_not_exists index(:events, [:created_at, :created_by], concurrently: true)
  end
end
