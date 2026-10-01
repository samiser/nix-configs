#!/usr/bin/env bash

NIXPKGS_DIR="$STATE_DIR/nixpkgs"
REVIEW_REPO="$GH_USER/nixpkgs-review-gha"

GH_TOKEN=$(tr -d '\n' <"$TOKEN_FILE")
export GH_TOKEN

failed=0

if [ ! -d "$NIXPKGS_DIR/.git" ]; then
  echo "cloning nixpkgs into $NIXPKGS_DIR (several minutes, one time only)"
  git clone --origin upstream https://github.com/NixOS/nixpkgs.git "$NIXPKGS_DIR"
fi

fork="git@github.com:$GH_USER/nixpkgs.git"
git -C "$NIXPKGS_DIR" remote set-url origin "$fork" 2>/dev/null ||
  git -C "$NIXPKGS_DIR" remote add origin "$fork"

if ! gh repo sync "$GH_USER/nixpkgs" --branch master; then
  echo "could not sync fork master from upstream"
  exit 1
fi

git -C "$NIXPKGS_DIR" fetch --quiet origin master

cd "$NIXPKGS_DIR" || exit

newest() {
  printf '%s\n%s\n' "$1" "$2" | sed 's/-/~/' | sort -V | tail -n1 | sed 's/~/-/'
}

supports() {
  [ -z "$platforms" ] && return 0
  case " $platforms " in
  *" $1 "*) return 0 ;;
  esac
  return 1
}

