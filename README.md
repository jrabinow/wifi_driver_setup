# Setup wifi on qubes

- auto-attach wifi antenna to sys-net when it's plugged in
- auto-compile and load kernel module for antenna device driver

## Setup:
Copy the files in `dom0` directory to dom0 domain  
Copy the files in `sys-usb` directory to sys-usb domain  
Run the following in sys-net console:  
`sudo bash -c 'echo "/home/user/wifi_driver_setup/build_dkms.sh &" >> /rw/config/rc.local'`  

### References:
https://www.qubes-os.org/doc/yubi-key  
https://opensource.com/article/18/11/udev  
