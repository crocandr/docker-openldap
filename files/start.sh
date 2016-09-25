#!/bin/bash

if [ -z $DEBUGLEVEL ]
then
  DL=0
else
  DL=$DEBUGLEVEL
fi

if [ -z "$DOMAIN" ]
then
  echo "no DOMAIN defined! (example: mydomain.com )"
  DOMAIN="example.com"
  #exit 1
fi

if [ -z "$ADMINPASS" ]
then
  echo "Admin user password not defined! (default is: secret)"
  ADMINPASS="secret"
fi

DOM1=$( echo $DOMAIN | cut -f1 -d'.' )
DOM2=$( echo $DOMAIN | cut -f2 -d'.' )

BASEFILE="/opt/ldap-base.ldif"
sed -i s@--DOMAIN--@$DOMAIN@g $BASEFILE 
sed -i s@--DOM1--@$DOM1@g $BASEFILE
sed -i s@--DOM2--@$DOM2@g $BASEFILE 

# config ldap
/opt/ldap-config.sh

# start ldap
echo "Starting LDAP service..."
slapd -d $DL 

#slapadd -F /etc/ldap/ldap-config -l /opt/01-ldap-base.ldif
#slapd -F /etc/ldap/ldap-config

# LAST LINE
#/bin/bash

