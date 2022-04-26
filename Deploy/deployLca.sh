#!/bin/bash
## Recordar subir lca, LCA tazgz y killtree.sh
## Variables
## logDir = Carpeta donde van los LOGS
## installDir = basepath de las aplicaciones de genesys
## unpackDir = carpeta para copiar y descomprimir el instalador
## nameFolder = Carpeta donde va a quedar instalado el LCA RELATIVO a su installDir
## lcaInstallFile = Archivo .tar.gz del instalador

usuario=x002896
logDir=/var/log/genesys
installDir=/opt/genesys
unpackDir=/opt/genesys/instaladores
nameFolder=/LCA
lcaInstallFile=IP_LCA_8510037b1_ENU_linux.tar.gz

## Variables SilentInstall
Host=PLGIRAPP197
Port=2025
User=u594135
Password=123456
DataModel=64

## Creacion Carpetas ##
mkdir -p $unpackDir$nameFolder
mkdir -p $installDir$nameFolder
mkdir -p $logDir$nameFolder

## TAR al archivo ##
chown $usuario. $installDir/$lcaInstallFile
chmod 755 $installDir/$lcaInstallFile
tar -zvxf $installDir/$lcaInstallFile -C $unpackDir$nameFolder
mv $installDir/$lcaInstallFile $unpackDir/$lcaInstallFile

## Permisos ##
chown $usuario. $logDir/ -R
chown $usuario. $installDir/ -R
chmod 755 $logDir$nameFolder -R

## Silent Install de Genesys

echo '[ConfigServer]
Host='$Host'
Port='$Port'
User='$User'
Password='$Password'

[IPCommon]
InstallPath='$installDir$nameFolder'/
DataModel='$DataModel'

[LCA]
TuneStartupFiles=no
LCA_TLS_Mode=false
Silent_Installation_Without_ConfigServer=no
' > genesys_silent.ini
mv $installDir/genesys_silent.ini $unpackDir$nameFolder/ip/genesys_silent.ini
chmod 777 $unpackDir$nameFolder/ip/genesys_silent.ini
su - $usuario -s /bin/bash -c "cd $unpackDir$nameFolder/ip; ./install.sh -s -fr $unpackDir$nameFolder/ip/genesys_silent.ini -fl $unpackDir$nameFolder/ip/genesys_install_result.log"


##Post Instalacion

echo '[general] 
wmiquery-timeout=-1 
 
[log] 
enable-thread=false 
verbose = all 
all = '$logDir$nameFolder$nameFolder-$HOSTNAME' 
keep-startup-file = true 
expire = 5 
segment = 10000 ' > lca.cfg

rm $installDir$nameFolder/lca.cfg
mv $installDir/lca.cfg $installDir$nameFolder/lca.cfg
chown $usuario. $installDir$nameFolder/lca.cfg
chmod 750 $installDir$nameFolder/lca.cfg

## Generacion de servicio

mv killtree.sh /usr/local/bin
mv $installDir/lca /etc/init.d/lca
sed "s/PLIVRUNIAPP013/$HOSTNAME/" /etc/init.d/lca >> /etc/init.d/lca2
sed "s/x002492/$usuario/" /etc/init.d/lca2 >> /etc/init.d/genesys-LCA_$HOSTNAME
chmod 755 /etc/init.d/genesys-LCA_$HOSTNAME
chmod 755 /usr/local/bin/killtree.sh
rm /etc/init.d/lca
rm /etc/init.d/lca2

/etc/init.d/genesys-LCA_$HOSTNAME start
/etc/init.d/genesys-LCA_$HOSTNAME status
systemctl enable genesys-LCA_$HOSTNAME

