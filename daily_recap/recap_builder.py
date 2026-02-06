"""Recap builder - formats activities into an email-ready summary."""

from collections import defaultdict
from datetime import date

from jinja2 import Template

from daily_recap.tracker import get_today_activities, get_activities_for_date

HTML_TEMPLATE = Template("""\
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
  h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
  h2 { color: #2980b9; margin-top: 24px; }
  .category { background: #f8f9fa; border-left: 4px solid #3498db; padding: 12px 16px; margin: 8px 0; border-radius: 0 4px 4px 0; }
  .category-name { font-weight: 600; color: #2980b9; text-transform: capitalize; margin-bottom: 6px; }
  .activity { padding: 4px 0; }
  .time { color: #7f8c8d; font-size: 0.85em; margin-right: 8px; }
  .project { background: #e8f4fd; color: #2980b9; padding: 2px 8px; border-radius: 12px; font-size: 0.8em; margin-left: 6px; }
  .stats { background: #eaf7ea; padding: 16px; border-radius: 8px; margin-top: 24px; }
  .stats span { font-weight: 600; color: #27ae60; }
  .empty { color: #95a5a6; font-style: italic; padding: 20px; text-align: center; }
  .footer { margin-top: 32px; padding-top: 16px; border-top: 1px solid #eee; font-size: 0.85em; color: #95a5a6; }
</style>
</head>
<body>
  <h1>Daily Recap - {{ date_display }}</h1>

  {% if activities %}
  {% for category, items in grouped.items() %}
  <div class="category">
    <div class="category-name">{{ category }} ({{ items|length }})</div>
    {% for item in items %}
    <div class="activity">
      <span class="time">{{ item.timestamp }}</span>
      {{ item.description }}
      {% if item.project %}<span class="project">{{ item.project }}</span>{% endif %}
    </div>
    {% endfor %}
  </div>
  {% endfor %}

  <div class="stats">
    <span>{{ total }}</span> item{{ 's' if total != 1 else '' }} logged across
    <span>{{ category_count }}</span> categor{{ 'ies' if category_count != 1 else 'y' }}
    {% if projects %} | Projects: {{ projects | join(', ') }}{% endif %}
  </div>
  {% else %}
  <div class="empty">No activities logged today. Use <code>python main.py add "your task"</code> to start tracking!</div>
  {% endif %}

  <div class="footer">Sent by Daily Recap Bot</div>
</body>
</html>
""")

PLAIN_TEMPLATE = Template("""\
Daily Recap - {{ date_display }}
================================

{% if activities %}
{% for category, items in grouped.items() %}
[{{ category | upper }}]
{% for item in items %} - {{ item.timestamp }}  {{ item.description }}{% if item.project %} ({{ item.project }}){% endif %}
{% endfor %}
{% endfor %}
---
{{ total }} item(s) across {{ category_count }} category/categories.
{% if projects %}Projects: {{ projects | join(', ') }}{% endif %}
{% else %}
No activities logged today.
Use: python main.py add "your task"
{% endif %}
""")


def _group_by_category(activities):
    grouped = defaultdict(list)
    for a in activities:
        grouped[a["category"]].append(a)
    return dict(grouped)


def _get_projects(activities):
    return sorted({a["project"] for a in activities if a.get("project")})


def build_recap(target_date=None):
    """Build the recap email content.

    Args:
        target_date: Date to recap (defaults to today).

    Returns:
        Tuple of (subject, html_body, plain_body).
    """
    if target_date is None:
        target_date = date.today()
        activities = get_today_activities()
    else:
        activities = get_activities_for_date(target_date)

    if isinstance(target_date, date):
        date_display = target_date.strftime("%A, %B %d, %Y")
    else:
        date_display = target_date

    grouped = _group_by_category(activities)
    projects = _get_projects(activities)

    context = {
        "date_display": date_display,
        "activities": activities,
        "grouped": grouped,
        "total": len(activities),
        "category_count": len(grouped),
        "projects": projects,
    }

    subject = f"Daily Recap - {date_display}"
    html_body = HTML_TEMPLATE.render(**context)
    plain_body = PLAIN_TEMPLATE.render(**context)

    return subject, html_body, plain_body
