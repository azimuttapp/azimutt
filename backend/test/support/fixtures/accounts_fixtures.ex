defmodule Azimutt.AccountsFixtures do
  @moduledoc false

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    i = System.unique_integer()

    Enum.into(attrs, %{
      name: "User #{i}",
      email: "user#{i}@example.com",
      password: "hello world!",
      avatar: Faker.Avatar.image_url()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Azimutt.Accounts.register_password_user(DateTime.utc_now())

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
