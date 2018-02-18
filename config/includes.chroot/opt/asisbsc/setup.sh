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

DT="/opt/asisbsc"
clear

if [ $(id -u) -eq 0 ]
then
	MENU=0
	## Bucle menú principal
	while [ $MENU -eq 0 ]
	do
		OPC=$(zenity --height=250 --width=350 --list --radiolist \
		--title=" Asistente de Configuración BSC Rhizomatica " \
		--text " Menú Principal Asistente \n " \
		--column "Seleccionar" --column "Acción" TRUE "Utilidades" FALSE "Instalar")
		if [ $? -ne 0 ]
		then
			MENU=1
		else
			if [ $OPC = "Utilidades" ]
			then
				. $DT/utiles.sh
			elif [ $OPC = "Instalar" ]
			then
				. $DT/instalar.sh
			else
				MENU=1
			fi
		fi
	done
else
	zenity --error --text="Debes de ser root para ejecutar el asistente"
fi
exit 0
