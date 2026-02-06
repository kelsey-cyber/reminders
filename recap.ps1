# Daily Recap Email Tool
# No installation needed - runs on any Windows computer with PowerShell

# --- Settings ---
# Edit these lines with your email info:
$Settings = @{
    SmtpHost       = "smtp.gmail.com"
    SmtpPort       = 587
    YourEmail      = "your-email@gmail.com"
    AppPassword    = "your-app-password-here"
    SenderName     = "Daily Recap Bot"
}

# --- File paths ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataFile = Join-Path $ScriptDir "activities.json"
$TodoFile = Join-Path $ScriptDir "todos.json"

# --- Helper functions ---

function Load-Activities {
    if (Test-Path $DataFile) {
        $content = Get-Content $DataFile -Raw
        if ($content) {
            return $content | ConvertFrom-Json
        }
    }
    return @{}
}

function Save-Activities($data) {
    $data | ConvertTo-Json -Depth 5 | Set-Content $DataFile
}

function Get-Today {
    return (Get-Date).ToString("yyyy-MM-dd")
}

# --- Commands ---

function Add-Activity {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Description,
        [string]$Category = "general",
        [string]$Project = ""
    )

    $data = Load-Activities
    $today = Get-Today
    $time = (Get-Date).ToString("HH:mm")

    $activity = @{
        description = $Description
        category    = $Category
        project     = $Project
        timestamp   = $time
    }

    # PowerShell JSON handling for adding to a date key
    if ($data.PSObject.Properties.Name -contains $today) {
        $existing = @($data.$today)
        $existing += $activity
        $data.$today = $existing
    } else {
        $data | Add-Member -NotePropertyName $today -NotePropertyValue @($activity)
    }

    Save-Activities $data

    Write-Host ""
    Write-Host "  Added: $Description" -ForegroundColor Green
    Write-Host "  Time: $time | Category: $Category" -ForegroundColor Gray
    if ($Project) { Write-Host "  Project: $Project" -ForegroundColor Gray }
    Write-Host ""
}

