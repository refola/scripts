#!/bin/bash

LOC="/home/gaming/m/minecraft.jar"
#ARGS="-Xmx4G -Xms1G -jar $LOC"
ARGS="-jar $LOC" # Don't need the memory options here now that the launcher handles it.

##Uncomment exactly one of the following 2 lines for that java version.
JAVA="java"				# System Java (Oracle Java via CCR, as of 2013-07-01)
#JAVA="/path/to/java/executable"	# For some alternative Java installation, if needed again later

cd ~/.minecraft/
echo "Caching Minecraft files in background."
find . -type f -exec cat {} > /dev/null + &
echo "Starting Minecraft."
$JAVA $ARGS

exit 0
