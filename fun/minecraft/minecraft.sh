#!/usr/bin/env bash
## minecraft.sh
# Run Minecraft client and server, precaching files in the background.

game_jar="$(get-config minecraft/game-jar -what-do "the path to Minecraft.jar")" || exit 1

# Make sure the server config is there before starting. It's either
# this duplicate code, or spamming a bunch of Minecraft client
# launcher startup console stuff while the user tries to focus on the
# server config.
get-config minecraft/server-path -what-do "the path to the Minecraft server's folder" || exit 1


mc_data="~/.minecraft/"
if [ -d "$mc_data" ]; then
    cache-folder "$mc_data"
fi

echo "Starting Minecraft client in background."
java -jar "$game_jar" &

minecraft-server
