#!/bin/bash
# Release contentful.swift. CircleCI runs the same steps as a manual release.
#
# Usage: ./Scripts/release.sh <step>
#
#   validate        version files agree, version is new and greater than the last tag,
#                   no branch named like the version, working tree clean
#   xcframework     build Carthage/Build/Contentful.xcframework and zip it (ditto) into build/release/
#   tag             tag RELEASE_COMMIT (default: HEAD) and push only that tag
#   github-release  create the GitHub release (generated notes) and attach the xcframework zip
#   docs            generate the Jazzy reference docs for the tag and force-push them to gh-pages
#   all             validate, xcframework, tag, github-release, docs
#
# Environment:
#   DRY_RUN=1        print the commands that would change anything on GitHub instead of running them
#   RELEASE_COMMIT   commit to tag (CI passes $CIRCLE_SHA1); defaults to HEAD
#   GITHUB_TOKEN     used for pushes and the GitHub API when set (CI); otherwise your git/gh auth is used
#   GIT_REMOTE       remote to fetch from and push to (default: origin)
#
# CocoaPods: new versions are no longer pushed to trunk (read-only from 2026-12-02). Existing
# versions stay installable. See RELEASING.md.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

REPO_SLUG="contentful/contentful.swift"
GIT_REMOTE="${GIT_REMOTE:-origin}"
RELEASE_DIR="$ROOT/build/release"
ZIP_NAME="Contentful.xcframework.zip"
DRY_RUN="${DRY_RUN:-0}"

VERSION="$(sed -n 's/^CONTENTFUL_SDK_VERSION=//p' .env | tr -d '[:space:]')"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  export GH_TOKEN="${GH_TOKEN:-$GITHUB_TOKEN}"
fi

log()  { printf '\n==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Runs a command that changes remote state, or prints it when DRY_RUN=1.
publish() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# git with GitHub auth from GITHUB_TOKEN when it is set (CI). Locally it falls back to your own credentials.
git_auth() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    local basic
    basic="$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')"
    git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $basic" "$@"
  else
    git "$@"
  fi
}

# Remote to push to: an HTTPS URL when a token is available (CI checkout keys are read-only), else GIT_REMOTE.
push_target() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "https://github.com/$REPO_SLUG.git"
  else
    echo "$GIT_REMOTE"
  fi
}

remote_tag_sha() {
  git_auth ls-remote "$(push_target)" "refs/tags/$VERSION^{}" "refs/tags/$VERSION" | awk 'NR==1{print $1}'
}

require() {
  command -v "$1" >/dev/null 2>&1 || fail "'$1' is required. $2"
}

step_validate() {
  log "Validating release $VERSION"

  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail ".env has an invalid version '$VERSION'"

  local xcconfig_version
  xcconfig_version="$(sed -n 's/^CONTENTFUL_SDK_VERSION=//p' Config.xcconfig | tr -d '[:space:]')"
  [[ "$xcconfig_version" == "$VERSION" ]] \
    || fail "Config.xcconfig has '$xcconfig_version' but .env has '$VERSION'. Run ./Scripts/set-version.sh $VERSION"

  [[ -z "$(git status --porcelain --untracked-files=no)" ]] \
    || fail "Working tree has uncommitted changes to tracked files"

  git fetch --quiet --tags --force "$GIT_REMOTE"

  if [[ -n "$(remote_tag_sha)" ]]; then
    fail "Tag $VERSION already exists on $GIT_REMOTE. Bump the version with ./Scripts/set-version.sh"
  fi

  local latest
  latest="$(git tag -l '[0-9]*.[0-9]*.[0-9]*' | sort -V | tail -1)"
  if [[ -n "$latest" ]]; then
    [[ "$(printf '%s\n%s\n' "$latest" "$VERSION" | sort -V | tail -1)" == "$VERSION" ]] \
      || fail "$VERSION is not greater than the latest tag $latest"
  fi

  if git ls-remote --exit-code --heads "$GIT_REMOTE" "$VERSION" >/dev/null 2>&1; then
    fail "A branch named '$VERSION' exists on $GIT_REMOTE. Rename or delete it, because it makes the tag ambiguous"
  fi

  local commit
  commit="$(git rev-parse "${RELEASE_COMMIT:-HEAD}^{commit}")"
  if ! git merge-base --is-ancestor "$commit" "$GIT_REMOTE/master" 2>/dev/null; then
    git fetch --quiet "$GIT_REMOTE" master
    git merge-base --is-ancestor "$commit" "$GIT_REMOTE/master" \
      || fail "Commit $commit is not on $GIT_REMOTE/master. Releases are made from master only"
  fi

  echo "OK: $VERSION (previous: ${latest:-none}) from $commit"
}

