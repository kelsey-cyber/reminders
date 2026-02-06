import os
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
RECIPIENT_EMAIL = os.getenv("RECIPIENT_EMAIL", "")
SENDER_NAME = os.getenv("SENDER_NAME", "Daily Recap Bot")
RECAP_TIME = os.getenv("RECAP_TIME", "18:00")

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
ACTIVITY_LOG = os.path.join(DATA_DIR, "activities.json")
