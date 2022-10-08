defmodule Azimutt.Repo.Migrations.InitDatabase do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users,
             comments:
               "users are never deleted to not break foreign keys, they are cleared when deleted"
           ) do
      add :slug, :citext, null: false, comment: "friendly id to show on url"
      add :name, :string, null: false
      add :email, :citext, null: false
      # TODO: delete
      add :provider, :string
      # TODO: delete
      add :provider_uid, :string
      add :avatar, :string
      add :company, :string
      add :location, :string
      add :description, :text
      add :github_username, :string
      add :twitter_username, :string
      add :is_admin, :boolean, null: false
      add :hashed_password, :string, comment: "present only if user used login/pass auth"
      add :last_signin, :utc_datetime_usec, null: false
      timestamps()

      add :confirmed_at, :utc_datetime_usec,
        comment:
          "if and when the used was confirmed: immediately for social, on email confirmation otherwise"

      add :deleted_at, :utc_datetime_usec,
        comment: "on deletion data is cleared but the record is kept for foreign keys"
    end

    create unique_index(:users, [:slug])
    create unique_index(:users, [:email])

    #    create table(:github_profiles, primary_key: false, comment: "data from github auth, should not be modified") do
    #      add :id, :string, primary_key: true, null: false
    #      add :user_id, references(:users), null: false
    #      add :name, :string
    #      add :nickname, :string
    #      add :first_name, :string
    #      add :last_name, :string
    #      add :email, :string
    #      add :phone, :string
    #      add :image, :string
    #      add :description, :string
    #      add :location, :string
    #      # add :urls, :map
    #      timestamps()
    #    end
    #    create index(:github_profiles, [:user_id])

    create table(:users_tokens, comment: "needed for login/pass auth") do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string, comment: "email"
      timestamps(updated_at: false)
    end

    create unique_index(:users_tokens, [:context, :token])
    create index(:users_tokens, [:user_id])

    create table(:organizations) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :contact_email, :string, null: false
      add :logo, :string
      add :location, :string
      add :description, :text
      add :github_username, :string
      add :twitter_username, :string
      add :stripe_customer_id, :string, null: false
      add :stripe_subscription_id, :string

      add :is_personal, :boolean,
        null: false,
        comment:
          "personal organizations are created for each user, they can't invite other people in it"

      add :created_by, references(:users), null: false
      add :updated_by, references(:users), null: false
      timestamps()
      add :deleted_by, references(:users)

      add :deleted_at, :utc_datetime_usec,
        comment: "on deletion data is cleared but the record is kept for foreign keys"
    end

    create unique_index(:organizations, [:slug])
    create unique_index(:organizations, [:name])

    create table(:organizations_members, primary_key: false) do
      add :user_id, references(:users), primary_key: true, null: false
      add :organization_id, references(:organizations), primary_key: true, null: false
      add :created_by, references(:users), null: false
      add :updated_by, references(:users), null: false
      timestamps()
    end

    create table(:organization_invitations) do
      add :sent_to, :string, null: false, comment: "email to send the invitation"
      add :organization_id, references(:organizations), null: false
      add :expire_at, :utc_datetime_usec, null: false
      add :created_by, references(:users), null: false
      timestamps(updated_at: false)
      add :cancel_at, :utc_datetime_usec
      add :answered_by, references(:users)
      add :refused_at, :utc_datetime_usec
      add :accepted_at, :utc_datetime_usec
    end

    create index(:organization_invitations, [:organization_id])

    create table(:projects) do
      add :organization_id, references(:organizations), null: false
      add :slug, :citext, null: false
      add :name, :string, null: false
      add :description, :text
      add :encoding_version, :integer, null: false, comment: "encoding version for the project"
      add :storage_kind, :string, null: false, comment: "enum: local, remote"
      add :file, :string, comment: "stored file reference for remote projects"
      add :local_owner, references(:users), comment: "user owning a local project"
      add :nb_sources, :integer, null: false
      add :nb_tables, :integer, null: false
      add :nb_columns, :integer, null: false
      add :nb_relations, :integer, null: false
      add :nb_types, :integer, null: false, comment: "number of SQL custom types in the project"
      add :nb_comments, :integer, null: false, comment: "number of SQL comments in the project"
      add :nb_notes, :integer, null: false
      add :nb_layouts, :integer, null: false
      add :created_by, references(:users), null: false
      add :updated_by, references(:users), null: false
      timestamps()
      add :archived_by, references(:users)
      add :archived_at, :utc_datetime_usec
    end

    create unique_index(:projects, [:organization_id, :slug])
  end
end
