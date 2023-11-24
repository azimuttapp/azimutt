defmodule Azimutt.Accounts.UserTest do
  use Azimutt.DataCase
  alias Azimutt.Accounts.User

  describe "User.start_checklist_changeset/2" do
    test "validates required fields and embeds" do
      changeset = User.start_checklist_changeset(%User{}, ["test", "demo"])
      assert changeset.valid?
    end
  end
end
