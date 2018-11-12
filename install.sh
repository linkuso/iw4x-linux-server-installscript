#!/bin/bash
# init

echo "Install IW4x debian linux" 

dpkg --add-architecture i386
apt-get update && apt-get upgrade -y
apt-get install wine wine32 unzip git screen -y

echo "### Specify username to install under - can be a new or existing user - DO NOT use root ###"
read username
echo "### Specify password if new user ###"
read password
echo "### Specify server hostname (Visable in the serverbrowser) ###"
read svhostname
#echo "### Specify server ip ###"
#read ip
echo "### Specify server port default is 28960 ###"
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

echo "### Adding urls to download_list.txt ###"
cat > /home/"$username"/download_list.txt <<EOF
http://downloads.warzone.gg/IW4M/MW2.zip
http://downloads.warzone.gg/IW4M/iw4x_files.zip
http://downloads.warzone.gg/IW4M/iw4x_dlc.zip
EOF


echo "### Downloading MW2 ###"
wget -P /home/"$username"/servers/"$svalias" -i /home/"$username"/download_list.txt

echo "### Extracting MW2 ###"
unzip /home/"$username"/servers/"$svalias"/MW2.zip
unzip -o /home/"$username"/servers/"$svalias"/iw4x_dlc.zip -d /home/"$username"/servers/"$svalias"/MW2/
unzip -o /home/"$username"/servers/"$svalias"/iw4x_files.zip -d /home/"$username"/servers/"$svalias"/MW2/

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
wine /home/"$username"/servers/"$svalias"/MW2/iw4x.exe -dedicated -stdout +set net_port "$port" +exec server.cfg +set playlistFilename "playlists_default.info" +playlist 0
EOF

echo "### Fixing ownership of serverfiles ###"
chown -R "$username":users /home/"$username"

echo "### Deleting downloaded zip-files to save HDD-space ###"
rm /home/"$username"/servers/"$svalias"/*.zip


cd /home/"$username"/
su "$username"

###END