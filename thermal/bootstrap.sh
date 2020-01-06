#!/bin/bash

# Color
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`
bold=`tput bold`

thermal_config_wp_dir="."
thermal_config_wp_version="latest"

_parse_yaml() {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
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

if [ -f $(sudo find / -name "thermal-config.yml") ]; then
  eval $(_parse_yaml $(sudo find / -name "thermal-config.yml") "thermal_")
else
  echo "${red}Error:${reset} Thermal config not found."

  return 1
fi

thermal_apache_servername_update () {
  echo
  echo "Updating Apache server..."
  echo

  sudo sed -i "s:ServerName thermal.test:ServerName "${thermal_config_name}":g" /etc/apache2/sites-available/thermal.conf

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Could not update Apache server."
    echo
    echo "Command: ${bold}${yellow}sudo sed -i "s:ServerName thermal.test:ServerName "${thermal_config_name}":g" /etc/apache2/sites-available/thermal.conf${reset}"

    return 1
  fi

  sudo sed -i "s:/var/www:"${thermal_config_wp_dir}":g" /etc/apache2/sites-available/thermal.conf

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Could not update Apache server."
    echo
    echo "Command: ${bold}${yellow}sudo sed -i "s:/var/www:"${thermal_config_wp_dir}":g" /etc/apache2/sites-available/thermal.conf${reset}"

    return 1
  fi

  sudo sed -i "s:ServerName status.thermal.test:ServerName status."${thermal_config_name}":g" /etc/apache2/sites-available/thermal.conf

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Could not update Apache server for status page."
    echo
    echo "Command: ${bold}${yellow}sudo sed -i "s:ServerName status.thermal.test:ServerName status."${thermal_config_name}":g" /etc/apache2/sites-available/thermal.conf${reset}"

    return 1
  fi

  sudo service apache2 restart

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Could not restart Apache."
  else
    echo "${green}Successfully updated Apache server.${reset}"
  fi
}

thermal_check_db () {
  echo
  echo "Checking database connection..."
  echo

  wp db check --quiet --path=/var/www/"${thermal_config_wp_dir}" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Could not connect to database.${reset}"
    echo
    echo "Exiting..."

    exit 1
  else
    echo "${green}Successfully connected to database.${reset}"
  fi
}

thermal_apache_servername_update

# Check for WordPress main files
if [ -f /var/www/"${thermal_config_wp_dir}"/wp-includes/version.php ] || [ $(find "/var/www/"${thermal_config_wp_dir}"" -name wp-config.php 2> /dev/null) ]; then
  echo
  echo "WordPress core detected."
else

  # If not found download WordPress
  wp core download --path=/var/www/"${thermal_config_wp_dir}" --quiet --skip-content --version="${thermal_config_wp_version}"

  if [ $? -ne 0 ]; then
    echo
    echo "Skipping WordPress core download. Files may already exist in ${thermal_config_wp_dir}."
  fi
fi

# Check for wp-config.php then check database connection
if [ $(find "/var/www/"${thermal_config_wp_dir}"" -name wp-config.php 2> /dev/null) ]; then
  thermal_check_db
else
  echo
  echo "${blue}Creating wp-config.php...${reset}"
  echo

  wp core config --dbname="thermal" --dbuser="root" --dbpass="root" --dbhost="localhost" --dbprefix="wp_" --path=/var/www/"${thermal_config_wp_dir}" --quiet

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Failed to create wp-config.php file."
    echo
    echo "Command: ${bold}${yellow}wp core config --dbname="thermal" --dbuser="root" --dbpass="root" --dbhost="localhost" --dbprefix="wp_" --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    echo "${green}Successfully created wp-config.php.${reset}"
  fi

  thermal_check_db
fi

# Check if WordPress installed in database
wp core is-installed --path=/var/www/"${thermal_config_wp_dir}" --quiet > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo
  echo "Installing WordPress..."
  echo

  wp core install --admin_email="thermal@thermal.test" --admin_password="vagrant" --admin_user="thermal" --path=/var/www/"${thermal_config_wp_dir}" --quiet --skip-email --url="${thermal_config_name}" --title="Thermal" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Could not install WordPress.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp core install --quiet --skip-email --path=/var/www/"${thermal_config_wp_dir}" --url="${thermal_config_name}" --title="Thermal" --admin_user="thermal" --admin_password="vagrant" --admin_email="thermal@thermal.test"${reset}"
    echo
  else
    echo "${green}Successfully installed WordPress.${reset}"
    echo
  fi
fi

# Check if plugins directory exists
if [ ! -d /var/www/"${thermal_config_wp_dir}"/wp-content/plugins ]; then
  mkdir /var/www/"${thermal_config_wp_dir}"/wp-content/plugins

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not create plugins directory.${reset}"
    echo
    echo "Command: ${bold}${yellow}mkdir /var/www/"${thermal_config_wp_dir}"/wp-content/plugins${reset}"
    echo
  fi
fi

# Check if themes directory exists
if [ ! -d /var/www/"${thermal_config_wp_dir}"/wp-content/themes ]; then
  mkdir /var/www/"${thermal_config_wp_dir}"/wp-content/themes

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not create themes directory.${reset}"
    echo
    echo "Command: ${bold}${yellow}mkdir /var/www/"${thermal_config_wp_dir}"/wp-content/themes${reset}"
    echo
  fi
fi

# Pass config variable to status page
sudo sed -i "s:thermal_config_name = 'thermal.test':thermal_config_name = '"${thermal_config_name}"':g" /var/www/"${thermal_config_wp_dir}"/thermal/status.php
sudo sed -i "s:thermal_config_site = 'site-url.com':thermal_config_site = '"${thermal_config_site}"':g" /var/www/"${thermal_config_wp_dir}"/thermal/status.php

# Correct permission of public key
chmod 600 ~/.ssh/id_rsa

# Install Thermal
echo ". "${thermal_config_wp_dir}"/thermal/thermal.sh" >> ~/.profile

if [ $? -ne 0 ]; then
  echo
  echo "${red}Error:${reset} Could not install Thermal.${reset}"
  echo
  echo "Command: ${bold}${yellow}. "${thermal_config_wp_dir}"/thermal/thermal.sh${reset}"
  echo
fi

echo
echo "${green}Finished provisioning.${reset}"
echo
echo "Run ${bold}${yellow}vagrant ssh${reset} to use Thermal."
echo