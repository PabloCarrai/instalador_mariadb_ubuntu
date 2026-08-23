#!/bin/bash

#	Chequeo que tenga permisos de sudo
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse con privilegios sudo." 1>&2
   exit 1
else
   echo "1) Tienes permisos para continuar"
fi

# Cargar la información del sistema operativo
if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

#	La idea es que usemos ubuntu 2404
if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "24.04" ]; then
    echo "2) Estamos usando el SO que necesitamos."
else
    echo "Este script esta pensado para funcionar en Ubuntu 24.04. Tu versión es: ${PRETTY_NAME:-desconocida}"
    exit 1
fi


instalar_mariadb_desatendido() {
    echo "Iniciando instalación de MariaDB..."

    # 1. Instalar paquetes sin interacción
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y && sudo apt-get install -y mariadb-server

    # 2. Iniciar y habilitar servicio
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
}

asegurar_mariadb() {
    echo "Aplicando configuraciones de seguridad en MariaDB..."

    sudo mariadb -e "DELETE FROM mysql.user WHERE User='';"
    sudo mariadb -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    sudo mariadb -e "DROP DATABASE IF EXISTS test;"
    sudo mariadb -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    sudo mariadb -e "FLUSH PRIVILEGES;"

    echo "¡Configuración de seguridad completada!"
}

chequear_mariadb_instalado() {
    if dpkg-query -W -f='${Status}' mariadb-server 2>/dev/null | grep -q "ok installed"; then
        echo "MariaDB ya está instalado en el sistema."
        return 0 
    else
        echo "MariaDB no está instalado."
	echo "Arrancamos a instalarlo"
	instalar_mariadb_desatendido
	asegurar_mariadb	
    fi
}

#	Aca chequemos si esta instalado mariadb, sino lo instalamos
chequear_mariadb_instalado
