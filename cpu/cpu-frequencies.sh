#!/bin/bash
watch -n1 "cat /proc/cpuinfo | grep MHz | grep -v 800 | cut -c12-13"
exit
