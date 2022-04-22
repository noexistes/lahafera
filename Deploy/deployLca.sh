#!/bin/bash
## Recordar subir lca, LCA tazgz y killtree.sh
## Variables
usuario=x002896

## Creacion Carpetas ##
mkdir -p /opt/genesys/instaladores/LCA 
mkdir -p /opt/genesys/LCA 
mkdir -p /var/log/genesys/LCA 

## TAR al archivo ##
chown $usuario. /opt/genesys/IP_LCA_8510037b1_ENU_linux.tar.gz
chmod 755 /opt/genesys/IP_LCA_8510037b1_ENU_linux.tar.gz
tar -zvxf /opt/genesys/IP_LCA_8510037b1_ENU_linux.tar.gz -C /opt/genesys/instaladores/LCA
mv /opt/genesys/IP_LCA_8510037b1_ENU_linux.tar.gz /opt/genesys/instaladores/IP_LCA_8510037b1_ENU_linux.tar.gz

## Permisos ##
chown $usuario. /var/log/genesys/ -R
chown $usuario. /opt/genesys/ -R
chmod 755 /var/log/genesys/LCA -R

## Silent Install de Genesys

echo '[ConfigServer]
Host=PLGIRAPP197
Port=2025
User=u594135
Password=123456

[IPCommon]
InstallPath=/opt/genesys/LCA/
DataModel=64

[LCA]
TuneStartupFiles=no
LCA_TLS_Mode=false
Silent_Installation_Without_ConfigServer=no
' >> genesys_silent.ini
mv /opt/genesys/genesys_silent.ini /opt/genesys/instaladores/LCA/ip/genesys_silent.ini
chmod 777 /opt/genesys/instaladores/LCA/ip/genesys_silent.ini
su - $usuario -s /bin/bash -c 'cd /opt/genesys/instaladores/LCA/ip; ./install.sh -s -fr /opt/genesys/instaladores/LCA/ip/genesys_silent.ini -fl /opt/genesys/instaladores/LCA/ip/genesys_install_result.log'


##Post Instalacion

echo [general] >> lca.cfg
echo wmiquery-timeout=-1 >> lca.cfg
echo  >> lca.cfg
echo [log] >> lca.cfg
echo enable-thread=false >> lca.cfg
echo verbose = all >> lca.cfg
echo all = /var/log/genesys/LCA/LCA-$HOSTNAME >> lca.cfg
echo keep-startup-file = true >> lca.cfg
echo expire = 5 >> lca.cfg
echo segment = 10000 >> lca.cfg

rm /opt/genesys/LCA/lca.cfg
mv /opt/genesys/lca.cfg /opt/genesys/LCA/lca.cfg
chown $usuario. /opt/genesys/LCA/lca.cfg
chmod 750 /opt/genesys/LCA/lca.cfg

## Generacion de servicio

mv killtree.sh /usr/local/bin
mv /opt/genesys/lca /etc/init.d/lca
sed "s/PLIVRUNIAPP013/$HOSTNAME/" /etc/init.d/lca >> /etc/init.d/lca2
sed "s/x002492/$usuario/" /etc/init.d/lca2 >> /etc/init.d/genesys-LCA_$HOSTNAME
chmod 755 /etc/init.d/genesys-LCA_$HOSTNAME
chmod 755 /usr/local/bin/killtree.sh
rm /etc/init.d/lca
rm /etc/init.d/lca2

/etc/init.d/genesys-LCA_$HOSTNAME start
/etc/init.d/genesys-LCA_$HOSTNAME status
systemctl enable genesys-LCA_$HOSTNAME

