import Ecto.Query
import Ecto.Changeset
alias Ecto.Adapters.SQL

alias Azimutt.{Accounts, Admin, Organizations, Projects, Repo}
alias Azimutt.Accounts.User
alias Azimutt.Organizations.{OrganizationMember, Organization, OrganizationInvitation}

user_admin = Accounts.get_user_by_email("admin@example.com")
