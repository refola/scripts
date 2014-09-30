#!/bin/bash

echo "\"update-grub\" probably doesn't exist on this system. It's running $MACHTYPE, not Ubuntu!"
echo "This script is just a convenience to run \"grub2-mkconfig -o /boot/grub2/grub.cfg\" for you."
echo "To keep it from being too convenient, you still have to get root your own way for update-grub.sh."
echo
grub2-mkconfig -o /boot/grub2/grub.cfg
