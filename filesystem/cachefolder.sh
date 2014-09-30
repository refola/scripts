#!/bin/bash
echo "Running \"find . -type f -exec cat {} > /dev/null +\" to put everything in this folder into the kernel's filesystem cache."
find . -type f -exec cat {} > /dev/null +
exit
