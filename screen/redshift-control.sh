#!/usr/bin/env bash
## redshift-control.sh
# Set redshift to change the color temperature to the configured day
# and night temperature for the configured location.

# TODO: use config for this

## get variable-name config-name config-description
# Shortcut function to get a config with description, exiting on fail.
_script_name="redshift-control"
get() {
    local var_name="$1"
    local cfg_name="$2"
    local cfg_desc="$3"
    local result
    result="$(get-config "$_script_name/$cfg_name" -what-do "$cfg_desc")"
    if [ $? != "0" ]; then
        echo "Error getting config $cfg_name. Exiting." >&2
        exit 1
    else
        # Save config to variable.
        eval "declare -g $var_name='$result'"
    fi
}

# get config
declare profile gamma coords place \
        default_tint_day default_tint_night \
        default_temp_day default_temp_night
# set the profile, taking further config from its subfolder
_profile="your name for the set of options you're using (use the
default of 'default' to be walked thru default options)"
get profile profile "$_profile"
_script_name="$_script_name/$profile"
# get gamma target
get gamma gamma \
    "gamma for the X server, as R:G:B, or 'nil' to skip gamma adjustment"
# get location or location provider mechanism
_coords="coordinates. Manual format is lattitude:longitude, with
positive (no prefix) for north/east and negative (-) for
south/west. Note that 15° longitude is 1 hour, so, e.g., setting
longitude 15 higher activates everything 1 hour earlier. Automatic
format is provider[:option[...]], with providers listed by
'redshift -l list'"
get coords coords "$_coords"
get place place "the name of the place your coordinates describe"
# important places this may end up (uncomment exactly one):
#coords="35:-111"; place="Flagstaff"
#coords="43:-86"; place="Grand Rapids"
#coords="35:-81"; place="Flagstaff - 2hrs"
#coords="33:-112"; place="Phoenix"
#coords="33:-82"; place="Phoenix - 2hrs"
#coords="32:-111"; place="Tucson"
#coords="-8.6:115.2"; place="Bali"
#
# get brightnesses and colour temperatures
_day_brite="default day brightness, with 1-9 meaning 10%-90% and 0
meaning 100%; use '0' if you want to control it with monitor
brightness "
get default_tint_day day-brightness "$_day_brite"
get default_tint_night night-brightness "${_day_brite//day/night}"
_day_temp="day colour temperature, in thousands of kelvins, from 10 thru 100"
get default_temp_day day-temp "$_day_temp"
get default_temp_night night-temp "${_day_temp//day/night}"

# show usage if no args
name="$(basename "$0")"
usage="Usage: $name [values [...]]

Kills currently running instances of redshift and runs it again with
the given values.

Values are as follows, with two values of a given type respectively
corresponding to day and night.

1-9, 0   Set brightness, with '1' thru '9' respectively corresponding
         to 10% thru 90% and '0' corresponding to 100% (because 0%
         brightness isn't very useful and '10' already means 1000K
         colour temperature; see below). Use '0' if you want to
         control it with, e.g, the monitor's brightness controls.
10-100   Set colour temperature, with '10' through '100' respectively
         corresponding to 1000K thru 10000K.
-        Ignore all other values and load saved defaults.
"
if [ $# -eq 0 ]; then
    echo "$usage"
    exit 1
fi

## tint config-tint
# Convert redshift-control tint value into redshift tint value
tint() {
    if [ "$1" -eq 0 ]; then
        echo "1"
    else
        echo "0.$1"
    fi
}

## temp config-temp
# Convert redshift-control temperature value into redshift
# temperature value
temp() {
    echo "${1}00"
}

# Get all the info we need.
for arg in "$@"; do
    if [ "$arg" == "-" ]; then
        break # leave everything default
    elif [ "$arg" -lt 10 ]; then # Tint, not temperature
        if [ -z "$tint_day" ]; then
            tint_day="$arg"
        elif [ -z "$tint_night" ]; then
            tint_night="$arg"
        else
            echo "Invalid to have more than 2 tints! Exiting."
            exit 1
        fi
    else # We're assuming here that the user won't pass any invalid
         # parameters even though we assumed 3 lines up that they
         # might pass too many....
        if [ -z "$temp_day" ]; then
            temp_day="$arg"
        elif [ -z "$temp_night" ]; then
            temp_night="$arg"
        else
            echo "Invalid to have more than 2 temperatures! Exiting."
            exit 1
        fi
    fi
done

# Gracefully handle any combination of unset vars.
if [ -z "$tint_day" ]; then
    tint_day="$default_tint_day"
    tint_night="$default_tint_night"
fi
[ -z "$tint_night" ] &&
    tint_night="$tint_day"
if [ -z "$temp_day" ]; then
    temp_day="$default_temp_day"
    temp_night="$default_temp_night"
fi
[ -z "$temp_night" ] &&
    temp_night="$temp_day"

# Convert to real values
temp_day="$(temp "$temp_day")"
temp_night="$(temp "$temp_night")"
tint_day="$(tint "$tint_day")"
tint_night="$(tint "$tint_night")"

# Stop and restart redshift.
echo "Killing redshift."
killall redshift
echo "Starting redshift for $place at lat:lon $coords with (daytemp, nighttemp, daytint, nighttint) = (${temp_day}K, ${temp_night}K, $tint_day, $tint_night)."
args=()
[ "$gamma" = nil ] ||
    args+=(-g "$gamma")
args+=(-l "$coords" -t "$temp_day:$temp_night" -b "$tint_day:$tint_night" -r)
echo "redshift ${args[*]} &"
redshift "${args[@]}" &
sleep 2 && echo # Make the prompt happen correctly after running this.
