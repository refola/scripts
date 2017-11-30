#!/bin/bash
watch -n1 "cat /proc/cpuinfo | grep MHz | cut -c12-"
exit
