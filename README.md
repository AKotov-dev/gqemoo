# GQemoo
GUI for `qemoo` - wrapper script for qemu to start and install guest systems.  
  
qemoo project: https://abf.io/import/qemoo  
qemoo rpm: [qemoo-x.x-x-rosa2021.1.noarch.rpm](https://mirror.yandex.ru/rosa/rosa2021.1/repository/x86_64/contrib/release) (Ctrl+F)  
qemoo config: /etc/qemoo.cfg  
[qemoo and systemd integration](https://abf.io/import/qemoo/blob/rosa2023.1/%D1%81%D0%BF%D1%80%D0%B0%D0%B2%D0%BA%D0%B0.%D0%BA%D0%BE%D0%BC%D0%B0%D0%BD%D0%B4%D0%B0.qemoo)  
  
Free icons: https://www.flaticon.com  
Dependencies: `qemoo qemu gtk2 virt-viewer rsync`  
Dependencies for VMs: `xrandr spice-vdagent`  
  
**GQemoo Hot Keys:**
+ `F12` - Update the list of connected devices
+ `Ctrl+Q` - Force reset of all QEMU processes
+ `Esc` - Canceling image cloning *.qcow2  
  
Supported loading and installing virtual machines from flash drives, images and already installed images `*.qcow2`. Before booting a virtual machine, you can connect additional flash drives, images, and block devices. Bidirectional `Clipboard` and `Drag&Drop` are also supported.  
  
Host share/working directory: `~/qemoo_tmp`  
  
**Note** You need to add the user to groups `disk,kvm` and reboot: `usermod -aG disk,kvm $(logname); reboot`  
For support Drag and Drop + bidirectional Clipboard on the guest system must be installed `spice-vdagent` (Linux, usually already installed) or [spice-guest-tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) (Windows).  
  
![](https://github.com/AKotov-dev/gqemoo/blob/main/ScreenShot8.png)
