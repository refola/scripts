#!/usr/bin/env bash
## build_zandronum.sh
# Automate installation of Zandronum from source, based on
# <ref>. NOTE: The wiki page this is based off of does not state a
# license. Therefore, I cannot license this script as a whole. But, in
# the event of a license being officially applied to that page, I want
# this script to automatically convert to that license.
## ref: http://wiki.zandronum.com/Compiling_Zandronum_on_Linux

# Hard-code where to build Zandronum.
zandronum_path="$(get-config zandronum/path -what-do "where to build Zandronum")" || exit 1

# Choose what the fmod folder will be called based on CPU bit-ness.
if [ "$(uname -m)" = "x86_64" ]
then
    fmod_folder="fmodapi42416linux64"
    fmod_file="libfmodex64-4.24.16"
else
    fmod_folder="fmodapi42416linux"
    fmod_file="libfmodex-4.24.16"
fi

deps-suse() {
    sudo zypper install gcc-c++ make zlib-devel libSDL-devel libjpeg-devel nasm tar libbz2-devel gtk2-devel cmake mercurial fluidsynth-devel Mesa-libGL-devel libopenssl-devel
}

deps-chakra() {
    sudo pacman -S --needed gcc make zlib sdl libjpeg-turbo nasm tar bzip2 gtk2 cmake mercurial fluidsynth mesa glu openssl
}

clean() {
    rm -rf "$zandronum_path"
    mkdir -p "$zandronum_path"
}

get-zandronum() {
    cd "$zandronum_path"
    if [ ! -d "zandronum" ]
    then
        hg clone https://bitbucket.org/Torr_Samaho/zandronum
    else
        echo "Already have zandronum source. Use the 'clean' option to start over."
    fi
    cd "zandronum"
    echo "Updating Zandronum source to latest stable release."
    hg update -cr "max(tagged())" # Use the latest stable version.
    mkdir -p zandronum/{buildclient,buildserver}
}

get-fmod() {
    cd "$zandronum_path"
    if [ ! -d "$zandronum_path/zandronum/$fmod_folder" ]
    then
        wget -nc "http://www.fmod.org/download/fmodex/api/Linux/$fmod_folder.tar.gz"
        tar -xzf "$zandronum_path/$fmod_folder.tar.gz" -C "$zandronum_path/zandronum"
    else
        echo "Already have fmod. Use the 'clean' option to start over."
    fi
}

get-sqlite-amalgamation() {
    cd $zandronum_path
    if [ ! -d "zandronum/sqlite" ]
    then
        v=$(wget -c -q -O - http://www.sqlite.org/download.html | sed -n '/>Source Code</,/zip</ s/.*sqlite-amalgamation-\(.*\)\.zip.*/\1/p')
        wget -nc "http://www.sqlite.org/$(date +%Y)/sqlite-amalgamation-$v.zip"
        unzip -j sqlite-amalgamation-"$v".zip -d zandronum/sqlite
    else
        echo "Already have sqlite. Use the 'clean' option to start over."
    fi
}

get-all() {
    get-zandronum
    get-fmod
    get-sqlite-amalgamation
}

compile-client() {
    cd "$zandronum_path/zandronum/buildclient"
    make clean
    cmake -Wno-dev \
          -DCMAKE_BUILD_TYPE=Release \
          -DFMOD_LIBRARY="$zandronum_path/zandronum/$fmod_folder/api/lib/$fmod_file.so" \
          -DFMOD_INCLUDE_DIR="$zandronum_path/zandronum/$fmod_folder/api/inc" ..
    make
}

compile-server() {
    cd "$zandronum_path/zandronum/buildserver"
    make clean
    cmake -Wno-dev -DCMAKE_BUILD_TYPE=Release -DSERVERONLY=ON ..
    make
}

package() {
    cd "$zandronum_path"
    local dest="../zandronum_$(date --utc "+%F_%H%M.%S")"
    mkdir -p "$dest"
    cd "$dest"
    echo -e "Backing up compiled Zandronum binaries to\n '$PWD'."

    # Make launcher script
    # shellcheck disable=SC2016
    local script_lines=('#!/bin/sh'
                        '# zandronum.sh -- Change to current directory and run zandronum.'
                        'cd "$(dirname "$(readlink -f "$0")")" # Be here now.'
                        './zandronum')
    for line in "${script_lines[@]}"
    do
        echo "$line" >> "$dest/zandronum.sh"
    done
    chmod +x "$dest/zandronum.sh"

    # Copy files
    local files=("zandronum/buildclient/zandronum"
                 "zandronum/buildclient/zandronum.pk3"
                 "zandronum/buildclient/skulltag_actors.pk3"
                 "zandronum/buildclient/output_sdl/liboutput_sdl.so"
                 "zandronum/buildserver/zandronum-server")
    for file in "${files[@]}"
    do
        if [ -f "$zandronum_path/$file" ]
        then
            cp "$zandronum_path/$file" "$dest"
        else
            echo "Could not find '$file' in '$zandronum_path'."
        fi
    done
}

if [ -z "$1" ]
then
    echo "Usage: $(basename "$0") [options]"
    echo "This is a script to automatically build Zandronum on Linux."
    echo "You must use the appropriate options for this to work, as described below."
    echo
    echo "Options:"
    echo -e "\tdeps-suse        Install dependencies for openSUSE"
    echo -e "\tdeps-chakra      Install dependencies for Chakra"
    echo -e "\tclean            Delete downloaded and compiled stuff and remake directory."
    echo -e "\tget-all          Download and extract Zandronum and its non-repo dependencies."
    echo -e "\tcompile-client   Compile the Zandronum client."
    echo -e "\tcompile-server   Compile the Zandronum server."
    echo -e "\tpackage          Copy zandronum binaries and launch script into new folder."
    echo
    echo "Example - Get dependencies and do a fresh compile on Chakra."
    echo -e "\t$(basename "$0") deps-chakra clean get-all compile-client"
else
    while [ -n "$1" ]
    do
        echo -e "\e[1;37mRunning \e[0;32m$1\e[0m"
        "$1"
        shift
    done
fi
