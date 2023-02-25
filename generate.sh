#!/bin/sh

# Create a function to parse a YAML file and save the value of a key in a variable with the same name as the key (the configuration file is a YAML file)
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}





# Get the full name of the file (lcg.sh) and save it in a variable $SCRIPT_NAME
SCRIPT_NAME=$(basename "$0")

# Check if the script is called from the current directory or not, if not, exit
if [ ! -f "$SCRIPT_NAME" ]
then
  echo " ❌  Error: You must run this script from the scripts directory"
  exit 1
fi





echo " 🔎 Searching for the configuration file..."
printf "\n"

# Read the configuration file named "config.yml" or "config.yaml" and save it in a variable $CONFIG_FILE
CONFIG_FILE=$(find . -name "config.yml" -o -name "config.yaml" | head -n 1)

# check if the configuration file exists or not, if not, exit
if [ ! -f "$CONFIG_FILE" ]
then
  echo " ❌  Error: The configuration file does not exist"
  exit 1
fi

echo "    ✓ Configuration file found: $CONFIG_FILE"
printf "\n"





# Parse the configuration file with the function parse_yaml and
# save the values of the keys in variables with the same name as the keys
eval "$(parse_yaml "$CONFIG_FILE" "CONF_")"





# Check if the common name is empty or not, if yes, exit
if [ -z "$CONF_common_name" ]
then
  echo " ❌  Error: The common name is empty"
  exit 1
fi

# Check if the destination is empty or not, if yes, exit
if [ -z "$CONF_dest" ]
then
  echo " ❌  Error: The destination is empty"
  exit 1
fi

# Check if the domain is empty or not, if yes, exit
if [ -z "$CONF_domain" ]
then
  echo " ❌  Error: The domain is empty"
  exit 1
fi

# Check if the days is empty or not, if yes, set the default value to 1825
if [ -z "$CONF_options_days" ]
then
  CONF_options_days=1825
fi

# Check if the country name is empty or not, if yes, set the default value to FR
if [ -z "$CONF_options_details_country_name" ]
then
  CONF_options_details_country_name=JP
fi

