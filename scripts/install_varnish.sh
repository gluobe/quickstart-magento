yum -y install epel-release
yum -y install varnish

cat << 'EOF' > /etc/varnish/default.vcl
backend default {
  .host = “127.0.0.1”;
  .post = “8080”;
}
EOF

systemctl start varnish
systemctl enable varnish

nginx_config="/etc/nginx/nginx.conf"
nginx_default="listen 80 default_server;"
nginx_varnish="listen 8080 default_server;"

sed -i 's/'$nginx_default'/'$nginx_varnish'/' $nginx_config
