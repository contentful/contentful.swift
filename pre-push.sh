#!/bin/bash

# This is a pre-push hook that runs tests in command line before
# each commit. 

# to commit without pre-commit hook run "git commit --no-verify"

# Inspired by http://codeinthehole.com/writing/tips-for-using-a-git-pre-commit-hook/
# but with some modifications


# http://stackoverflow.com/a/20480591/4068264 how to properly stash/unstash
# First, stash index and work dir, keeping only the
# to-be-committed changes in the working directory.
old_stash=$(git rev-parse -q --verify refs/stash)
git stash save -q --keep-index --include-untracked
new_stash=$(git rev-parse -q --verify refs/stash)

# If there were no changes (e.g., `--amend` or `--allow-empty`)
# then nothing was stashed, and we should skip everything,
# including the tests themselves.  (Presumably the tests passed
# on the previous commit, so there is no need to re-run them.)
if [ "$old_stash" = "$new_stash" ]; then
    echo "pre-push script: No changes to test"
    exit 0
fi

# Run tests
make test
RESULT=$?

# Restore changes
git reset --hard -q && git stash apply --index -q && git stash drop -q

# Exit with status from test-run: nonzero prevents commit
exit $status


git stash apply stash^{/$PRETEST}
[ $RESULT -ne 0 ] && exit 1

