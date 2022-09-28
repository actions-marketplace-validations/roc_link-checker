#!/bin/bash
# Fail when any task exits with a non-zero error
set -e

# Setup temporary file for output
BLC_TMP="${inputs_output_file:-blc/out.md}"
GITHUB_WORKFLOW_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}?check_suite_focus=true"

# Create temp dir
mkdir -p "$(dirname $BLC_TMP)"

echo "## Broken link checker report" 2>&1 | tee $BLC_TMP
echo "### Running broken link checker on URL: $inputs_url" 2>&1 | tee -a $BLC_TMP

if [ -z "$inputs_url" ] || [ "$inputs_url" == 'https://github.com/roc/link-checker' ]; then
    echo -e "**Warning:** Running test on default URL, please provide a URL in your action.yml." >>$BLC_TMP
fi

echo "blc $inputs_url $inputs_blc_args"
# Wrap report in backticks for md rendering
echo '```' >>$BLC_TMP
# Run broken link checker, save to markdown file, also show stdout & sterr while running
blc $inputs_url $inputs_blc_args 2>&1 | tee -a $BLC_TMP
echo '```' >>$BLC_TMP

# TODO: a bit of rewriting the file to make it immediately obvious which links are broken

# Set exit code on broken count
exit_code=0
if grep -q 'BROKEN' $BLC_TMP; then
    exit_code=1
fi
# TODO: how to caputre exit_code AND report to the console the output, even on exit code 1?
# exit_code=$?
echo "exit code was ${exit_code}"

# Pass link-checker exit code to next step
echo ::set-output name=exit_code::$exit_code

cat "${BLC_TMP}" >"${GITHUB_STEP_SUMMARY}"

echo "[Full Github Actions output](${GITHUB_WORKFLOW_URL})" >>$BLC_TMP

echo ::set-output name=report::$BLC_TMP

# If `inputs_allow_failures` is set to `false`, propagate the real exit value to the workflow
# runner. This will cause the pipeline to fail on exit != 0.
if [ "$inputs_allow_failures" = false ]; then
    echo "exiting with $exit_code"
    exit ${exit_code}
else
    exit 0
fi
