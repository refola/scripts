#!/bin/bash

echo "Restarting 'KDE5' desktop stuff."

for app in kwin_x11 plasmashell; do
    echo "Restarting $app."
    kquitapp "$app"
    kstart "$app"
done

echo "Done."
