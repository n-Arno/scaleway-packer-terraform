#!/bin/bash
set -e
sleep 20

# Build postgresql TDE
sed -i.bak 's/^# *deb-src/deb-src/g' /etc/apt/sources.list
apt-get update
apt-get install devscripts equivs -y
mk-build-deps postgresql-12 -i -r -t "apt-get --no-install-recommends -y"
mkdir -p /temp-build
cd /temp-build
wget https://download.cybertec-postgresql.com/postgresql-12.3_TDE_1.0.tar.gz
tar xvfz postgresql-12.3_TDE_1.0.tar.gz
cd postgresql-12.3_TDE_1.0
./configure --with-openssl --with-perl --with-python --with-ldap
make install
cd contrib
make install

# Post install
for f in $(ls -1 /usr/local/pgsql/bin/); do ln -s /usr/local/pgsql/bin/$f /usr/local/bin/$f; done
mkdir -p /usr/local/pgsql/{data,private}
adduser --system --quiet --home /usr/local/pgsql/data --no-create-home --shell /bin/bash --group --gecos "PostgreSQL administrator" postgres
echo -e '#!/bin/sh\necho '$(hexdump -vn16 -e'4/4 "%08X" 1 "\n"' /dev/urandom) > /usr/local/pgsql/private/pass.sh
chmod 700 /usr/local/pgsql/private/pass.sh
chown -R postgres:postgres /usr/local/pgsql/data /usr/local/pgsql/private
su - postgres -c '/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data -K /usr/local/pgsql/private/pass.sh'
cat<<EOF>/etc/systemd/system/postgresql.service
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
Type=forking

User=postgres
Group=postgres

# Where to send early-startup messages from the server (before the logging
# options of postgresql.conf take effect)
# This is normally controlled by the global default set by systemd
# StandardOutput=syslog

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000
# ... but allow it still to be effective for child processes
# (note that these settings are ignored by Postgres releases before 9.5)
Environment=PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
Environment=PG_OOM_ADJUST_VALUE=0

# Maximum number of seconds pg_ctl will wait for postgres to start.  Note that
# PGSTARTTIMEOUT should be less than TimeoutSec value.
Environment=PGSTARTTIMEOUT=270

Environment=PGDATA=/usr/local/pgsql/data

ExecStart=/usr/local/pgsql/bin/pg_ctl start -D \${PGDATA} -s -w -t \${PGSTARTTIMEOUT}
ExecStop=/usr/local/pgsql/bin/pg_ctl stop -D \${PGDATA} -s -m fast
ExecReload=/usr/local/pgsql/bin/pg_ctl reload -D \${PGDATA} -s

# Give a reasonable amount of time for the server to start up/shut down.
# Ideally, the timeout for starting PostgreSQL server should be handled more
# nicely by pg_ctl in ExecStart, so keep its timeout smaller than this value.
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

# Clean build dependencies
apt-get purge postgresql-12-build-deps devscripts equivs -y
apt-get autoremove -y
mv /etc/apt/sources.list.bak /etc/apt/sources.list
rm -rf /temp-build
