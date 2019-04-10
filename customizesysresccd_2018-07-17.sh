#******************************************************************
#****        Read the whole script, and understand it.         ****
#****  If not, you might suffer from dataloss or even worse!   ****
#******************************************************************
#** This script customizes the non-UEFI Boot of a sysresccd.     **
#** It has been tested wit SysRescCD Version 5.2.2               **
#** Get that from system-rescue-cd.org                           **
#******************************************************************
#*** First, boot the unmodified sysresccd without docache option.
#*** wget eck.spdns.de/customizesysresccd.sh
#*** BEFORE running it: Make sure you modified the relevant parts
#*** of this script to reflect your systems needs !!!!
#*** Execute this script with:
#*** time bash customizesysresccd.sh
#*** (that may take up to 30 minutes)

#****************************************************************
#*** Optional: Mount folder which will later receive the iso: ***
#****************************************************************
sshfs -o Ciphers=aes128-ctr,compression=yes pi@raspizerow:/home/pi/Documents /mnt/floppy
#*** when problems arise:
#*** sshfs -o debug,Ciphers=aes128-ctr,compression=yes pi@raspizerow:/home/pi/Documents /mnt/floppy
if grep -q " /mnt/floppy " /proc/mounts
then
  echo "/mnt/floppy is mounted -> ok"
else
  echo "/mnt/floppy is not mounted -> Cannot continue."
  exit 1
fi

#******************************************************
#*** Mandatory: Extract the files for customization ***
#******************************************************
mount /dev/sda1 /mnt/custom
if grep -q " /mnt/custom " /proc/mounts
then
  echo "/mnt/custom is mounted -> ok"
else
  echo "/mnt/custom is not mounted -> Cannot continue."
  exit 1
fi
#*** Check if /mnt/custom is empty.
DIR="/mnt/custom"
if [ "$(ls -A $DIR)" ]; then
echo "$DIR is not Empty"
read -p "It is better to press Ctrl-C which will stop the script; If you choose to proceed then press enter."
else
echo "$DIR is Empty"
fi
/usr/sbin/sysresccd-custom extract

#*********************************************************************************
#*** Optional: Customize the login screen to give a hint to the backup manual. ***
#*********************************************************************************
sed -i 's?# ============ SHELL PROMPT?echo -e "${dc1}*${lc1} Show manual to backup/restore${dc2} : ${lc2}less backup.txt"\n# ============ SHELL PROMPT?' /mnt/custom/customcd/files/bin/bashlogin

#***********************************
#*** Optional: Create the manual ***
#***********************************
cat <<EOF >/mnt/custom/customcd/files/root/backup.txt

 Backup of block devices (2018-06-28)
**************************************

Disclaimer: This work was produced with the best intentions by me. Nevertheless, I cannot make any warranty, express or implied, or can be held accountable for any liability or responsibility for the accuracy, completeness, or usefulness of any information, apparatus, product, or process disclosed, or represent that its use would not infringe privately-owned rights. Use this Document at your own risk. The developer and/or provider is not responsible for what you do with your device or data.


Prerequisites or, what i need before i really start:
****************************************************
• You need a PC.

• A SysRescCD boot medium. Prefer the newest, but for restore reasons it may be good to have the one which you used at a former backup session. Download it from http://www.system-rescue-cd.org

• The source block device you whish to make a backup from. Like an HDD, SDD, USB flash drive, MicroSD Card, etc.

