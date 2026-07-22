#!/bin/sh
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
# cron sets HOME to the user's home dir, so claude/git/ssh find ~/.claude, ~/.ssh, ~/.gitconfig

# load automation credentials (CLAUDE_CODE_OAUTH_TOKEN) — kept outside the repo, not committed.
# Generate the token once with: claude setup-token
[ -f "$HOME/.config/my-ai-daily/env" ] && . "$HOME/.config/my-ai-daily/env"

# don't let two runs overlap (brief generation can take many minutes)
LOCK=/tmp/run-daily-my-ai-daily.lock
mkdir "$LOCK" 2>/dev/null || { echo "$(date '+%F %T') skip: already running"; exit 0; }
trap 'rmdir "$LOCK"' EXIT

# 1) be in the project root (parent of src/) — where index.html etc. live
cd "$HOME/repos/my-ai-daily" || { echo "$(date '+%F %T') cd failed"; exit 1; }
echo "$(date '+%F %T') run-daily.sh starting"

# 2) generate today's brief with the Claude CLI, non-interactive —
#    skip if today's brief already exists (idempotent for a frequent schedule)
TODAY_BRIEF="$(date +%F).html"
if [ -f "$TODAY_BRIEF" ]; then
    echo "$(date '+%F %T') $TODAY_BRIEF already exists; skipping generation"
else
    claude -p "$(cat src/prompt.md)" --permission-mode bypassPermissions \
        || { echo "$(date '+%F %T') claude run failed"; exit 1; }
    echo "$(date '+%F %T') brief generated"
fi

# 3) commit & push to the remote repo (cheap; retries a stranded push, no-op if clean)
src/publish-my-ai-daily.sh
