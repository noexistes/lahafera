#!/bin/bash
##Todas las variables de carpeta, no deben finalizar con /
## Variables

usuario=x002896
host=$(hostname)
mcp1='slz_mcp'
num1=$(hostname | sed 's/PLGIRAPP//')
sus1=$(($num1-140)) ##Corregir numero de la resta una vez tengamos los nombres de equipo
logDir=/var/log/genesys
installDir=/opt/genesys
unpackDir=/opt/genesys/instaladores/MCP
mcpInstallFile=IP_vpMediaControl_9003653b1_ENU_linux.tar.gz

## Variables SilentInstall
Host=PLGIRAPP197
Port=2025
User=u594135
Password=123456
DataModel=64
AudioFormat=Alaw

## Condicional de menos a 10
if [[ $sus1 -lt 10 ]]
    then
        mcp1=$mcp1'0'$sus1
    else
        mcp1=$mcp1$sus1
fi

## Variable Post Condicional
mcp2=$mcp1'b'

## Creacion Carpetas ##
mkdir -p /var/www/gvp/mcp
mkdir -p $installDir/$mcp1
mkdir -p $installDir/$mcp2
mkdir -p $logDir/$mcp1
mkdir -p $logDir/$mcp2
mkdir -p $unpackDir

## Permisos ##
chown -R $usuario:accesstt /var/www/gvp 
chown -R $usuario. $installDir/$mcp1
chown -R $usuario. $installDir/$mcp2
chown -R $usuario. $logDir/$mcp1
chown -R $usuario. $logDir/$mcp2
chown -R $usuario. $unpackDir
chmod -R 777 $unpackDir
chmod -R 755 $logDir/$mcp1
chmod -R 755 $logDir/$mcp2
chmod -R 755 /var/www 

## Descomprimir
chown $usuario. $installDir/$mcpInstallFile
chmod 755 $installDir/$mcpInstallFile
tar -zvxf $installDir/$mcpInstallFile -C $unpackDir
chmod -R 777 $unpackDir
mv $installDir/$mcpInstallFile $unpackDir/$mcpInstallFile

## Silent Install archivo A
echo '[ConfigServer]
Host='$Host'
Port='$Port'
User='$User'
Password='$Password'
ApplicationName='$mcp1'

[IPCommon]
InstallPath='$installDir'/'$mcp1'/
DataModel='$DataModel'

[vpMediaControl]
AudioFormat='$AudioFormat'
HttpProxyHost=
VoiceXML=yes
' > genesys_silent.ini
mv $installDir/genesys_silent.ini $unpackDir/ip/genesys_silent.ini
chmod 755 $unpackDir/ip/genesys_silent.ini


## Silent Install archivo B

echo '[ConfigServer]
Host='$Host'
Port='$Port'
User='$User'
Password='$Password'
ApplicationName='$mcp2'

[IPCommon]
InstallPath='$installDir'/'$mcp2'/
DataModel='$DataModel'

[vpMediaControl]
AudioFormat='$AudioFormat'
HttpProxyHost=
VoiceXML=yes
' >> genesys_silent2.ini
mv $installDir/genesys_silent2.ini $unpackDir/ip/genesys_silent2.ini
chmod 755 $unpackDir/ip/genesys_silent2.ini

## Creacion de Servicio A

echo '#!/bin/sh

# chkconfig: 23 99 1
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Short-Description: Init script for '$mcp1'_'$host'
# Description:       A simple daemon wrapper for '$mcp1'_'$host'




#Get killproc and other funcitons
. /etc/init.d/functions

SERVICE_NAME='$mcp1'
USER='$usuario'
LOG_FILE='$logDir'/'$mcp1'/'$mcp1'_init
SUBIT="su - $USER -c "
KILL_TIME=60


#TODO pass on the network configuration as a #n parameter??  that shoudl allow us to have multipe instances on a single node
PIDFILE=/var/run/${SERVICE_NAME}.pid


