#!/bin/bash
## minecraft-server.sh
# Run the official Minecraft server program for my particular setup.

## Expected setup
# You must have the official Minecraft server program (or compatible)
# set up with a file called "version" and a folder called "jars" that
# contains "minecraft_server.VERSION.jar", where "VERSION" is the
# contents of the file called "version".
##
# You must also have 4+ GiB RAM available for the server, IN ADDITION
# to the amount used by the game, your operating system, and whatever
# else your computer may be running. The amount of RAM to allocate to
# the server /should/ be configurable, but I don't think it will need
# to be changed before more general solutions for custom server stuff
# are needed.

server_path="$(get-config minecraft/server-path -what-do "the path to the Minecraft server's folder")" || exit 1

cd "$server_path"
cache-folder

version="$(cat version)"
server_jar="jars/minecraft_server.$version.jar"

echo "Starting Minecraft server...."
echo "Type 'stop' when you're done to safely exit."
java -Xmx4G -Xms1G -jar "$server_jar"
