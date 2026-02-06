"""Email service - sends the daily recap email via SMTP."""

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from config import SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, RECIPIENT_EMAIL, SENDER_NAME


def send_email(subject, html_body, plain_body=None):
    """Send an email with the given subject and HTML body.

    Args:
        subject: Email subject line.
        html_body: HTML-formatted email body.
        plain_body: Optional plain-text fallback.

    Raises:
        ValueError: If SMTP credentials are not configured.
        smtplib.SMTPException: If sending fails.
    """
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        raise ValueError(
            "SMTP credentials not configured. "
            "Copy .env.example to .env and fill in your email settings."
        )

    if not RECIPIENT_EMAIL:
        raise ValueError("RECIPIENT_EMAIL not set in .env")

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{SENDER_NAME} <{SMTP_USERNAME}>"
    msg["To"] = RECIPIENT_EMAIL

    if plain_body:
        msg.attach(MIMEText(plain_body, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.sendmail(SMTP_USERNAME, RECIPIENT_EMAIL, msg.as_string())

    print(f"Recap email sent to {RECIPIENT_EMAIL}")
