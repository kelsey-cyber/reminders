# Daily Recap Email

Track what you work on throughout the day and get a summary emailed to you.

## Windows Setup (No Installation Needed)

### Step 1: Set up your email

Double-click **setup.bat** -- it will open the settings file and show you instructions for getting your Gmail App Password.

In the file that opens, find these lines near the top and replace them with your info:

```
YourEmail      = "your-email@gmail.com"
AppPassword    = "your-app-password-here"
```

Save the file and close it.

### Step 2: Use it

Open Command Prompt, go to the project folder, and use these commands:

```
.\recap.bat add "what you worked on"       Log something you did
.\recap.bat list                            See today's list
.\recap.bat send                            Send the recap email
.\recap.bat clear                           Erase today's list
```

---

## Python Setup (Mac/Linux/Advanced)

1. Install dependencies:

```bash
pip install -r requirements.txt
```

2. Configure email:

```bash
cp .env.example .env
# Edit .env with your SMTP credentials
```

For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833) (not your regular password).

### Commands

```bash
python main.py add "Fixed authentication bug"
python main.py add "Sprint planning meeting" --category meeting
python main.py add "Reviewed PR #42" --category review --project myapp
python main.py list
python main.py preview
python main.py send
python main.py schedule
python main.py clear
```

## Project Structure

```
reminders/
  recap.bat              - Windows shortcut (just type .\recap.bat)
  recap.ps1              - Windows PowerShell version (no install needed)
  setup.bat              - Double-click to set up your email
  main.py                - Python version entry point
  config.py              - Python version configuration
  daily_recap/
    tracker.py           - Activity logging (JSON-based storage)
    recap_builder.py     - Formats activities into HTML/plain-text email
    email_service.py     - Sends email via SMTP
```
