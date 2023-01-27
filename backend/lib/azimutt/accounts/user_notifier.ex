defmodule Azimutt.Accounts.UserNotifier do
  @moduledoc "base user notifier generate by `mix phx.gen.auth`"
  import Swoosh.Email
  alias Azimutt.Mailer

  # FIXME: make emails optional (if not configured)
  # TODO: send all emails from a central place
  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Azimutt", Azimutt.config(:mailer_default_from_email)})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc "Deliver instructions to confirm account."
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """
    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  @doc "Deliver instructions to reset a user password."
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """
    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  @doc "Deliver instructions to update a user email."
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """
    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  @doc "Deliver instructions to an invited member of an organization."
  def deliver_organization_invitation_instructions(invitation, organization, creator, url) do
    deliver(invitation.sent_to, "Organization invitation", """
    Hi,

    #{creator.name} invited you to join #{organization.name} organization on Azimutt.

    Please visit the below link to accept or not this invitation:

    #{url}

    If you are not interested, you can ignore this email. The invitation will expire after a few days.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end
end
