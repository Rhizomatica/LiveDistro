#!/bin/sh
#################################################################
#   Script escrito por Javier De La Cruz para la configuración de la distro de Rhizomatica
#   Con apoyo de Javier Obregon
#   Configuraciones:
#   + Basicas del Sitio
#   + Kannel
#   + PostgreSQL
#   + Freeswitch
#   Licencia: GPL o superior
##################################################################

##############################
## Declaracion de variables ##
##############################

DT="/opt/asisbsc"
SEMAFORO=".insta.sem"
mi_ip=$(ip addr| grep 'eth0' | tail -n1 | awk '{print $2}'| cut -f1 -d"/")
audio_file="/usr/share/freeswitch/sounds/en/us/callie/001_bienvenidos.gsm"
titulo=" Asistente de Configuración Rhizomatica "
DISBASE=$(lsb_release -d | awk '{print $2}')
BD="rhizomatica"
location_file="/var/rhizomatica/db/migration/011_location.sql"
UBD=$(cat /etc/passwd | grep -i 1000 | awk -F":" '{print $1}')
PUBD="prueba"
export PGPASSWORD="$password_usuario_sistema"

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

instalar_rccn(){
	if [ $DISBASE = "Debian" ]
	then
		(systemctl stop freeswitch;\
		systemctl stop lcr;\
		systemctl stop osmocom-nitb;\
		systemctl disable freeswitch;\
		systemctl disable lcr;\
		systemctl disable osmocom-nitb) | zenity --progress --title="$titulo" --text="Desactivando Servicios" --pulsate --auto-close
		(systemctl restart postgresql) | zenity --progress title="$titulo" --text="Reiniciando PostgreSQL" --pulsate --auto-close
	else
		(service freeswitch stop;\
		service lcr stop;\
		service osmocom-nitb stop;\
		update-rc.d -f freeswitch disable;\
		update-rc.d -f lcr disable;\
		update-rc.d -f osmocom-nitb disable) | zenity --progress --title="$titulo" --text="Desactivando Servicios" --pulsate --auto-close
		(service postgresql restart) | zenity --progress title="$titulo" --text="Reiniciando PostgreSQL" --pulsate --auto-close
	fi
	
	(python /var/rhizomatica/rccn/install.py) | zenity --progress title="$titulo" --text="Configurando software RCCN" --pulsate --auto-close
	#(su - postgres -c "psql -d rhizomatica -f $location_file ") | zenity --progress --title="$titulo" --text="Creando columna locations" --pulsate --auto-close
	(su - postgres -c "psql -c \"ALTER DATABASE $BD OWNER to $usuario_sistema; \" ") | zenity --progress --title="$titulo" --text="Asignando Base de datos $BD al usuario $usuario_sistema" --pulsate --auto-close
	(sv restart rapi) | zenity --progress --title="$titulo" --text="Reiniciando RAPI" --pulsate --auto-close

	if [ $DISBASE = "Debian" ]
	then
		(systemctl restart apache2) | zenity --progress --title="$titulo" --text="Reiniciando el servicio de  Apache" --pulsate --auto-close
	else
		(service apache2 restart) | zenity --progress --title="$titulo" --text="Reiniciando el servicio de  Apache" --pulsate --auto-close
	fi
	
	(sv restart osmo-nitb)| zenity --progress --title="$titulo" --text="Reiniciando Osmo-nitb" --pulsate --auto-close
	
	(ln -s /etc/sv/rapi /etc/service/; sv start rapi)| zenity --progress --title="$titulo" --text="Iniciando RAPI" --pulsate --auto-close
	
	if [ $DISBASE = "Debian" ]
	then
		(systemctl restart kannel) | zenity --progress --title="$titulo" --text="Reiniciando Kannel" --pulsate --auto-close
	else
		(service kannel restart) | zenity --progress --title="$titulo" --text="Reiniciando Kannel" --pulsate --auto-close
	fi
	(sv restart freeswitch) | zenity --progress --title="$titulo" --text="Reiniciando Freeswitch" --pulsate --auto-close

	touch $DT/$SEMAFORO
	zenity --info --title="$titulo" --text="Instalación Exitosa"
	exit 0
}


