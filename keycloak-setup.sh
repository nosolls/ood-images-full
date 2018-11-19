#!/bin/bash

# Install keycloak
# Download and unpack Keycloak 4.5.0
cd /opt
sudo curl -o keycloak-4.5.0.Final.tar.gz https://downloads.jboss.org/keycloak/4.5.0.Final/keycloak-4.5.0.Final.tar.gz
sudo tar xzf keycloak-4.5.0.Final.tar.gz

# Add keycloak user and change ownership of files
sudo groupadd -r keycloak
sudo useradd -m -d /var/lib/keycloak -s /sbin/nologin -r -g keycloak keycloak
# if -m doesn't work, do this:
# sudo install -d -o keycloak -g keycloak /var/lib/keycloak
# this makes a home directory, which is needed when running API calls as
# keycloak user
sudo chown keycloak: -R keycloak-4.5.0.Final

# Restrict access to keycloak-4.5.0.Final/standalone, which will contain sensitive data for the Keycloak server
cd keycloak-4.5.0.Final
sudo -u keycloak chmod 700 standalone

# install JDK 1.8.0
yum -y install java-1.8.0-openjdk-devel

# Added ‘admin’ to ‘/opt/keycloak-3.1.0.Final/standalone/configuration/keycloak-add-user.json’, (re)start server to load user
cd /opt/keycloak-4.5.0.Final
openssl rand -hex 20 # generate a password to use for admin user
sudo -u keycloak ./bin/add-user-keycloak.sh --user admin --password KEYCLOAKPASS --realm master

# Modify standalone/configuration/standalone.xml to enable proxying to Keycloak:
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=proxy-address-forwarding,value=true)'
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/socket-binding-group=standard-sockets/socket-binding=proxy-https:add(port=8443)'
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=redirect-socket,value=proxy-https)'

# Create keycloak.service to start and stop the server:
sudo cat > /etc/systemd/system/keycloak.service <<EOF

[Unit]
Description=Jboss Application Server
After=network.target

[Service]
Type=idle
User=keycloak
Group=keycloak
ExecStart=/opt/keycloak-4.5.0.Final/bin/standalone.sh -b 0.0.0.0
TimeoutStartSec=600
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /opt/rh/httpd24/root/etc/httpd/conf.d
#Define apache config to proxy keycloak requests
sudo cat > /opt/rh/httpd24/root/etc/httpd/conf.d/ood-keycloak.conf <<EOF
Listen 8443
<VirtualHost *:8443>
  #ServerName idp.hpc.edu

  ErrorLog  "log/keycloak_error_ssl.log"
  CustomLog "log/keycloack_access_ssl.log" combined

  ## SSL directives
  SSLEngine on
  SSLCertificateFile      "/etc/pki/tls/certs/localhost.crt"
  SSLCertificateKeyFile   "/etc/pki/tls/private/localhost.key"
  SSLCertificateChainFile "/etc/pki/tls/certs/server-chain.crt"
  SSLCACertificatePath    "/etc/pki/tls/certs/ca-bundle.crt"

  # Proxy rules
  ProxyRequests Off
  ProxyPreserveHost On
  ProxyPass / http://localhost:8080/
  ProxyPassReverse / http://localhost:8080/

  ## Request header rules
  ## as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#requestheader
  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "8443"
</VirtualHost>
EOF

sudo iptables -I INPUT -p tcp -m multiport --dports 8443 -m comment --comment "08443 *:8443" -j ACCEPT

# start keycloak
sudo systemctl daemon-reload
sudo systemctl start keycloak