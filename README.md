# gqemoo
GUI for qemoo - wrapper script for qemu to start and install guest systems.  
  
qemoo_source: https://abf.io/betcher_/qemoo  
qemoo_rpm: [qemoo-0.7-5-rosa2021.1.noarch.rpm](https://mirror.yandex.ru/rosa/rosa2021.1/repository/x86_64/contrib/release/qemoo-0.7-5-rosa2021.1.noarch.rpm)  
  
VM loading from flash drives and images is supported `*.qcow2` and `*.iso`. Before loading the VM, you can connect flash drives, `*.iso`, `*.img` images and block devices.

**Dependencies:** qemoo qemu gtk2  
  
Working directory: `~/qemoo_tmp`; The images for loading and connecting are here.  
  
Note: You need to add the user to group `disk` and reboot: `usermod -aG disk $(logname); reboot`
  
![](https://github.com/AKotov-dev/gqemoo/blob/main/ScreenShot1.png)
