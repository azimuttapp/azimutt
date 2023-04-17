defmodule Azimutt.Accounts.UserNotifier do
  @moduledoc "base user notifier generate by `mix phx.gen.auth`"
  require Logger
  import Swoosh.Email
  alias Azimutt.Mailer
  alias Azimutt.Utils.Result

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

  def send_password_reset(user, url) do
    deliver(user.email, "Password reset request", """
    Hi #{user.name},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Happy database hunting,
    Samir & Loïc, from Azimutt
    """)
  end

  def send_email_update(user, previous_email, url) do
    deliver(previous_email, "Email update request", """
    Hi #{user.name},

    We got a request to change your Azimutt account email to #{user.email}
    You can confirm this change by visiting the URL below:

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
      |> from({"Azimutt team", Azimutt.config(:sender_email)})
      |> subject(subject)
      |> text_body(body)

    Mailer.deliver(email)
    |> Result.map(fn _metadata -> email end)
    |> Result.tap_error(fn {_, err} -> Logger.error("Error sending email: #{err.error.message}") end)
  end
end
