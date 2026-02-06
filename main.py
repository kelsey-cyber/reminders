#!/usr/bin/env python3
"""Daily Recap Email - track your work and get a summary emailed to you.

Usage:
    python main.py add "Fixed login bug" --category coding --project myapp
    python main.py add "Sprint planning" --category meeting
    python main.py list
    python main.py send
    python main.py preview
    python main.py schedule
"""

import argparse
import sys
import time

from daily_recap.tracker import add_activity, get_today_activities, clear_today
from daily_recap.recap_builder import build_recap
from daily_recap.email_service import send_email


def cmd_add(args):
    """Log a new activity."""
    activity = add_activity(
        description=args.description,
        category=args.category,
        project=args.project,
    )
    print(f"Logged: [{activity['category']}] {activity['description']} at {activity['timestamp']}")
    if activity["project"]:
        print(f"  Project: {activity['project']}")


def cmd_list(args):
    """Show today's logged activities."""
    activities = get_today_activities()
    if not activities:
        print("No activities logged today.")
        print('Use: python main.py add "your task description"')
        return

    print(f"Today's activities ({len(activities)} items):\n")
    for i, a in enumerate(activities, 1):
        project = f" [{a['project']}]" if a.get("project") else ""
        print(f"  {i}. {a['timestamp']}  ({a['category']}) {a['description']}{project}")


def cmd_preview(args):
    """Preview the recap email in the terminal."""
    _, _, plain_body = build_recap()
    print(plain_body)


def cmd_send(args):
    """Send the recap email now."""
    activities = get_today_activities()
    if not activities:
        print("No activities logged today. Nothing to send.")
        sys.exit(1)

    subject, html_body, plain_body = build_recap()
    try:
        send_email(subject, html_body, plain_body)
    except ValueError as e:
        print(f"Configuration error: {e}")
        sys.exit(1)


def cmd_clear(args):
    """Clear today's activities."""
    count = clear_today()
    print(f"Cleared {count} activit{'ies' if count != 1 else 'y'}.")


def cmd_schedule(args):
    """Run as a daemon, sending the recap email at the configured time each day."""
    import schedule as sched

    from config import RECAP_TIME

    def send_daily():
        activities = get_today_activities()
        if not activities:
            print("No activities logged today, skipping email.")
            return
        subject, html_body, plain_body = build_recap()
        try:
            send_email(subject, html_body, plain_body)
        except Exception as e:
            print(f"Failed to send recap: {e}")

    sched.every().day.at(RECAP_TIME).do(send_daily)
    print(f"Scheduler running. Recap email will be sent daily at {RECAP_TIME}.")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            sched.run_pending()
            time.sleep(30)
    except KeyboardInterrupt:
        print("\nScheduler stopped.")


def main():
    parser = argparse.ArgumentParser(
        description="Daily Recap Email - track your work and get a summary emailed to you."
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # add
    add_parser = subparsers.add_parser("add", help="Log a work activity")
    add_parser.add_argument("description", help="What you worked on")
    add_parser.add_argument("-c", "--category", default="general",
                            help="Category (e.g. coding, meeting, review, writing, research)")
    add_parser.add_argument("-p", "--project", default=None, help="Project name")

    # list
    subparsers.add_parser("list", help="Show today's activities")

    # preview
    subparsers.add_parser("preview", help="Preview the recap email in the terminal")

    # send
    subparsers.add_parser("send", help="Send the recap email now")

    # clear
    subparsers.add_parser("clear", help="Clear today's activities")

    # schedule
    subparsers.add_parser("schedule", help="Run scheduler to auto-send at a set time")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    commands = {
        "add": cmd_add,
        "list": cmd_list,
        "preview": cmd_preview,
        "send": cmd_send,
        "clear": cmd_clear,
        "schedule": cmd_schedule,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
