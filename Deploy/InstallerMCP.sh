#!/bin/bash

## Variables
usuario=x002896
host=$(hostname)
mcp1='slz_mcp'
num1=$(hostname | sed 's/PLIVRUNIAPP//')
sus1=$(($num1-140)) ##Corregir numero de la resta una vez tengamos los nombres de equipo

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
mkdir -p /opt/genesys/$mcp1
mkdir -p /opt/genesys/$mcp2
mkdir -p /var/log/genesys/$mcp1
mkdir -p /var/log/genesys/$mcp2
mkdir -p /opt/genesys/instaladores/MCP

## Permisos ##
chown -R $usuario:accesstt /var/www/gvp 
chown -R $usuario. /opt/genesys/$mcp1
chown -R $usuario. /opt/genesys/$mcp2
chown -R $usuario. /var/log/genesys/$mcp1
chown -R $usuario. /var/log/genesys/$mcp2
chown -R $usuario. /opt/genesys/instaladores/MCP
chmod -R 777 /opt/genesys/instaladores/MCP
chmod -R 755 /var/log/genesys/$mcp1
chmod -R 755 /var/log/genesys/$mcp2
chmod -R 755 /var/www 

## Descomprimir
chown $usuario. /opt/genesys/IP_vpMediaControl_9004606b1_ENU_linux.tar.gz
chmod 755 /opt/genesys/IP_vpMediaControl_9004606b1_ENU_linux.tar.gz
tar -zvxf /opt/genesys/IP_vpMediaControl_9004606b1_ENU_linux.tar.gz -C /opt/genesys/instaladores/MCP
chmod -R 777 /opt/genesys/instaladores/MCP
mv /opt/genesys/IP_vpMediaControl_9004606b1_ENU_linux.tar.gz /opt/genesys/instaladores/IP_vpMediaControl_9004606b1_ENU_linux.tar.gz

## Silent Install archivo A
echo '[ConfigServer]
Host=PLGIRAPP197
Port=2025
User=u594135
Password=123456
ApplicationName='$mcp1'

[IPCommon]
InstallPath=/opt/genesys/'$mcp1'/
DataModel=64

[vpMediaControl]
AudioFormat=Alaw
HttpProxyHost=
VoiceXML=yes
' > genesys_silent.ini
mv /opt/genesys/genesys_silent.ini /opt/genesys/instaladores/MCP/ip/genesys_silent.ini
chmod 755 /opt/genesys/instaladores/MCP/ip/genesys_silent.ini


## Silent Install archivo B

echo '[ConfigServer]
Host=PLGIRAPP197
Port=2025
User=u594135
Password=123456
ApplicationName='$mcp2'

[IPCommon]
InstallPath=/opt/genesys/'$mcp2'/
DataModel=64

[vpMediaControl]
AudioFormat=Alaw
HttpProxyHost=
VoiceXML=yes
' >> genesys_silent2.ini
mv /opt/genesys/genesys_silent2.ini /opt/genesys/instaladores/MCP/ip/genesys_silent2.ini
chmod 755 /opt/genesys/instaladores/MCP/ip/genesys_silent2.ini

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
LOG_FILE=/var/log/genesys/'$mcp1'/'$mcp1'_init
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
  PID=`su - $USER -s /bin/bash -c '\''cd /opt/genesys/'$mcp1'/bin ; ./run.sh >> /dev/null 2>&1 & echo $!'\''`
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
LOG_FILE=/var/log/genesys/'$mcp2'/'$mcp2'_init
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
  PID=`su - $USER -s /bin/bash -c '\''cd /opt/genesys/'$mcp2'/bin ; ./run.sh >> /dev/null 2>&1 & echo $!'\''`
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
mv /opt/genesys/genesys-$mcp1 /etc/init.d/genesys-$mcp1
mv /opt/genesys/genesys-$mcp2 /etc/init.d/genesys-$mcp2
chmod 755 /etc/init.d/genesys-$mcp1
chmod 755 /etc/init.d/genesys-$mcp2


## Instalacion con Silent
su - $usuario -s /bin/bash -c 'cd /opt/genesys/instaladores/MCP/ip; ./install.sh -s -fr /opt/genesys/instaladores/MCP/ip/genesys_silent.ini -fl /opt/genesys/instaladores/MCP/ip/genesys_install_result.log'

su - $usuario -s /bin/bash -c 'cd /opt/genesys/instaladores/MCP/ip; ./install.sh -s -fr /opt/genesys/instaladores/MCP/ip/genesys_silent2.ini -fl /opt/genesys/instaladores/MCP/ip/genesys_install_result.log'

/etc/init.d/genesys-$mcp1 start
/etc/init.d/genesys-$mcp2 start
/etc/init.d/genesys-$mcp1 status
/etc/init.d/genesys-$mcp2 status
systemctl enable genesys-$mcp1
systemctl enable genesys-$mcp2
