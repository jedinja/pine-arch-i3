# Pinephone x Arch Linux x i3

Instructions for installing bare-bones Arch on your Pinephone and using i3 on top of it.

The manual is devided into steps, which follow the following format:
### Step 0
```diff
@@ Decide to install Arch + i3 on your Pinephone @@

Why: Because it'd be cool to just dock your phone and be at your desktop environment
```

It's done by following the instructions in this page.
##### Resources
- [This post](https://github.com/jedinja/pine-arch-i3)
- [What is Arch](https://en.wikipedia.org/wiki/Arch_Linux)
- [What is i3](https://en.wikipedia.org/wiki/I3_(window_manager))

The steps are ordered in a way to help one bring the next most important functionality to the phone. 
A special note on this one: bringing a dialer, contacts app, sms app and mobile data would be done at the end.
The motivation for this is I want to treat my Pinephone as a computer-first, phone-second device.

**Also relevant configuration files for the step are added under a folder with the same name.**

## So Let's Begin 

### Step 1
```diff
@@ Download and write the bare-bones image from dreemurrs-embedded @@

Why: Because somebody smart has done the heavy-lifting of making a good image for 
the Pinephone
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
@@ Install X, i3, and make it boot into it without login @@

Why: First thing needed is the graphical environment and being able to get into it 
without keyboard.
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
@@ Disable default power button behavior @@

Why: You don't want the power button on a phone to shut it down.
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
@@ Install App launcher (for desktop mode) and a better status bar @@

Why: The status bar would be configured to show ip and battery, 
so that you won't forget to charge it on during installation
and won't need to wire a keyboard and run commands to get the ip,
so that you can connect using ssh. App launcher is already installed,
but I find it more natural to configure it right after i3. 
```
i3 comes with _**dmenu**_ preinstalled as app launcher (via keyboard) but I prefer to use _**rofi**_ as it supports theme-ing.
Here's the diff from the .config/i3/config file:
```diff
-bindsym $mod+d exec --no-startup-id dmenu_run
+bindsym $mod+d exec rofi -show combi
+bindsym $mod+Tab exec rofi -modi window -show window
```
A complete config file for this step is provided at step_4/home/alarm/.config/i3/config.

The **_rofi_** configs are put into .config/rofi. There is a file for the actual config and one for a theme.
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

### Step 5
```diff
@@ Do something useful with the Power button like Suspend @@

Why: Achieve first version of traditional phone behavior like pressing the power
button to make the phone "sleep" to conserve the battery. Also it's like first 
steps in what can be done with i3.
```

Accessing power functions on the OS is a bit tricky if you want to do it as an underprivileged user.
This is made easier with using a tool like _**polkit**_ - install it.
Then a polkit policy is required to allow such behavior. A file needs to be added in /etc/polkit-1/rules.d/.
Its name kind of follows Xorg conf conventions. Let's name it 85-suspend.rules. 
It's contents are as follows:
```shell
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.suspend" &&
        subject.isInGroup("users")) {
        return polkit.Result.YES;
    }
});
```
The "&& subject.isInGroup("users")" could be omitted but I find it better to use as direct control on who can suspend the machine.

Moving to actual key handling:

First try was with using "bindcode" and finding the power button's key code in the i3 config.
However, it turns out there is a handy symbol: XF86PowerOff, which could be used instead.

So now, alongside the above polkit config adding the following line to i3's config makes the phone suspend.
```diff
+ bindsym --release XF86PowerOff exec systemctl suspend -i
```
Turns out it brings a problem: when you press the power button again to wake up the phone it suspends a few seconds later again.
It's not a 100% reproducible but it can fall into an endless loop. It could also be related to the --release modifier.
Nonetheless, it brings up the opportunity to use one of i3's powerful toolsets - modes.
With every action one can tell i3 to fall into a specific mode, which could have a totally different keybinding scheme.
You define a mode as:
```shell
mode "NAME_OF_THE_MODE" {
  
}
```
There is an example of this already in the default i3 config - the "resize" mode, which can be used as a reference.
You put the overriding bindings inside the curly brackets and Voala.
Activating the mode happens as you append the mode in a keybinding after a comma.
So using a mode to resolve the aforementioned problem would look like this:
```shell
bindsym --release XF86PowerOff exec systemctl suspend -i, mode "susp"
mode "susp" {
    bindsym --release XF86PowerOff mode "default"
}
```
As you can see pressing the power button suspends the system and makes it fall into "susp" mode.
Pressing it again, however, only changes the mode to the default one. (You don't need to define that one though)

##### Resources
- [Polkit policy](https://itectec.com/ubuntu/ubuntu-authentication-required-before-suspend/)
- [i3 binding modes](https://i3wm.org/docs/userguide.html#binding_modes)

### Step 6
```diff
@@ Time to create an App Launcher using rofi @@

Why: As the phone has a status bar it's time to make it open applications. 
This is kind of a proof of concept step. Turns out Rofi is pretty powerful 
for such a task and if it's already the default desktop launcher 
then why not reuse it in the mobile interactions?
```

I wouldn't go much in the details of how to customize the **_rofi_** themes. 
It's a powerful tool and one can look at the man page to see how it works.
However, the man page is not very up-to-date, it seems, and the knowledge to enable you to create an Android-style launcher is just not there.
Moreover the themes in the official repo feel like more of a skin, not really showing the real flexibility of the tool.

Good news is there is a great repo with a ton of different themes, which could be used as a basis for developing one's own launcher experience.
Thanks to [Aditya Shakya](https://github.com/adi1090x) there is this nice repo with all the themes. 
I've provided a simple theme in this step's source files based on (stealed from) one of the colorful launchers in that repo. 
Just drop it in ~/.config/rofi. And don't forget the colors.rasi file too.

Then let's test it when the phone logs in - after all its point is not to only look at the status bar.
The following should be appended at the end of the i3's config file:
```diff
+ rofi -modi drun -show drun -theme sample
```

Reboot and there's the PoC for the launcher!

##### Resources
- [Rofi theme man page](https://manpages.debian.org/testing/rofi/rofi-theme.5.en.html)
- [Comprehensive rofi themes](https://github.com/adi1090x/rofi)

### Step 7
```diff
@@ Decide on UI/UX interactions @@

Why: This is a pure planning step, on which next steps would depend.
That's why it's abstracted in a separate step.
```

This is a cycle process, which has the following steps:

1. Draw a UI/UX wireframe
2. Research and evaluate what is and what isn't possible with the available tools (_**rofi**_)
3. If something is not possible either find a new tool or return to 1. to redesign it in a way to be possible with the available tools

The end result from this process would shape the next steps added to this manual. 
That's why they will be tracked as 7.8, 7.9, etc.
This way it will be easier for people who want to do something differently to spot at which steps they need deviate from the manual.

This process has yielded the following:

- Workspace is used by default in tabbed mode with possibly removed window title
- The Volume Up button is used for either Previous window or move to the left
- Pressing the Volume Down button would open an App Drawer with four sections:
- The first one (the default) is for favourites
- The second one is for phone function scripts and toggles like WiFi, Torch, Data
- The third contains all apps
- The fourth one contains all open apps/windows
- Develop a nice to look at theme for _**rofi**_

Technical solutions for each are:

- Scripting in i3
- i3 config
- i3 config
- Custom _**rofi**_ modi implemented in bash to read .desktop files from custom folder
- Custom _**rofi**_ modi implemented in bash to read .desktop files from custom folder
- Regular "drun" modi in _**rofi**_
- Regular "window" modi in _**rofi**_
- Existing _**rofi**_ functionallity - the benefit of separated presentation from data








