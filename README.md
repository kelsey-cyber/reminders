# Daily Recap Email

A CLI tool to track what you work on throughout the day and send yourself a recap email summary.

## Setup

1. Install dependencies:

```bash
pip install -r requirements.txt
```

2. Configure email settings:

```bash
cp .env.example .env
# Edit .env with your SMTP credentials
```

For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833) (not your regular password).

## Usage

### Log activities throughout the day

```bash
python main.py add "Fixed authentication bug"
python main.py add "Sprint planning meeting" --category meeting
python main.py add "Reviewed PR #42" --category review --project myapp
```

Categories: `general`, `coding`, `meeting`, `review`, `writing`, `research` (or any custom string).

### View today's log

```bash
python main.py list
```

### Preview the recap

```bash
python main.py preview
```

### Send the recap email

```bash
python main.py send
```

### Auto-send on a schedule

```bash
python main.py schedule
```

This runs a background process that sends the recap at the time set in `.env` (`RECAP_TIME`, default `18:00`).

### Clear today's activities

```bash
python main.py clear
```

## Project Structure

```
reminders/
  config.py              - Configuration (loads from .env)
  main.py                - CLI entry point
  daily_recap/
    tracker.py           - Activity logging (JSON-based storage)
    recap_builder.py     - Formats activities into HTML/plain-text email
    email_service.py     - Sends email via SMTP
  data/
    activities.json      - Stored activities (auto-created, git-ignored)
```
