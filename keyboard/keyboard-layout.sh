#!/usr/bin/env bash
echo "Setting keyboard layout and options."
setxkbmap -layout us,us -variant dvorak, -option grp:sclk_toggle,caps:backspace,compose:menu,grp_led:scroll
exit
