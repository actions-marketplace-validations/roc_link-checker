#!/bin/bash
# Fail when any task exits with a non-zero error
set -e

NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;34m'

# Env vars work! Great!
echo "env:"$env

# Setup temporary file for output
BLC_TMP="/tmp/blc/out.md"
GITHUB_WORKFLOW_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}?check_suite_focus=true"

# Create temp dir
mkdir -p "$(dirname $BLC_TMP)"

# Install the broken-link-checker module globally on the docker instance
npm i -g broken-link-checker -s

# TODO
# set all vars as named env vars ✅
# pipe all output into a md/output file
# pass output to next steps
# allow passing of all args to blc, --verbose, --filter-level, --get, --user-agent etc

# Options
#   --exclude               A keyword/glob to match links against. Can be used multiple times.
#   --exclude-external, -e  Will not check external links.
#   --exclude-internal, -i  Will not check internal links.
#   --filter-level          The types of tags and attributes that are considered links.
#                             0: clickable links
#                             1: 0 + media, iframes, meta refreshes
#                             2: 1 + stylesheets, scripts, forms
#                             3: 2 + metadata
#                             Default: 1
#   --follow, -f            Force-follow robot exclusions.
#   --get, -g               Change request method to GET.
#   --help, -h, -?          Display this help text.
#   --input                 URL to an HTML document.
#   --host-requests         Concurrent requests limit per host.
#   --ordered, -o           Maintain the order of links as they appear in their HTML document.
#   --recursive, -r         Recursively scan ("crawl") the HTML document(s).
#   --requests              Concurrent requests limit.
#   --user-agent            The user agent to use for link checks.
#   --verbose, -v           Display excluded links.
#   --version, -V           Display the app version.

echo -e "$PURPLE=== BROKEN LINK CHECKER ===$NC"
echo -e "Running broken link checker on URL: $GREEN $inputs_url $NC"

if [ -z "$inputs_url" ] || [ "$inputs_url" == 'https://github.com/roc/link-checker' ]; then
    echo -e "$YELLOW Warning: Running test on default URL, please provide a URL in your action.yml.$NC"
fi

# TODO: execute using eval e.g.
# eval lychee ${FORMAT} --output ${LYCHEE_TMP} ${ARGS}
echo "blc $inputs_url $inputs_blc_args"

# Run broken link checker, save to markdown file, also show stdout & sterr while running
blc $inputs_url $inputs_blc_args 2>&1 | tee $BLC_TMP

cat "${BLC_TMP}" >"${GITHUB_STEP_SUMMARY}"
# TODO: is this line necessary for echoing cat??
echo

echo 'got this far?'

# Pass link-checker exit code to next step
echo ::set-output name=exit_code::$exit_code

echo "[Full Github Actions output](${GITHUB_WORKFLOW_URL})"
# echo "[Full Github Actions output](${GITHUB_WORKFLOW_URL})" >>"${BLC_TMP}"

# Create command and remove extra quotes
# Put result in variable to be able to iterate on it later
# $OUTPUT="$(blc "$inputs_url" $EXCLUDE $FOLLOW $SET_RECURSIVE -v | sed 's/"//g')"

# echo "out:" $OUTPUT

# # Count lines of output
# TOTAL_COUNT="$(wc -l <<<"$OUTPUT")"

# # Count 'BROKEN' lines of result or return 0
# if grep -q 'BROKEN' <<<"$OUTPUT"; then
#     BROKEN="$(grep -q 'BROKEN' <<<"$OUTPUT")"
#     BROKEN_COUNT="$(wc -l <<<"$BROKEN")"
# else
#     BROKEN_COUNT=0
# fi

# exit_code=$?

# # Return results
# if [ "$BROKEN_COUNT" -gt 0 ]; then
#     RESULT="$BROKEN_COUNT broken link(s) found (out of $TOTAL_COUNT total)"
#     echo -e "$RED Failed $RESULT: $NC"
#     grep -E 'BROKEN' <<<"$OUTPUT" | awk '{print "[✗] " $2 "\n" }'
#     echo -e "$PURPLE ============================== $NC"
#     echo ::set-output name=result::"$RESULT"
#     exit_code=1
# elif [ "$TOTAL_COUNT" == 0 ]; then
#     echo -e "Didn't find any links to check"
#     exit_code=0
# else
#     RESULT="✓ Checked $TOTAL_COUNT link(s), no broken links found!"
#     echo -e "$GREEN $RESULT $NC"
#     echo ::set-output name=result::"$RESULT"
#     echo -e "$PURPLE ============================== $NC"
#     exit_code=0
# fi
# # exit 0

# # TODO:
# #   pass through exit code and choose whether to use it or not
# #   make and store output of report to be passed to issue filing next step
# #   switch inputs from numbered to named args and pass through using ENV kind of like https://github.com/lycheeverse/lychee-action/blob/master/action.yml
# # Pass link-checker exit code to next step
# echo ::set-output name=exit_code::$exit_code

# # If `fail` is set to `true`, propagate the real exit value to the workflow
# # runner. This will cause the pipeline to fail on exit != 0.
# if [ exit_code !=0 && "$input_fail" = true ]; then
#     exit ${exit_code}
# else
#     exit 0
# fi
