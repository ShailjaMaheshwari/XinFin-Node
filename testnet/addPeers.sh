#!/bin/bash

# Auther :- Anil Chinchawale
# AutherEmailID :- anil@xinfin.org
# Setup XDC Network blockchain with single script

echo "[*] Init XinFin XDC Network"

# echo "[*]Specify your chain/network ID if you want an explicit one (default = random) :-"
# read network_id

#PROJECT_ROOT_DIR=${project_name}_network
mypassword=''
DPOS_CUSTOM_GENESIS_FILE=testnetgenesis.json
Bin_NAME=XDC
DPOS_GLOBAL_ARGS="--mine --rpc --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,dpos,posv,XDPoS  --rpcaddr 0.0.0.0"
ENODE_START_PORT=30301
RPC_START_PORT=8545
WS_START_PORT=9545

#cd $PROJECT_ROOT_DIR
mkdir logs
killall $Bin_NAME
touch .pwd

mkdir nodes
WORK_DIR=$PWD
#PROJECT_DIR="${HOME}/github/xinFinOrg/XDPoS-TestNet-Apothem"
#cd $PROJECT_DIR && make all
#cd $WORK_DIR
numMN=2

if [[ $numMN > 9 ]]
then
    echo "Current Count ${numMN} , MasterNodes Count should not exceed more then 21..!"
    exit 1
fi

echo "[*] Creating Accounts for ${numMN} nodes"

for ((i= 1;i<= $numMN;i++)){
    echo $i
    $Bin_NAME --datadir nodes/node_$i account new --password <(echo $mypassword)
    ACCOUNTS[$i]=`$Bin_NAME account list --keystore nodes/node_$i/keystore | sed 's/^[^{]*{\([^{}]*\)}.*/\1/'`
    echo "[*] New account = ${ACCOUNTS[$i]}"
}

echo "Accounts Created -------------"
read a


# INIT GENESIS 
for (( i = 1;i<=$numMN;i++)){
    echo "[*] Init Node $i"
    $Bin_NAME --datadir nodes/node_$i init $DPOS_CUSTOM_GENESIS_FILE $>> logs/node_$i.log
    echo "[*] Start Nodes $i"
    $Bin_NAME --datadir nodes/node_$i $DPOS_GLOBAL_ARGS  --unlock ${ACCOUNTS[$i]} --password ./.pwd \
                                      --rpcport $(($RPC_START_PORT + $i - 2)) --port $(($ENODE_START_PORT + $i - 1)) --wsport $(($WS_START_PORT + $i - 1)) &>> logs/node_$i.log & 
 
    
}
echo "[*] Setting up network, please wait ..."
sleep 10

for ((i=1;i<=$numMN;i++)){
    if [ ! -e "nodes/node_$i/$Bin_NAME.ipc" ]; then
      sleep 2
    fi
ls nodes/node_$i/$Bin_NAME.ipc
}
read a
#Create file of enodes
ENODES_FILE=enodes_list.txt
rm -rf $ENODES_FILE
for ((i = 1; i <= $numMN; i++)) {
  if [ -e "nodes/node_$i/$Bin_NAME.ipc" ]; then
    echo "[*] Directory found for node $i"
    $Bin_NAME --exec 'admin.nodeInfo.enode' attach nodes/node_$i/$Bin_NAME.ipc >> $ENODES_FILE 
  else "[*] Please check node $i, there is something wrong with it"
  fi
}

#ADD PEERS
for ((i = 1; i <= $numMN; i++)) {
 if [ -e "nodes/node_$i/$Bin_NAME.ipc" ]; then
  echo "[*] Add peers for node $i"
  OWNED_ENODE=`$Bin_NAME --exec 'admin.nodeInfo.enode' attach nodes/node_$i/$Bin_NAME.ipc`
  echo "Owned enode = $OWNED_ENODE"
  echo "line = $line"
  while read line; do
    if [ $OWNED_ENODE != $line ]; then
     	    echo $line
	    $Bin_NAME --exec "admin.addPeer($line)" attach nodes/node_$i/$Bin_NAME.ipc >> "nodes_add_res.txt" 
    fi
  done < $ENODES_FILE
 fi
}
