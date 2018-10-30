#!/bin/bash
sudo yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm
sudo yum remove -y MariaDB-common
sudo yum install -y Percona-XtraDB-Cluster-57

if [ ! -d /u01 ]; then
    sudo mkdir -p /u01
fi
sudo usermod -m -d /u01/mysql mysql
if [ ! -d /u01/mysql ]; then
    sudo mv /var/lib/mysql /u01/mysql
fi
grep -R -l /var/lib/mysql /etc/init.d/ /etc/percona-xtradb-cluster.c* /etc/my.cnf* \
     /etc/logrotate.d | xargs sudo sed -i s,/var/lib/mysql,/u01/mysql,g
grep -R -l /var/lock/subsys/mysqld /etc/init.d/mysql /etc/percona-xtradb-cluster.c* \
     /etc/my.cnf* | xargs sudo sed -i 's,/var/lock/subsys/mysqld,/var/run/mysqld,'
(echo '[mysql]'; echo 'socket=/u01/mysql/mysql.sock') | sudo tee -a /etc/my.cnf
sudo cp wsrep.cnf /etc/percona-xtradb-cluster.conf.d/wsrep.cnf

sudo yum install -y policycoreutils-python
sudo semanage fcontext -a -t mysqld_db_t "/u01/mysql(/.*)?"
sudo restorecon -Rv /u01/mysql

sudo semanage fcontext -a -t mysqld_etc_t "/etc/percona-xtradb-cluster\.cnf"
sudo semanage fcontext -a -t mysqld_etc_t "/etc/percona-xtradb-cluster\.conf\.d(/.*)?"
sudo restorecon -v /etc/percona-xtradb-cluster.cnf
sudo restorecon -R -v /etc/percona-xtradb-cluster.conf.d/

sudo semanage port -a -t mysqld_port_t -p tcp 4568
sudo semanage port -m -t mysqld_port_t -p tcp 4444
sudo semanage port -m -t mysqld_port_t -p tcp 4567 # may have to use -a instead of -m on Centos6

checkmodule -M -m -o PXC.mod PXC.te
semodule_package -o PXC.pp -m PXC.mod
sudo semodule -i PXC.pp

ports="3306 4444 4567 4568"

allowPort() {
    port=$1
    if [ -f /usr/bin/firewall-cmd ]; then
        sudo firewall-cmd --zone=public --add-port=$port/tcp --permanent
    else
        sudo sed -i "/-A INPUT -j REJECT/ i -A INPUT -p tcp --dport $port -j ACCEPT" \
             /etc/sysconfig/iptables
    fi
}

restartFirewall() {
    if [ -f /usr/bin/firewall-cmd ]; then
        sudo firewall-cmd --reload
    else
        sudo /etc/init.d/iptables restart
    fi
}

for port in $ports; do
    allowPort $port
done

restartFirewall
