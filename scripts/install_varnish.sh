yum -y install epel-release
yum -y install varnish

cat << 'EOF' > /etc/varnish/default.vcl
backend default {
  .host = “127.0.0.1”;
  .post = “8080”;
}
EOF

sed -i 's/listen 80/listen 8080/g' /etc/nginx/nginx.conf

service nginx reload
service varnish start
