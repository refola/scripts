#!/bin/sh
x=`echo $@`

## Unsuccessful way of making only one message happen at once.
f() {
#sleep 2
while [ "`ps cax | grep -c say`" -gt 2 ]
do
	echo `ps cax | grep -c say`
	sleep 1
done
spd-say "$x"
}
#f

spd-say "$x"

echo $x
