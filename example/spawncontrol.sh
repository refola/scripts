#!/usr/bin/env bash

exec 2> /dev/null # suppress "Terminated" message
DEL="1.5" # delay (not delaminate, delapsion, delator, delineavit, deliquescence, deliquium, delitescence, delope, deltiology, delubrum, or delustrant)

zombie() {
    sleep 20 # something like 10 * $DEL + 5
    export TRUE="FALSE"
    loop &
    clear
    echo "> BRAAAA-AAAAA-AAAA-AAAA-AAAAINS!"
    sleep $DEL
    echo "> BY MAGIC, MASTER RESPAWNS!"
    sleep $DEL
    echo "> BUT NOW FALSE IS TRUE...."
    echo
}

loop() {
    if [ -z "$TRUE" ]
    then
        zombie & # necramancy, in a child so young!
    fi
    while [ -z "$FALSE" ]
    do
        sleep $DEL $DEL $DEL
        echo "  The Child: \"I live!\""
        sleep $DEL $DEL
        echo "  I hope I get to say this!"
        FALSE="TRUE"
    done
    sleep $DEL
    echo "  The loop is broken."
    sleep $DEL
    echo "  "
    sleep $DEL
    echo "  The time is now come."
    sleep $DEL
    echo "  When TRUE is FALSE and FALSE TRUE,"
    sleep $DEL
    echo "  The prompt goes to you."

    sleep $DEL
    echo
    echo -n "$USER@$HOST:`pwd`> "
}

echo
echo "i spawn a child"
loop &

sleep $DEL

echo "i save its process number"
CPID=$!

sleep $DEL

echo "narcoleptic nap"
echo 
sleep $DEL $DEL

echo "i kill my child, by PID"
kill $CPID 2>/dev/null

sleep $DEL
echo "it dead, i die too"

sleep $DEL
echo

exit
