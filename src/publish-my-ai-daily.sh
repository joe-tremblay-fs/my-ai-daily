#!/bin/sh
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
# cron sets HOME to the user's home dir, so git/ssh find ~/.ssh and ~/.gitconfig

# don't let two runs overlap
LOCK=/tmp/publish-my-ai-daily.lock
mkdir "$LOCK" 2>/dev/null || { echo "$(date '+%F %T') skip: already running"; exit 0; }
trap 'rmdir "$LOCK"' EXIT

cd "$HOME/repos/my-ai-daily" || { echo "$(date '+%F %T') cd failed"; exit 1; }
echo "$(date '+%F %T') publish-my-ai-daily.sh ran"

# explicit key — no dependence on the ssh-agent
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/daily_deploy -o IdentitiesOnly=yes -o BatchMode=yes"

# commit anything new
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Daily update $(date +%F)" || { echo "  COMMIT FAILED"; exit 1; }
fi

# push whenever local is ahead — this retries commits stranded by an earlier failed push
if [ -n "$(git rev-list origin/main..HEAD 2>/dev/null)" ]; then
    git push origin main || { echo "  PUSH FAILED"; exit 1; }
    echo "  pushed OK"
else
    echo "  nothing to push"
fi