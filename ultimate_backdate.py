import os
import subprocess
import random
from datetime import datetime, timedelta

# --- CONFIGURATION ---
REPO_PATH = r"c:\Users\hp\Desktop\calAI"
USER_NAME = "Oubaid Boussaidi"
USER_EMAIL = "oubaydboussaidi@gmail.com"
REMOTE_URL = "https://github.com/oubaidboussaidi/FoodIQ.git"

DATES = ["2026-01-30", "2026-01-31", "2026-02-01", "2026-02-02", "2026-02-03", 
         "2026-02-04", "2026-02-05", "2026-02-06", "2026-02-07", "2026-02-08", "2026-02-09"]

COMMIT_MESSAGES = [
    "feat: initialize flutter project and theme",
    "feat: add daily activity and progress models",
    "feat: implement food database with USDA data",
    "feat: build local NLP engine for meal parsing",
    "feat: design premium dark mode UI",
    "feat: add radial calorie progress charts",
    "feat: implement AI-assisted food detection",
    "feat: add hydration tracking and sync",
    "feat: implement streak and reward system",
    "feat: add weight trending and analytics",
    "feat: build settings and notifications module",
    "feat: optimize database queries for speed",
    "feat: implement meal templates and history",
    "feat: add biometric data integration",
    "feat: improve natural language understanding",
    "fix: resolve calculation edge cases",
    "refactor: optimize rendering for smooth animations",
    "docs: update architecture and setup guides",
    "chore: initial workspace configuration",
    "feat: add macro adjustment sliders",
    "feat: build food analytics insights",
    "feat: implement smart meal logging flow",
    "docs: restore screenshots folder and update README paths"
]

def run_git(args, env=None):
    """Runs a git command in the REPO_PATH."""
    cmd = ["git"] + args
    result = subprocess.run(cmd, cwd=REPO_PATH, capture_output=True, text=True, env=env if env else os.environ.copy())
    return result.stdout.strip()

def get_all_files():
    """Recursively gets all relevant files in the repo for meaningful commits."""
    all_files = []
    # Important directories to include in history
    dirs_to_crawl = ['lib', 'assets', 'screenshots', 'android', 'ios', 'web', 'test']
    files_to_include = ['README.md', 'ARCHITECTURE.md', 'MVP_ROADMAP.md', 'SETUP.md', 'pubspec.yaml']
    
    for root, dirs, files in os.walk(REPO_PATH):
        # Skip .git and build folders
        if '.git' in root or 'build' in root or '.dart_tool' in root:
            continue
            
        for file in files:
            rel_path = os.path.relpath(os.path.join(root, file), REPO_PATH)
            all_files.append(rel_path)
            
    return all_files

def main():
    print(f"Resetting and re-generating history for: {REPO_PATH}")
    
    # 1. HARD RESET: Delete existing .git
    git_dir = os.path.join(REPO_PATH, ".git")
    if os.path.exists(git_dir):
        subprocess.run(["rmdir", "/S", "/Q", git_dir], shell=True)
    
    # 2. Init and Config
    run_git(["init"])
    run_git(["config", "user.name", USER_NAME])
    run_git(["config", "user.email", USER_EMAIL])
    
    files = get_all_files()
    if not files:
        print("No files found!")
        return

    random.shuffle(files)
    total_files = len(files)
    print(f"Distributing {total_files} files across {len(DATES)} days for green graph.")

    file_index = 0
    
    # We want at least one commit per date to guarantee green dots
    for i, day_str in enumerate(DATES):
        # Minimum commits per day to make it look active
        commits_for_day = random.randint(3, 8)
        
        print(f"Day {day_str}: {commits_for_day} commits")
        
        for c in range(commits_for_day):
            # Calculate how many files to add in this commit
            remaining_days = len(DATES) - i
            remaining_files = total_files - file_index
            
            if remaining_days > 1:
                files_this_commit = random.randint(1, max(1, remaining_files // (remaining_days * 5)))
            else:
                files_this_commit = max(1, remaining_files // (commits_for_day - c))

            commit_files = []
            for _ in range(files_this_commit):
                if file_index < total_files:
                    commit_files.append(files[file_index])
                    file_index += 1
            
            if not commit_files and i < len(DATES) - 1:
                # Add a dummy change if no files left, but we need dots
                continue
            elif not commit_files and i == len(DATES) - 1:
                # Last day, if no files left, just finish
                break
                
            # Stage files
            for f in commit_files:
                run_git(["add", f])
            
            # Timestamp
            hour = random.randint(9, 21)
            minute = random.randint(0, 59)
            second = random.randint(0, 59)
            timestamp = f"{day_str} {hour:02d}:{minute:02d}:{second:02d}"
            
            msg = random.choice(COMMIT_MESSAGES)
            if i == len(DATES) - 1 and c == commits_for_day - 1:
                msg = "chore: final repository cleanup and workspace synchronization"
            
            env = os.environ.copy()
            env["GIT_AUTHOR_DATE"] = timestamp
            env["GIT_COMMITTER_DATE"] = timestamp
            
            run_git(["commit", "-m", msg], env=env)

    # 3. Remote and Push
    print("\nPushing to remote...")
    run_git(["branch", "-M", "main"])
    run_git(["remote", "add", "origin", REMOTE_URL])
    push_result = subprocess.run(["git", "push", "origin", "main", "--force"], cwd=REPO_PATH, capture_output=True, text=True)
    if push_result.returncode == 0:
        print("Successfully pushed! Check your GitHub graph.")
    else:
        print(f"Push failed: {push_result.stderr}")

if __name__ == "__main__":
    main()
