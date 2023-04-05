#!/bin/sh

# The script is always located at
# ${HOME}/<servername>/daemon/script.sh
cd $(dirname $(realpath $(dirname ${0})))

unset jvm_args
jvm_args="${jvm_args} -Xms1024M"
jvm_args="${jvm_args} -Xmx8192M"
jvm_args="${jvm_args} -XX:ActiveProcessorCount=4"
jvm_args="${jvm_args} -XX:+UseG1GC"
jvm_args="${jvm_args} -XX:+ParallelRefProcEnabled"
jvm_args="${jvm_args} -XX:MaxGCPauseMillis=200"
jvm_args="${jvm_args} -XX:+UnlockExperimentalVMOptions"
jvm_args="${jvm_args} -XX:+DisableExplicitGC"
jvm_args="${jvm_args} -XX:+AlwaysPreTouch"
jvm_args="${jvm_args} -XX:G1NewSizePercent=30"
jvm_args="${jvm_args} -XX:G1MaxNewSizePercent=40"
jvm_args="${jvm_args} -XX:G1HeapRegionSize=8M"
jvm_args="${jvm_args} -XX:G1ReservePercent=20"
jvm_args="${jvm_args} -XX:G1HeapWastePercent=5"
jvm_args="${jvm_args} -XX:G1MixedGCCountTarget=4"
jvm_args="${jvm_args} -XX:InitiatingHeapOccupancyPercent=15"
jvm_args="${jvm_args} -XX:G1MixedGCLiveThresholdPercent=90"
jvm_args="${jvm_args} -XX:G1RSetUpdatingPauseTimePercent=5"
jvm_args="${jvm_args} -XX:SurvivorRatio=32"
jvm_args="${jvm_args} -XX:+PerfDisableSharedMem"
jvm_args="${jvm_args} -XX:MaxTenuringThreshold=1"

unset server_args
server_args="${server_args} --nogui"
server_args="${server_args} --universe worlds"

unset server_path
server_path="${PWD}/paper-1.19.4-492.jar"

# The daemon.log file contains logged events about
# server starts, stops, commands sent through the
# stuff.sh script and start.sh watchdog trips
daemon_log="${PWD}/daemon/daemon.log"

# 2023-04-06: I have spent the entire evening trying
# to make daemonizing the server process directly behave
# but I gave up on that, so have just upgrades.
# Truly, if it ain't broke, don't touch it.
screen_name="$(basename ${PWD})"

# This is not necessary anymore as the daemon
# directory where this script is exists by definition,
# otherwise how would we actually run this script?
mkdir -p "$(dirname ${daemon_log})"

if test "${1}" = "watchdog"
then
    opt_watchdog=true
else
    opt_watchdog=false
fi

if screen -list | grep -q ${screen_name}
then
    if ${opt_watchdog}
    then
        # 2023-04-06: watchdog floods logs too much
        # printf "[%s] Watchdog not tripped\n" "$(date +'%F %T')" >> "${daemon_log}"
        exit 0
    fi

    printf "[%s] stopping server\n" "$(date +'%F %T')" >> "${daemon_log}"
    screen -XS ${server_name} stuff "save-all\\015"
    screen -XS ${screen_name} quit
fi

if ${opt_watchdog}
then
    # UNDONE: have a special lock-esque file to prevent
    # watchdog trips when the server is shut down for maintenance;
    # Currently I have to comment out crontab entries and this is annoying
    printf "[%s] WATCHDOG TRIPPED\n" "$(date +'%F %T')" >> "${daemon_log}"
fi

printf "[%s] starting server\n" "$(date +'%F %T')" >> "${daemon_log}"
screen -dmS ${screen_name} java -server ${jvm_args} -jar "${server_path}" ${server_args}
exit 0