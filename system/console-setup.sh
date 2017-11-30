#!/bin/sh
# Attempt to set a larger font for a high-DPI display. The "ter-132n"
# font from the terminus-font package is nicer, but
# "latarcyrheb-sun32" from the kbd package is more universally
# available. So we attempt to use the former, but fallback to the
# latter.
setfont ter-132n || setfont latarcyrheb-sun32
