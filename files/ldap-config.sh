#!/bin/bash

if [ ! -e /etc/ldap/slapd.conf ] && [ -e /var/lib/ldap/slapd.conf ]
then
  # recovery old config
  cp -f /var/lib/ldap/slapd.conf /etc/ldap/slapd.conf
fi

if [ ! -e /etc/ldap/slapd.conf ] && [ ! -e /var/lib/ldap/slapd.conf ]
then
  # unlock ldap for reconfig
  rm -f /var/lib/ldap/configured.lock
fi

if [ -e /var/lib/ldap/configured.lock ]
then
  echo "LDAP is already configured."
  exit 0
fi

# CLEAN
#if [ ! -e /etc/ldap/slapd.conf ]
#if [ ! -e /var/lib/ldap/configured.lock ]
#then
rm -rf /etc/ldap/slapd.d/*
rm -rf /var/lib/ldap/*
chown -R openldap:openldap /var/lib/ldap
chown -R openldap:openldap /etc/ldap/slapd.d
#fi


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

slaptest -u
if [ $? -eq 0 ]
then
  cp -f /etc/ldap/slapd.conf /var/lib/ldap
  date > /var/lib/ldap/configured.lock
else
  echo "ERROR in LDAP config!"
  exit 1 
fi