• A destination medium you can write a file to. Make sure it is big enough to hold the whole size of your source device. I speak of the whole size, not only the sum of all file sizes. So, if you  backup a 1TB HDD, have a destination medium which can hold 1.1TB at minimum, just to be safe. I strongly suggest using a file system, on the destination medium, which makes use of compression. Under some conditions this will not save any space, though under most conditions it saves a lot of space.


 ◦ In a SysRescCD session You can delete and prepare a future destination HDD with the following nine command lines; Don't forget to correct /dev/sdz:
  (
  echo o # Create a new empty DOS partition table
  echo n # Add a new partition
  echo p # Primary partition
  echo 1 # Partition number
  echo   # First sector (Accept default: 1)
  echo   # Last sector (Accept default: varies)
  echo w # Write changes
  ) | fdisk /dev/sdz
  reboot
  lsblk # Check what name the destination HDD got after the reboot (formerly sdz)
  mkfs.btrfs /dev/sdz1
 ◦ This cleared the partition table and made a new one that has a single partition that spans the entire disk. Also a btrfs fs on this partition has been created.

 ◦ Here we compare compression and zeroeing. Compression has to be chosen in the prerequisites, zeroeing makes only sense in addition to compression and has to be decided every backup session and for every partition.
  ◦ Shown by an example Ubuntu OS partition, size 29GB, filled with 25GB of files, results in:
  ◦ backup size 29GB, w/o compression, w/o zeroeing.
  ◦ backup size 29GB, w/o compression, w/ zeroeing.
  ◦ backup size 21GB, w compression, w/o zeroeing.
  ◦ backup size 18GB, w compression, w zeroeing.


Backup:
*******
• At first, you may consider overwriting unused space on the source device with zeroes before backuping, which can hugely reduce the needed space on the destination medium, in addition to the, former mentioned, compression. But decide wisely if you, or others, want these old files overwritten. And if you choose to do that, do it from within the OS which normally uses this source device, do that not from within a running SysRescCD session.
 ◦ In Linux, use the one-liner: cat /dev/zero > zero.fill; rm zero.fill
 ◦ In Windows use one of them: eraser.heidi.ie; sdelete; ccleaner; FileWing Pro.

• If you are going to boot SysRescCD from anything at a USB Connector, it is better to remove all other USB-connected block devices from this PC, such as flash drives, Memory Cards at USB-Card readers and at USB-Printers or cameras that are currently connected to USB.

• Now boot SysRescCD. Wait and/or answer possibly arising questions, until the boot process is finished.

• Connect the source medium and the destination medium. Check with lsblk.

• Mount the destination medium. Maybe with one of the following mount examples:
 ◦ mount -o noatime,nodiratime,compress-force=lzo /dev/sdz1 /mnt/backup
 ◦ mount -o guest,noperm,iocharset=utf8,vers=1.0 //192.168.178.23/public /mnt/backup

• Maybe you want to create a directory for this specific backup. E.g.
 ◦ mkdir /mnt/backup/backup_of_my_daughters_PC; cd /mnt/backup/backup_of_my_daughters_PC

• Do the backup. E.g.
 ◦ ddrescue /dev/sdy 2018-05-16_sdy.ddrescue.img; sync


Restore:
********
• Boot into a sufficient Linux.
 ◦ If you use sysRescCD for restoring then be aware that you don't have to use sudo.
 ◦ If you are going to restore files to a NTFS-Partition (not restoring a complete partition or a complete block device) then make sure you disabled the "Windows' fast startup feature" or you do use "reboot Windows" just before booting into Linux, which also does not use "fast startup".

• Connect all the needed devices.

• Mount the (former) destination device, where the backup resides, e.g.:
 ◦ sudo mount /dev/sdz1 /mnt/backup

• Then create loop devices from the image file, e.g.:
 ◦ sudo losetup /mnt/backup/backup_of_my_daughters_PC/2018-05-16_sdy.ddrescue.img -vrPf --show

• Check with lsblk.


If you want to restore only specific files:
• Mount the source device (a.k.a. backup drive), e.g.:
 ◦ sudo mkdir /mnt/filebackup; sudo mount -o ro /dev/loop0p1 /mnt/filebackup

• Now mount the destination partition, e.g.:
 ◦ sudo mount /dev/nvme0 /mnt/windows # This line may need to be corrected.

