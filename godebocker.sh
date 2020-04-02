#!/bin/sh

name="GoDebugger"
tag="\033[0;32m$name\033[0m"
etag="\033[0;31m$name\033[0m"
itag="\033[0;34m$name\033[0m"

printf "Welcome to $tag\n"

printf "$itag: begin message: $BEGIN_MSG\n" # needed for begin detection of vscode tas\nk

printf "$itag: cd'ing into workdir $WORKDIR ...\n"
cd $WORKDIR

if [ "$BUILD" == true ]; then
  printf "$itag: Building binary ...\n"
  printf "$itag: HINT: \033[0;37mmount a persisten volume to speed up dependency fetching.\033[0;37m\n"
  # set up ssh agent
  mkdir -p /root/.ssh
  chmod 0700 /root/.ssh
  if [ "$KNOWN_HOSTS" != "" ]; then
    echo "$KNOWN_HOSTS" >  /root/.ssh/known_hosts
  fi
  if [ "$SSH_KEY" != "" ]; then
    echo "$SSH_KEY" > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
  fi

  # build binary
  CGO_ENABLED=0 go build -gcflags "all=-N -l" -o $BINARY .
  if [ $? -ne 0 ]; then
    rpintf "$etag: Build failed."
    rm -f /root/.ssh/id_rsa # delte private key!
    exit 1
  fi
  rm -f /root/.ssh/id_rsa # delete private key!
  printf "$itag: Build successfull.\n"
fi

continueFlag="--continue"
if [ "$CONTINUE" == false ]; then
  continueFlag=""
fi

logFlag="--log"
if [ "$DLV_LOG" == false ]; then
  logFlag=""
fi

printf "$itag: Starting delve exec"
dlv exec ${BINARY} --listen=:${DLVPORT} --headless=true --api-version=2 $logFlag --accept-multiclient $continueFlag -- ${ARGS} &
DLVPID=$!
printf ", pid=$DLVPID ... have fun debugging!\n\n"

handle_signal() {
  printf "$itag: Received signal $1\n"
  pid=$(ps | grep "${BINARY}$" | awk '{print $1}') # try to get pid by BINARY
  if [ "$pid" == "" ]; then
    pid=$(netstat -lnp | grep -E "$PORT|$GRPCPORT" -m1 | grep -oE '(\d+)\/\w+$' | grep -oE '\d+')
    # or by used port
  fi
  if [ "$pid" != "" ]; then
    printf "$itag: Found PID $pid for debug binary, sending $1 to it ...\n"
    # debug binary pid found, send signal to it
    sh -c "kill -$1 $pid"
    wait $pid
    kill_delve_timeout &
  else
    printf "$itag: Did not find debug process, sending $1 to delve ...\n"
    sh -c "kill -$1 $DLVPID"
  fi
  printf "$itag: Waiting for delve (pid=$DLVPID) to end ...\n"
  wait $DLVPID
  printf "$tag: Delve ended ... BYE!\n"
  exit 0
}

trapper_INT() {
  handle_signal INT 
}

trapper_TERM() {
  handle_signal TERM
}

kill_delve_timeout() {
  sleep 1
  kill -TERM $DLVPID
}

trap trapper_INT SIGINT
trap trapper_TERM SIGTERM

while true; do
  if [ $? -ne 0 ]; then
    printf "$etag: Something went wrong, exiting\n"
    exit 1
  fi
  sleep 1
done