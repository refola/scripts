#!/bin/bash
# Generate random password-suitable symbols from /dev/random.

# Note: The combination of cat|tr|fold|head and the original tr
# pattern are originally from <ref>.
# ref: http://blog.colovirt.com/2009/01/07/linux-generating-strong-passwords-using-randomurandom/

if [ -z "$1" ]
then
    PATTERN="a-zA-Z0-9-_!@#$%^&*()+{}|:<>?='\`\"\\\\"
else
    PATTERN="$1"
fi
echo "Password character pattern is: $PATTERN"

FILE="/tmp/my_temp_random"
SEC="13"

echo "Generating \"random\" bytes for $SEC seconds."
cat /dev/random >> "$FILE" &
pid="$!"
sleep "$SEC"
kill $pid
# Use Bash builtin to help suppress "terminated" messages, per
# https://stackoverflow.com/questions/81520/how-to-suppress-terminated-message-after-killing-in-bash
wait $pid 2> /dev/null

echo "Here are the \"random\" symbols."
tr -dc "$PATTERN" < "$FILE" | fold -w 20
echo

echo "Now deleting temporary file $FILE."
rm "$FILE"
