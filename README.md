Make grub to boot over UEFI/BIOS network boot/iPXE/PXE. 

After building it, create a symlink to grub.* on your tftp root, served by dnsmasq.

The grub.cfg can be customized by changing grub_template_menu.cfg and running make again.

The same grub.cfg will be used by booth BIOS and UEFI network boot.

You can find a few snippets of configuration for dnsmasq in dnsmasq-snippets. The file dnsmasq.conf-proxy-mode can be used as the sole config file when using dnsmasq to serve netboot, without acting as DHCP server. (So it can run in parallel to an existent DHCP server, without having to change anything on the DHCP server)
