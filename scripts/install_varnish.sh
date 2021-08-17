yum -y install epel-release
yum -y install varnish

cat << 'EOF' > /etc/varnish/default.vcl
backend default {
  .host = "127.0.0.1";
  .port = "8080";
}
EOF

cat << 'EOF' > /etc/sysconfig/varnish

# Maximum number of open files (for ulimit -n)
NFILES=131072

# Locked shared memory (for ulimit -l)
# Default log size is 82MB + header
MEMLOCK=82000

# Maximum number of threads (for ulimit -u)
NPROCS="unlimited"

# Maximum size of corefile (for ulimit -c). Default in Fedora is 0
# DAEMON_COREFILE_LIMIT="unlimited"

# Set this to 1 to make init script reload try to switch vcl without restart.
# To make this work, you need to set the following variables
# explicit: VARNISH_VCL_CONF, VARNISH_ADMIN_LISTEN_ADDRESS,
# VARNISH_ADMIN_LISTEN_PORT, VARNISH_SECRET_FILE, or in short,
# use Alternative 3, Advanced configuration, below
RELOAD_VCL=1

DAEMON_OPTS="-a :80 \
             -T localhost:6082 \
             -f /etc/varnish/default.vcl \
             -u varnish -g varnish \
             -S /etc/varnish/secret \
             -s file,/var/lib/varnish/varnish_storage.bin,1G"
EOF

sed -i 's/listen 80/listen 8080/g' /etc/nginx/nginx.conf

chkconfig varnish on

service nginx reload
service varnish start
