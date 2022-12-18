# gqemoo
GUI for `qemoo` - wrapper script for qemu to start and install guest systems.  
  
qemoo project: https://abf.io/import/qemoo  
qemoo rpm: [qemoo-x.x-x-rosa2021.1.noarch.rpm](https://mirror.yandex.ru/rosa/rosa2021.1/repository/x86_64/contrib/release) (Ctrl+F)  
  
VM loading from flash drives and images is supported `*.qcow2` and `*.iso`. Before loading the VM, you can connect flash drives, `*.iso`, `*.img` images and block devices.

**Dependencies:** qemoo qemu gtk2  
  
Working directory: `~/qemoo_tmp`; The images for loading and connecting are here.  
  
**Note:** You need to add the user to group `disk` and reboot: `usermod -aG disk $(logname); reboot`
  
![](https://github.com/AKotov-dev/gqemoo/blob/main/ScreenShot2.png)
