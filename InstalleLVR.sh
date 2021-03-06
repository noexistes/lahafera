#!/bin/bash

## Variables
usuario=x002896

##Generacion de CRONTAB
echo '0 0 * * * sudo -u '$usuario' java -jar /opt/genesys/lvr/recover_LVRs.jar --mode recover --component LVR --properties /opt/genesys/lvr/MCP_premise.properties' >> /var/spool/cron/root

## Armado de carpetas
mkdir /opt/genesys/failed_recordings
mkdir /var/log/genesys/lvr
mkdir /opt/genesys/lvr
mkdir /opt/genesys/instaladores/LVR

## Permisos 
chown $usuario:accesstt /var/log/genesys/lvr
chown $usuario:accesstt /opt/genesys/failed_recordings
chown $usuario:accesstt /opt/genesys/lvr
chown $usuario:accesstt /opt/genesys/instaladores/LVR
chown $usuario:accesstt IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz
chmod 755 /var/log/genesys/lvr
chmod 755 /opt/genesys/failed_recordings
chmod 755 /opt/genesys/jdk-8u241-linux-x64.rpm
chmod 755 /opt/genesys/lvr
chmod 755 /opt/genesys/instaladores/LVR
chmod 755 IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz

## Instalacion de JAVA
rpm -i /opt/genesys/jdk-8u241-linux-x64.rpm
echo generando variable JAVA_HOME
echo '# Java
export JAVA_HOME=/usr/java/default
export JRE_HOME=$JAVA_HOME
umask 0022' >> /home/$usuario/.bash_profile
rm /opt/genesys/jdk-8u241-linux-x64.rpm

## Descomprimir

chown $usuario. /opt/genesys/IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz
chmod 755 /opt/genesys/IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz
tar -zvxf /opt/genesys/IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz -C /opt/genesys/instaladores/LVR
chmod -R 777 /opt/genesys/instaladores/LVR
mv /opt/genesys/IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz /opt/genesys/instaladores/IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz

## Silent Install
echo '
[IPCommon]
InstallPath=/opt/genesys/lvr

[IntRcLVRRSPrem]
InstallationType=MCP
MCP_Directory=/opt/genesys/failed_recordings
MCP_Schedule= 00:00
' > genesys_silent.ini
mv /opt/genesys/genesys_silent.ini /opt/genesys/instaladores/LVR/ip/genesys_silent.ini
chmod 755 /opt/genesys/instaladores/LVR/ip/genesys_silent.ini

## Instalacion con Silent
su - $usuario -s /bin/bash -c 'cd /opt/genesys/instaladores/LVR/ip; ./install.sh -s -fr /opt/genesys/instaladores/LVR/ip/genesys_silent.ini -fl /opt/genesys/instaladores/LVR/ip/genesys_install_result.log'

## Armado de archivo MCP_premise

echo '
lvrrecovery.failedfolder=/opt/genesys/failed_recordings
lvrrecovery.log_dir=/var/log/genesys/lvr
lvrrecovery.log_level=DEBUG
mcp.configserver.host=plgirapp197
mcp.configserver.port=2025
mcp.configserver.appname=default
mcp.configserver.username=recording
mcp.configserver.password=recording
mcp.minimumRecordingAge=0
lvrrecovery.webDAV.tenants=Environment,UNKNOWN
lvrrecovery.webDAV.UNKNOWN.unrecoverable.url=http://pgirhorwebdavvip/recordings
lvrrecovery.webDAV.UNKNOWN.unrecoverable.username=dav_user
lvrrecovery.webDAV.UNKNOWN.unrecoverable.password=dav_pass
zabbix.Enabled=false
lvrrecovery.parquet.Enabled=false
' > MCP_premise.properties
chown -R $usuario. MCP_premise.properties
chmod 755 MCP_premise.properties
mv /opt/genesys/lvr/MCP_premise.properties /opt/genesys/lvr/MCP_premise.properties_BKP
mv MCP_premise.properties /opt/genesys/lvr/MCP_premise.properties

## Armado de Reproceso Manual

echo '#!/bin/bash
JRE_HOME=/usr/java/default/jre

java -jar /opt/genesys/lvr/recover_LVRs.jar --mode recover --component MCP --properties /opt/genesys/lvr/MCP_premise.properties' > reproceso_manual.sh
chown -R $usuario:accesstt reproceso_manual.sh
chmod 755 /opt/genesys/lvr/reproceso_manual.sh
mv reproceso_manual.sh /opt/genesys/lvr/

