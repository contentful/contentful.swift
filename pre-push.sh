#!/bin/bash

# This is a pre-push hook that runs tests in command line before
# each commit. 

# to commit without pre-commit hook run "git commit --no-verify"

# Inspired by http://codeinthehole.com/writing/tips-for-using-a-git-pre-commit-hook/



# Stash unstaged changes before testing so we can isolate the broken tests to commits
git stash -q --keep-index

# Run tests
make test
RESULT=$?
git stash pop -q
[ $RESULT -ne 0 ] && exit 1

