defmodule Azimutt.Repo.Migrations.AllowNullOnStripeOrgaAndEventUser do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      modify :stripe_customer_id, :string, null: true, from: :string
    end

    alter table(:events) do
      modify :created_by, references(:users), null: true, from: references(:users)
    end
  end
end