• Now you can move files from the backup to where ever you want them and with whatever app you want to use for this task. E.g.:
 ◦ mc
 ◦ Hints:
  ◦ Teamspeak3: C:\Users\Username\AppData\Roaming\TS3Client
  ◦             /home/Username/.ts3client
  ◦ Thunderbird: C:\Users\Username\AppData\Roaming\Thunderbird
  ◦              /home/Username/.thunderbird
  ◦ Minecraft: C:\Users\Username\AppData\Roaming\.minecraft
  ◦            /home/Username/.minecraft
  ◦ Firefox: C:\Users\Username\AppData\Roaming\Mozilla
  ◦          /home/Username/.mozilla
  ◦ general: C:\Users\Username\Desktop
  ◦          C:\Users\Username\Downloads
  ◦          C:\Users\Username\Favorites
  ◦          C:\Users\Username\Music
  ◦          C:\Users\Username\OneDrive
  ◦          C:\Users\Username\Videos
  ◦ Oxygen not included: /home/Username/.config/unity3D/Klei/Oxygen not included
  ◦ 7 Days to die: C:\Users\Username\AppData\Roaming\7DaysToDie
  ◦ Stellaris: C:\Users\Username\Documents\Paradox interactive\Stellaris
  ◦ Steam: C:\Program Files(x86)\Steam\steamapps\common
  ◦ jameica/hibiscus: /home/Username/.jameica
  ◦                   /home/Username/bin/jameica

  ◦ find /path/to/backupfolder/ \( -iname "*.jpg" -o -iname "*.odt" \)


If you want to restore a complete drive, e.g.:
• sudo ddrescue -f /dev/loop0 /dev/sdy


If you want to restore a specific complete partition, e.g.:
• sudo ddrescue -f /dev/loop0p1 /dev/sdy1


• When the Restoring has ended you can reboot to unmount and reset 
the loop devices.
EOF

#******************************************************************************
#*** Optional: Next, we customize /mnt/custom/customcd/isoroot/isolinux.cfg ***
#******************************************************************************
# Set bootmenu-timeout to 4 seconds.
sed -i 's?TIMEOUT 900?TIMEOUT 40?' /mnt/custom/customcd/isoroot/isolinux/isolinux.cfg
# Set Standard boot label to sysresccd_docache
sed -i 's?ONTIMEOUT rescuecd_std?ONTIMEOUT rescuecd_docache?' /mnt/custom/customcd/isoroot/isolinux/isolinux.cfg
# Set language to "de" to prevent the language-question every boot (but only for the docache-label)
sed -i 's?APPEND rescue64 docache?APPEND rescue64 docache setkmap=de?' /mnt/custom/customcd/isoroot/isolinux/isolinux.cfg

#**************************************
#** Mandatory: Create the iso file. ***
#**************************************
/usr/sbin/sysresccd-custom squashfs
/usr/sbin/sysresccd-custom isogen my_srcd

#********************************************
#** Optional: Print some Version-Numbers. ***
#********************************************
echo "**************************************************************************************"
echo "*** This part will print information about fulfilled prerequisites to build lfs 8.2***"
echo "**************************************************************************************"
cd /mnt/floppy
#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f2-4
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh -> $MYSH"
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
unset MYSH

echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

if [ -h /usr/bin/yacc ]; then
  echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
  echo yacc is `/usr/bin/yacc --version | head -n1`
else
  echo "yacc not found" 
fi

bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [ -h /usr/bin/awk ]; then
  echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
  echo awk is `/usr/bin/awk --version | head -n1`
else 
  echo "awk not found" 
fi

gcc --version | head -n1
g++ --version | head -n1
ldd --version | head -n1 | cut -d" " -f2-  # glibc version
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1
xz --version | head -n1

echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
  then echo "g++ compilation OK";
  else echo "g++ compilation failed"; fi
rm -f dummy.c dummy

#**************************************************
#*** Optional: Transfer the iso to /mnt/floppy. ***
#**************************************************
#scp  aes128-gcm@openssh.com /mnt/custom/customcd/isofile/*.iso pi@raspizerow:/home/pi/Documents/
rsync -h --progress /mnt/custom/customcd/isofile/*.iso /mnt/floppy
echo "The customized .iso-File has been written to /mnt/floppy."

#*****************************
#*** Optional: Last words. ***
#*****************************
echo "You can directly burn the customized SysRescCD to a CD, or write it to a flashdrive."
echo "For instructions about that, read the original instructions"
echo "at system-rescue-cd.org."

