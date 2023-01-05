# gqemoo
GUI for `qemoo` - wrapper script for qemu to start and install guest systems.  
  
qemoo project: https://abf.io/import/qemoo  
qemoo rpm: [qemoo-x.x-x-rosa2021.1.noarch.rpm](https://mirror.yandex.ru/rosa/rosa2021.1/repository/x86_64/contrib/release) (Ctrl+F)  
qemoo config: /etc/qemoo.cfg  
  
Free icons: https://www.flaticon.com  
Dependencies: `qemoo qemu gtk2 virt-viewer`  
  
**Hot Keys:**
+ `F12` - Update the list of connected devices
+ `Ctrl+Q` - Force reset of all QEMU processes  
  
Supported loading and installing virtual machines from flash drives, images and already installed images `*.qcow2`. Before booting a virtual machine, you can connect additional flash drives, images, and block devices. Bidirectional `Clipboard` and `Drag&Drop` are also supported.  
  
Host share/Working directory: `~/qemoo_tmp`  
Linux guest mount command example [ ~/hostdir ]:  
```
test -d /home/$(logname)/hostdir || mkdir /home/$(logname)/hostdir && mount -t 9p -o trans=virtio,msize=100000000 hostdir /home/$(logname)/hostdir && chown $(logname) -R /home/$(logname)/hostdir
```
**Note-1:** When installing `Mageia Linux` from an image or from a USB flash drive in EFI mode, install checkbox `Install in /EFI/BOOT (removable device or workaround for some BIOS's)` at the last step of the installer.  
  
**Note-2:** You need to add the user to group `disk` and reboot: `usermod -aG disk $(logname); reboot`  
For support Drag and Drop + bidirectional Clipboard on the guest system must be installed `spice-vdagent` (Linux, usually already installed) or [spice-guest-tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) (Windows).  
  
![](https://github.com/AKotov-dev/gqemoo/blob/main/ScreenShot6.png)
