#!/bin/bash
# si_regexes.sh
# Apply a series of regex find-replace operations to convert DataPacRat's formatting for S.I. into proper HTML.
# Author: Mark Haferkamp
# License: Public domain/Unlicense (http://unlicense.org/)

if [ -z "$1" ]
then
    echo "Usage: si_regexes.sh in1 [in2 [in3 [...]]]"
    echo "Formats input files with DataPacRat's formatting for the S.I. story into HTML."
    echo "Note: Input files must be single chapters only. This script cannot handle"
    echo "    splitting book files into chapters."
    echo "Example: Try putting a bunch of chapterXX.txt files in the same difectory as"
    echo "    this script and running \"./si_regexes.sh *.txt\"."
fi

# Make a single regex replacement in $OUTPUT, repeating until there's no change.
# Usage: replace detect_pattern replace_pattern
# NOTE: Requires $OUTPUT to be set to where this should check.
replace() {
    local CODE="1"
    while [ $CODE != "0" ]
    do
        perl -p -i.bak -e "s/${1}/${2}/;" $OUTPUT
        diff $OUTPUT $OUTPUT.bak > /dev/null
        CODE=$?
    done
    rm $OUTPUT.bak
}

# Apply a bunch of regex find-replaces to change from DPR formatting to HTML.
regexes() {
    # /slashes/ to <em>HTML emphasis</em>
    SLASH='( )\/(.*?)\/([ .?])'
    EM='$1<em>$2<\/em>$3'
    replace "$SLASH" "$EM"

    # 'apostrophes' into &lsquo;curly quotes&rsquo;
    #APOS='( )'\''(.*?)'\''([ .?])'
    APOS='([^a-zA-Z])'\''([a-zA-Z&].*?[a-zA-Z.;,?!])'\''([^a-zA-Z])'
    #SQUO='&lsquo;$1&rsquo;'
    SQUO='$1&lsquo;$2&rsquo;$3'
    replace "$APOS" "$SQUO"

    # "quotes" into &ldquo;curly quotes&rdquo;
    #QUOTE='"([a-zA-Z&].*?[a-zA-Z.;,?!])"'
    QUOTE='"(.*?)"'
    DQUO='&ldquo;$1&rdquo;'
    replace "$QUOTE" "$DQUO"

    # ... into &hellip;
    DOTS='\.\.\.'
    HELLIP='&hellip;'
    replace "$DOTS" "$HELLIP"

    # " - " into "&thinsp;&mdash;&thinsp;"
    DASH=' - '
    MDASH='&thinsp;&mdash;&thinsp;'
    replace "$DASH" "$MDASH"

    # ugly hack to make line break detection work
    BREAK='\n'
    FAKE='LINEBREAKLOL'
    replace "$BREAK" "$FAKE"

    # Double dashses "--" to HTML lines "<hr size=1 noshade>", but also doing paragraph formatting
    DDASH="$FAKE$FAKE--$FAKE$FAKE"
    HR='<\/p>\n<hr size=1 noshade>\n<p>'
    replace "$DDASH" "$HR"

    # Pairs of line breaks into <p> tags
    BREAKS="$FAKE$FAKE"
    PARAS='<\/p>\n\n<p>'
    replace "$BREAKS" "$PARAS"

    # Convert remaining line break placeholders back into real line breaks.
    replace "$FAKE" '' #'\n'

    # Fix unmatched opening quotes
    OPENPARAQUO='<p>"'
    OPENPARALDQUO='<p>&ldquo;'
    replace "$OPENPARAQUO" "$OPENPARALDQUO"

    # Manually add <p> at beginning and </p> at end
    echo -n "<p>$(cat $OUTPUT)</p>" > $OUTPUT.bak
    mv $OUTPUT.bak $OUTPUT
}

# Get and move to script location. Don't want to mess up other files elsewhere.
cd "$(dirname "$(readlink -f "$0")")"

# Go through everything and replace stuff.
for arg in "$@"
do
    OUTPUT="${arg%.*}.html"
    cp "$arg" "$OUTPUT"
    regexes
done