NICBTS(){

	cp /etc/network/interfaces /etc/network/interfaces-bak-rhizo
	cat << EOF > /etc/network/interfaces
# Loopback interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
allow-hotplug eth0

# The secondary network interface
auto eth1
iface eth1 inet static
        address 172.16.0.1
        netmask 255.255.255.0
        network 172.16.0.0
allow-hotplug eth1

## PC-Admin interface
auto eth3
iface eth3 inet static
	address 192.168.150.1
	netmask 255.255.255.0
	network 192.168.150.0
allow-hotplug eth3
EOF

    if [ $DISBASE = "Debian" ] ;then
		(systemctl restart networking ; sleep 5)  | zenity --progress --title="$titulo" --text="Configurando NIC para la BTS" --pulsate --auto-close
    else
		(service networking restart ; sleep 5)  | zenity --progress --title="$titulo" --text="Configurando NIC para la BTS" --pulsate --auto-close
	fi
}

editar(){
	### config_values.py
	(sed -i 's/DebianBSC/'$n_sitio'/' $conf_values;\
	sed -i 's/DebianGSM/'$n_gsm'/' $conf_values;\
	sed -i 's/99999/'$c_p'/' $conf_values;\
	sed  -i 's/pbxcode = "1"/pbxcode = "'$c_pbx'"/' $conf_values;\
	sed -i 's/192.168.0.49/'$ip'/' $conf_values;\
	sed -i 's/ 40 / '$cuo_rec' /' $conf_values)\
	| zenity --progress --title="$titulo" --text="Aplicando cambios en archivo config_values.py" --pulsate --auto-close

	### osmo-nitb.cfg
	(sed -i 's/DebianGSM/'$n_gsm'/' $conf_osmo;\
	sed -i 's/DebianGSM/'$n_gsm'/' $conf_osmo;\
	sed -i 's/network country code 334/network country code '$mcc'/' $conf_osmo;\
	sed -i 's/mobile network code 7/mobile network code '$mnc'/' $conf_osmo;\
	sed -i 's/arfcn 246/arfcn '$arfcnA'/' $conf_osmo;\
	sed -i 's/arfcn 249/arfcn '$arfcnB'/' $conf_osmo)\
	| zenity --progress --title="$titulo" --text="Aplicando cambios en archivo osmo-nitb.cfg" --pulsate --auto-close

	### freeswitch
	(sed -i  's/192.168.0.49/'$ip'/' $conf_freeswitch_vars) | zenity --progress --title="$titulo" --text="Aplicando cambios Freeswitch vars.xml" --pulsate --auto-close

	sed -i 's/DB_USER = "rhizomatica"/DB_USER = "'$usuario_sistema'"/' $conf_rai
	sed -i 's/DB_PASSWORD = "TestTest"/DB_PASSWORD = "'$password_usuario_sistema'"/' $conf_rai

	## config_values.py
	sed -i "s/pgsql_user = 'rhizomatica'/pgsql_user = '"$usuario_sistema"'/" $conf_values
	sed -i "s/pgsql_pwd = 'prueba'/pgsql_pwd = '"$password_usuario_sistema"'/" $conf_values

	## freeswitch
	sed -i "s/<%= pgsql_host %>/localhost/" $conf_freeswitch_cdr
	sed -i "s/<%= pgsql_db %>/$BD/" $conf_freeswitch_cdr
	sed -i "s/<%= pgsql_user %>/$usuario_sistema/" $conf_freeswitch_cdr
	sed -i "s/<%= pgsql_pwd %>/$password_usuario_sistema/" $conf_freeswitch_cdr
	(sleep 2) | zenity --progress --title="$titulo"  --text="Aplicando cambios Freeswitch CDR" --pulsate --auto-close

	(sed -i  "s/username = rhizomatica/username = $usuario_sistema/g" $ka;\
	sed -i  "s/password = password/password = $password_usuario_sistema/g" $ka;\
	sed -i  "s/kannel_username = 'rhizomatica'/kannel_username = '$usuario_sistema'/g" $conf_values;\
	sed -i  "s/kannel_password = 'password'/kannel_password = '$password_usuario_sistema'/g " $conf_values)\
	| zenity --progress --title="$titulo" --text="Aplicando cambios Kannel" --pulsate --auto-close

	(sed -i  "s/rai_admin_user = 'rhizomatica'/rai_admin_user = '"$usuario_sistema"'/" $conf_values;\
	sed -i  "s/rai_admin_pwd = 'prueba'/rai_admin_pwd = '"$password_usuario_sistema"'/" $conf_values)\
	| zenity --progress --title="$titulo" --text="Aplicando cambios RAI" --pulsate --auto-close

	####/etc/freeswitch/sip_profiles/external/provider.xml
	(sed -i '/name/ s/provider/'$provoip_name'/' $conf_freeswitch_prov;\
	sed -i '/username/ s/0000000001/'$usernamevoip'/'  $conf_freeswitch_prov;\
	sed -i '/from-user/ s/0000000001/'$fromuservoip'/' $conf_freeswitch_prov;\
	sed -i '/password/ s/123456/'$passwordvoip'/' $conf_freeswitch_prov;\
	sed -i '/proxy/ s/169.132.196.33/'$proxyvoip'/' $conf_freeswitch_prov)\
	| zenity --progress --title="$titulo" --text="Aplicando cambios Freeswitch provider.xml" --pulsate --auto-close

	####/var/rhizomatica/rccn/config_values.py
	(sed -i '/voip_provider_name/ s/'\"provider\"'/'\"$provoip_name\"'/' $conf_values;\
	sed -i '/voip_username/ s/0000000001/'$usernamevoip'/' $conf_values;\
	sed -i '/voip_fromuser/ s/0000000001/'$fromuservoip'/' $conf_values;\
	sed -i '/voip_password/ s/123456/'$passwordvoip'/' $conf_values;\
	sed -i '/voip_proxy/ s/169.132.196.33/'$proxyvoip'/' $conf_values;\
	sed -i '/voip_did/ s/12132614308/'$didvoip'/' $conf_values;\
	sed -i '/voip_cli/ s/12132614308/'$clivoip'/' $conf_values)\
	| zenity --progress --title="$titulo" --text="Aplicando cambios RCCN config_values.py" --pulsate --auto-close
}

crear_db_pg(){
	(su - postgres -c "createuser -s -e -E -d $usuario_sistema ")\
	| zenity --progress --title="$titulo" --text="Creando usuario $psql_usuario" --pulsate --auto-close
	(su - postgres -c "createdb -O $usuario_sistema $BD ")\
	| zenity --progress --title="$titulo" --text="Creando Base de Datos" --pulsate --auto-close
	(su - postgres -c "psql -c \"ALTER DATABASE $BD OWNER to $usuario_sistema; \" ")\
	| zenity --progress --title="$titulo" --text="Asignando Base de datos $BD al usuario $usuario_sistema" --pulsate --auto-close
	(su - postgres -c "psql  -c \"alter user $usuario_sistema with password '$password_usuario_sistema'; \" ")\
	| zenity --progress --title="$titulo" --text="Asignando Contraseña" --pulsate --auto-close

	if [ $DISBASE = "Debian" ]
	then
		(systemctl restart postgresql) | zenity --progress --title="$titulo" --text="Reiniciando postgresql" --pulsate --auto-close
	else
		(service postgresql restart) | zenity --progress --title="$titulo" --text="Reiniciando postgresql" --pulsate --auto-close
	fi
}

validacion(){
	if [ -z $n_sitio ]
	then
		zenity --info --title "$titulo" --text="Favor de ingresar el  nombre del Sitio"
		return 1
	elif [ -z $n_gsm ]
	then
		zenity --info --title "$titulo" --text="Favor de Ingresar el nombre del Sitio GSM"
		return 1
	elif [ -z $c_p ]
	then
		zenity --info --title "$titulo" --text="Codigo Postal necesario para generar el prefijo del Sitio"
		return 1
	elif [ -z $c_pbx ]
	then
		zenity --info --title "$titulo" --text="Por defecto 1"
		return 1
	elif [ -z $ip ]
	then
		zenity --info --title "$titulo" --text="Ingresa la IP (eth0) de tu Equipo"
		return 1
	elif [ -z $arfcnA ]
	then
		zenity --info --title "$titulo" --text "Ingresa un ARFCN A dentro del rango otorgado en tu licencia"
		return 1
	elif [ -z $arfcnB ]
	then
		zenity --info --title "$titulo" --text "Ingresa un ARFCN B dentro del rango otorgado en tu licencia"
		return 1
	elif [ -z $mcc ]
	then
		zenity --info --title "$titulo" --text "Ingresa el Codigo de Celular de tu Pais MCC(Mobile Country Code)"
		return 1
	elif [ -z $mnc ]
	then
		zenity --info --title "$titulo" --text "Ingresa el Codigo de tu Red Celular MNC(Mobile Network Code)"
		return 1
	elif [ -z $cuo_rec ]
	then
		zenity --info --title "$titulo" --text "Por Favor ingresa la cuota de recuperación al mes por usuario"
		return 1
	elif [ -z $usuario_sistema  ]
	then
		zenity --info --title="$titulo" --text="Ingresa un nombre de usuario"
		return 1
	elif [ -z $password_usuario_sistema ]
	then
		zenity --info --title="$titulo" --text="Ingresa una contraseña"
		return 1
	elif [ -z $provoip_name ]
	then
		zenity --info --title "$titulo " --text="Favor de ingresar el Nombre del proveedor VoIP"
		return 1
	elif [ -z $usernamevoip ]
	then
		zenity --info --title "$titulo " --text="Favor de Ingresar el Usuario de la cuenta VoIP"
		return 1
	elif [ -z $fromuservoip ]
	then
		zenity --info --title "$titulo " --text="Favor de Ingresar el FromUser de la cuenta VoIP"
		return 1
	elif [ -z $passwordvoip ]
	then
		zenity --info --title "$titulo " --text="Favor de Ingresar la contraseña de la cuenta VoIP"
		return 1
	elif [ -z $proxyvoip ]
	then
		zenity --info --title "$titulo " --text="Ingresa la IP del servidor proxy VoIP"
		return 1
	elif [ -z $didvoip ]
	then
		zenity --info --title "$titulo" --text "Ingresa el DID otorgado a su cuenta VoIP"
		return 1
	elif [ -z $clivoip ]
	then
		zenity --info --title "$titulo" --text "Ingresa el Cliente otorgado a su cuenta VoIP"
		return 1
	else
		editar
		crear_db_pg
		return 0
	fi
}


formulario(){
	local MENU=0
	## Bucle menú principal
	while [ $MENU -eq 0 ] ; do
		var_for=$(zenity --height=480 --width=600 --forms --title="$titulo" --text=" Configuración General " --separator="," \
		--add-entry="Nombre del Sitio:" \
		--add-entry="Nombre de Red GSM:" \
		--add-entry="Codigo Postal:" \
		--add-entry="Codigo PBX:" \
		--add-entry="IP eth0:" \
		--add-entry="ARFCN A:" \
		--add-entry="ARFCN B:" \
		--add-entry="MCC:" \
		--add-entry="MNC:" \
		--add-entry="Cuota de Recuperación:" \
		--add-entry="Usuario:" \
		--add-entry="Contraseña:" \
		--add-entry="Nombre Proveedor VoIP:" \
		--add-entry="Usuario VoIP:" \
		--add-entry="Fromuser VoIP:" \
		--add-entry="Contraseña VoIP:"\
		--add-entry="Proxy VoIP:"\
		--add-entry="DID VoIP:" \
		--add-entry="Cliente VoIP:")
		if [ $? -eq 0 ] ; then
			## Datos Sitio
			n_sitio=$(echo ${var_for} | awk -F "," '{print $1}')
			n_gsm=$(echo ${var_for} | awk -F "," '{print $2}')
			c_p=$(echo ${var_for} | awk -F "," '{print $3}')
			c_pbx=$(echo ${var_for} | awk -F "," '{print $4}')
			ip=$(echo ${var_for} | awk -F "," '{print $5}')
			arfcnA=$(echo ${var_for} | awk -F "," '{print $6}')
			arfcnB=$(echo ${var_for} | awk -F "," '{print $7}')
			mcc=$(echo ${var_for} |awk -F "," '{print $8}')
			mnc=$(echo ${var_for} | awk -F "," '{print $9}')
			cuo_rec=$(echo ${var_for} | awk -F "," '{print $10}')
			## Usuario Contraseña
			usuario_sistema=$(echo ${var_for} | awk -F "," '{print $12}')
			password_usuario_sistema=$(echo ${var_for} | awk -F "," '{print $13}')
			##VoIP
			provoip_name=$(echo ${var_for} | awk -F "," '{print $14}')
			usernamevoip=$(echo ${var_for} | awk -F "," '{print $15}')
			fromuservoip=$(echo ${var_for} | awk -F "," '{print $16}')
			passwordvoip=$(echo ${var_for} | awk -F "," '{print $17}')
			proxyvoip=$(echo ${var_for} | awk -F "," '{print $18}')
			didvoip=$(echo ${var_for} | awk -F "," '{print $19}')
			clivoip=$(echo ${var_for} | awk -F "," '{print $20}')
			## Validación de datos ingresados
			validacion
			if [ $? -eq 0 ] ; then
				MENU=1
				return 0
			fi
		else
			MENU=1
			return 1
		fi
	done
}


if [ ! -f $DT/$SEMAFORO ] ; then
	formulario
	if [ $? -eq 0 ] ; then
		NICBTS
		instalar_rccn
	else
		return 1
	fi
else
	zenity --error --title="$titulo" --text="El asistente solo puede ejecutarse una vez.\n Mas información comuniquese con la Administración.\n Gracias."
fi
