#!/bin/bash
# redshift-control.sh sets redshift on Mark's computer to change the color temperature for Flagstaff according to the day and night temperature

# gamma for the X server, as R:G:B
gamma="0.85:0.95:1.05"

# coordinates, as lattitude:longitude, with positive (no prefix) for north/east and negative (-) for south/west
# 15° longitude == 1 hours, so setting longitude 15 higher activates everything 1 hour earlier
# important places this may end up (uncomment exactly one):
coords="35:-111"; place="Flagstaff"
#coords="35:-81"; place="Flagstaff - 2hrs"
#coords="33:-112"; place="Phoenix"
#coords="33:-82"; place="Phoenix - 2hrs"
#coords="32:-111"; place="Tucson"

# defaults -- full brightness and native temperature at day, both cut back a bunch at night
default_tint_day=0
default_tint_night=8
default_temp_day=65
default_temp_night=35

if [ -z "$1" ]
then
    name="$(basename "$0")"
    echo "Usage: $name - | [(day)temp100s [nighttemp100s]] [(day)tint [nighttint]]"
    echo "Kills currently running instances of redshift and runs it again with the given (day and night) color temperature(s) in hundreds of Kelvins."
    echo "  Temperature ranges from 10 through 100, correspoding to the 1000K to 10000K range."
    echo "  Tint ranges from 0 to 9, with \"0\" actually meaning \"10\" since 10 is a temperature, not a tint. Lower number meanings give darker screens."
    echo
    echo "  Defaults: \"$name -\" is equivalent to \"$name $default_tint_day $default_tint_night $default_temp_day $default_temp_night\"."
    echo "  Note: It doesn't matter which order arguments are passed in."
    echo "  Note: Location is currently hardcoded to $place with coordinates $coords. See the source to change this."
    exit 1
fi

# Convert redshift-control tint values into redshift tint values
tint() {
    if (( "$1" == 0 ))
    then
        echo "1"
    else
        echo "0.$1"
    fi
}

# Convert redshift-control temperature values into redshift temperature values
temp() {
    echo "${1}00"
}

# Get all the info we need.
for arg in "$@"
do
    if [ "$arg" == "-" ]
    then
        shift # skipping "-" if it's the only arg leaves things default
    elif (( arg < 10 )) # Tint, not temperature
    then
        if [ -z "$tint_day" ]
        then
            tint_day="$arg"
        elif [ -z "$tint_night" ]
        then
            tint_night="$arg"
        else
            echo "Invalid to have more than 2 tints! Exiting."
            exit 1
        fi
    else # We're assuming here that the user won't pass any invalid parameters even though we assumed 3 lines up that they might pass too many....
        if [ -z "$temp_day" ]
        then
            temp_day="$arg"
        elif [ -z "$temp_night" ]
        then
            temp_night="$arg"
        else
            echo "Invalid to have more than 2 temperatures! Exiting."
            exit 1
        fi
    fi
done

# Gracefully handle any combination of unset vars.
if [ -z "$tint_day" ]
then
    tint_day="$default_tint_day"
    tint_night="$default_tint_night"
fi
if [ -z "$tint_night" ]; then tint_night="$tint_day"; fi
if [ -z "$temp_day" ]
then
    temp_day="$default_temp_day"
    temp_night="$default_temp_night"
fi
if [ -z "$temp_night" ]; then temp_night="$temp_day"; fi

# Convert to real values
temp_day="$(temp "$temp_day")"
temp_night="$(temp "$temp_night")"
tint_day="$(tint "$tint_day")"
tint_night="$(tint "$tint_night")"

# Stop and restart redshift.
echo "Killing redshift."
killall redshift
echo "Starting redshift for $place at lat:lon $coords with (daytemp, nighttemp, daytint, nighttint) = (${temp_day}K, ${temp_night}K, $tint_day, $tint_night)."
echo "redshift -g \"$gamma\" -l \"$coords\" -t \"$temp_day:$temp_night\" -b \"$tint_day:$tint_night\" -r &"
redshift -g "$gamma" -l "$coords" -t "$temp_day:$temp_night" -b "$tint_day:$tint_night" -r &
sleep 0.2 && echo # Make the prompt happen correctly after running this.

exit