function Show-Activities {
    $data = Load-Activities
    $today = Get-Today

    if (-not ($data.PSObject.Properties.Name -contains $today)) {
        Write-Host ""
        Write-Host "  Nothing logged today yet." -ForegroundColor Yellow
        Write-Host "  To add something, run:  .\recap.bat add `"what you worked on`"" -ForegroundColor Gray
        Write-Host ""
        return
    }

    $activities = @($data.$today)
    $todayDisplay = (Get-Date).ToString("dddd, MMMM dd, yyyy")

    Write-Host ""
    Write-Host "  === $todayDisplay ===" -ForegroundColor Cyan
    Write-Host "  $($activities.Count) item(s) logged:" -ForegroundColor Gray
    Write-Host ""

    $i = 1
    foreach ($a in $activities) {
        $proj = ""
        if ($a.project) { $proj = " [$($a.project)]" }
        Write-Host "  $i.  $($a.timestamp)  ($($a.category)) $($a.description)$proj"
        $i++
    }
    Write-Host ""
}

function Send-RecapEmail {
    $data = Load-Activities
    $today = Get-Today

    if (-not ($data.PSObject.Properties.Name -contains $today)) {
        Write-Host ""
        Write-Host "  Nothing logged today. No email to send." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    if ($Settings.YourEmail -eq "your-email@gmail.com" -or $Settings.AppPassword -eq "your-app-password-here") {
        Write-Host ""
        Write-Host "  You haven't set up your email yet!" -ForegroundColor Red
        Write-Host "  Open 'recap.ps1' in Notepad and edit the Settings section at the top." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $activities = @($data.$today)
    $todayDisplay = (Get-Date).ToString("dddd, MMMM dd, yyyy")

    # Group by category
    $grouped = $activities | Group-Object -Property category

    # Build HTML email
    $rows = ""
    foreach ($group in $grouped) {
        $catName = $group.Name.Substring(0,1).ToUpper() + $group.Name.Substring(1)
        $rows += "<div style='background:#f8f9fa;border-left:4px solid #3498db;padding:12px 16px;margin:8px 0;border-radius:0 4px 4px 0;'>"
        $rows += "<div style='font-weight:600;color:#2980b9;margin-bottom:6px;'>$catName ($($group.Count))</div>"
        foreach ($a in $group.Group) {
            $projBadge = ""
            if ($a.project) {
                $projBadge = "<span style='background:#e8f4fd;color:#2980b9;padding:2px 8px;border-radius:12px;font-size:0.8em;margin-left:6px;'>$($a.project)</span>"
            }
            $rows += "<div style='padding:4px 0;'><span style='color:#7f8c8d;font-size:0.85em;margin-right:8px;'>$($a.timestamp)</span>$($a.description)$projBadge</div>"
        }
        $rows += "</div>"
    }

    # Collect projects
    $projects = ($activities | Where-Object { $_.project } | Select-Object -ExpandProperty project -Unique | Sort-Object) -join ", "
    $projLine = ""
    if ($projects) { $projLine = " | Projects: $projects" }

    # Build to-do list section
    $todos = Load-Todos
    $todoSection = ""
    if ($todos.Count -gt 0) {
        $todoSection = "<h2 style='color:#2c3e50;border-bottom:2px solid #e67e22;padding-bottom:10px;margin-top:32px;'>Tomorrow's To-Do List</h2>"
        foreach ($t in $todos) {
            $checkStyle = "width:18px;height:18px;border:2px solid #e67e22;border-radius:4px;display:inline-block;margin-right:10px;vertical-align:middle;"
            $textStyle = "font-size:1em;"
            if ($t.done) {
                $checkStyle = "width:18px;height:18px;border:2px solid #27ae60;border-radius:4px;display:inline-block;margin-right:10px;vertical-align:middle;background:#27ae60;color:white;text-align:center;line-height:18px;font-size:12px;"
                $textStyle = "font-size:1em;text-decoration:line-through;color:#95a5a6;"
                $todoSection += "<div style='padding:8px 0;'><span style='$checkStyle'>&#10003;</span><span style='$textStyle'>$($t.description)</span></div>"
            } else {
                $todoSection += "<div style='padding:8px 0;'><span style='$checkStyle'></span><span style='$textStyle'>$($t.description)</span></div>"
            }
        }
    }

    $html = @"
<!DOCTYPE html>
<html><body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#333;max-width:600px;margin:0 auto;padding:20px;">
<h1 style="color:#2c3e50;border-bottom:2px solid #3498db;padding-bottom:10px;">Daily Recap - $todayDisplay</h1>
$rows
<div style="background:#eaf7ea;padding:16px;border-radius:8px;margin-top:24px;">
<span style="font-weight:600;color:#27ae60;">$($activities.Count)</span> item(s) across <span style="font-weight:600;color:#27ae60;">$($grouped.Count)</span> category/categories$projLine
</div>
$todoSection
<div style="margin-top:32px;padding-top:16px;border-top:1px solid #eee;font-size:0.85em;color:#95a5a6;">Sent by Daily Recap Bot</div>
</body></html>
"@

    $subject = "Daily Recap - $todayDisplay"

    # Send the email
    try {
        $password = ConvertTo-SecureString $Settings.AppPassword -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($Settings.YourEmail, $password)

        $mailParams = @{
            From       = "$($Settings.SenderName) <$($Settings.YourEmail)>"
            To         = $Settings.YourEmail
            Subject    = $subject
            Body       = $html
            BodyAsHtml = $true
            SmtpServer = $Settings.SmtpHost
            Port       = $Settings.SmtpPort
            UseSsl     = $true
            Credential = $credential
        }

        Send-MailMessage @mailParams

        Write-Host ""
        Write-Host "  Email sent to $($Settings.YourEmail)!" -ForegroundColor Green
        Write-Host "  Check your inbox." -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "  Failed to send email." -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Common fixes:" -ForegroundColor Gray
        Write-Host "  - Make sure your email and app password are correct in recap.ps1" -ForegroundColor Gray
        Write-Host "  - Make sure you created an App Password (not your regular password)" -ForegroundColor Gray
        Write-Host ""
    }
}

# --- To-do list functions ---

function Load-Todos {
    if (Test-Path $TodoFile) {
        $content = Get-Content $TodoFile -Raw
        if ($content) {
            return @(($content | ConvertFrom-Json))
        }
    }
    return @()
}

function Save-Todos($todos) {
    if ($todos.Count -eq 0) {
        "[]" | Set-Content $TodoFile
    } else {
        $todos | ConvertTo-Json -Depth 5 | Set-Content $TodoFile
    }
}

function Add-Todo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Description
    )

    $todos = Load-Todos
    $todo = @{
        description = $Description
        done        = $false
    }
    $todos += $todo
    Save-Todos $todos

    Write-Host ""
    Write-Host "  To-do added: $Description" -ForegroundColor Green
    Write-Host "  You now have $($todos.Count) item(s) on tomorrow's list." -ForegroundColor Gray
    Write-Host ""
}

function Show-Todos {
    $todos = Load-Todos

    if ($todos.Count -eq 0) {
        Write-Host ""
        Write-Host "  No to-do items yet." -ForegroundColor Yellow
        Write-Host "  To add one, run:  recap.bat todo `"what you need to do tomorrow`"" -ForegroundColor Gray
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "  === Tomorrow's To-Do List ===" -ForegroundColor Cyan
    Write-Host ""

    $i = 1
    foreach ($t in $todos) {
        $check = " "
        $color = "White"
        if ($t.done) { $check = "x"; $color = "DarkGray" }
        Write-Host "  $i. [$check] $($t.description)" -ForegroundColor $color
        $i++
    }
    Write-Host ""
}

function Complete-Todo {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Number
    )

    $todos = Load-Todos

    if ($Number -lt 1 -or $Number -gt $todos.Count) {
        Write-Host ""
        Write-Host "  Invalid number. You have $($todos.Count) to-do item(s)." -ForegroundColor Red
        Write-Host ""
        return
    }

    $todos[$Number - 1].done = $true
    Save-Todos $todos

    Write-Host ""
    Write-Host "  Done: $($todos[$Number - 1].description)" -ForegroundColor Green
    Write-Host ""
}

