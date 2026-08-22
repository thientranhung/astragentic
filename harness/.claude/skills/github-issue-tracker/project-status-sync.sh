#!/usr/bin/env bash
# Mirror the tracker's LABEL state onto the owner's GitHub Project Status column.
#
# The label is the source of truth: the frontier is derived from labels + native issue
# dependencies, and Status takes part in no query. Status is a one-way MIRROR, written so the
# owner — the one person who does not run queries — can open the board and see the truth.
# PROJ-033 is why this exists: for one day the board showed 68 tickets in Backlog while three
# of them had live Builders on them.
#
#   ./project-status-sync.sh            # report the drift, change nothing
#   ./project-status-sync.sh --apply    # write it
#
# Mapping (closed wins over any label):
#   closed              -> Done
#   open + in-progress  -> In progress
#   open + todo         -> Ready
#   open + backlog      -> Backlog
# An issue carrying none of the three status labels is REPORTED, never guessed at.
# CONFIGURATION — per project, and this script refuses to guess any of it. Put the values in
# the project's own copy of this file, or export them before calling.
#
#   GH_PROJECT_OWNER    the user or org that owns the Project (not the repo owner, if they differ)
#   GH_PROJECT_NUMBER   the number in the Project's URL
#
# The Status field id and its option ids are discovered at runtime rather than pasted. They are
# opaque per-project strings, and a stale pasted one writes to a field that is not the one on the
# board — a silent wrong write, which is the class this whole mirror exists to prevent.
set -euo pipefail

OWNER="${GH_PROJECT_OWNER:?set GH_PROJECT_OWNER (the Project owner login)}"
PROJECT_NUMBER="${GH_PROJECT_NUMBER:?set GH_PROJECT_NUMBER (the number in the Project URL)}"

# Requirement 5 has an auth precondition, and its failure is SILENT: without the `project`
# OAuth scope, project queries return empty rather than erroring, which reads exactly like
# "nothing is on a board". Check it before believing any emptiness below.
gh auth status 2>&1 | grep -q "'project'" || {
  echo "STOP: gh is missing the 'project' OAuth scope, and without it this script cannot tell" >&2
  echo "      an empty board from an unauthorised read. The OWNER runs: gh auth refresh -s project" >&2
  exit 1
}

# Discover the Status field and its options for THIS project.
read -r FIELD_ID FIELD_OPTIONS <<EOF
$(gh api graphql -f query='{ user(login:"'"$OWNER"'"){ projectV2(number:'"$PROJECT_NUMBER"'){ field(name:"Status"){ ... on ProjectV2SingleSelectField { id options { id name } } } } } }' \
  --jq '.data.user.projectV2.field | [.id, ([.options[] | .name + "=" + .id] | join(";"))] | @tsv')
EOF
[ -n "${FIELD_ID:-}" ] && [ "$FIELD_ID" != "null" ] || {
  echo "STOP: project $OWNER/#$PROJECT_NUMBER has no single-select field named 'Status'" >&2
  exit 1
}

# macOS ships bash 3.2, which has no associative arrays — string lookup is the portable form.
opt_id() {
  local want="$1" pair
  IFS=';' read -ra pairs <<< "$FIELD_OPTIONS"
  for pair in "${pairs[@]}"; do
    [ "${pair%%=*}" = "$want" ] && { echo "${pair#*=}"; return 0; }
  done
  echo "STOP: this project's Status field has no option named '$want'." >&2
  echo "      Options present: ${FIELD_OPTIONS//;/, }" >&2
  echo "      Either add it in the Project UI (an owner action) or change the mapping below." >&2
  exit 1
}

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

PROJECT_ID=$(gh api graphql -f query="{ user(login:\"$OWNER\"){ projectV2(number:$PROJECT_NUMBER){ id } } }" \
  --jq '.data.user.projectV2.id')

items=$(gh api graphql --paginate -f query='query($c:String){ user(login:"'"$OWNER"'"){ projectV2(number:'"$PROJECT_NUMBER"'){ items(first:100, after:$c){ pageInfo{hasNextPage endCursor} nodes{ id content{ ... on Issue { number state labels(first:20){nodes{name}} } } fieldValueByName(name:"Status"){ ... on ProjectV2ItemFieldSingleSelectValue { name } } } } } } }' \
  --jq '.data.user.projectV2.items.nodes[] | select(.content.number != null)
        | [.id, (.content.number|tostring), .content.state,
           (.fieldValueByName.name // "EMPTY"),
           ([.content.labels.nodes[].name] | join(","))] | @tsv')

changed=0; ok=0; unknown=0
while IFS=$'\t' read -r item_id number state current labels; do
  case "$state" in
    CLOSED) want="Done" ;;
    *)
      case ",$labels," in
        *,in-progress,*) want="In progress" ;;
        *,todo,*)        want="Ready" ;;
        *,backlog,*)     want="Backlog" ;;
        *) echo "UNLABELLED  #$number  status=$current  labels=$labels"; unknown=$((unknown+1)); continue ;;
      esac ;;
  esac

  if [ "$current" = "$want" ]; then ok=$((ok+1)); continue; fi
  echo "DRIFT  #$number  $current -> $want"
  changed=$((changed+1))
  [ "$APPLY" = "1" ] || continue
  gh api graphql -f query='mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){ updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){ projectV2Item{ id } } }' \
    -f p="$PROJECT_ID" -f i="$item_id" -f f="$FIELD_ID" -f o="$(opt_id "$want")" >/dev/null
done <<< "$items"

echo "---"
echo "in sync: $ok   drifted: $changed   unlabelled: $unknown   applied: $APPLY"
