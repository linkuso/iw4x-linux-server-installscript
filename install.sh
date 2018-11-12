#!/bin/bash
# init

echo "Install IW4x debian linux" 

dpkg --add-architecture i386
apt-get update -y
apt-get install wine wine32 unzip git screen -y

echo "### Specify username to install under - can be a new or existing user - DO NOT use root ###"
read username
echo "### Specify password if new user ###"
read password
echo "### Specify server hostname (Visable in the serverbrowser) ###"
read svhostname
#echo "### Specify server ip ###"
#read ip
echo "### Specify server port default is 28960 (You must Specify a port) ###"
read port
echo "### Specify server alias - a name to refer to this server by - use different names for multiple servers ###"
read svalias


if id "$username" >/dev/null 2>&1; then
        echo "### User already exists ###"
else
        echo "### Creating user $username ###"
        useradd -m -g users -d /home/"$username" -s /bin/bash -p $(echo "$password" | openssl passwd -1 -stdin) "$username"
fi

if [ -d /home/'$username'/servers/'$svalias' ]; then
  echo "### You already have a server with that alias ###"
  exit 0
fi


echo "### Creating serverfolder '$svalias'"
su "$username" -c "mkdir -p /home/'$username'/servers/'$svalias'"

if [[ -f /home/"$username"/MW2.zip ]]; then 
    echo "### The install file exists already ###"
else
    echo "### Continuing ###"
    echo "### Adding urls to download_list.txt ###"
	cat > /home/"$username"/download_list.txt <<EOF
	http://downloads.warzone.gg/IW4M/MW2.zip
	http://downloads.warzone.gg/IW4M/iw4x_files.zip
	http://downloads.warzone.gg/IW4M/iw4x_dlc.zip
EOF


echo "### Downloading MW2 ###"
wget -P /home/"$username" -i /home/"$username"/download_list.txt
fi


echo "### Extracting MW2 ###"
unzip /home/"$username"/MW2.zip -d /home/"$username"/servers/"$svalias"/
echo "### Extracting MW2-DLC's ###"
unzip -u /home/"$username"/iw4x_dlc.zip -d /home/"$username"/servers/"$svalias"/MW2/
echo "### Extracting iw4x files ###"
unzip -u /home/"$username"/iw4x_files.zip -d /home/"$username"/servers/"$svalias"/MW2/

echo "### Generating server.cfg ###"
cat > /home/"$username"/servers/"$svalias"/MW2/iw4x/server.cfg <<EOF
////////////////////////////////////////////////////////////
///            IW4x Server Configuration file            ///
////////////////////////////////////////////////////////////

// Configure your host
set sv_hostname "$svhostname"
set sv_securityLevel 23 // required security level to join the server
EOF

echo "### Generating Startscript ###"
cat > /home/"$username"/"$svalias".sh <<EOF
#!/bin/bash
wine /home/$username/servers/$svalias/MW2/iw4x.exe -dedicated -stdout +set net_port $port +exec server.cfg +set playlistFilename "playlists_default.info" +playlist 0
EOF

echo "### Making startscript executable ###"
chmod +x /home/"$username"/"$svalias".sh

echo "### Fixing ownership of serverfiles ###"
chown -R "$username":users /home/"$username"

echo "### Do you wish to remove the downloaded zip-files? ###"
read -p "### Yes or No [Yy/Nn] ###" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "### Deleting downloaded zip-files ###"
    rm /home/"$username"/MW2.zip
    rm /home/"$username"/iw4x_files.zip
    rm /home/"$username"/iw4x_dlc.zip
fi

echo "### Before anything else run  ###"
echo "###     script /dev/null      ###"
echo "### Start server in a screen with command ### "
echo "###     screen -RD $svalias   ###"
echo "### Then in the screen run ./$svalias ###"

cd /home/"$username"/
su "$username"