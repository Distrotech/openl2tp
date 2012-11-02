#! /bin/sh -e

### BEGIN INIT INFO
# Provides:          openl2tpd
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Required-Start:    $network $remote_fs $syslog $portmap
# Required-Stop:     $network $remote_fs $syslog
# Short-Description: Start openl2tp daemon
# Description:       Start openl2tp daemon
### END INIT INFO

DAEMON=/usr/sbin/openl2tpd
NAME=openl2tpd
MODULE1=pppol2tp
MODULE2=l2tp_ppp
PIDFILE=/var/run/$NAME.pid

# Check for daemon presence
test -x $DAEMON || exit 0

# Get lsb functions
. /lib/lsb/init-functions
. /etc/default/rcS

# Source defaults file; edit that file to configure this script.
OPENL2TPD_ARGS=""
OPENL2TPD_CONFIG_FILE=""
if [ -e /etc/default/openl2tp ]; then
    . /etc/default/openl2tp
fi

if [ -n "$OPENL2TPD_CONFIG_FILE" ]; then
    OPENL2TPD_ARGS="-c $OPENL2TPD_CONFIG_FILE $OPENL2TPD_ARGS"
fi

if [ "x$VERBOSE" = "xno" ]; then
    MODPROBE_OPTIONS="$MODPROBE_OPTIONS -q"
    export MODPROBE_OPTIONS
fi

cleanup_pidfile ()
{
    if [ -e $PIDFILE ]; then
	PID="`cat $PIDFILE`"
	if ! [ -d "/proc/$PID" ]; then
	    echo "Deleting stale PID file."
	    rm $PIDFILE
	fi
    fi
}

# As the name says. If the kernel supports modules, it'll try to load l2tp module(s).
# First try to load l2tp_ppp. If that fails, try pppol2tp.
load_module()
{
    LIST=`/sbin/lsmod|awk '!/Module/ {print $1}'`
    log_begin_msg "Loading L2TP kernel modules..."
    STATUS=0
    
    if echo $LIST | grep -q -w "$MODULE1"; then
	[ "$VERBOSE" != no ] && log_success_msg "Module already loaded: $MODULE1"
    elif echo $LIST | grep -q -w "$MODULE2"; then
	[ "$VERBOSE" != no ] && log_success_msg "Module already loaded: $MODULE2"
    else
        modprobe -n $MODULE2 2> /dev/null || MODULE=$MODULE1
        if [ -z $MODULE ]; then
            MODULE=$MODULE2
        fi
	if modprobe $MODULE 2>/dev/null; then
	    [ "$VERBOSE" != no ] && log_success_msg "Loaded module: $MODULE"
	else
	    if [ "$VERBOSE" != no ]; then
		log_warning_msg "Unable to load module: $MODULE"
	    fi
        fi
    fi

    log_end_msg $STATUS
}

# As the name says. It'll try to remove L2TP kernel module(s).
remove_module()
{
    LIST=`/sbin/lsmod|awk '!/Module/ {print $1}'`
    log_begin_msg "Unloading L2TP kernel modules..."
    STATUS=0
    
    if echo $LIST | grep -q -w "$MODULE1"; then
	[ "$VERBOSE" != no ] && log_success_msg "Module is loaded. Unloading...: $MODULE1"
	if modprobe -r $MODULE1 2>/dev/null; then
	    [ "$VERBOSE" != no ] && log_success_msg "Unloaded module: $MODULE1"
	else
	    if [ "$VERBOSE" != no ]; then
		log_warning_msg "Unable to unload module: $MODULE1"
	    fi
        fi
    elif echo $LIST | grep -q -w "$MODULE2"; then
	[ "$VERBOSE" != no ] && log_success_msg "Module is loaded. Unloading...: $MODULE2"
	if modprobe -r $MODULE2 2>/dev/null; then
	    [ "$VERBOSE" != no ] && log_success_msg "Unloaded module: $MODULE2"
	else
	    if [ "$VERBOSE" != no ]; then
		log_warning_msg "Unable to unload module: $MODULE2"
	    fi
        fi
    fi
    
    log_end_msg $STATUS
}

case "$1" in
    start)
	[ -f /proc/modules ] && load_module
	log_begin_msg "Starting openl2tpd..."
	start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- $OPENL2TPD_ARGS
	log_end_msg $?
	;;
    stop)
	log_begin_msg "Stopping openl2tpd..."
	start-stop-daemon --stop --quiet --oknodo --retry 2 --exec $DAEMON
	log_end_msg $?
	cleanup_pidfile
	remove_module
	;;
    restart)
	$0 stop
	sleep 1
	$0 start
	;;
    reload|force-reload) 
	log_begin_msg "Reloading openl2tpd..."
	start-stop-daemon --stop --signal 1 --exec $DAEMON
	log_end_msg $?
	;;
    *)
	log_success_msg "Usage: /etc/init.d/openl2tpd {start|stop|restart|reload|force-reload}"
	exit 1
esac

exit 0

