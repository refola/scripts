scripts
=======
This repository contains most of the personal Bash scripts I've developed over the years. They cover a wide variety of tasks and reflect the process of me learning more and more Bash. Please see the Contents section below to see which scripts may interest you.


License
-------
I'm using the Unlicense for making my scripts public domain, so you may freely use most of these scripts however you want to. My scripts are free as in freedom, free as in beer, and free as in not liable. Use at your own discretion.

For scripts that specify another license, their license is as stated. See the LICENSE file and check each script's source for more information.


Installation
------------
For the most part, you can get away with just copying a script to wherever and running it. However, some scripts depend on others, some depend on a system configured similar to mine, and others need to be integrated with Bash. If my scripts aren't playing nice with your system or installation is too tricky, then please open a GitHub ticket or email me. I want my scripts to be properly general, as long as there's demand.

Anyway, here's how my setup is installed. Similar steps should work for you. <a href="http://refola.com/contact">Complain to me</a> if it doesn't work.

### Initial Setup
This should get you a basic working system of scripts.

1. Clone this repo to wherever you want my scripts on your system.
2. Run `build_bin.sh` to build the bin folder with symlinks to the scripts.
3. Add the newly-created bin folder to your $PATH.
4. Complain to me when a script is hard-coded to my system's setup.

### Bash Environment Setup
This should get you a Bash shell environment similar to mine. As of this writing, such integration or similar is required for shell-environment-changing things like the "cmcd" command to work correctly.

0. Follow the Initial Setup directions first.
1. Do the things that bash_custom/install.sh is meant to do.
2. Cross your fingers and open a new shell.
3. Complain to me if bash_custom/install.sh eats your hamster.

### System-specific Setup
There's too much integration to describe this. Instead, I need to refactor the scripts to use config files for system-specific stuff instead of hard-coding it. Please help me by complaining about scripts you want to use being hard-coded to my system.


Contents
--------
Beyond this readme, the license file, and build_bin.sh at the top level, here's what to expect if you dig in to the script collection.

<table>
<tr><th>Folder</th><th>Contents</th><th>Main scripts</th></tr>
<tr><td>backup</td><td>scripts for backing up my computer</td><td>
 <ul><li>backup-btrfs.sh - full system backups via btrfs snapshots</li><li>phone-system-to-home.sh - use adb to pull user data from Android system folders</li></td></tr>
<tr><td>bash_custom</td><td>my .bash* files and such</td><td>.bashrc sources the functionality stuff which is stashed away in the "sourced" folder.</td></tr>
<tr><td>cpu</td><td>scripts for managing CPU throttling</td><td>cpu-set-ghz.sh and cpu-frequencies.sh</td></tr>
<tr><td>example</td><td>scripts that demonstrate various Bash techniques or which are too miscellaneous to go in other folders</td><td>
 I think that tuple_funcs.sh is a neat demonstration of simulating arrays in Bash.</td></tr>
<tr><td>filesystem</td><td>scripts for keeping the filesystem running smoothly</td><td>
 <ul><li>hist.sh - search custom Bash history folder</li>
 <li>restore-from-btrfs-snapshot.sh - much easier than calling cp with a zillion args and really long paths</li>
 <li>scrub-btrfs.sh - scrub multiple btrfs volumes at once</li></ul></td></tr>
<tr><td>found</td><td>scripts that I found online and have no interest in changing</td><td /></tr>
<tr><td>fun</td><td>scripts related to computer games and such</td><td /></tr>
<tr><td>keyboard</td><td>keyboard controlling stuff</td><td>layout.sh turns Scroll Lock into "Dvorak Lock", sets Caps Lock as an extra backspace, and sets Menu as Compose.</td></tr>
<tr><td>net</td><td>networking scripts</td><td>download-site.sh recursively downloads a site to a preset location</td></tr>
<tr><td>proc</td><td>manage processes freezing</td><td /></tr>
<tr><td>screen</td><td>override screen locking and manage <a href="http://jonls.dk/redshift/">Redshift</a></td><td>
 <ul><li>lights-on.sh - keep a KDE session from entering sleep/standby mode</li><li>redshift-control.sh - front-end for configuring Redshift more easily</li></ul></td></tr>
<tr><td>shortcut</td><td>shortcut commands that may be useful for scripts and stuff</td><td /></tr>
<tr><td>sourced</td><td>scripts that are sourced by my .bashrc for setting up my custom Bash environment</td><td>prompt is probably the most interesting script here. It sets my $PROMPT_COMMAND for using a custom history folder and it sets $PS1 to provide colored time instead of user@host.</td></tr>
<tr><td>speech</td><td>front-end to spd-say command for text-to-speech</td><td>say.sh pretty much does the same as "say" on OS X.</td></tr>
<tr><td>system</td><td>general system-y things</td><td>
 <ul><li>chrootdistro.sh automates certain mount points needed for system stuff to work in the chroot</li><li>update-grub.sh acts like the Ubuntu update-grub command</li><li>mirror-check.sh is a rewritten version of Chakra Linux's mirror-check script</li></ul></td></tr>
<tr><td>volume</td><td>controls volume from the command line</td><td>volume-* scripts increase, decrease, and (un) mute the volume</td></tr>
</table>


### Dependencies - in progress
Right now the state of dependencies in my scripts is undefined. Here's the situation and how I plan to fix it.

Most scripts are useless without some other command that is not part of the shell. Bad things happen if the command is not found. Here are my use cases:

1. A script calls a command or other script that cannot be found.
2. A script's dependency changes in a way that breaks how it's called.
3. Some scripts have functionality in common and it's annoying to handle the duplicate code.

Here's what I plan to do about these cases:

1. Use something like `if ! which cmd1 cmd2; then exit 1; fi` to do a quick sanity check at the beginning of each script that uses custom commands.
2. Localize generally-useful dependency scripts into the `lib` folder and other dependency scripts into the folders that contain the scripts they're used in. This makes it easier to avoid breaking dependencies, but doesn't solve the problem. Suggestions are welcome and encouraged.
3. Refactor common functionality into new scripts with locations as described in #2.

Finally, I'll try to avoid these issues in the future.


Future Plans
------------
My computer use and understanding evolve constantly. So the main goals for these scripts are to make them general enough for future changes and simple enough for present use.

One key criterion for both generality and simplicity is that other people can easily setup and use my scripts if they want to. So if a script doesn't work easily for you, or you have a better idea, please <a href="http://refola.com/contact">send me your feedback</a> and I'll try to make it better.

In absence of feedback, I think the biggest long-term usability issue is that many scripts hard-code my system's specifics instead of using config files. Hard-coded stuff should be extracted into config files under `$HOME/.config/refola`.

The biggest functionality addition planned is to streamline my "one-home-per-distro with some shared config" setup (useful workaround for cross-distro incompatibilities, with a cleaner /home/$USER as a nice side-effect) and integrate that into these scripts. Eventually, I might even have a decent script for automagically configuring per-distro home folders and account stuff for multiple users on multiple distros.

Everything else is just the regular ad-hoc want-build-test-refactor loop.
