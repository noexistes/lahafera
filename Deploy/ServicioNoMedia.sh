#!/bin/bash
## Se pasa como variables al ejecutar el archivo el nombre del app de genesys y el usuario que lo ejecuta
## Se asume que se tiene el killtree.sh

usuario=$1
servicio=$2

##Se verifica que se ingresen todos los parametros

if [[ $# -eq 0 ]] ; then

{

    echo 'Falta ingresar algun parametro'
    echo 'Se envia primero usuario y luego servicio'
    exit 1

}

fi

## Generacion de lca para servicio

echo '#!/bin/sh

# chkconfig: 23 99 1
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Short-Description: Init script for '$servicio'
# Description:       A simple daemon wrapper for '$servicio'

#Get killproc and other funcitons
. /etc/init.d/functions

SERVICE_NAME='$servicio'
USER='$usuario'
LOG_FILE=/var/log/genesys/'$servicio'/'$servicio'_init
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
  #/usr/sbin/logrotate -f -s /logrotate/logrotate.status /logrotate/'$servicio'.conf 


  echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Starting" > $LOG_FILE

  if [ ! -z "$SUBIT" ]; then
    chown $USER $LOG_FILE
  fi

  #TODO look at using a more standard daemon function
  PID=`su - $USER -s /bin/bash -c '\''cd /opt/genesys/'$servicio'; ./run.sh >> /dev/null 2>&1 & echo $!'\''`
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
        status -p ${PIDFILE} '\'''\''
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
' > /etc/init.d/genesys-$servicio
chmod 755 /etc/init.d/genesys-$servicio

## Lenas agregadas para iniciar el servicio, ver el status para ver si esta OK
## y arrancarlo en el systemctl
read -p 'Inicio el servicio y lo envio a systemctl: (Si/No) ' Inicio

if [[ $Inicio == 'Si' ]] || [[ $Inicio == 'S' ]]; then

{

/etc/init.d/genesys-$servicio start
/etc/init.d/genesys-$servicio status
systemctl enable genesys-$servicio

}

else
    echo 'Ok cerramos'
    exit 1

fi