function Remove-Todo {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Number
    )

    $todos = @(Load-Todos)

    if ($Number -lt 1 -or $Number -gt $todos.Count) {
        Write-Host ""
        Write-Host "  Invalid number. You have $($todos.Count) to-do item(s)." -ForegroundColor Red
        Write-Host ""
        return
    }

    $removed = $todos[$Number - 1].description
    $newTodos = @()
    for ($i = 0; $i -lt $todos.Count; $i++) {
        if ($i -ne ($Number - 1)) {
            $newTodos += $todos[$i]
        }
    }
    Save-Todos $newTodos

    Write-Host ""
    Write-Host "  Removed: $removed" -ForegroundColor Green
    Write-Host ""
}

function Clear-AllTodos {
    Save-Todos @()
    Write-Host ""
    Write-Host "  To-do list cleared." -ForegroundColor Green
    Write-Host ""
}

function Clear-TodayActivities {
    $data = Load-Activities
    $today = Get-Today

    if ($data.PSObject.Properties.Name -contains $today) {
        $count = @($data.$today).Count
        $data.PSObject.Properties.Remove($today)
        Save-Activities $data
        Write-Host ""
        Write-Host "  Cleared $count item(s)." -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "  Nothing to clear." -ForegroundColor Yellow
        Write-Host ""
    }
}

function Show-Help {
    Write-Host ""
    Write-Host "  ===============================" -ForegroundColor Cyan
    Write-Host "     Daily Recap Email Tool" -ForegroundColor Cyan
    Write-Host "  ===============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  COMMANDS:" -ForegroundColor White
    Write-Host ""
    Write-Host "  .\recap.bat add `"what you worked on`"" -ForegroundColor Green
    Write-Host "      Log something you did" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat add `"task`" -category meeting" -ForegroundColor Green
    Write-Host "      Log with a category (coding, meeting, review, writing, research)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat add `"task`" -category coding -project myapp" -ForegroundColor Green
    Write-Host "      Log with a category and project name" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat list" -ForegroundColor Green
    Write-Host "      See everything you logged today" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat send" -ForegroundColor Green
    Write-Host "      Send the recap email to yourself" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat clear" -ForegroundColor Green
    Write-Host "      Erase today's list and start over" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  TOMORROW'S TO-DO LIST:" -ForegroundColor White
    Write-Host ""
    Write-Host "  .\recap.bat todo `"task for tomorrow`"" -ForegroundColor Green
    Write-Host "      Add something to tomorrow's to-do list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat todos" -ForegroundColor Green
    Write-Host "      See tomorrow's to-do list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat done 1" -ForegroundColor Green
    Write-Host "      Mark a to-do item as done (use the number from the list)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat remove 1" -ForegroundColor Green
    Write-Host "      Remove a to-do item (use the number from the list)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\recap.bat cleartodos" -ForegroundColor Green
    Write-Host "      Erase the whole to-do list" -ForegroundColor Gray
    Write-Host ""
}

# --- Run the right command ---

$command = $args[0]

switch ($command) {
    "add" {
        if ($args.Count -lt 2) {
            Write-Host ""
            Write-Host "  What did you work on?" -ForegroundColor Yellow
            Write-Host "  Usage: .\recap.bat add `"what you did`"" -ForegroundColor Gray
            Write-Host ""
        } else {
            $desc = $args[1]
            $cat = "general"
            $proj = ""

            for ($i = 2; $i -lt $args.Count; $i++) {
                if ($args[$i] -eq "-category" -and ($i + 1) -lt $args.Count) {
                    $cat = $args[$i + 1]; $i++
                }
                if ($args[$i] -eq "-project" -and ($i + 1) -lt $args.Count) {
                    $proj = $args[$i + 1]; $i++
                }
            }

            Add-Activity -Description $desc -Category $cat -Project $proj
        }
    }
    "list"  { Show-Activities }
    "send"  { Send-RecapEmail }
    "clear" { Clear-TodayActivities }
    "todo" {
        if ($args.Count -lt 2) {
            Write-Host ""
            Write-Host "  What do you need to do tomorrow?" -ForegroundColor Yellow
            Write-Host "  Usage: recap.bat todo `"task for tomorrow`"" -ForegroundColor Gray
            Write-Host ""
        } else {
            Add-Todo -Description $args[1]
        }
    }
    "todos" { Show-Todos }
    "done" {
        if ($args.Count -lt 2) {
            Write-Host ""
            Write-Host "  Which item number? Run 'recap.bat todos' to see the list." -ForegroundColor Yellow
            Write-Host ""
        } else {
            Complete-Todo -Number ([int]$args[1])
        }
    }
    "remove" {
        if ($args.Count -lt 2) {
            Write-Host ""
            Write-Host "  Which item number? Run 'recap.bat todos' to see the list." -ForegroundColor Yellow
            Write-Host ""
        } else {
            Remove-Todo -Number ([int]$args[1])
        }
    }
    "cleartodos" { Clear-AllTodos }
    default { Show-Help }
}
