# GQemoo
GUI for `qemoo` - wrapper script for qemu to start and install guest systems.  
  
Perhaps the easiest and most understandable tandem for working with virtual machines in QEMU. Minimum settings for running and installing VMs: `RAM`(MB), `SIZE`(GB) - the size of the disk to install and the number of CPU cores (-smp X and other parameters) in the `QEMUADD` field. Perfect for testing/installing any Linux/Windows distributions.  
  
qemoo project: https://abf.io/import/qemoo  
qemoo rpm: [qemoo-x.x-x-rosa2021.1.noarch.rpm](https://mirror.yandex.ru/rosa/rosa2021.1/repository/x86_64/contrib/release) (Ctrl+F)  
  
Free icons: https://www.flaticon.com  
Dependencies for VMs: `xrandr spice-vdagent`  
GQemoo dependencies: `qemoo qemu gtk2 virt-viewer rsync polkit`  
  
**GQemoo Hot Keys:**
+ `Esc` - Canceling image cloning .qcow2  
+ `F12` - Update the list of connected devices
+ `Ctrl+Q` - Force reset of all QEMU processes
  
Supported loading and installing virtual machines from flash drives, images (.img, .iso, .qcow2, .raw, .vdi, .vmdk, .vpc) and already installed images `*.qcow2`. Before booting a virtual machine, you can connect additional flash drives, images, and block devices. Bidirectional `Clipboard` and `Drag&Drop` are also supported.  
  
The shared directory `~/qemoo_tmp` (Host) <> `~/hostdir` (Guest), as well as the automatic scaling of the VM window `XResize` are enabled by inserting embedded scripts from the Clipboard.
  
**Note:** You need to add the user to groups `disk,kvm` and reboot: `usermod -aG disk,kvm $(logname); reboot`  
For support Drag and Drop + bidirectional Clipboard on the guest system must be installed `spice-vdagent` (Linux, usually already installed) or [spice-guest-tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) (Windows).  
  
![](https://github.com/AKotov-dev/gqemoo/blob/main/ScreenShot8.png)
