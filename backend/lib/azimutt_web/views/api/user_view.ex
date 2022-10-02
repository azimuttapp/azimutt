defmodule AzimuttWeb.Api.UserView do
  use AzimuttWeb, :view
  alias Azimutt.Accounts.User

  def render("show.json", %{user: %User{} = user}) do
    %{
      id: user.id,
      slug: user.slug,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      company: user.company,
      location: user.location,
      description: user.description,
      github_username: user.github_username,
      twitter_username: user.twitter_username,
      is_admin: user.is_admin,
      last_signin: user.last_signin,
      created_at: user.created_at
    }
  end
end
