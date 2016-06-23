#!/bin/bash

cp -f /usr/share/doc/samba/examples/LDAP/samba.schema.gz /etc/ldap/schema
gzip -f -d /etc/ldap/schema/samba.schema.gz

exit 0

# ------ not necessary lines below -------
# TODO: clean!

mkdir /etc/ldap/ldif_out

echo "" > /tmp/schema_convert.conf
for i in /etc/ldap/schema/*schema
do
  echo "include $i" >> /tmp/schema_convert.conf
done
cat /tmp/schema_convert.conf | sort > /tmp/schema_convert.conf

sdn="$( slapcat -f /tmp/schema_convert.conf -F /etc/ldap/ldif_out -n 0 | grep samba,cn=schema )"

slapcat -f /tmp/schema_convert.conf -F /etc/ldap/ldif_out -n0 -H "ldap:///$sdn" -l /tmp/cn-samba.ldif
cat /tmp/cn-samba.ldif | sed "s@olcAttributeTypes.*@@g" | sed "s@olcObjectClasses.*@@g" | sed "s@^\ .*@@g" > /tmp/samba.ldif

# import
#ldapadd -f /tmp/samba.ldif

