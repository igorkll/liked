# likedbox

## this is an embedded operating system liked (similar to windowsCE)
in fact, this is a full-fledged liked one, but it does not contain a desktop or any pre-installed applications.
after loading, it launches an application named "shell".
by default, in the "/system/bin" folder there is an example "shell.lua" which will be launched if you run an unconfigured likedbox.

## likedbox configurations:
to configure likedbox you need to change the contents of the "/system" folder
you can change the boot logo, palette, default registry contents.
you also need to replace the "shell.lua" application with your own.
instead of "shell.lua" you can use "shell.app" that is a package application.
however, since it is better to install likedbox using the "box" archive, and the file cannot be deleted through the archive,
it would be better to name your application not “shell.app” but by the name of your project (this would be more correct),
and place this application in the folder "/system/apps/exampleProject.app", and in the file "/system/bin/shell.lua" place a simple code that will launch your application:
```lua
local screen = ...
assert(require("apps").execute("exampleProject", screen))
```

## scope of application likedbox
likedbox can be used for exchangers, navigators, cameras, slot machines.
and other things where a desktop is not required, and any control over the device, in addition to that provided by the standard installed application

## impertinence
likedbox has increased assertiveness.
if your program crashes,
then it will not crash to the desktop (there is no desktop or console in likedbox, the shell you installed is the only one existing in this OS)
likedbox will log the error to the file "/data/errorlog.log" and restart your application.
If for some reason likedbox itself crashes, then with a 90% probability (depending on the cause of the crash) it will simply restart the computer.