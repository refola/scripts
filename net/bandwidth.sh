#!/bin/bash
watch -n1 "ifconfig enp3s0 | grep bytes | sed 's/ *[RT]X packets [0-9]* *//'"
exit
