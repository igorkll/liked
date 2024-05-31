# liked & likeOS
liked is a system based on likeOS.
designed for computers from the OpenComputers mod for Minecraft.
the installer can be run from any other OS or from the eeprom firmware.

### minimum system requirements:
* video card - tier2
* monitor - tier2
* RAM - 768KB
* processor - tier1
* hdd - tier2

### recommended system requirements:
* video card - tier3
* monitor - tier3
* RAM - 1536KB
* processor - tier2
* hdd - tier2

if openOS or MineOS is installed on the device, then during installation, liked will offer to save your OS,
after which it can be launched with a single click on the liked desktop.
if MineOS was previously installed and you saved it when installing liked, then the "like loader" will be flashed in the EEPROM for the place of the BIOS originally standing there.
this is done because in "MineOS EFI" the priority is set to MineOS and liked would be unavailable.

## installer link
* installer: https://raw.githubusercontent.com/igorkll/liked/main/installer/webInstaller.lua
* computercraft version(alpha): https://raw.githubusercontent.com/igorkll/liked/main/installer/computercraft.lua

## installation commands:
* openOS : wget https://raw.githubusercontent.com/igorkll/liked/main/installer/webInstaller.lua /tmp/like; /tmp/like
* craftOS: wget run https://raw.githubusercontent.com/igorkll/liked/main/installer/computercraft.lua