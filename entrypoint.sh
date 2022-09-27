#!/bin/bash
# Fail when any task exits with a non-zero error
set -e

# Env vars work! Great!
echo "we got it?" $INPUT_FOO
echo "we got input_fail?" $input_fail
echo "we got inputs_url?" $inputs_url
echo "we got input_force_follow?" $input_force_follow
# TODO
    # set all vars as named env vars
    # pipe all output into a md/output file
    # pass output to next steps
    # allow passing of all args to blc, --verbose, --filter-level, --get, --user-agent etc


NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;34m'

# Install the broken-link-checker module globally on the docker instance
npm i -g broken-link-checker -s

echo -e "$PURPLE=== BROKEN LINK CHECKER ===$NC"
echo -e "Running broken link checker on URL: $GREEN $inputs_url $NC"

# Create exclude and settings strings based on configuration
EXCLUDE="" 
# SET_FOLLOW=""
SET_RECURSIVE=""

if [ -z "$inputs_url" ] || [ "$inputs_url" == 'https://github.com/roc/link-checker' ]
then
    echo -e "$YELLOW Warning: Running test on default URL, please provide a URL in your action.yml.$NC"
fi

# Set arguments for blc
# --follow,  -f Force-follow robot exclusions.
FOLLOW=$input_force_follow

# [ "$2" == false ] && SET_FOLLOW="--follow"

[ "$4" == true ] && SET_RECURSIVE="-ro"

for PATTERN in ${3//,/ }; do
    EXCLUDE+="--exclude $PATTERN "
done

# Echo settings if any are set
echo -e "Configuration: \n Honor robot exclusions: $GREEN$2$NC, \n Exclude URLs that match: $GREEN$3$NC, \n Resursive URLs: $GREEN$4$NC"


# TODO: execute using eval e.g.
# eval lychee ${FORMAT} --output ${LYCHEE_TMP} ${ARGS}


# Create command and remove extra quotes
# Put result in variable to be able to iterate on it later
$OUTPUT="$(blc "$inputs_url" $EXCLUDE $FOLLOW $SET_RECURSIVE -v | sed 's/"//g')"

# Count lines of output
TOTAL_COUNT="$(wc -l <<< "$OUTPUT")"

# Count 'BROKEN' lines of result or return 0
if grep -q 'BROKEN' <<< "$OUTPUT" 
then
    BROKEN="$(grep -q 'BROKEN' <<< "$OUTPUT")"
    BROKEN_COUNT="$(wc -l <<< "$BROKEN")"
else 
    BROKEN_COUNT=0
fi

exit_code=$?


# Return results
if [ "$BROKEN_COUNT" -gt 0 ] 
then 
    RESULT="$BROKEN_COUNT broken link(s) found (out of $TOTAL_COUNT total)"
    echo -e "$RED Failed $RESULT: $NC"
    grep -E 'BROKEN' <<< "$OUTPUT" | awk '{print "[✗] " $2 "\n" }'
    echo -e "$PURPLE ============================== $NC"
    echo ::set-output name=result::"$RESULT"
    exit_code=1
elif [ "$TOTAL_COUNT" == 0 ]
then
    echo -e "Didn't find any links to check"
    exit_code=0
else 
    RESULT="✓ Checked $TOTAL_COUNT link(s), no broken links found!"
    echo -e "$GREEN $RESULT $NC"
    echo ::set-output name=result::"$RESULT"
    echo -e "$PURPLE ============================== $NC"
    exit_code=0
fi
# exit 0

# TODO:
#   pass through exit code and choose whether to use it or not
#   make and store output of report to be passed to issue filing next step
#   switch inputs from numbered to named args and pass through using ENV kind of like https://github.com/lycheeverse/lychee-action/blob/master/action.yml
# Pass link-checker exit code to next step
echo ::set-output name=exit_code::$exit_code

# If `fail` is set to `true`, propagate the real exit value to the workflow
# runner. This will cause the pipeline to fail on exit != 0.
if [ exit_code !=0 &&  "$input_fail" = true ] ; then
    exit ${exit_code}
fi
[exit_code == 0] && exit ${exit_code} 