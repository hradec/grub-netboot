Makes grub to boot over UEFI/BIOS network boot/iPXE/PXE
After building it, create a symlink of grub.* to your tftp root, served by dnsmasq.
The grub.cfg can be customized by changing grub_template_menu.cfg and running make again.
The same grub.cfg will be used by booth BIOS and UEFI network boot.
