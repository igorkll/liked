# xpkg
xpkg is an analogue of apk on Android,
this is essentially a tar or afpx archive.
during installation, this archive is unpacked into the "/data" folder
to create an installation package, create an “apps” folder in the archive and place the necessary applications in it.
all conflicting files will be automatically replaced.
we recommend a package for one application only.