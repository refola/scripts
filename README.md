scripts
=======

A collection of personal Bash scripts I've developed over the years. They may be useful to others.


License
-------
I'm using the Unlicense for making these scripts public domain. In case one of the scripts specifies another license, then that one takes priority.


Folders
-------

<table>
<tr><th>Folder</th><th>Contents</th><th>Most important/best tested scripts</th></tr>
<tr><td>backup</td><td>scripts for backing up my computer</td><td><ul><li>btrfsbackup.sh</li><li>phone-system-to-home.sh</li></td></tr>
<tr><td>backup/old</td><td>an old system of scripts for managing rsync backups</td><td>this is for historical purposes only; see <a href="https://github.com/refola/golang/tree/master/backup">this</a> for the replacement</td></tr>
<tr><td>bin</td><td>symbolic links to scripts I use regularly so I only need to add a single folder to my $PATH</td><td>everything here should be important, but I don't think git supports symlinks and it may be empty</td></tr>
<tr><td>cpu</td><td>scripts for managing CPU throttling</td><td>all of them</td></tr>
<tr><td>example</td><td>scripts that demonstrate Bash techniques I was struggling with</td><td>script.sh is a convenient template for starting a new script</td></tr>
<tr><td>filesystem</td><td>scripts for keeping the filesystem running smoothly</td><td><ul><li>cachefolder.sh</li><li>fixperms.sh</li><li>precache.sh</li></ul></td></tr>
<tr><td>keyboard</td><td>single-script folder</td><td>layout.sh is for setting the keyboard layout to alternate between QWERTY and Dvorak by pressing Scroll Lock, light up Scroll Lock when Dvorak's active, set Caps Lock as an extra backspace, and set the "Menu" key as the "Compose" key.</td></tr>
<tr><td>net</td><td>scripts for managing and monitoring the OS's networking layer and download a site</td><td>they're all kinda, but not extremely, useful to me</td></tr>
<tr><td>proc</td><td>manage processes</td><td><ul><li>I haven't used these in ages, but they were made for pausing processes, locking the screen, and combining these scripts to put the computer in "lockdown" until I've had enough time away to get some sleep</td></tr>
<tr><td>screen</td><td>override screen locking and manage <a href="http://jonls.dk/redshift/">Redshift</a></td><td>all 3 scripts are useful to me</td></tr>
<tr><td>speach</td><td>use some sort of speach synthesizer to say stuff</td><td>broken last I checked...</td></tr>
<tr><td>system</td><td>scripts to help fix things in other distros installed on a mounted drive</td><td><ul><li>chrootdistro.sh automates certain mount points needed for system stuff to work in the chroot</li><li>update-grub.sh tells the user that they're not on Ubuntu and thus don't have the update-grub command, then runs "grub2-mkconfig -o /boot/grub2/grub.cfg" like update-grub would</li></ul></td></tr>
<tr><td>volume</td><td>controls volume from the command line</td><td>these may be useful for other scripts</td></tr>
<tr><td>xautomation</td><td>another single-script folder...</td><td>clickn.sh sends a bunch of virtual clicks to an X server</td></tr>
</table>
