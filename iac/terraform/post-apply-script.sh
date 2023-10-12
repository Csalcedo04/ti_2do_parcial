#! /bin/sh

sleep 30s

# General
username=$1
ansible_hosts_file="../ansible/hosts"
vars_file="../ansible/vars/main.yml"
username_var=$(echo "username:" $username)
sed -i "1s/.*/$username_var/g" $vars_file

db_hostname=$2
db_public_ip=$3
db_private_key_file=$4

db_host=$(sed 's/[\/&]/\\&/g' <<< $(echo $db_hostname 'ansible_host='$db_public_ip 'ansible_user='$username 'ansible_connection=ssh ansible_ssh_private_key_file='$db_private_key_file))

host_public_ip=$(curl -s ipconfig.org)
ssh_allowed_ip=$(sed 's/[\/&]/\\&/g' <<< $(echo "    src: $host_public_ip"))

firewall_file="../ansible/roles/firewall/tasks/firewall.yml"
app_db_config="../backend/nodejs-express-mysql/app/config/db.config.js"
app_db_host=$(sed 's/[\/&]/\\&/g' <<< $(echo "  HOST: \"$db_public_ip\","))

sed -i "2s/.*/$db_host/g" $ansible_hosts_file
sed -i "6s/.*/$ssh_allowed_ip/g" $firewall_file
sed -i "2s/.*/$app_db_host/g" $app_db_config

cd ../backend/nodejs-express-mysql/
zip -r nodejs-express-mysql.zip .
mv nodejs-express-mysql.zip ..
cd -

az webapp deploy --resource-group parcial2 --name parcial2ipti --src-path ../backend/nodejs-express-mysql.zip

firewall_vars="../ansible/roles/firewall/defaults/main.yml"
app_outbound_ips=$(az webapp show -n parcial2ipti -g parcial2 --query "outboundIpAddresses" | tr -d '"')

IFS=',' read -ra ip_addresses <<< $app_outbound_ips
echo 'ips:' > $firewall_vars
for ip in "${ip_addresses[@]}"; do
    echo "  - $ip" >> $firewall_vars
done

ANSIBLE_CONFIG=../ansible/ansible.cfg ansible-playbook ../ansible/run.yml
