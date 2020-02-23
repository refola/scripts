#!/bin/sh
# Switch to Dvorak, with scroll lock toggling between Dvorak and
# QWERTY and some other fancy stuff.
setxkbmap -layout us,us -variant dvorak, \
          -option grp:sclk_toggle,caps:backspace,compose:menu,grp_led:scroll
