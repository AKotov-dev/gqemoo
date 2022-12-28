# gqemoo
GUI for `qemoo` - wrapper script for qemu to start and install guest systems.  
  
qemoo project: https://abf.io/import/qemoo  
qemoo rpm: [qemoo-x.x-x-rosa2021.1.noarch.rpm](https://mirror.yandex.ru/rosa/rosa2021.1/repository/x86_64/contrib/release) (Ctrl+F)  
qemoo config: /etc/qemoo.cfg  
  
It supports downloading and installing virtual machines from flash drives and images. Before booting a virtual machine, you can connect additional flash drives, images, and block devices. If necessary, you can select the display from the list: `default`, `STD`, `QXL` and `VIRTIO` (virtio is preferred for Mageia Linux). Returning the mouse pointer from the guest OS - `Ctrl+Alt+g`.  
  
When installing `Mageia Linux` from an image or from a USB flash drive in EFI mode, install checkbox `Install in /EFI/BOOT (removable device or workaround for some BIOS's)` at the last step of the installer.
  
**Dependencies:** qemoo qemu gtk2  
**Free icons:** https://www.flaticon.com  
  
Working directory: `~/qemoo_tmp`; The images for loading and connecting are here.  
  
**Note:** You need to add the user to group `disk` and reboot: `usermod -aG disk $(logname); reboot`
  
![](https://github.com/AKotov-dev/gqemoo/blob/main/ScreenShot4.png)
