defmodule Azimutt.Accounts.UserNotifier do
  @moduledoc "base user notifier generate by `mix phx.gen.auth`"
  import Swoosh.Email
  alias Azimutt.Mailer

  def send_email_confirmation(user, url) do
    deliver(user.email, "Please confirm your email", """
    Hi #{user.name},

    Thank you for signing up to Azimutt.
    You can confirm your email by visiting the below URL:

    #{url}

    If you didn't create an account with us, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  # FIXME: check this
  def send_password_reset(user, url) do
    deliver(user.email, "Password reset request", """
    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  # FIXME: make it work
  def send_email_update(user, url) do
    deliver(user.email, "Email update request", """
    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  def send_organization_invitation(invitation, organization, creator, url) do
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

  # FIXME: make emails optional (if not configured)
  # TODO: send all emails from a central place
  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Azimutt", Azimutt.config(:sender_email)})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