step_xcframework() {
  log "Building Contentful.xcframework $VERSION"
  require carthage "Install it with: brew install carthage"
  require ditto "ditto ships with macOS"

  rm -rf Carthage/Build/Contentful.xcframework "$RELEASE_DIR"
  mkdir -p "$RELEASE_DIR"

  carthage build Contentful \
    --no-skip-current \
    --platform all \
    --use-xcframeworks \
    --derived-data "$ROOT/build/DerivedData"

  [[ -d Carthage/Build/Contentful.xcframework ]] || fail "Carthage did not produce Carthage/Build/Contentful.xcframework"

  # ditto keeps the symlinks inside the macOS framework slice. zip -r would break them.
  ditto -c -k --sequesterRsrc --keepParent Carthage/Build/Contentful.xcframework "$RELEASE_DIR/$ZIP_NAME"
  (cd "$RELEASE_DIR" && shasum -a 256 "$ZIP_NAME" | tee "$ZIP_NAME.sha256")
  ls -lh "$RELEASE_DIR/$ZIP_NAME"
}

step_tag() {
  local commit existing
  commit="$(git rev-parse "${RELEASE_COMMIT:-HEAD}^{commit}")"
  log "Tagging $commit as $VERSION"

  existing="$(remote_tag_sha)"
  if [[ -n "$existing" ]]; then
    [[ "$existing" == "$commit" ]] || fail "Tag $VERSION already exists on a different commit ($existing)"
    echo "Tag $VERSION already points at $commit, nothing to do"
    return
  fi

  if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
    [[ "$(git rev-parse "refs/tags/$VERSION^{commit}")" == "$commit" ]] \
      || fail "A local tag $VERSION exists on a different commit. Delete it with: git tag -d $VERSION"
  elif [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] git tag %s %s\n' "$VERSION" "$commit"
  else
    git tag "$VERSION" "$commit"
  fi

  # Push only this tag, never --tags.
  publish git_auth push "$(push_target)" "refs/tags/$VERSION"
}

step_github_release() {
  log "Publishing GitHub release $VERSION"
  require gh "Install it with: brew install gh"

  local zip="$RELEASE_DIR/$ZIP_NAME"
  [[ -f "$zip" ]] || fail "$zip not found. Run: ./Scripts/release.sh xcframework"

  if gh release view "$VERSION" --repo "$REPO_SLUG" >/dev/null 2>&1; then
    echo "Release $VERSION exists, uploading the xcframework again"
    publish gh release upload "$VERSION" "$zip" --clobber --repo "$REPO_SLUG"
  else
    publish gh release create "$VERSION" "$zip" \
      --repo "$REPO_SLUG" \
      --title "$VERSION" \
      --generate-notes \
      --latest \
      --verify-tag
  fi
}

step_docs() {
  log "Publishing reference docs for $VERSION to gh-pages"
  require bundle "Run: gem install bundler && bundle install"

  local ref="refs/tags/$VERSION"
  if ! git rev-parse -q --verify "$ref" >/dev/null; then
    [[ "$DRY_RUN" == "1" ]] || fail "Tag $VERSION not found locally. Run: ./Scripts/release.sh tag"
    ref="${RELEASE_COMMIT:-HEAD}"
  fi

  # Build in a separate worktree so the current checkout is never switched or modified.
  local worktree status=0
  worktree="$(mktemp -d "${TMPDIR:-/tmp}/contentful-docs.XXXXXX")"
  git worktree add --quiet --detach "$worktree" "$ref"

  # errexit must stay active inside the subshell, so capture its status without `||`.
  set +e
  (
    set -e
    cd "$worktree"
    BUNDLE_GEMFILE="$ROOT/Gemfile" BUNDLE_PATH="$ROOT/vendor/bundle" ./Scripts/reference-docs.sh
    # Jazzy --clean wipes docs/. Keep the hand-written ADRs that live next to the generated site.
    if git cat-file -e "$ref:docs/ADRs" 2>/dev/null; then
      git checkout "$ref" -- docs/ADRs
    fi
    git add -A docs
    git -c user.name="${GIT_AUTHOR_NAME:-Contentful SDK Release}" \
        -c user.email="${GIT_AUTHOR_EMAIL:-sdk-release@contentful.com}" \
        commit --quiet --allow-empty -m "docs: reference documentation for $VERSION"
    # gh-pages = release commit + one docs commit, same shape as before.
    publish git_auth push --force "$(push_target)" HEAD:refs/heads/gh-pages
  )
  status=$?
  set -e

  git worktree remove --force "$worktree" >/dev/null 2>&1 || true
  return "$status"
}

case "${1:-}" in
  validate)       step_validate ;;
  xcframework)    step_xcframework ;;
  tag)            step_tag ;;
  github-release) step_github_release ;;
  docs)           step_docs ;;
  all)
    step_validate
    step_xcframework
    step_tag
    step_github_release
    step_docs
    if [[ "$DRY_RUN" == "1" ]]; then
      log "Dry run of $VERSION finished. Nothing was pushed"
    else
      log "Contentful $VERSION released"
    fi
    ;;
  *)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
