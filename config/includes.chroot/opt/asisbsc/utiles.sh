#!/bin/sh
#################################################################
#   Script escrito por Javier De La Cruz para la configuración de la distro  de Rhizomatica
#
#   Configuraciones:
#   + Basicas del Sitio
#   + Kannel
#   + PostgreSQL
#   + Freeswitch
#   Licencia: GPL o superior
###################################################################
clear
MENU=0

##############################
## Declaracion de variables ##
##############################

mi_ip=$(ip addr| grep 'eth0' | tail -n1 | awk '{print $2}'| cut -f1 -d"/")
audio_file="/usr/share/freeswitch/sounds/en/us/callie/001_bienvenidos.gsm"
titulo=" Asistente de Configuración Rhizomatica "
DISBASE=$(lsb_release -d | awk '{print $2}')
BD="rhizomatica"
user_pg=$(grep "pgsql_user" /var/rhizomatica/rccn/config_values.py | awk -F "'" '{print $2}')
location_file="/var/rhizomatica/db/migration/011_location.sql"
UBD=$(cat /etc/passwd | grep -i 1000 | awk -F":" '{print $1}')
PUBD="prueba"
export PGPASSWORD="$psql_pass"

dir_audio="/usr/share/freeswitch/sounds/en/us/callie/"
dir_rai="/var/rhizomatica/rai/include/"
dir_config_values="/var/rhizomatica/rccn/"
dir_freeswitch="/etc/freeswitch/autoload_configs/"
dir_kannel="/etc/kannel/"
dir_config_values="/var/rhizomatica/rccn/"
dir_osmo="/etc/osmocom/"

conf_freeswitch_vars="/etc/freeswitch/vars.xml"
conf_freeswitch_prov="/etc/freeswitch/sip_profiles/external/provider.xml"
conf_freeswitch_cdr="/etc/freeswitch/autoload_configs/cdr_pg_csv.conf.xml"

conf_values="/var/rhizomatica/rccn/config_values.py"

conf_kannel="/etc/kannel/kannel.conf"
conf_psql="/var/rhizomatica/rai/include/database.php"
conf_rai="/var/rhizomatica/rai/include/database.php"
conf_osmo="/etc/osmocom/osmo-nitb.cfg"

ka="/etc/kannel/kannel.conf"

###############################
## Fin Declaración variables ##
###############################

##############################################################
################## Declaración de Funciones ##################
##############################################################

### Inicio control archivo de audio ###
ctrl_audio(){
	AUDIOGSM=$(file $selec_audio | awk -F":" '{print $2}' | tr -d ' ')
	if [ $AUDIOGSM = "data" ]
	then
		OK=0
	else
		OK=1
	fi
}

audio(){
	selec_audio=$(zenity --file-selection --title="Selecciona el Audio(.gsm) de Bienvenida:  ")
	case $? in
		0)
			ctrl_audio $selec_audio
			if [ $OK -eq 0 ]
			then
				(cp $selec_audio $dir_audio"001_bienvenidos.gsm") | zenity --progress --title="$titulo" --text="Cargando audio al directorio $dir_audio" --percentage=10
			else
				zenity --error --title="$titulo" --text="El archivo seleccionado no es del tipo requerido. (Audio gsm)"
			fi
			;;
		1)
			zenity --info --title="$titulo" --text="No se seleccionó ningún archivo"
			;;
	       -1)
			zenity --info --title="$titulo" --text="Ha ocurrido un error inesperado"
	esac
}

### Fin control archivo de audio ###

### Inicio función Respaldar ###
respaldar(){
if [ ! -f $conf_freeswitch_vars".bk" ]
then
	(cp $conf_freeswitch_vars $conf_freeswitch_vars".bk" ; sleep 0.5 ; cp $conf_freeswitch_prov $conf_freeswitch_prov".bk" ; cp $conf_freeswitch_cdr $conf_freeswitch_cdr".bk" ; sleep 0.5 ; cp $conf_values $conf_values".bk" ; cp $conf_kannel $conf_kannel".bk" ; sleep 0.5 ; cp $conf_psql $conf_psql".bk" ; sleep 0.5 ; cp $conf_osmo $conf_osmo".bk" ; cp $audio_file $audio_file".bk") | zenity --progress --title="$titulo" --text="Haciendo respaldo de configuraciones" --pulsate --auto-close
	if [ $? -eq 0 ]
	then
		zenity --info --title="$titulo" --text="Respaldo Exitoso"
		return 0
	else
		zenity --error --title="$titulo" --text="Respaldo Fallido"
		return 1
	fi
else
	zenity --error --title="$titulo" --text="Ya se hizo un respaldo antes."
	return 0
fi
}

### Fin función Respaldar ###

### Inicio función Restaurar ###
restaurar(){
if [ -f $conf_freeswitch_vars".bk" ]
then
	(mv $conf_freeswitch_vars".bk" $conf_freeswitch_vars ; sleep 0.5 ; mv $conf_freeswitch_prov".bk" $conf_freeswitch_prov ; mv $conf_freeswitch_cdr".bk" $conf_freeswitch_cdr ; sleep 0.5 ; mv $conf_values".bk" $conf_values ; mv $conf_kannel".bk" $conf_kannel ; sleep 0.5 ; mv $conf_psql".bk" $conf_psql ; mv $conf_osmo".bk" $conf_osmo ; mv $audio_file".bk" $audio_file) | zenity --progress --title="$titulo" --text="Restaurando configuraciones" --pulsate --auto-close
	if [ $? -eq 0 ]
	then
		zenity --info --title="$titulo" --text="Restauración Exitosa"
		return 0
	else
		zenity --error --title="$titulo" --text="Restauración Fallida"
		return 1
	fi
else
	zenity --error --title="$titulo" --text="No hay respaldo que restaurar"
	return 0
fi
}

### Fin función Restaurar ###

## Bucle menú principal
while [ $MENU -eq 0 ]
do
	OPC=$(zenity --height=250 --width=450 --list --radiolist --title="$titulo" --text " Menú Utilidades \n " \
	--column "Seleccionar" --column "Acción" TRUE "Audio" FALSE "Respaldar" FALSE "Restaurar" )
	if [ $? != 0 ]
	then
		MENU=1
	else
		if [ $OPC = "Audio" ]
		then
			audio
		elif [ $OPC = "Respaldar" ]
		then
			respaldar
		elif [ $OPC = "Restaurar" ]
		then
			restaurar
		fi
	fi
done
. $DT/setup.sh