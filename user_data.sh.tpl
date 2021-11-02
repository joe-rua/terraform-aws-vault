#!/bin/bash

# Always update packages installed.
yum update -y

# Add the HashiCorp RPM repository.
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install a specific version of Vault.
yum install -y vault-${vault_version}

# Allow IPC lock capability to Vault.
setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

# Make a directory for Raft, certificates and init information.
mkdir -p /vault/data
chown vault:vault /vault/data
chmod 750 /vault/data

# 169.254.169.254 is an Amazon service to provide information about itself.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"

# Place TLS material.
mkdir /etc/vault.d/tls
chown vault:vault /etc/vault.d/tls
echo "${ca_key}" > /etc/vault.d/tls/vault_ca.pem
echo "${ca_cert}" > /etc/vault.d/tls/vault_ca.crt
chown vault:vault /etc/vault.d/tls/*
chmod 750 /etc/vault.d/tls
chmod 640 /etc/vault.d/tls/*

cat << EOF > /etc/vault.d/tls/ca.conf
[ ca ]
default_ca = ca_default
[ ca_default ]
dir = /etc/vault.d/tls/
certs = \$dir
new_certs_dir = \$dir/ca.db.certs
database = \$dir/ca.db.index
serial = \$dir/ca.db.serial
RANDFILE = \$dir/ca.db.rand
certificate = \$dir/vault_ca.crt
private_key = \$dir/vault_ca.pem
default_days = 365
default_crl_days = 30
default_md = md5
preserve = no
policy = generic_policy
[ generic_policy ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = optional
emailAddress = optional
EOF

mkdir /etc/vault.d/tls/ca.db.certs
touch /etc/vault.d/tls/ca.db.index
echo "1234" > /etc/vault.d/tls/ca.db.serial

# Describe the CSR details in a file.
cat << EOF > /etc/vault.d/tls/csr_details.txt
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=NL
ST=UTRECHT
L=Breukelen
O=Very little to none.
OU=IT Department
CN = $${my_ipaddress}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1  = $${my_ipaddress}
DNS.1 = $${my_hostname}
EOF

openssl req -new -sha256 -nodes -out /etc/vault.d/tls/vault.csr -newkey rsa:2048 -keyout /etc/vault.d/tls/vault.key -config /etc/vault.d/tls/csr_details.txt

# Sign the csr, create the crt for this instance.
openssl ca -batch -config /etc/vault.d/tls/ca.conf -out /etc/vault.d/tls/vault.crt -infiles /etc/vault.d/tls/vault.csr

# Append the ca to the certificate.
cat /etc/vault.d/tls/vault_ca.crt >> /etc/vault.d/tls/vault.crt

# Place the Vault configuration.
cat << EOF > /etc/vault.d/vault.hcl
ui=true

storage "raft" {
  path = "/vault/data"
  node_id = "$${my_hostname}"
  retry_join {
    auto_join               = "provider=aws tag_key=name tag_value=${name}-${random_string} region=${region}"
    auto_join_scheme        = "https"
    leader_ca_cert_file     = "/etc/vault.d/tls/vault_ca.crt"
    leader_client_cert_file = "/etc/vault.d/tls/vault.crt"
    leader_client_key_file  = "/etc/vault.d/tls/vault.key"
  }
}

cluster_addr = "https://$${my_ipaddress}:8201"
api_addr = "https://$${my_ipaddress}:8200"

listener "tcp" {
  address            = "$${my_ipaddress}:8200"
  tls_client_ca_file = "/etc/vault.d/tls/vault_ca.crt"
  tls_cert_file      = "/etc/vault.d/tls/vault.crt"
  tls_key_file       = "/etc/vault.d/tls/vault.key"
}

seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

# Start and enable Vault.
systemctl --now enable vault

# Allow users to use `vault`.
echo "export VAULT_ADDR=https://$${my_ipaddress}:8200" >> /etc/profile
echo "export VAULT_SKIP_VERIFY=1" >> /etc/profile
