#!/bin/bash

LOCKFILE="/var/lib/ldap/configured.lock"

if [ -e /etc/ldap/slapd.conf ] && [ -e $LOCKFILE ]                          
then                                                                                            
  echo "LDAP is already configured."                                                            
  exit 0                                                                                        
fi                                                                                              

if [ ! -e /etc/ldap/slapd.conf ] && [ ! -e $LOCKFILE ]
then
  CREATE_NEW_DB=true
else
  CREATE_NEW_DB=false
fi

if [ ! -e /etc/ldap/slapd.conf ] && [ -e $LOCKFILE ]
then
  echo "LDAP is already configured, but config file does not exists. Recovery in progress..."
#  # backup old database files
  for of in /var/lib/ldap/*mdb
  do
    mv $of $of.bckp
  done
  # search for old backup
  #lf=$( ls -1t /var/lib/ldap/ldap-autobackup-*.ldif | head -n1 )
  VALID=0
  for i in $( ls -1t /var/lib/ldap/ldap-autobackup-*.ldif )
  do
    MAIL_WITHAT=$( grep -iR mail:.*@.* $i | wc -l)
    MAIL_ALL=$( grep -iR mail:.* $i | wc -l )
    [ $VALID -eq 1 ] && { continue; }
    [ $MAIL_WITHAT -eq $MAIL_ALL ] && { echo -e "OK\t$i"; DUMP=$i; VALID=1; } || { echo -e "INVALID\t$i"; rm -f $i; }
  done
  #echo "---$DUMP---"
  lf=$DUMP
  if [ ! -z "$lf" ]
  then
    echo "Found a backup file: $lf"
    recovery=1
  fi
fi

# CLEAN
rm -rf /etc/ldap/slapd.d/*
#rm -rf /var/lib/ldap/*
rm -f $LOCKFILE
chown -R openldap:openldap /var/lib/ldap
chown -R openldap:openldap /etc/ldap/slapd.d

echo "" > /opt/slapd.conf

DOM1=$( echo $DOMAIN | cut -f1 -d'.' )
DOM2=$( echo $DOMAIN | cut -f2 -d'.' )

# include
# order is important!
for f in $( find /etc/ldap/schema/ -iname *.schema )
do
  echo "include $f" >> /opt/slapd.conf
done
cp -f /opt/slapd.conf /tmp/slapd.conf
cat /tmp/slapd.conf | sort > /opt/slapd.conf
i=1
for mod in core.schema cosine.schema inetorgperson.schema nis.schema
do
  ln="$( grep -i $mod /opt/slapd.conf )"
  sed -i "/${mod}/d" /opt/slapd.conf
  sed -i "${i}i $ln" /opt/slapd.conf
  let "i=i+1"
done

# modules
echo "" >> /opt/slapd.conf
echo "modulepath /usr/lib/ldap" >> /opt/slapd.conf
for m in /usr/lib/ldap/*mdb*.la
do
  echo "moduleload $m" >> /opt/slapd.conf
done

#
echo "" >> /opt/slapd.conf
echo database mdb >> /opt/slapd.conf
echo suffix "dc=$DOM1,dc=$DOM2" >> /opt/slapd.conf
echo rootdn "cn=admin,dc=$DOM1,dc=$DOM2" >> /opt/slapd.conf
Apass=$( slappasswd -s $ADMINPASS -n )
echo rootpw $Apass >> /opt/slapd.conf
echo directory /var/lib/ldap >> /opt/slapd.conf

cp -f /opt/slapd.conf /etc/ldap/slapd.conf

# import base structure
#slapadd -c -v -l /opt/ldap-base2.ldif 
if [ $CREATE_NEW_DB == true ]
then
  echo "Creating new empty database..."
  slapadd -c -v -l /opt/ldap-base2.ldif
fi

slaptest -u
if [ $? -eq 0 ]
then
  # note
  date > $LOCKFILE 
else
  echo "ERROR in LDAP config!"
  exit 1 
fi

# recovery
# if the file exists and size is not zero
if [ ! -z $recovery ]
then
  if [ -s "$lf" ]
  then
    echo "Recoverying last backup from $lf file ..."
    slapadd -c -v -l $lf
    if [ $? -eq 0 ]
    then
      echo "LDAP DB recovered."
    fi
  else
    echo "Recover failed. Backup file ( $lf ) not usable. :("
  fi
fi

