#!/bin/bash

## Variables
usuario=x002896
logDir=/var/log/genesys
installDir=/opt/genesys
unpackDir=/opt/genesys/instaladores
nameFolder=/lvr
jdkDir=/opt/genesys
jdkFile=jdk-8u241-linux-x64.rpm
failedRecordingsDir=/failed_recordings
lvrInstallFile=IP_IntRcLVRRSPrem_8522248b1_ENU_linux.tar.gz

## Variables para MCP_premises
lvrrecovery_log_level=DEBUG
mcp_configserver_host=plgirapp197
mcp_configserver_port=2025
mcp_configserver_appname=default
mcp_configserver_username=recording
mcp_configserver_password=recording
mcp_minimumRecordingAge=0
lvrrecovery_webDAV_tenants=Environment,UNKNOWN
lvrrecovery_webDAV_UNKNOWN.unrecoverable.url=http://pgirhorwebdavvip/recordings
lvrrecovery_webDAV_UNKNOWN.unrecoverable.username=dav_user
lvrrecovery_webDAV_UNKNOWN.unrecoverable.password=dav_pass
zabbix_Enabled=false
lvrrecovery_parquet_Enabled=false

##Generacion de CRONTAB
echo '0 0 * * * sudo -u '$usuario' java -jar '$installDir$nameFolder'/recover_LVRs.jar --mode recover --component LVR --properties '$installDir$nameFolder'/MCP_premise.properties' >> /var/spool/cron/root

## Armado de carpetas
mkdir $installDir$failedRecordingsDir
mkdir $logDir$nameFolder
mkdir $installDir$nameFolder
mkdir $unpackDir$nameFolder

## Permisos 
chown $usuario. $logDir$nameFolder
chown $usuario. $installDir$failedRecordingsDir
chown $usuario. $installDir$nameFolder
chown $usuario. $unpackDir$nameFolder -R
chown $usuario. $lvrInstallFile
chmod 755 $logDir$nameFolder
chmod 755 $installDir$failedRecordingsDir
chmod 755 $jdkDir/$jdkFile
chmod 755 $installDir$nameFolder
chmod 755 $unpackDir$nameFolder -R
chmod 755 $lvrInstallFile

## Instalacion de JAVA
rpm -i $jdkDir/$jdkFile
echo generando variable JAVA_HOME
echo '# Java
export JAVA_HOME=/usr/java/default
export JRE_HOME=$JAVA_HOME
umask 0022' >> /home/$usuario/.bash_profile
rm $jdkDir/$jdkFile

## Descomprimir

chown $usuario. $installDir/$lvrInstallFile
chmod 755 $installDir/$lvrInstallFile
tar -zvxf $installDir/$lvrInstallFile -C $unpackDir$nameFolder
chmod -R 777 $unpackDir$nameFolder
mv $installDir/$lvrInstallFile $unpackDir/$lvrInstallFile

## Silent Install
echo '
[IPCommon]
InstallPath='$installDir$nameFolder'

[IntRcLVRRSPrem]
InstallationType=MCP
MCP_Directory='$installDir$failedRecordingsDir'
MCP_Schedule= 00:00
' > genesys_silent.ini
mv $installDir/genesys_silent.ini $unpackDir$nameFolder/ip/genesys_silent.ini
chmod 755 $unpackDir$nameFolder/ip/genesys_silent.ini

## Instalacion con Silent
su - $usuario -s /bin/bash -c "cd $unpackDir$nameFolder/ip; ./install.sh -s -fr $unpackDir$nameFolder/ip/genesys_silent.ini -fl $unpackDir$nameFolder/ip/genesys_install_result.log"

## Armado de archivo MCP_premise

echo '
lvrrecovery.failedfolder='$installDir$failedRecordingsDir'
lvrrecovery.log_dir='$logDir$nameFolder'
lvrrecovery.log_level='$lvrrecovery_log_level'
mcp.configserver.host='$mcp_configserver_host'
mcp.configserver.port='$mcp_configserver_port'
mcp.configserver.appname='$mcp_configserver_appname'
mcp.configserver.username='$mcp_configserver_username'
mcp.configserver.password='$mcp_configserver_password'
mcp.minimumRecordingAge='$mcp_minimumRecordingAge'
lvrrecovery.webDAV.tenants='$lvrrecovery_webDAV_tenants'
lvrrecovery.webDAV.UNKNOWN.unrecoverable.url='$lvrrecovery_webDAV_UNKNOWN_unrecoverable_url'
lvrrecovery.webDAV.UNKNOWN.unrecoverable.username='$lvrrecovery_webDAV_UNKNOWN_unrecoverable_username'
lvrrecovery.webDAV.UNKNOWN.unrecoverable.password='$lvrrecovery_webDAV_UNKNOWN_unrecoverable_password'
zabbix.Enabled='$zabbix_Enabled'
lvrrecovery.parquet.Enabled='$lvrrecovery_parquet_Enabled'
' > MCP_premise.properties
chown -R $usuario. MCP_premise.properties
chmod 755 MCP_premise.properties
mv $installDir$nameFolder/MCP_premise.properties $installDir$nameFolder/MCP_premise.properties_BKP
mv MCP_premise.properties $installDir$nameFolder/MCP_premise.properties

## Armado de Reproceso Manual

echo '#!/bin/bash
JRE_HOME=/usr/java/default/jre

java -jar '$installDir$nameFolder'/recover_LVRs.jar --mode recover --component MCP --properties '$installDir$nameFolder'/MCP_premise.properties' > reproceso_manual.sh
chown -R $usuario/ reproceso_manual.sh
mv reproceso_manual.sh $installDir$nameFolder/
chmod 755 $installDir$nameFolder/reproceso_manual.sh
