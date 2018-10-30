#!/bin/bash
# Put the DB server to bootstrap on first
export SERVER_LIST="centos7-blank.default centos6.default"
export SSTUSER=sstuser
export SSTSECRET=s3cret

getIP() {
    name=$1
    ip=`awk "/^$name / {print \\$2}" server-ips.txt`

    echo $ip
}

./fill-ip.sh > server-ips.txt

echo -n Please enter a new root password for the database:
read -s NEWPW
echo
export NEWPW

NODE_LIST=$( (
    first=1
    for host in $SERVER_LIST; do
        if [ $first -ne 1 ]; then
            echo -n " "
        fi
        first=0
        echo -n `getIP $host`
    done ) | sed "s/ /,/g;" )
export NODE_LIST

rm -f setup-primary.sh
for host in $SERVER_LIST; do
    FILES="server-ips.txt install-percona.sh PXC.te start-mysql.sh bootstrap-server.sh
                update-db-users.sh check-db-status.sh wsrep.cnf"

    node=`getIP $host`
    cat cluster-config-snippet.txt |
        sed "s,THIS_NODE,$node,g; s/NODE_LIST/$NODE_LIST/g; s/NODE_NAME/$host/g;
             s,SSTSECRET,$SSTSECRET,g; s,SSTUSER,$SSTUSER,g;" > wsrep.cnf

    SETUP=bogus
    if [ ! -f setup-primary.sh ]; then
        SETUP=setup-primary.sh
        (
            cat<<EOF
#!/bin/sh -e
export NEWPW=$NEWPW
export THIS_NODE=$node
export NODE_LIST=$NODE_LIST
export SSTUSER=$SSTUSER
export SSTSECRET=$SSTSECRET
./install-percona.sh
./bootstrap-server.sh
./update-db-users.sh;
./check-db-status.sh
EOF
        ) > $SETUP
    else
        SETUP=setup-$host.sh
        (
            cat<<EOF
#!/bin/sh -e
export NEWPW=$NEWPW
export THIS_NODE=$node
export NODE_LIST=$NODE_LIST
./install-percona.sh;
./start-mysql.sh;
./update-db-users.sh;
./check-db-status.sh
EOF
        ) > $SETUP
    fi
    chmod +x $SETUP
    scp -p $FILES $SETUP $host:
    echo '********************************************************************************'
    echo '********************************************************************************'
    echo '**                                                                            **'
    echo "           Run $SETUP on $host"
    echo '**                                                                            **'
    echo '********************************************************************************'
    echo '********************************************************************************'
done
