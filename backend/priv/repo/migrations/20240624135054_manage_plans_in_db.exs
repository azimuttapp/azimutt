defmodule Azimutt.Repo.Migrations.ManagePlansInDb do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      remove :stripe_subscription_id

      add :plan, :string,
        comment:
          "organization pricing plan, ex: free, solo, team... If null, it has to be computed and stored"

      add :plan_freq, :string,
        comment:
          "subscription period, ex: monthly, yearly. If null, it has to be computed and stored"

      add :plan_status, :string,
        comment: "stripe status or 'manual' to disable the sync with stripe"

      add :plan_seats, :integer

      add :plan_validated, :utc_datetime_usec,
        comment: "the last time the plan was computed and stored"

      add :free_trial_used, :utc_datetime_usec,
        comment: "when the free trial was used, null otherwise"
    end
  end
end
