#!/bin/bash
clean
ARCHLOG="bind_check.log monitor_amp.log monitor_rapi.log"
DIRLOG="osmocom freeswitch kiwi lcr osmo-nitb rapi smpp"
USUNUEV=$(cat /etc/passwd | grep -i 1000 | awk -F":" '{print $1}')
IDI=$(echo $LANG | cut -d . -f1)
DISBASE=$(lsb_release -d | awk '{print $2}')

clear

# -> Activa inicio gráfico sin contraseña una vez instalado ...
#sed -i 's/autologin-user=rhizomatica/'autologin-user="$USUNUEV"'/' /etc/lightdm/lightdm.conf
#sed -i 's/default_user=rhizomatica/'default_user="$USUNUEV"'/' /etc/slim.conf
sed -i 's/#autologin-user=/'autologin-user="$USUNUEV"'/' /etc/lightdm/lightdm.conf

# Configura directorio .config/ del nuevo usuario
sed -i 's/rhizomatica/'"$USUNUEV"'/' /home/$USUNUEV/.config/gtk-3.0/bookmarks

# -> Modificar datos para QupZilla ...
sed -i 's/rhizomatica/'"$USUNUEV"'/' /home/$USUNUEV/.config/qupzilla/profiles/default/settings.ini

# -> Quitando contrib y non-free de /usr/share/doc/apt/examples/sources.list
if [ -f /usr/share/doc/apt/examples/sources.list ]
then
	sed -i 's/contrib//' /usr/share/doc/apt/examples/sources.list
	sed -i 's/non-free//' /usr/share/doc/apt/examples/sources.list
fi

## Configurar crontab
mv /var/spool/cron/crontabs/rhizomatica /var/spool/cron/crontabs/$USUNUEV
chown $USUNUEV.crontab /var/spool/cron/crontabs/$USUNUEV
chmod 600 /var/spool/cron/crontabs/$USUNUEV

echo "## Configuración sudo..."
sed -i 's/RHIZO=rhizomatica/'RHIZO="$USUNUEV"'/' /etc/sudoers
chown root.root /etc/sudoers
chmod 440 /etc/sudoers
echo

echo " ## Modificando /etc/init.d/freeswitch"
sed -i 's/\"-u freeswitch -g freeswitch -nc\"/'\"-nc\"'/' /etc/init.d/freeswitch
echo

echo " ## Permisos en /etc/rc.local"
chmod 755 /etc/rc.local
echo

echo "## Configurar archivos /usr/lib/freeswitch/mod/mod_*.so..." 
chown root.root /usr/lib/freeswitch/mod/mod_*.so
chmod 444 /usr/lib/freeswitch/mod/mod_*.so
echo

echo "## Configurar directorio /etc/freeswitch..." 
chown root.root /etc/freeswitch/ -R
chown freeswitch.freeswitch /var/run/freeswitch/ -R
echo