start() {
  if [ -f ${PIDFILE} ]; then
   #verify if the process is actually still running under this pid
   OLDPID=`cat ${PIDFILE}`
   #See if the pid is running, making sure that were not tracking the grep process itself
   RESULT=`ps -ef | grep ${OLDPID} | grep -v grep` 

   if [ -n "${RESULT}" ]; then
     echo "Script already running! Exiting"
     exit 255
   fi

  fi



  echo "Starting up $SERVICE"

  #Flip over the console file if needed with logrotate
  #/usr/sbin/logrotate -f -s /logrotate/logrotate.status /logrotate/noexiste.conf 


  echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Starting" > $LOG_FILE

  if [ ! -z "$SUBIT" ]; then
    chown $USER $LOG_FILE
  fi

  #TODO look at using a more standard daemon function
  PID=`su - $USER -s /bin/bash -c '\''cd '$installDir'/'$mcp1'/bin ; ./run.sh >> /dev/null 2>&1 & echo $!'\''`
  RETVAL=$?

  
  #grab pid of this process and update the pid file with it
  echo "$PID" > $PIDFILE


  if [ ! -z "$SUBIT" ]; then
    chown $USER $PIDFILE
  fi

}
# Restart the service FOO
stop() {
    
    if [ -f ${PIDFILE} ]; then
      /usr/local/bin/killtree.sh -d   $KILL_TIME `cat $PIDFILE`
      RETVAL=$?
      echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Stopped" >> $LOG_FILE

      rm ${PIDFILE}
    else
      echo "No ${PIDFILE} exists, nothing to stop"
    fi
}



case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
  #//not sure if we feed the prog itself
        status -p ${PIDFILE} ''
        RETVAL=$?
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        RETVAL=1
esac
exit $RETVAL
' >> genesys-$mcp1

## Creacion de Servicio B

echo '#!/bin/sh

# chkconfig: 23 99 1
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Short-Description: Init script for '$mcp2'_'$host'
# Description:       A simple daemon wrapper for '$mcp2'_'$host'




#Get killproc and other funcitons
. /etc/init.d/functions

SERVICE_NAME='$mcp2'
USER='$usuario'
LOG_FILE='$logDir'/'$mcp2'/'$mcp2'_init
SUBIT="su - $USER -c "
KILL_TIME=60


#TODO pass on the network configuration as a #n parameter??  that shoudl allow us to have multipe instances on a single node
PIDFILE=/var/run/${SERVICE_NAME}.pid


start() {
  if [ -f ${PIDFILE} ]; then
   #verify if the process is actually still running under this pid
   OLDPID=`cat ${PIDFILE}`
   #See if the pid is running, making sure that were not tracking the grep process itself
   RESULT=`ps -ef | grep ${OLDPID} | grep -v grep` 

   if [ -n "${RESULT}" ]; then
     echo "Script already running! Exiting"
     exit 255
   fi

  fi



  echo "Starting up $SERVICE"

  #Flip over the console file if needed with logrotate
  #/usr/sbin/logrotate -f -s /logrotate/logrotate.status /logrotate/noexiste.conf 


  echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Starting" > $LOG_FILE

  if [ ! -z "$SUBIT" ]; then
    chown $USER $LOG_FILE
  fi

  #TODO look at using a more standard daemon function
  PID=`su - $USER -s /bin/bash -c '\''cd '$installDir'/'$mcp2'/bin ; ./run.sh >> /dev/null 2>&1 & echo $!'\''`
  RETVAL=$?

  
  #grab pid of this process and update the pid file with it
  echo "$PID" > $PIDFILE


  if [ ! -z "$SUBIT" ]; then
    chown $USER $PIDFILE
  fi

}
# Restart the service FOO
stop() {
    
    if [ -f ${PIDFILE} ]; then
      /usr/local/bin/killtree.sh -d   $KILL_TIME `cat $PIDFILE`
      RETVAL=$?
      echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Stopped" >> $LOG_FILE

      rm ${PIDFILE}
    else
      echo "No ${PIDFILE} exists, nothing to stop"
    fi
}



case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
  #//not sure if we feed the prog itself
        status -p ${PIDFILE} ''
        RETVAL=$?
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        RETVAL=1
esac
exit $RETVAL
' >> genesys-$mcp2

## Mover archivos a Init.d
mv $installDir/genesys-$mcp1 /etc/init.d/genesys-$mcp1
mv $installDir/genesys-$mcp2 /etc/init.d/genesys-$mcp2
chmod 755 /etc/init.d/genesys-$mcp1
chmod 755 /etc/init.d/genesys-$mcp2


## Instalacion con Silent
su - $usuario -s /bin/bash -c "cd $unpackDir/ip; ./install.sh -s -fr $unpackDir/ip/genesys_silent.ini -fl $unpackDir/ip/genesys_install_result.log"
su - $usuario -s /bin/bash -c "cd $unpackDir/ip; ./install.sh -s -fr $unpackDir/ip/genesys_silent2.ini -fl $unpackDir/ip/genesys_install_result.log"

## Iniciando servicios y viendo status
## Adicionalmente se agregan al SystemCTL
/etc/init.d/genesys-$mcp1 start
/etc/init.d/genesys-$mcp2 start
/etc/init.d/genesys-$mcp1 status
/etc/init.d/genesys-$mcp2 status
systemctl enable genesys-$mcp1
systemctl enable genesys-$mcp2
