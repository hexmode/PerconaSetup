#!/bin/bash
PW=$(sudo perl -ne '/temporary password is generated for root\@localhost: (.*)/ && {print "$1\n"}' /var/log/mysqld.log)
echo "set password for root@localhost = '$NEWPW';"|mysql -u root -p"$PW" --connect-expired-password

(
cat<<EOF
  CREATE USER '$SSTUSER'@'localhost' IDENTIFIED BY '$SSTSECRET';
  GRANT PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT
     ON *.* TO '$SSTUSER'@'localhost';
  FLUSH PRIVILEGES;
EOF
) | mysql -u root -p"$NEWPW"
