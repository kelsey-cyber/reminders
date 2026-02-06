"""Activity tracker - logs work items throughout the day."""

import json
import os
from datetime import datetime, date

from config import ACTIVITY_LOG, DATA_DIR


def _ensure_data_dir():
    os.makedirs(DATA_DIR, exist_ok=True)


def _load_all():
    """Load all activity data from disk."""
    _ensure_data_dir()
    if not os.path.exists(ACTIVITY_LOG):
        return {}
    with open(ACTIVITY_LOG, "r") as f:
        return json.load(f)


def _save_all(data):
    """Save all activity data to disk."""
    _ensure_data_dir()
    with open(ACTIVITY_LOG, "w") as f:
        json.dump(data, f, indent=2)


def add_activity(description, category="general", project=None):
    """Log a work activity for today.

    Args:
        description: What you worked on.
        category: Type of work (e.g. coding, meeting, review, writing, research).
        project: Optional project name.

    Returns:
        The saved activity dict.
    """
    data = _load_all()
    today = date.today().isoformat()

    if today not in data:
        data[today] = []

    activity = {
        "description": description,
        "category": category,
        "project": project,
        "timestamp": datetime.now().strftime("%H:%M"),
    }
    data[today].append(activity)
    _save_all(data)
    return activity


def get_today_activities():
    """Return all activities logged today."""
    data = _load_all()
    today = date.today().isoformat()
    return data.get(today, [])


def get_activities_for_date(target_date):
    """Return activities for a specific date (YYYY-MM-DD string or date object)."""
    data = _load_all()
    if isinstance(target_date, date):
        target_date = target_date.isoformat()
    return data.get(target_date, [])


def clear_today():
    """Remove all of today's activities."""
    data = _load_all()
    today = date.today().isoformat()
    removed = len(data.pop(today, []))
    _save_all(data)
    return removed