count=$(jq 'length' "$SPECS_FILE")
i=0
while [ "$i" -lt "$count" ]; do
  name=$(jq -r ".[$i].name" "$SPECS_FILE")
  pref=$(jq -r ".[$i].versionPreference" "$SPECS_FILE")
  i=$((i + 1))

  branch="auto-update/$name"

  git reset --quiet --hard
  git clean -qfd
  git checkout --quiet -B "$branch" origin/master

  before=$(git rev-parse HEAD)

  platforms=$(nix-instantiate --eval --json -E \
    "(import $NIXPKGS_DIR { }).\"$name\".meta.platforms or [ ]" 2>/dev/null |
    jq -r 'join(" ")' || echo "")

  args=(--commit "--version=$pref")

  ntests=$(nix-instantiate --eval --json -E \
    "builtins.length (builtins.attrNames ((import $NIXPKGS_DIR { }).\"$name\".passthru.tests or { }))" \
    2>/dev/null || echo 0)
  review_args=()
  if [ "$ntests" != "0" ]; then
    review_args+=(-f extra-args=--tests)
    tests_box="x"
  else
    tests_box=" "
  fi

  if ! nix-update "${args[@]}" "$name"; then
    echo "$name: nix-update failed"
    failed=1
    continue
  fi

  after=$(git rev-parse HEAD)
  if [ "$before" = "$after" ]; then
    echo "$name: already up to date"
    continue
  fi

  subject=$(git log -1 --pretty=%s)
  rest=${subject#*: }
  old=${rest%% -> *}
  new=${rest##* -> }

  if [ "$(newest "$old" "$new")" != "$new" ]; then
    echo "$name: refusing downgrade $old -> $new"
    git reset --quiet --hard origin/master
    continue
  fi

  changes_link=$(nix-instantiate --eval --json -E \
    "(import $NIXPKGS_DIR { }).\"$name\".meta.changelog or \"\"" 2>/dev/null |
    jq -r 'if type == "array" then .[0] else . end' || echo "")

  if [ -z "$changes_link" ]; then
    src_url=$(nix-instantiate --eval --json -E \
      "(import $NIXPKGS_DIR { }).\"$name\".src.url or \"\"" 2>/dev/null | jq -r . || echo "")
    repo=$(printf '%s' "$src_url" | sed -nE 's#^https://github\.com/([^/]+)/([^/]+)/.*#\1/\2#p')
    new_tag=$(printf '%s' "$src_url" |
      sed -nE 's#^https://github\.com/[^/]+/[^/]+/(archive/(refs/tags/)?(.+)\.tar\.gz|releases/download/([^/]+)/.*)$#\3\4#p')

    if [ -n "$repo" ] && [ -n "$new_tag" ] && [ "${new_tag#*"$new"}" != "$new_tag" ]; then
      # hyprmag tags "2.2.0" while the noctalia repos tag "v5.0.0"; reuse
      # whatever prefix the new tag carries to name the old one
      prefix=${new_tag%%"$new"*}
      changes_link="https://github.com/$repo/compare/$prefix$old...$prefix$new"
    fi
  fi

  changelog_line=""
  if [ -n "$changes_link" ]; then
    changelog_line="
Changelog: $changes_link
"
  fi

  # force-pushing a branch that already carries an open PR would silently
  # swap that PR's diff out from under its title
  if ! open_on_branch=$(gh pr list --repo NixOS/nixpkgs --head "$branch" --state open \
    --json number --jq '.[0].number // empty'); then
    echo "$name: could not list open PRs, skipping"
    failed=1
    continue
  fi
  if [ -n "$open_on_branch" ]; then
    echo "$name: PR #$open_on_branch is already open on $branch, skipping"
    continue
  fi

  # nixpkgs commit subjects are mechanically "pkg: old -> new", so an exact
  # title match finds the same bump proposed by anyone, on any branch, and a
  # closed one means it was already turned down
  if ! proposed=$(gh pr list --repo NixOS/nixpkgs --search "\"$subject\" in:title" --state all \
    --limit 20 --json number,state,title,author |
    jq -r --arg s "$subject" \
      'map(select(.title == $s)) | .[0] // empty | "#\(.number) \(.state | ascii_downcase) by \(.author.login)"'); then
    echo "$name: could not search existing PRs, skipping"
    failed=1
    continue
  fi
  if [ -n "$proposed" ]; then
    echo "$name: \"$subject\" already proposed as $proposed, skipping"
    continue
  fi

  review_systems=""
  review_args+=(-f pr=PR_NUMBER)
  for s in x86_64-linux aarch64-linux; do
    if supports "$s"; then
      review_args+=(-f "$s=true")
      review_systems="${review_systems:+$review_systems, }$s"
    else
      review_args+=(-f "$s=false")
    fi
  done
  for s in x86_64-darwin aarch64-darwin; do
    if supports "$s"; then
      review_args+=(-f "$s=yes_sandbox_relaxed")
      review_systems="${review_systems:+$review_systems, }$s"
    else
      review_args+=(-f "$s=no")
    fi
  done

  body=$(
    cat <<BODY
Automatic update by [nix-update](https://github.com/Mic92/nix-update).
$changelog_line
## Things done

- Built on platform:
  - [ ] x86_64-linux
  - [ ] aarch64-linux
  - [ ] x86_64-darwin
  - [ ] aarch64-darwin
- Tested, as applicable:
  - [ ] [NixOS tests] in [nixos/tests].
  - [$tests_box] [Package tests] at \`passthru.tests\`.
  - [ ] Tests in [lib/tests] or [pkgs/test] for functions and "core" functionality.
- [x] Ran \`nixpkgs-review\` on this PR. See [nixpkgs-review usage].
- [ ] Tested basic functionality of all binary files, usually in \`./result/bin/\`.
- Nixpkgs Release Notes
  - [ ] Package update: when the change is major or breaking.
- NixOS Release Notes
  - [ ] Module addition: when adding a new NixOS module.
  - [ ] Module update: when the change is significant.
- [x] Fits [CONTRIBUTING.md], [pkgs/README.md], [maintainers/README.md] and other READMEs.
- [x] Follows the [automation/AI policy].

[NixOS tests]: https://nixos.org/manual/nixos/unstable/index.html#sec-nixos-tests
[Package tests]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md#package-tests
[nixpkgs-review usage]: https://github.com/Mic92/nixpkgs-review#usage

[CONTRIBUTING.md]: https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md
[automation/AI policy]: https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md#automationai-policy
[lib/tests]: https://github.com/NixOS/nixpkgs/blob/master/lib/tests
[maintainers/README.md]: https://github.com/NixOS/nixpkgs/blob/master/maintainers/README.md
[nixos/tests]: https://github.com/NixOS/nixpkgs/blob/master/nixos/tests
[pkgs/README.md]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md
[pkgs/test]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/test
BODY
  )

  if [ "$CREATE_PRS" != "true" ]; then
    echo "$name: would open PR \"$subject\" (dry run, nothing pushed)"
    if [ -n "$changes_link" ]; then
      echo "$name: changes $changes_link"
    else
      echo "$name: no changes link (no meta.changelog, src is not a github tag archive or release asset)"
    fi
    echo "$name: would run: gh workflow run review.yml --repo $REVIEW_REPO ${review_args[*]}"
    continue
  fi

  if ! git push --quiet --force origin "$branch"; then
    echo "$name: push failed, skipping"
    failed=1
    continue
  fi

  if ! pr_url=$(gh pr create \
    --repo NixOS/nixpkgs \
    --base master \
    --head "$GH_USER:$branch" \
    --title "$subject" \
    --body "$body"); then
    echo "$name: pr create failed, skipping"
    failed=1
    continue
  fi

  pr_number=${pr_url##*/}
  echo "$name: opened PR #$pr_number for $old -> $new"

  review_args=("${review_args[@]/pr=PR_NUMBER/pr=$pr_number}")
  if ! gh workflow run review.yml --repo "$REVIEW_REPO" "${review_args[@]}"; then
    echo "$name: could not start nixpkgs-review-gha for #$pr_number"
    failed=1
    continue
  fi
  echo "$name: started nixpkgs-review-gha for #$pr_number on $review_systems"
done

exit "$failed"