# Check if the country name has a length of 2 or not, if not, exit
if [ ${#CONF_options_details_country_name} -ne 2 ]
then
  echo " ❌  Error: The country name must have a length of 2"
  exit 1
fi

# Check if the state or province name is empty or not, if yes, set the default value to Tokyo
if [ -z "$CONF_options_details_state_or_province_name" ]
then
  CONF_options_details_state_or_province_name=Tokyo
fi

# Check if the locality name is empty or not, if yes, set the default value to Tokyo
if [ -z "$CONF_options_details_locality_name" ]
then
  CONF_options_details_locality_name=Tokyo
fi

# Check if the organization name is empty or not, if yes, set the default value to Might Tower
if [ -z "$CONF_options_details_organization_name" ]
then
  CONF_options_details_organization_name="Might Tower"
fi

# Check if the organizational unit name is empty or not, if yes, set the default value to Heroes Department
if [ -z "$CONF_options_details_organizational_unit_name" ]
then
  CONF_options_details_organizational_unit_name="Heroes Department"
fi






# Check if the subdomain wildcard is equal to true or not, if yes, set the default value to false
if [ "$CONF_options_subdomain_wildcard" = "true" ]
then
  CONF_options_subdomain_wildcard=true
else
  CONF_options_subdomain_wildcard=false
fi






# The configuration to use for the certificate (default values and values from the configuration file)
echo " 👀 The configuration to use for the certificate (default values and values from the configuration file):"
echo "      - common_name: $CONF_common_name"
echo "      - dest: $CONF_dest"
echo "      - domain: $CONF_domain"
echo "      - options:"
echo "        - days: $CONF_options_days"
echo "        - details:"
echo "          - country_name: $CONF_options_details_country_name"
echo "          - state_or_province_name: $CONF_options_details_state_or_province_name"
echo "          - locality_name: $CONF_options_details_locality_name"
echo "          - organization_name: $CONF_options_details_organization_name"
echo "          - organizational_unit_name: $CONF_options_details_organizational_unit_name"
echo "        - subdomain wildcard: $CONF_options_subdomain_wildcard"






printf "\n"
echo " 🗑️ Removing the old SSL certificates..."
printf "\n"

# Check if the $CONF_dest directory exists or not, if yes, remove files in it
if [ -d "$CONF_dest" ]
then
  rm -rf "${CONF_dest:?}/*"
  echo "    ✓ The old SSL certificates have been removed"
else
  mkdir "$CONF_dest"
  echo "    ✓ The destination directory has been created"
fi






cd "$CONF_dest" || exit






printf "\n"
echo " 📝 Generating the secret passphrase used for the certificates..."
# Set the passphrase to a random string of 16 characters (letters, special characters and numbers)
PASSPHRASE=$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9!@#$%^&*()_+' | fold -w 16 | head -n 1)
echo "Secret passphrase used for the certificates: $PASSPHRASE" > passphrase.txt

printf "\n"
echo "    ✓ The secret passphrase used for the certificates has been generated"
printf "\n"






echo " 📝 Generating the private key..."
printf "\n"

expect -c "
  spawn openssl genrsa -des3 -out myCA.key 2048
  expect \"Enter pass phrase for myCA.key:\"
  send \"$PASSPHRASE\r\"
  expect \"Verifying - Enter pass phrase for myCA.key:\"
  send \"$PASSPHRASE\r\"
  expect eof"

printf "\n"
echo "    ✓ The private key for the certificate authority (myCA.key) has been generated"
printf "\n"






echo " 📝 Generating the certificate..."
printf "\n"

openssl req -x509 -new -nodes -key myCA.key -sha256 -days $CONF_options_days -out myCA.pem -passin pass:"$PASSPHRASE" -passout \
pass:"$PASSPHRASE" -subj "/CN=$CONF_common_name/C=$CONF_options_details_country_name/ST=$CONF_options_details_state_or_province_name/L=$CONF_options_details_locality_name/O=$CONF_options_details_organization_name/OU=$CONF_options_details_organizational_unit_name"

echo "    ✓ The certificate for $CONF_common_name (myCA.pem) has been generated"
printf "\n"






echo " 🧠 Setting up the certificate authority..."
printf "\n"

sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" myCA.pem

echo "    ✓ The certificate authority has been set up"
printf "\n"






echo " 📝 Generating the private key for the domain..."
printf "\n"

openssl genrsa -out $CONF_domain.key 2048

echo "    ✓ The private key for the domain ($CONF_domain.key) has been generated"
printf "\n"






# Create a variable to domain name with wildcard if the subdomain wildcard is equal to true
if [ "$CONF_options_subdomain_wildcard" = true ]
then
  DOMAIN_WILDCARD="*.${CONF_domain}"
else
  DOMAIN_WILDCARD="$CONF_domain"
fi






echo " 📝 Generating the certificate signing request for the domain..."
printf "\n"

openssl req -new -key "$CONF_domain".key -out "$CONF_domain".csr -subj "/CN=$DOMAIN_WILDCARD/C=$CONF_options_details_country_name/ST=$CONF_options_details_state_or_province_name/L=$CONF_options_details_locality_name/O=$CONF_options_details_organization_name/OU=$CONF_options_details_organizational_unit_name"

printf "\n"
echo "    ✓ The certificate signing request for the domain ($CONF_domain.csr) has been generated"
printf "\n"






echo " 📝 Generating the certificate extension file for the domain..."
printf "\n"

cat > "$CONF_domain".ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN_WILDCARD
EOF

echo "    ✓ The certificate extension file for the domain ($CONF_domain.ext) has been generated"
printf "\n"






echo " 📝 Generating the certificate for the domain..."
printf "\n"

openssl x509 -req -in "$CONF_domain".csr -CA myCA.pem -CAkey myCA.key \
 -CAcreateserial -out "$CONF_domain".crt -days $CONF_options_days -sha256 -extfile "$CONF_domain".ext -passin pass:"$PASSPHRASE"

printf "\n"
echo "    ✓ The certificate for the domain ($CONF_domain.crt) has been generated"
printf "\n"






echo " 🧠 Setting up the certificate for the domain..."
printf "\n"

sudo security add-trusted-cert -d -r trustAsRoot -k "/Library/Keychains/System.keychain" "$CONF_domain".crt

echo "    ✓ The certificate for the domain has been set up"
printf "\n"






echo " ✅  The SSL certificates have been generated"
printf "\n"

cd - || exit