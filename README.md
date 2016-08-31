# OpenLDAP in Docker container

This LDAP container implementation contains the default OpenLDAP schemas and the samba schema too.

This is not the best solution, but works :)

You can manage this OpenLDAP from Windows, Linux and OSX with ApacheDS Studio ( http://directory.apache.org/studio/ ), and from the CLI, of course :)

Good Luck! :)


## Build

```
docker build -t sandras/openldap .
```

## Run

```
docker run -tid --name=ldap -p 389:389 -e DOMAIN=mydomain.site -e ADMINPASS=MySecret -v /srv/ldap/extra/:/etc/ldap/schema/extra/ -v /srv/ldap/data/:/var/lib/ldap sandras/openldap /opt/start.sh
```

  - `DOMAIN=mydomain.site` - is your domain name (example: dc=mydomain,dc=site)
  - `ADMINPASS=MySecret` - is your admin password for the `cn=admin,dc=mydomain,dc=site` user
  - the `/srv/ldap/extra` is a directory on your docker host for your custom schema files
  - the `/srv/ldap/data/` folder stores your LDAP database and a backup copy of the `slapd.conf`
  - the container start script generates the LDAP config automatically after the start

After the first start, You have to import the base tree (Domain, People, Group tree) into the LDAP db with this command:

```
docker exec -ti ldap /usr/bin/ldapadd -D cn=admin,dc=mydomain,dc=site -w MySecret -f /opt/ldap-base.ldif
```


## LDAP DB

  - You can stop/start the LDAP container without lose your LDAP database
  - please make a backup (`slapcat > /var/lib/ldap/ldap-dump.ldif`) before you delete (`docker rm -v ldap`) the ldap container. I've tested, you can reuse an old LDAP db in a new container generally, but I don't take responsibility if you can't reuse your DB. Sorry :(

## Export & Import

You can export your full ldap:

```
docker slapcat > /tmp/ldap-dump.ldif
```

You can import your old dump:

```
slapadd -c -v -l /mnt/data/ldap-dump.ldif
```

But if you don't like to overwrite the "admin" user password (and other attributes), please delete the admin user block from the ldif file before the import.

