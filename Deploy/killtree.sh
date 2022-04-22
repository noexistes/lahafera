#Based off killtree from
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
