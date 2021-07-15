# Pinephone x Arch Linux x i3

Instructions for installing bare-bones Arch on your Pinephone and using i3 on top of it.

The manual is devided into steps, which follow the following format:
### Step 0
```diff
+ Decide to install Arch + i3 on your Pinephone

! Why: Because it'd be cool to just dock your phone and be at your desktop environment
```
It's done by following the instructions in this page.
##### Resources
- [This post](https://github.com/jedinja/pine-arch-i3)

The steps are ordered in a way to help one bring the next most important functionality to the phone. 
A special note on this one: bringing a dialer, contacts app, sms app and mobile data would be done at the end.
The motivation for this is I want to treat my Pinephone as a computer-first, phone-second device.

**Also relevant configuration files for the step are added under a folder with the same name.**

## So Let's Begin 

### Step 1
```diff
+ Download and write the bare-bones image from dreemurrs-embedded

! Why: Because somebody smart has done the heavy-lifting of making a good image for the Pinephone
```
Follow the installation guide [here](https://github.com/dreemurrs-embedded/Pine64-Arch/wiki/Installation-Guide).
Don't forget to read the quick guide for the bare-bones image on that wiki.
Update the system at the end:
```shell
sudo pacman -Syu
```

##### Resources
- [Installation guide](https://github.com/dreemurrs-embedded/Pine64-Arch/wiki/Installation-Guide)
- [Bare-bone Image Quick Start](https://github.com/dreemurrs-embedded/Pine64-Arch/wiki/Barebone-Image-Quick-Start)
- [PinePhone Installation Instructions](https://wiki.pine64.org/index.php/PinePhone_Installation_Instructions#Installation_to_eMMC_.28Optional.29)

### Step 2
```diff
+ Install X, i3, and make it boot into it without login

! Why: First thing needed is the graphical environment and being able to get into it without keyboard.
```
I prefer to install the whole xorg group just in case. Also the xorg-xinit package for auto-starting. 
i3-wm and i3status should also be added:
```shell
sudo pacman -S xorg xorg-xinit i3-wm i3status
```
You can easily bring your i3 config from your desktop. 
Be careful using the stock one because it starts a wizard, which cannot be viewed.
This repo provides the config file at step_2/home/alarm/.config/i3/config. 

**Note the paths are in the form of STEP_NUM/ABSOLUTE-PATH-TO-FILE-ON-PHONE.**

Next i3 is to be configured to auto-start on login. Starting X happens with adding the following to .bash_profile:
```shell
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi
```
Then i3 is executed from the xorg-xinit package through adding the following to .xinitrc:
```shell
exec i3
```
Personally at this point I prefer to install a terminal, which would let me run commands through the graphical env running.
My personal favourite is _**xfce4-terminal**_. However the default way for starting the terminal on i3 is through i3-sensible-terminal,
and this means you can choose from variety of other terminals and they will work out of the box.

Finally auto-login.
The usual way is to copy the getty service, rename it, create sym link and edit it. 
For my personal phone though I prefer to just edit the getty service (/usr/lib/systemd/system/getty@.service) itself
and replace the exec line as follows:
```shell
ExecStart=-/sbin/agetty -a alarm %I $TERM
```
where "alarm" is the default user on the arch image.

Note that from here on "alarm" would be used for the configuration. 
If you want to use another user you'll have to substitute it on every place in the manual. 

##### Resources
- [i3 config docs](https://i3wm.org/docs/userguide.html#configuring)
- [Start X on login](https://wiki.archlinux.org/title/Xinit#Autostart_X_at_login)
- [Init X](https://wiki.archlinux.org/title/Xinit#Configuration)
- [i3 terminals](https://man.archlinux.org/man/i3-sensible-terminal.1.en)
- [Passwordless auto-login](https://unix.stackexchange.com/questions/42359/how-can-i-autologin-to-desktop-with-systemd)

### Step 3
```diff
+ Disable default power button behavior

! Why: You don't want the power button on a phone to shut it down.
```
The default power action would be set to ignore, so that nothing happens. 
But no worries - later it'd be configured in i3 to do what we want it to.
For now disabling it would prevent accidental shut down, which is annoying.

Locate the file /etc/systemd/logind.conf and add the line:
```shell
HandlePowerKey=ignore
```
Note there is already one commented out.

##### Resources
- [logind.conf manual](https://man7.org/linux/man-pages/man5/logind.conf.5.html)

### Step 4
```diff
+ Install App launcher (for desktop mode) and a better status bar

! Why: The status bar would be configured to show ip and battery, 
! so that you won't forget to charge it on during installation
! and won't need to wire a keyboard and run commands to get the ip,
! so that you can connect using ssh. App launcher is already installed,
! but I find it more natural to configure it right after i3. 
```
i3 comes with _**dmenu**_ preinstalled as app launcher (via keyboard) but I prefer to use _**rofi**_ as it supports theme-ing.
Here's the diff from the .config/i3/config file:
```diff
-bindsym $mod+d exec --no-startup-id dmenu_run
+bindsym $mod+d exec rofi -show combi
+bindsym $mod+Tab exec rofi -modi window -show window
```
A complete config file for this step is provided at step_4/home/alarm/.config/i3/config.

The rofi configs are put into .config/rofi. There is a file for the actual config and one for a theme.
Two files are accessible at step_4/home/alarm/.config/rofi/. 

The more interesting part is using _**i3blocks**_ for the status bar, which offers good configuration options.
You can add text of course, but also more descriptive one and colors. 
You can write your own programs to output info on the status bar, and you just need to follow the format.
For start I only add the ip, the time and the battery to make the rest of the installation smoother.
_**i3blocks**_ has one config file, which defines "sections" as:
```shell
[SECTION_NAME]
command=PATH_TO_COMMAND
color=COLOR
interval=INTERVAL
```
The file sits at ~/.i3blocks.conf. 
The referenced commands are put into ~/i3blocks-programs/ but can be anywhere as the path is written in the config itself.

The clock script and the ip script are plundered from elsewhere. 
With the battery script be careful using the path to the battery file. 
For other devices it could be different.

The last thing is to make i3 use the _**i3blocks**_, which is done through changes in the i3 config:
```diff
bar {
-        status_command i3status
+        status_command i3blocks
+        font pango:monospace 16
+#       mode hide
+        modifier $mod2
+        position top
+        colors {
+                background #333333
+#               statusline #ffe57c
+                separator #0373bc
+        }
+        separator_symbol "|"
}
```

##### Resources
- [Rofi project](https://github.com/davatorium/rofi/wiki/Configuring-Rofi)
- [Rofi themes](https://github.com/davatorium/rofi/wiki/Themes)
- [i3blocks project](https://github.com/vivien/i3blocks)