echo "## Propiedad del los archivos de sonido de freeswitch..." 
chown freeswitch.freeswitch -R /usr/share/freeswitch/sounds/en/*
echo

echo "## Configurar directorio /etc/sv..." 
chown root.root /etc/sv/ -R
echo

echo " ## Enlaces simbolicos para sv..."
ln -s /etc/sv/freeswitch /etc/service/
ln -s /etc/sv/lcr /etc/service/
ln -s /etc/sv/osmo-nitb /etc/service/
ln -s /etc/sv/rapi /etc/service/
echo

echo "## Configurando cron..." 
chown root.root /etc/cron.d/rhizomatica
chmod 644 /etc/cron.d/rhizomatica
echo

echo "## Configurando /etc/default..." 
chown root.root /etc/default/lcr
chmod 644 /etc/default/lcr
echo

echo "## Configurar rccn..."
chown root.staff /var/rhizomatica -R
chmod 775 /var/rhizomatica/ -R
echo

echo "## Creando Enlaces Simbólicos en /var/www/html/..."
ln -s /var/rhizomatica/rai /var/www/html/rai
ln -s /var/rhizomatica/rrd/graphs /var/www/html/rai/graphs
echo

echo "## Agregando repo de NodeJS y llave..."
echo "deb https://deb.nodesource.com/node_0.10 jessie main" > /etc/apt/sources.list.d/nodesource.list
apt-key add /opt/nodesource.gpg.key
echo

echo "## Agregando llave del repo de Freeswitch..."
apt-key add /opt/freeswitch_archive_g0.pub 
echo

echo "## Configurando permisos y propiedad de archivos para gestiónde log's..."
for ARCHIVOS in $ARCHLOG
do
	if [ -f /var/log/$ARCHIVOS ];
	then
		echo "	-> Modificando /var/log/"$ARCHIVOS
	else
		echo "	-> Creando archivo /var/log/"$ARCHIVOS
		touch /var/log/$ARCHIVOS
	fi
	chown 1000.1000 /var/log/$ARCHIVOS
done
for DIRECTORIOS in $DIRLOG
do
	if [ -d /var/log/$DIRECTORIOS ];
	then
		echo "	-> Modificando directorio /var/log/"$DIRECTORIOS
	else
		echo "	-> Creando directorio /var/log/"$DIRECTORIOS
		mkdir /var/log/$DIRECTORIOS
	fi
	chown root.1000 /var/log/$DIRECTORIOS -R
	chmod 775 /var/log/$DIRECTORIOS -R
done
echo

## Enlaces ESL.py y ESL.pyc...
ln -s /usr/lib/python2.7/dist-packages/ESL.py /usr/local/lib/python2.7/dist-packages/
ln -s /usr/lib/python2.7/dist-packages/ESL.pyc /usr/local/lib/python2.7/dist-packages/
echo

# -> Configurar locale para RAI post instalación...
sed -i 's/# es_ES ISO-8859-1/es_ES ISO-8859-1/' /etc/locale.gen 
sed -i 's/# es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen
locale-gen && update-locale

# -> Modificar /home/rhizomatica por /home/$USUNUEV para que funcionen los scripts de /var/rhizomatica/bin y /home/$USUNUEV/bin/ 
aDESTINO="/var/rhizomatica/bin/network_graph_rrd.sh /var/rhizomatica/bin/sms_cleanup.sh /home/$USUNUEV/bin/check_amp_status.sh /home/$USUNUEV/bin/check_dirty.sh /home/$USUNUEV/bin/get_position.sh /home/$USUNUEV/bin/log_broken_channels.sh /home/$USUNUEV/bin/monitor_amp.sh /home/$USUNUEV/bin/turn_on_amplifier.sh /home/$USUNUEV/bin/vars.sh /etc/cron.d/rhizomatica"

for ARCH0 in $aDESTINO
do
	sed -i "s/\/home\/rhizomatica/\/home\/$USUNUEV/g" $ARCH0
done

# -> Desactivando servicios en la versión instalada...
if [ $DISBASE = "Debian" ]
then
	systemctl disable freeswitch
	systemctl disable lcr
	systemctl disable osmocom-nitb
	systemctl disable slim
	FG="rhizobsc-grub-splash-deb.png"
else
	update-rc.d -f freeswitch disable
	update-rc.d -f lcr disable
	update-rc.d -f osmocom-nitb disable
	update-rc.d -f slim disable
	FG="rhizobsc-grub-splash-dev.png"
fi

# -> Borra archivo temporales ...
rm /home/$USUNUEV/.config/autostart/eter-idi.desktop
rm /opt/eter-idi.sh
rm /opt/*.key
rm /opt/*.pub

# -> Configuración de GRUB2 ..
update-alternatives --install /usr/share/images/desktop-base/desktop-grub.png desktop-grub /usr/share/backgrounds/rhizobsc/$FG 0
update-alternatives --set desktop-grub /usr/share/backgrounds/rhizobsc/$FG
sed -i 's/OS=GNU\/Linux/'OS=RhizoBSC'/' /etc/grub.d/10_linux
sed -i 's/GRUB_DISTRIBUTOR/'#GRUB_DISTRIBUTOR'/' /etc/default/grub
update-grub2

### Fin Script ###