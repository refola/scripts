#!/bin/bash
# Apply a series of regex find-replace operations to convert DataPacRat's formatting for SI into proper HTML.
# Author: Mark Haferkamp
# License: Public domain/Unlicense (http://unlicense.org/)

# The file containing DPR-formatted text
INPUT="input"

# Where to save the HTML-formatted text
OUTPUT="output"

# Known properly-converted text for testing
EXPECTED="expected"

# Get script location. Don't want to mess up other files elsewhere.
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
cd "$HERE"

rm $OUTPUT
cp $INPUT $OUTPUT

# Make a single regex replacement in $OUTPUT, repeating until there's no change.
replace() {
	CODE="1"
	while [ $CODE != "0" ]
	do
		perl -p -i.bak -e "s/${1}/${2}/;" $OUTPUT
		diff $OUTPUT $OUTPUT.bak > /dev/null
		CODE=$?
	done
	rm $OUTPUT.bak
}

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
PARAS='<\/p>\n<p>'
replace "$BREAKS" "$PARAS"

# Convert remaining line break placeholders back into real line breaks.
replace "$FAKE" '\n'

# Quality check
diff $OUTPUT $EXPECTED
