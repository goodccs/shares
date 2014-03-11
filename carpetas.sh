#!/bin/bash

####################################################################################################################
# version 0.2
#	- verificar con smbclient que el usuario y clave son correctos antes de agregar carpetas y modificar el fstab
#                                                               						   
# version 0.1													   
#	- verifica que el paquete aptitude este instalado en el sistema de lo contrario aborta                     
#	- verifica que el paquete smbfs este instalado en el sistema de lo contrario pregunta para su instalacion  
#	- pide los valores de usuario, clave de acceso a la carpeta requerida					   
#	- pide el numero de carpetas, valida que no exista para crear los directorios donde montara las carpetas   
#	- agrega las lienas necesarias en el fstab 								   
#	- verifica el el script sea ejecutado por root								   
#                                                               						   
####################################################################################################################

## COLORES ##
black='\033[30'
red='\033[31'
green='\033[32'
yellow='\033[33'
blue='\033[34m'
magenta='\033[35'
cyan='\033[36m'
white='\033[37'

alias Reset="tput sgr0"

## CONSTANTES ##
servidor="192.168.5.5"
VERSION="0.1"
SCRIPT=" Instalación de Carpeta Compartida en Canaima $VERSION by JCP "
aptitude="/usr/bin/aptitude"

## FUNCIONES ##

# Color-echo.
cecho ()		# Argument $1 = message
                        # Argument $2 = color
{
local default_msg="No hay mensaje.."
message=${1:-$default_msg}   # Defaults to default message.
color=${2:-$black}           # Defaults to black, if not specified.
  echo "$color"
  echo "$message"
  Reset                      # Reset to normal.
  return
}  

version () {
echo $cyan "╔═══════════════════════════════════════════════════════════╗" 
echo $cyan "║ ${SCRIPT} ║" 
echo $cyan "╚═══════════════════════════════════════════════════════════╝" 
}

#verificar paquete instalado
existe_comando () {
if type "$1" > /dev/null; then
	cecho "El Programa ${1} esta Instalado." $blue
else
	cecho "El Programa ${1} es Requerido Saliendo..."; exit 1; $red
fi
}

#verificar directorio de carpeta
existe_carpeta () {
if [ ! -d "$1" ]; then
  # no existe se crea
  mkdir -p "/home/${2}/${1}"
  cecho "Se creo la carpeta /home/${2}/${1}" $blue	
fi
}

#ESPERA A QUE SE PULSE UNA TECLA
pulsar_una_tecla ()
{
echo
read TECLA
echo
if [ "$1" = cecho "Pulsa una tecla para salir..." $red ]
then
	exit 1
fi
}

#comprobar root
comprobar_root ()
{
ROOT=`whoami`
if [ "$ROOT" != "root" ]
then
	echo "                                            "
	cecho "ERROR: Necesitas permisos de root para poder" $red
	cecho "       ejecutar este script                 " $red         
	echo "                                            " 
	pulsar_una_tecla cecho "Pulsa una tecla para salir..." $red
fi
}

## PROGRAMA PRINCIPAL ##
comprobar_root
version

if existe_comando aptitude; then

	if ! dpkg --get-selections smbfs | grep install; then

	while true; do
    		read -p "El Paquete smbfs No Esta Instalado. Quieres Instalarlo? (s/n)?" sn
    		case $sn in
        		[Ss]* ) aptitude install -y smbfs; break;;
        		[Nn]* ) exit;;
        		* ) cecho "Por favor indique si o no." $red;;
    		esac
	done

	fi

fi

#indicar valores para generar linea en fstab
echo -n "Indique el usuario con permisos en la carpeta:"
read usuario
echo -n "Indique la clave de red:"
read clave
echo -n "Indique SOLO el numero de carpetas a crear:"
read num
#validar usuario y clave con el recuerso compartido
OUTPUT=$(smbclient -U=${usuario}%${clave} //{servidor}/{carpeta})

for reqsubstr in 'NT_STATUS_LOGON_FAILURE';do
if [ -z "${OUTPUT##*$reqsubstr*}" ];
	then		
       cecho "Error: $OUTPUT" $red
       cecho "El usuario: ${usuario} o la CLAVE ingresda no son correctas." $red && exit 1
	fi
done

#validar que solo sea numero
if [ ! -z "${num##*[!0-9]*}" ] ;then  
x=1
	while [ $x -le $num ]
	do
		echo -n "Indique el nombre de la carpeta compartida en Terepaima:"
		read carpeta
		existe_carpeta $carpeta $usuario
		line="//${servidor}/${carpeta} /home/${usuario}/${carpeta} smbfs username=${usuario},password=${clave},workgroup=corpivensa.gob.ve,rw 0 0"
		cecho "se agrego ${line} a fstab" $green	
		echo $line >> /etc/fstab
    	   x=$(( $x + 1 ))
	done
else
	cecho "${num} no es un numero" $red && exit 1
fi

mount -a
cecho "Carpetas Cargadas en el Sistema" $blue

cecho "Salduos ^.^'"

exit 0
