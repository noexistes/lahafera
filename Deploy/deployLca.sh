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

## Creacion de KILLTREE.SH
echo '#Based off killtree from
#From http://stackoverflow.com/a/3211182/252402
#amd killproc from init.d functions.  This will send a TERM signal to all processes ina  treet


. /etc/init.d/functions


killtree() {
    local RC
    local delay=3;


    if [ "$1" = "-d" ]; then
        delay=$2
        shift 2
    fi

    local pid=$1
    #Recursive loop that will call this on all the children first
    for _child in $(ps -o pid --no-headers --ppid ${pid}); do
        echo killtree -d $delay ${_child}

        killtree -d $delay ${_child}
    done


    if checkpid $pid 2>&1; then

     # TERM first, then KILL if not dead
     kill -TERM $pid >/dev/null 2>&1

     usleep 100000
      if checkpid $pid && sleep 1 &&
          checkpid $pid && sleep $delay &&
          checkpid $pid ; then

            echo "Must kill $pid hard"
            kill -KILL $pid >/dev/null 2>&1
            usleep 100000
       fi
    fi
    checkpid $pid
    RC=$?
    [ "$RC" -eq 0 ] && failure $"$pid shutdown" || success $"$pid shutdown"
    RC=$((! $RC))


    return $RC

}


if [ $# -eq 0 -o $# -gt 3 ]; then
    echo "Usage: $(basename $0) [-d delay] <pid>"
    exit 1
fi


killtree $@
' > killtree.sh

## Generacion de lca para servicio

echo '#!/bin/sh

# chkconfig: 23 99 1
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Short-Description: Init script for lca_'$HOSTNAME'
# Description:       A simple daemon wrapper for lca_'$HOSTNAME'

#Get killproc and other funcitons
. /etc/init.d/functions

SERVICE_NAME=LCA_'$HOSTNAME'
USER='$usuario'
LOG_FILE=/var/log/genesys/LCA/LCA_'$HOSTNAME'_init
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
  #/usr/sbin/logrotate -f -s /logrotate/logrotate.status /logrotate/LCA_'$HOSTNAME'.conf 


  echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Starting" > $LOG_FILE

  if [ ! -z "$SUBIT" ]; then
    chown $USER $LOG_FILE
  fi

  #TODO look at using a more standard daemon function
  PID=`su - $USER -s /bin/bash -c '\''cd /opt/genesys/LCA; ./run.sh >> /dev/null 2>&1 & echo $!'\''`
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
' > /etc/init.d/genesys-LCA_$HOSTNAME

## Generacion de servicio

mv killtree.sh /usr/local/bin
chmod 755 /etc/init.d/genesys-LCA_$HOSTNAME
chmod 755 /usr/local/bin/killtree.sh

/etc/init.d/genesys-LCA_$HOSTNAME start
/etc/init.d/genesys-LCA_$HOSTNAME status
systemctl enable genesys-LCA_$HOSTNAME

