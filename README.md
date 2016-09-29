# OpenLDAP in Docker container

This LDAP container implementation contains the default OpenLDAP schemas and the samba schema too.

This is not the best solution, but works :)

You can manage this OpenLDAP from Windows, Linux and OSX with ApacheDS Studio ( http://directory.apache.org/studio/ ), and from the CLI and with webmin too, of course :)

Good Luck! :)


## Build

```
docker build -t croc/openldap .
```

## Run

```
docker run -tid --name=ldap -p 389:389 -e DOMAIN=mydomain.site -e ADMINPASS=MySecret -v /srv/ldap/extra/:/etc/ldap/schema/extra/ -v /srv/ldap/data/:/var/lib/ldap croc/openldap /opt/start.sh
```

  - `DOMAIN=mydomain.site` - is your domain name (example: dc=mydomain,dc=site)
  - `ADMINPASS=MySecret` - is your admin password for the `cn=admin,dc=mydomain,dc=site` user
  - the `/srv/ldap/extra` is a directory on your docker host for your custom schema files
  - the `/srv/ldap/data/` folder stores your LDAP database and a backup copy of the `slapd.conf`
  - the container start script generates the LDAP config automatically after the start
  - if You define the `-e DEBUGLEVEL=9` parameter, the slapd daemon start verbose output in the container, default is 0 (no debugging)

The LDAP containers creates the basic LDAP tree automatically at the first start.
And creates a backup into the LDAP folder from the LDAP tree at every start. The backup file format is: `ldap-autobackup-<date>-<time>.ldif`. Please, do not overwrite or change these backup files!

## LDAP DB

  - You can stop/start the LDAP container without lose your LDAP database
  - please make a backup (`slapcat > /var/lib/ldap/ldap-dump.ldif`) before you delete (`docker rm -v ldap`) the ldap container. I've tested, you can reuse an old LDAP db in a new container generally, but I don't take responsibility if you can't reuse your DB. Sorry :(

## Container Update

If you stop and delete the ldap container, and run a new one (= container update), the container tries to recover the full LDAP tree from the latest autobackup file.
If the recover fails, please try remove empty or damaged autobackup files from the data folder of your ldap container.

## Export & Import & Backup

You can export your full ldap in the container:

```
slapcat > /tmp/ldap-dump.ldif
```

You can import your old dump in the container:

```
slapadd -c -v -l /tmp/ldap-dump.ldif
```

But if you don't like to overwrite the "admin" user password (and other attributes), please delete the admin user block from the ldif file before importing.


You can create a backup from the LDAP tree on your docker host at any time.

Example:

```
docker exec -ti ldap slapcat > /myfolder/ldap-backup-$( date +"%Y%m%d-%H%M ).ldif
```

