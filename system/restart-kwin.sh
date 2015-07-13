#!/bin/sh

echo "Restarting kwin and telling it that the old one crashed."
kwin --replace --crashes 1 &
