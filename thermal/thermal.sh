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

thermal_config_backup_dir=".thermal-backup"
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

if [ -f ../thermal-config.yml ]; then
  eval $(_parse_yaml ../thermal-config.yml "thermal_")
else
  eval $(_parse_yaml thermal-config.yml "thermal_")
fi

thermal_backup_local () {
  db_backup_local_succeeded=false
}

thermal_check_backup_dir () {
  backup_dir_local_exists=false
  backup_dir_remote_exists=false

  echo
  echo "${bold}${blue}Checking local backup directory...${reset}"
  echo

  if [ -d /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}" ]; then
    backup_dir_local_exists=true

    echo
    echo "${green}Local backup directory located in: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
    echo
  else
    echo
    echo "${red}Could not locate local backup directory.${reset}"
    echo
  fi

  touch /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Local backup directory not writable."
    echo
    echo "Directory: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
    echo
  else
    rm /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1
  fi

  echo
  echo "${bold}${blue}Checking remote backup directory...${reset}"
  echo

  ssh -q "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" -o ConnectTimeout=10 [ -d "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}" ] > /dev/null 2>&1 && backup_dir_remote_exists=true || backup_dir_remote_exists=false; > /dev/null 2>&1

  if [ ${backup_dir_remote_exists} == true ]; then
    echo
    echo "${green}Remote backup directory located in: ${bold}${yellow}"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"${reset}"
    echo
  else
    echo
    echo "${red}Could not locate remote backup directory.${reset}"
    echo
  fi

  ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" touch "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Remote backup directory not writable."
    echo
    echo "Directory: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
    echo
  else
    ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" rm "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1
  fi
}

thermal_check_database () {
  check_database_succeeded=false

  echo
  echo "${bold}${blue}Checking database...${reset}"
  echo

  wp db check --path=/var/www/"${thermal_config_wp_dir}" --quiet

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Cannot connect to database.${reset}"
    echo

    return 1
  else
    check_database_succeeded=true

    echo
    echo "${bold}${green}Successfully connected to database.${reset}"
    echo
  fi
}

thermal_check_key () {
  cat ~/.ssh/id_rsa.pub

  if [ $? -ne 0 ]; then
    echo "${red}Error:${reset} Public key not found.${reset}"
    echo

    return 1
  fi
}

thermal_check_ssh () {
  check_ssh_succeeded=false

  ssh -q "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" -o ConnectTimeout=10 exit

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not connect via SSH.${reset}"
    echo
    echo "Command: ${bold}${yellow}ssh -q "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" -o ConnectTimeout=10 exit${reset}"

    return 1
  else
    check_ssh_succeeded=true

    echo
    echo "${bold}${green}Successfully connected to database.${reset}"
    echo
  fi
}

thermal_db_export_local () {
  db_export_local_succeeded=false

  wp db export /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not export local database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db export /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    db_export_local_succeeded=true

    echo
    echo "${bold}${green}Successfully exported local database.${reset}"
  fi
}

thermal_db_export_local_old () {
  db_export_local_old_succeeded=false

  wp db export /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql-old.sql --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not export old local database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db export /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql-old.sql --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    db_export_local_old_succeeded=true

    echo
    echo "${bold}${green}Successfully exported old local database.${reset}"
  fi
}

thermal_db_local_import_local () {
  db_local_import_local_succeeded=false

  wp db import /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to import database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db import /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    db_local_import_local_succeeded=true

    echo
    echo "${bold}${green}Successfully imported database.${reset}"
  fi
}

thermal_db_local_import_remote () {
  db_local_import_remote_succeeded=false

  wp db import /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to import database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db import /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    db_local_import_remote_succeeded=true

    echo
    echo "${bold}${green}Successfully imported database.${reset}"
  fi
}

thermal_db_upload_local () {
  db_upload_local_succeeded=false

  echo
  echo "${bold}${blue}Uploading SQL file...${reset}"
  echo

  # Upload SQL file
  scp /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql

  if [ $? -ne 0 ]; then
    echo
    echo "Retrying..."
    echo

    scp /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql

    if [ $? -ne 0 ]; then
      echo "${red}Error:${reset} Could not upload SQL file.${reset}"
      echo
      echo "Command: ${bold}${yellow}scp /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql${reset}"

      return 1
    else
      db_upload_local_succeeded=true

      echo "${bold}${green}SQL upload complete.${reset}"
      echo
    fi
  else
    db_upload_local_succeeded=true

    echo
    echo "${bold}${green}SQL upload complete.${reset}"
    echo
  fi
}

thermal_db_download_remote () {
  db_download_remote_succeeded=false

  echo
  echo "${bold}${blue}Downloading SQL file...${reset}"
  echo

  # Download SQL file
  scp "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql

  if [ $? -ne 0 ]; then
    echo
    echo "Retrying..."
    echo

    scp "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql

    if [ $? -ne 0 ]; then
      echo "${red}Error:${reset} Could not download SQL file.${reset}"

      return 1
    else
      db_download_remote_succeeded=true

      echo
      echo "${bold}${green}SQL download complete.${reset}"
      echo
    fi
  else
    db_download_remote_succeeded=true

    echo
    echo "${bold}${green}SQL download complete.${reset}"
    echo
  fi
}

thermal_db_export_remote () {
  db_export_remote_succeeded=false

  wp db export "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not export remote database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db export "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"${reset}"
  else
    db_export_remote_succeeded=true

    echo
    echo "${bold}${green}Successfully exported remote database.${reset}"
  fi
}

thermal_db_export_remote_old () {
  db_export_remote_old_succeeded=false

  wp db export "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql-old.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not export old remote database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db export "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql-old.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"${reset}"
  else
    db_export_remote_old_succeeded=true

    echo
    echo "${bold}${green}Successfully exported old remote database.${reset}"
  fi
}

thermal_db_remote_import_local () {
  db_remote_import_local_succeeded=false

  wp db import "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to import database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db import "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_mysql.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"${reset}"
  else
    db_remote_import_local_succeeded=true

    echo
    echo "${bold}${green}Successfully imported database.${reset}"
  fi
}

thermal_db_remote_import_remote () {
  db_remote_import_remote_succeeded=false

  wp db import "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to import database.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp db import "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_mysql.sql --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"${reset}"
  else
    db_remote_import_remote_succeeded=true

    echo
    echo "${bold}${green}Successfully imported database.${reset}"
  fi
}

thermal_flush_cache_local () {
  flush_cache_local_succeeded=false

  echo
  echo "${bold}${blue}Flushing local cache...${reset}"
  echo

  wp cache flush --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to flush local cache.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp cache flush --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    flush_cache_local_succeeded=true

    echo
    echo "${bold}${green}Successfully flushed local cache.${reset}"
  fi
}

thermal_flush_cache_remote () {
  flush_cache_remote_succeeded=false

  echo
  echo "${bold}${blue}Flushing remote cache...${reset}"
  echo

  wp cache flush --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to flush remote cache.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp cache flush --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"${reset}"
  else
    flush_cache_remote_succeeded=true

    echo
    echo "${bold}${green}Successfully flushed remote cache.${reset}"
  fi
}

thermal_flush_rewrite_local () {
  flush_rewrite_local_succeeded=false

  echo
  echo "${bold}${blue}Flushing local rewrite rules...${reset}"
  echo

  wp rewrite flush --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to flush local rewrite rules.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp rewrite flush --path=/var/www/"${thermal_config_wp_dir}"${reset}"
  else
    flush_rewrite_local_succeeded=true

    echo
    echo "${bold}${green}Successfully flushed local rewrite rules.${reset}"
  fi
}

thermal_flush_rewrite_remote () {
  flush_rewrite_remote_succeeded=false

  echo
  echo "${bold}${blue}Flushing remote rewrite rules...${reset}"
  echo

  wp rewrite flush --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Failed to flush remote rewrite rules.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp rewrite flush --path="${thermal_config_ssh_path}" --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}"${reset}"
  else
    flush_rewrite_remote_succeeded=true

    echo
    echo "${bold}${green}Successfully flushed remote rewrite rules.${reset}"
  fi
}

thermal_repair_backup_dir () {
  backup_dir_local_exists=false
  backup_dir_remote_exists=false

  echo
  echo "${bold}${blue}Checking local backup directory...${reset}"
  echo

  if [ -d /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}" ]; then
    backup_dir_local_exists=true

    echo "${green}Local backup directory located in: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
  else
    echo "Creating ${yellow}${thermal_config_backup_dir}${reset} directory..."
    echo

    mkdir /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"

    if [ $? -ne 0 ]; then
      echo
      echo "${red}Could not create backup directory.${reset}"
      echo
      echo "Command: ${bold}${yellow}mkdir /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
    else
      backup_dir_local_exists=true

      echo "${green}Local backup directory located in: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
    fi
  fi

  touch /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Local backup directory not writable."
    echo
    echo "Directory: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
  else
    rm /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1
  fi

  echo
  echo "${bold}${blue}Checking remote backup directory...${reset}"
  echo

  ssh -q "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" -o ConnectTimeout=10 [ -d "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}" ] > /dev/null 2>&1 && backup_dir_remote_exists=true || backup_dir_remote_exists=false; > /dev/null 2>&1

  if [ ${backup_dir_remote_exists} == true ]; then
    echo "${green}Remote backup directory located in: ${bold}${yellow}"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"${reset}"
    echo
  else
    echo "Creating ${yellow}${thermal_config_backup_dir}${reset} directory..."

    ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" mkdir "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"

    if [ $? -ne 0 ]; then
      echo
      echo "${red}Could not create backup directory.${reset}"
      echo
      echo "Command: ${bold}${yellow}mkdir /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
    else
      backup_dir_remote_exists=true

      echo "${green}Remote backup directory located in: ${bold}${yellow}"${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"${reset}"
    fi
  fi

  ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" touch "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Remote backup directory not writable."
    echo
    echo "Directory: ${bold}${yellow}"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"${reset}"
  else
    ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" rm "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/test_writable > /dev/null 2>&1
  fi
}

thermal_repair_database () {
  echo
  echo "${bold}${blue}Repairing database...${reset}"
  echo

  if [ ! $(find "/var/www/"${thermal_config_wp_dir}"" -name wp-config.php) ]; then
    echo
    echo "Config file wp-config.php not found with command: ${bold}${yellow}$(find "/var/www/"${thermal_config_wp_dir}"" -name wp-config.php)${reset}"
    echo
    echo "${blue}Creating wp-config.php...${reset}"

    wp core config --dbname="thermal" --dbuser="root" --dbpass="root" --dbhost="localhost" --dbprefix="wp_" --path=/var/www/"${thermal_config_wp_dir}" --quiet

    if [ $? -ne 0 ]; then
      echo
      echo "${red}Error:${reset} Failed to create wp-config.php file."
      echo
      echo "Command: ${bold}${yellow}wp core config --dbname="thermal" --dbuser="root" --dbpass="root" --dbhost="localhost" --dbprefix="wp_" --path=/var/www/"${thermal_config_wp_dir}"${reset}"
      echo
    else
      echo
      echo "${bold}${green}Created wp-config.php file.${reset}"
    fi
  fi

  echo
  echo "${bold}${blue}Updating wp-config.php settings...${reset}"

  wp config set DB_NAME thermal --path=/var/www/"${thermal_config_wp_dir}" --quiet
  wp config set DB_USER root --path=/var/www/"${thermal_config_wp_dir}" --quiet
  wp config set DB_PASSWORD root --path=/var/www/"${thermal_config_wp_dir}" --quiet
  wp config set DB_HOST lcoalhost --path=/var/www/"${thermal_config_wp_dir}" --quiet
  wp config set table_prefix wp_ --path=/var/www/"${thermal_config_wp_dir}" --quiet

  echo
  echo "${bold}${blue}Checking connection to database...${reset}"

  wp db check --path=/var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Cannot connect to database."
  else
    echo
    echo "${bold}${green}Successful connection to database.${reset}"
  fi
}

thermal_db_search_replace_local () {
  db_search_replace_local_succeeded=false

  echo
  echo "${bold}${blue}Running database search replace...${reset}"

  wp search-replace "${thermal_config_site}" "${thermal_config_name}" --path=/var/www/"${thermal_config_wp_dir}" --quiet > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${yellow}Search replace failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp search-replace "${thermal_config_site}" "${thermal_config_name}" --path=/var/www/"${thermal_config_wp_dir}" --quiet${reset}"
  else
    db_search_replace_local_succeeded=true

    echo
    echo "${bold}${green}Completed database search replace.${reset}"
  fi
}

thermal_db_search_replace_remote () {
  db_search_replace_remote_succeeded=false

  echo
  echo "${bold}${blue}Running database search replace...${reset}"

  wp search-replace --path="${thermal_config_ssh_path}" --quiet --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" "${thermal_config_name}" "${thermal_config_site}" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${yellow}Search replace failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}wp search-replace --path="${thermal_config_ssh_path}" --quiet --ssh="${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" "${thermal_config_name}" "${thermal_config_site}"${reset}"
  else
    db_search_replace_remote_succeeded=true

    echo
    echo "${bold}${green}Completed database search replace.${reset}"
  fi
}

thermal_help () {
  cat << EOF

${bold}${yellow}Thermal${reset} — List of Commands

• check [backup_dir | database | ssh]
• help
• refresh
• restore
• status
• sync [down | up]
• sync uploads [down | up]
• sync wp-content [down | up]
• version (-v, --version)

EOF
}

thermal_refresh () {
  . /var/www/thermal/thermal.sh

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Could not refresh Thermal."
    echo
    echo "Command: ${bold}${yellow}. /var/www/thermal/thermal.sh${reset}"
    echo
  else
    echo
    echo "${bold}${green}Successfully refreshed.${reset}"
    echo
  fi
}

thermal_status () {
  ping -c 1 "${thermal_config_name}" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Error:${reset} Thermal is offline."
    echo
  else
    echo
    echo "${bold}${green}Thermal is online.${reset}"
    echo
  fi
}

thermal_sync_wp_content_down () {
  sync_wp_content_down_succeeded=false

  echo
  echo "${bold}${blue}Syncing wp-content...${reset}"
  echo

  rsync -r "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/wp-content /var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Sync failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}rsync -r "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/wp-content /var/www/"${thermal_config_wp_dir}"${reset}"

    return 1
  else
    sync_wp_content_down_succeeded=true

    echo "${bold}${green}Sync complete.${reset}"
    echo
  fi
}

thermal_sync_wp_content_up () {
  sync_wp_content_up_succeeded=false

  echo "${bold}${blue}Syncing wp-content...${reset}"
  echo

  rsync -re ssh /var/www/"${thermal_config_wp_dir}"/wp-content "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}" --exclude "mu-plugins/force-strong-passwords" --exclude "mu-plugins/wpengine-common"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Sync failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}rsync -re ssh /var/www/"${thermal_config_wp_dir}"/wp-content "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}" --exclude "mu-plugins/force-strong-passwords" --exclude "mu-plugins/wpengine-common"${reset}"

    return 1
  else
    sync_wp_content_up_succeeded=true

    echo "${bold}${green}Sync complete.${reset}"
    echo
  fi
}

thermal_wp_content_archive_local () {
  wp_content_archive_local_succeeded=false

  echo
  echo "${bold}${blue}Archiving local wp-content...${reset}"
  echo

  tar -zcf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content.tar.gz -C /var/www/"${thermal_config_wp_dir}" wp-content

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Archive local wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}tar -zcf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content.tar.gz -C /var/www/"${thermal_config_wp_dir}" wp-content${reset}"

    return 1
  else
    wp_content_archive_local_succeeded=true

    echo "${bold}${green}Archive local wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_archive_local_old () {
  wp_content_archive_local_old_succeeded=false

  echo
  echo "${bold}${blue}Archiving old local wp-content...${reset}"
  echo

  tar -zcf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content-old.tar.gz -C /var/www/"${thermal_config_wp_dir}" wp-content

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Archive old local wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}tar -zcf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content-old.tar.gz -C /var/www/"${thermal_config_wp_dir}" wp-content${reset}"

    return 1
  else
    wp_content_archive_local_old_succeeded=true

    echo "${bold}${green}Archive old local wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_archive_remote () {
  wp_content_archive_remote_succeeded=false

  echo
  echo "${bold}${blue}Archiving remote wp-content...${reset}"
  echo

  ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zcf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content.tar.gz -C "${thermal_config_ssh_path}" wp-content

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Archive remote wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zcf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content.tar.gz -C "${thermal_config_ssh_path}" wp-content${reset}"

    return 1
  else
    wp_content_archive_remote_succeeded=true

    echo "${bold}${green}Archive remote wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_archive_remote_old () {
  wp_content_archive_remote_old_succeeded=false

  echo
  echo "${bold}${blue}Archiving old remote wp-content...${reset}"
  echo

  ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zcf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content-old.tar.gz -C "${thermal_config_ssh_path}" wp-content

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Archive old remote wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zcf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content-old.tar.gz -C "${thermal_config_ssh_path}" wp-content${reset}"

    return 1
  else
    wp_content_archive_remote_old_succeeded=true

    echo "${bold}${green}Archive old remote wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_restore_local () {
  wp_content_restore_local_succeeded=false

  echo
  echo "${bold}${blue}Restoring local wp-content...${reset}"
  echo

  tar -zxf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content.tar.gz -C /var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Restore local wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}tar -zxf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content.tar.gz -C /var/www/"${thermal_config_wp_dir}"${reset}"

    return 1
  else
    wp_content_restore_local_succeeded=true

    echo "${bold}${green}Restore local wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_restore_local_old () {
  wp_content_restore_local_old_succeeded=false

  echo
  echo "${bold}${blue}Restoring old local wp-content...${reset}"
  echo

  tar -zxf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content-old.tar.gz -C /var/www/"${thermal_config_wp_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Restore old local wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}tar -zxf /var/www/"${thermal_config_wp_dir}"/"${thermal_config_backup_dir}"/"${thermal_config_name}"_wp-content-old.tar.gz -C /var/www/"${thermal_config_wp_dir}"${reset}"

    return 1
  else
    wp_content_restore_local_old_succeeded=true

    echo "${bold}${green}Restore old local wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_restore_remote () {
  wp_content_restore_remote_succeeded=false

  echo
  echo "${bold}${blue}Restoring remote wp-content...${reset}"
  echo

  ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zxf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content.tar.gz -C "${thermal_config_ssh_path}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Restore remote wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zxf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content.tar.gz -C "${thermal_config_ssh_path}"${reset}"

    return 1
  else
    wp_content_restore_remote_succeeded=true

    echo "${bold}${green}Restore remote wp-content complete.${reset}"
    echo
  fi
}

thermal_wp_content_restore_remote_old () {
  wp_content_restore_remote_old_succeeded=false

  echo
  echo "${bold}${blue}Restoring old remote wp-content...${reset}"
  echo

  ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zxf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content-old.tar.gz -C "${thermal_config_ssh_path}"

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Restore old remote wp-content failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}ssh -T "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}" tar -zxf "${thermal_config_ssh_path}"/"${thermal_config_backup_dir}"/"${thermal_config_site}"_wp-content-old.tar.gz -C "${thermal_config_ssh_path}"${reset}"

    return 1
  else
    wp_content_restore_remote_old_succeeded=true

    echo "${bold}${green}Restore old remote wp-content complete.${reset}"
    echo
  fi
}

# ------------------------
# System Functions
# ------------------------

thermal_repair_permalinks () {
  repair_permalinks_succeeded=false

  echo
  echo "${bold}${blue}Repairing permalinks...${reset}"

  # Flush local rewrite rules
  thermal_flush_rewrite_local

  if [ ${flush_rewrite_local_succeeded} != true ]; then
    echo "Flush local rewrite rules failed."

    return 1
  fi

  # Flush remote rewrite rules
  thermal_flush_rewrite_remote

  if [ ${flush_rewrite_remote_succeeded} != true ]; then
    echo "${red}Flush remote rewrite rules failed.${reset}"

    return 1
  fi

  # Flush local cache
  thermal_flush_cache_local

  if [ ${flush_cache_local_succeeded} != true ]; then
    echo "${red}Flush local cache failed.${reset}"

    return 1
  fi

  # Flush remote cache
  thermal_flush_cache_remote

  if [ ${flush_cache_remote_succeeded} != true ]; then
    echo "${red}Flush remote cache failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Repair permalinks complete.${reset}"
}

thermal_restore_local () {
  echo
  echo "${bold}${blue}Restoring local...${reset}"
  echo

  # Check backup directory
  thermal_check_backup_dir > /dev/null 2>&1

  if [ ${backup_dir_local_exists} != true ] || [ ${backup_dir_remote_exists} != true ]; then
    thermal_repair_backup_dir > /dev/null 2>&1

    thermal_check_backup_dir > /dev/null 2>&1

    if [ ${backup_dir_local_exists} != true ]; then
      echo "${red}Local backup directory not found.${reset}"

      return 1
    fi

    if [ ${backup_dir_remote_exists} != true ]; then
      echo "${red}Remote backup directory not found.${reset}"

      return 1
    fi
  fi

  # Export old local database for backup
  thermal_db_export_local_old > /dev/null 2>&1

  if [ ${db_export_local_old_succeeded} != true ]; then
    echo "${red old}Local database export failed.${reset}"

    return 1
  fi

  # Archive old wp-content for backup
  thermal_wp_content_archive_local_old > /dev/null 2>&1

  if [ ${wp_content_archive_local_old_succeeded} != true ]; then
    echo "${red}Archive old wp-content failed.${reset}"

    return 1
  fi

  # Restore local database
  thermal_db_local_import_local > /dev/null 2>&1

  if [ ${db_local_import_local_succeeded} != true ]; then
    echo "${red}Restore local database failed.${reset}"

    return 1
  fi

  # Restore local wp-content
  thermal_wp_content_restore_local > /dev/null 2>&1

  if [ ${wp_content_restore_local_succeeded} != true ]; then
    echo "${red}Restore local wp-content failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Restore local complete.${reset}"
  echo
}

thermal_restore_local_old () {
  echo
  echo "${bold}${blue}Restoring old...${reset}"
  echo

  # Restore old local database
  thermal_db_local_old_import_local_old > /dev/null 2>&1

  if [ ${db_local_old_import_local_old_succeeded} != true ]; then
    echo "${red}Restore old local database failed.${reset}"

    return 1
  fi

  # Restore old local wp-content
  thermal_wp_content_restore_local_old > /dev/null 2>&1

  if [ ${wp_content_restore_local_old_succeeded} != true ]; then
    echo "${red}Restore old local failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Restore old local complete.${reset}"
  echo
}

thermal_restore_remote () {
  echo
  echo "${bold}${blue}Restoring remote...${reset}"
  echo

  # Check backup directory
  thermal_check_backup_dir > /dev/null 2>&1

  if [ ${backup_dir_local_exists} != true ] || [ ${backup_dir_remote_exists} != true ]; then
    thermal_repair_backup_dir > /dev/null 2>&1

    thermal_check_backup_dir > /dev/null 2>&1

    if [ ${backup_dir_local_exists} != true ]; then
      echo "${red}Local backup directory not found.${reset}"

      return 1
    fi

    if [ ${backup_dir_remote_exists} != true ]; then
      echo "${red}Remote backup directory not found.${reset}"

      return 1
    fi
  fi

  # Export old remote database for backup
  thermal_db_export_remote_old > /dev/null 2>&1

  if [ ${db_export_remote_old_succeeded} != true ]; then
    echo "${red old}Remote database export failed.${reset}"

    return 1
  fi

  # Archive old wp-content for backup
  thermal_wp_content_archive_remote_old > /dev/null 2>&1

  if [ ${wp_content_archive_remote_old_succeeded} != true ]; then
    echo "${red}Archive old wp-content failed.${reset}"

    return 1
  fi

  # Restore remote database
  thermal_db_remote_import_remote > /dev/null 2>&1

  if [ ${db_remote_import_remote_succeeded} != true ]; then
    echo "${red}Restore remote database failed.${reset}"

    return 1
  fi

  # Restore remote wp-content
  thermal_wp_content_restore_remote > /dev/null 2>&1

  if [ ${wp_content_restore_remote_succeeded} != true ]; then
    echo "${red}Restore remote wp-content failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Restore remote complete.${reset}"
  echo
}

thermal_restore_remote_old () {
  echo
  echo "${bold}${blue}Restoring old remote...${reset}"
  echo

  # Restore old remote database
  thermal_db_remote_old_import_remote_old > /dev/null 2>&1

  if [ ${db_remote_old_import_remote_old_succeeded} != true ]; then
    echo "${red}Restore old remote database failed.${reset}"

    return 1
  fi

  # Restore old remote wp-content
  thermal_wp_content_restore_remote_old > /dev/null 2>&1

  if [ ${wp_content_restore_remote_old_succeeded} != true ]; then
    echo "${red}Restore old remote failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Restore old remote complete.${reset}"
  echo
}

thermal_sync_down () {
  echo
  echo "${bold}${blue}Preparing sync...${reset}"
  echo

  # Check SSH
  thermal_check_ssh > /dev/null 2>&1

  if [ ${check_ssh_succeeded} != true ]; then
    echo "${red}Check SSH failed.${reset}"

    return 1
  fi

  # Check backup directory
  thermal_check_backup_dir > /dev/null 2>&1

  if [ ${backup_dir_local_exists} != true ] || [ ${backup_dir_remote_exists} != true ]; then
    thermal_repair_backup_dir > /dev/null 2>&1

    thermal_check_backup_dir > /dev/null 2>&1

    if [ ${backup_dir_local_exists} != true ]; then
      echo "${red}Local backup directory not found.${reset}"

      return 1
    fi

    if [ ${backup_dir_remote_exists} != true ]; then
      echo "${red}Remote backup directory not found.${reset}"

      return 1
    fi
  fi

  # Export local database for backup
  thermal_db_export_local > /dev/null 2>&1

  if [ ${db_export_local_succeeded} != true ]; then
    echo "${red}Local database export failed.${reset}"

    return 1
  fi

  # Archive wp-content for backup
  thermal_wp_content_archive_local > /dev/null 2>&1

  if [ ${wp_content_archive_local_succeeded} != true ]; then
    echo "${red}Archive wp-content failed.${reset}"

    return 1
  fi

  # Export remote database
  echo "${bold}${blue}Exporting database...${reset}"
  echo

  thermal_db_export_remote > /dev/null 2>&1

  if [ ${db_export_remote_succeeded} != true ]; then
    echo "${red}Remote database export failed.${reset}"

    return 1
  fi

  # Download remote database
  echo "${bold}${blue}Downloading database...${reset}"
  echo

  thermal_db_download_remote > /dev/null 2>&1

  if [ ${db_download_remote_succeeded} != true ]; then
    echo "${red}Download database failed.${reset}"

    return 1
  fi

  # Import remote database
  echo "${bold}${blue}Importing database...${reset}"
  echo

  thermal_db_local_import_remote > /dev/null 2>&1

  if [ ${db_local_import_remote_succeeded} != true ]; then
    echo "${red}Database import failed.${reset}"

    return 1
  fi

  # Search replace
  echo "${bold}${blue}Running database search replace...${reset}"
  echo

  thermal_db_search_replace_local > /dev/null 2>&1

  if [ ${db_search_replace_local_succeeded} != true ]; then
    echo "${red}Database search replace failed.${reset}"

    return 1
  fi

  # Flush local rewrite rules
  echo "${bold}${blue}Flushing local rewrite rules...${reset}"
  echo

  thermal_flush_rewrite_local > /dev/null 2>&1

  if [ ${flush_rewrite_local_succeeded} != true ]; then
    echo "${red}Flush local rewrite rules failed.${reset}"

    return 1
  fi

  # Flush local cache
  echo "${bold}${blue}Flushing local cache...${reset}"
  echo

  thermal_flush_cache_local > /dev/null 2>&1

  if [ ${flush_cache_local_succeeded} != true ]; then
    echo "${red}Flush local cache failed.${reset}"

    return 1
  fi

  # Sync wp-content
  echo "${bold}${blue}Syncing wp-content...${reset}"
  echo

  thermal_sync_wp_content_down > /dev/null 2>&1

  if [ ${sync_wp_content_down_succeeded} != true ]; then
    echo "${red}Sync wp-content failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Sync complete.${reset}"
  echo
}

thermal_sync_up () {
  echo
  echo "${bold}${blue}Preparing sync...${reset}"
  echo

  # Check SSH
  thermal_check_ssh > /dev/null 2>&1

  if [ ${check_ssh_succeeded} != true ]; then
    echo "${red}Check SSH failed.${reset}"

    return 1
  fi

  if [ ${backup_dir_remote_exists} != true ]; then
    thermal_repair_backup_dir

    if [ ${backup_dir_remote_exists} != true ]; then
      echo "${red}Remote backup directory not found.${reset}"

      return 1
    fi
  fi

  # Export remote database for backup
  thermal_db_export_remote > /dev/null 2>&1

  if [ ${db_export_remote_succeeded} != true ]; then
    echo "${red}Remote database export failed.${reset}"

    return 1
  fi

  # Archive wp-content for backup
  thermal_wp_content_archive_remote > /dev/null 2>&1

  if [ ${wp_content_archive_remote_succeeded} != true ]; then
    echo "${red}Archive wp-content failed.${reset}"

    return 1
  fi

  # Export local database
  echo "${bold}${blue}Exporting database...${reset}"
  echo

  thermal_db_export_local > /dev/null 2>&1

  if [ ${db_export_local_succeeded} != true ]; then
    echo "${red}Local database export failed.${reset}"

    return 1
  fi

  # Upload local database
  echo "${bold}${blue}Uploading database...${reset}"
  echo

  thermal_db_upload_local > /dev/null 2>&1

  if [ ${db_upload_local_succeeded} != true ]; then
    echo "${red}Upload database failed.${reset}"

    return 1
  fi

  # Import local database
  echo "${bold}${blue}Importing database...${reset}"
  echo

  thermal_db_remote_import_local > /dev/null 2>&1

  if [ ${db_remote_import_local_succeeded} != true ]; then
    echo "${red}Database import failed.${reset}"

    return 1
  fi

  # Search replace
  echo "${bold}${blue}Running database search replace...${reset}"
  echo

  thermal_db_search_replace_remote > /dev/null 2>&1

  if [ ${db_search_replace_remote_succeeded} != true ]; then
    echo "${red}Search replace failed.${reset}"

    return 1
  fi

  # Flush remote rewrite rules
  echo "${bold}${blue}Flushing remote rewrite rules...${reset}"
  echo

  thermal_flush_rewrite_remote > /dev/null 2>&1

  if [ ${flush_rewrite_remote_succeeded} != true ]; then
    echo "${red}Flush remote rewrite rules failed.${reset}"

    return 1
  fi

  # Flush remote cache
  echo "${bold}${blue}Flushing remote cache...${reset}"
  echo

  thermal_flush_cache_remote > /dev/null 2>&1

  if [ ${flush_cache_remote_succeeded} != true ]; then
    echo "${red}Flush remote cache failed.${reset}"

    return 1
  fi

  # Sync wp-content
  echo "${bold}${blue}Syncing wp-content...${reset}"
  echo

  thermal_sync_wp_content_up > /dev/null 2>&1

  if [ ${sync_wp_content_up_succeeded} != true ]; then
    echo "${red}Sync wp-content failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Sync complete.${reset}"
  echo
}

thermal_sync_database_down () {
  echo
  echo "${bold}${blue}Preparing database sync...${reset}"
  echo

  # Check SSH
  thermal_check_ssh > /dev/null 2>&1

  if [ ${check_ssh_succeeded} != true ]; then
    echo "${red}Check SSH failed.${reset}"

    return 1
  fi

  # Check backup directory
  thermal_check_backup_dir > /dev/null 2>&1

  if [ ${backup_dir_local_exists} != true ] || [ ${backup_dir_remote_exists} != true ]; then
    thermal_repair_backup_dir > /dev/null 2>&1

    thermal_check_backup_dir > /dev/null 2>&1

    if [ ${backup_dir_local_exists} != true ]; then
      echo "${red}Local backup directory not found.${reset}"

      return 1
    fi

    if [ ${backup_dir_remote_exists} != true ]; then
      echo "${red}Remote backup directory not found.${reset}"

      return 1
    fi
  fi

  # Export local database for backup
  thermal_db_export_local > /dev/null 2>&1

  if [ ${db_export_local_succeeded} != true ]; then
    echo "${red}Local database export failed.${reset}"

    return 1
  fi

  # Export remote database
  echo "${bold}${blue}Exporting database...${reset}"
  echo

  thermal_db_export_remote > /dev/null 2>&1

  if [ ${db_export_remote_succeeded} != true ]; then
    echo "${red}Remote database export failed.${reset}"

    return 1
  fi

  # Download remote database
  echo "${bold}${blue}Downloading database...${reset}"
  echo

  thermal_db_download_remote > /dev/null 2>&1

  if [ ${db_download_remote_succeeded} != true ]; then
    echo "${red}Download database failed.${reset}"

    return 1
  fi

  # Import remote database
  echo "${bold}${blue}Importing database...${reset}"
  echo

  thermal_db_local_import_remote > /dev/null 2>&1

  if [ ${db_local_import_remote_succeeded} != true ]; then
    echo "${red}Database import failed.${reset}"

    return 1
  fi

  # Search replace
  echo "${bold}${blue}Running database search replace...${reset}"
  echo

  thermal_db_search_replace_local > /dev/null 2>&1

  if [ ${db_search_replace_local_succeeded} != true ]; then
    echo "${red}Search replace failed.${reset}"

    return 1
  fi

  # Flush local rewrite rules
  echo "${bold}${blue}Flushing local rewrite rules...${reset}"
  echo

  thermal_flush_rewrite_local > /dev/null 2>&1

  if [ ${flush_rewrite_local_succeeded} != true ]; then
    echo "${red}Flush local rewrite rules failed.${reset}"

    return 1
  fi

  # Flush local cache
  echo "${bold}${blue}Flushing local cache...${reset}"
  echo

  thermal_flush_cache_local > /dev/null 2>&1

  if [ ${flush_cache_local_succeeded} != true ]; then
    echo "${red}Flush local cache failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Sync database complete.${reset}"
  echo
}

thermal_sync_database_up () {
  echo
  echo "${bold}${blue}Preparing database sync...${reset}"
  echo

  # Check SSH
  thermal_check_ssh > /dev/null 2>&1

  if [ ${check_ssh_succeeded} != true ]; then
    echo "${red}Check SSH failed.${reset}"

    return 1
  fi

  # Check backup directory
  thermal_check_backup_dir > /dev/null 2>&1

  if [ ${backup_dir_local_exists} != true ] || [ ${backup_dir_remote_exists} != true ]; then
    thermal_repair_backup_dir > /dev/null 2>&1

    thermal_check_backup_dir > /dev/null 2>&1

    if [ ${backup_dir_local_exists} != true ]; then
      echo "${red}Local backup directory not found.${reset}"

      return 1
    fi

    if [ ${backup_dir_remote_exists} != true ]; then
      echo "${red}Remote backup directory not found.${reset}"

      return 1
    fi
  fi

  # Export remote database for backup
  thermal_db_export_remote > /dev/null 2>&1

  if [ ${db_export_remote_succeeded} != true ]; then
    echo "${red}Remote database export failed.${reset}"

    return 1
  fi

  # Export local database
  echo "${bold}${blue}Exporting database...${reset}"
  echo

  thermal_db_export_local > /dev/null 2>&1

  if [ ${db_export_local_succeeded} != true ]; then
    echo "${red}Local database export failed.${reset}"

    return 1
  fi

  # Upload local database
  echo "${bold}${blue}Uploading database...${reset}"
  echo

  thermal_db_upload_local > /dev/null 2>&1

  if [ ${db_upload_local_succeeded} != true ]; then
    echo "${red}Upload database failed.${reset}"

    return 1
  fi

  # Import local database
  echo "${bold}${blue}Importing database...${reset}"
  echo

  thermal_db_remote_import_local > /dev/null 2>&1

  if [ ${db_remote_import_local_succeeded} != true ]; then
    echo "${red}Database import failed.${reset}"

    return 1
  fi

  # Search replace
  echo "${bold}${blue}Running database search replace...${reset}"
  echo

  thermal_db_search_replace_remote > /dev/null 2>&1

  if [ ${db_search_replace_remote_succeeded} != true ]; then
    echo "${red}Search replace failed.${reset}"

    return 1
  fi

  # Flush remote rewrite rules
  echo "${bold}${blue}Flushing remote rewrite rules...${reset}"
  echo

  thermal_flush_rewrite_remote > /dev/null 2>&1

  if [ ${flush_rewrite_remote_succeeded} != true ]; then
    echo "${red}Flush remote rewrite rules failed.${reset}"

    return 1
  fi

  # Flush remote cache
  echo "${bold}${blue}Flushing remote cache...${reset}"
  echo

  thermal_flush_cache_remote > /dev/null 2>&1

  if [ ${flush_cache_remote_succeeded} != true ]; then
    echo "${red}Flush remote cache failed.${reset}"

    return 1
  fi

  echo "${bold}${green}Sync database complete.${reset}"
  echo
}

thermal_sync_uploads_down () {
  sync_uploads_down_succeeded=false

  echo
  echo "${bold}${blue}Syncing uploads...${reset}"
  echo

  rsync -r "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/wp-content/uploads /var/www/"${thermal_config_wp_dir}"/wp-content

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Sync failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}rsync -r "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/wp-content/uploads /var/www/"${thermal_config_wp_dir}"/wp-content${reset}"

    return 1
  else
    sync_uploads_down_succeeded=true

    echo "${bold}${green}Sync complete.${reset}"
    echo
  fi
}

thermal_sync_uploads_up () {
  sync_uploads_up_succeeded=false

  echo "${bold}${blue}Syncing uploads...${reset}"
  echo

  rsync -re ssh /var/www/"${thermal_config_wp_dir}"/wp-content/uploads "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/wp-content

  if [ $? -ne 0 ]; then
    echo
    echo "${red}Sync failed.${reset}"
    echo
    echo "Command: ${bold}${yellow}rsync -re ssh /var/www/"${thermal_config_wp_dir}"/wp-content/uploads "${thermal_config_ssh_user}"@"${thermal_config_ssh_host}":"${thermal_config_ssh_path}"/wp-content${reset}"

    return 1
  else
    sync_uploads_up_succeeded=true

    echo "${bold}${green}Sync complete.${reset}"
    echo
  fi
}

thermal_version () {
  echo
  echo "${bold}${yellow}Thermal${reset} — Vagrant box for syncing WordPress"
  echo

  if [ -f /var/www/thermal/version ]; then
    echo "Version: $(cat /var/www/thermal/version)"
    echo
  else
    echo "Version file not detected."
    echo
    echo "${bold}${yellow}/var/www/thermal/version${reset}"
    echo
  fi
}

thermal () {
  if [ $# -ne 0 ]; then
    declare -a list_of_methods=(-v --version backup check help refresh repair restore status sync version)

    is_method () {
      local e

      for e in "${list_of_methods[@]}"
        do [ "$e" == "${1}" ] && return 0
      done

      return 1
    }

    is_method "$1"

    if [ $? -ne 0 ]; then
      echo
      echo "${red}Error:${reset} Command not found: ${bold}${yellow}"${1}"${reset}"

      thermal_help
    fi
  else
    thermal_version
  fi

  # ------------------------
  # Command: check
  # ------------------------

  if [ "$1" == "check" ]; then
    if [ -z "$2" ]; then
      echo
      echo "Nothing specified after ${bold}${yellow}check${reset} command."
      echo
      echo "Options: ${bold}${yellow}backup_dir${reset} | ${bold}${yellow}database${reset} | ${bold}${yellow}key${reset} | ${bold}${yellow}ssh${reset}"
      echo
    fi

    if [ "$2" == "backup_dir" ]; then
      thermal_check_backup_dir
    fi

    if [ "$2" == "database" ]; then
      thermal_check_database
    fi

    if [ "$2" == "key" ]; then
      thermal_check_key
    fi

    if [ "$2" == "ssh" ]; then
      thermal_check_ssh
    fi
  fi

  # ------------------------
  # Command: help
  # ------------------------

  if [ "$1" == "help" ]; then
    thermal_help
  fi

  # ------------------------
  # Command: refresh
  # ------------------------

  if [ "$1" == "refresh" ]; then
    thermal_refresh
  fi

  # ------------------------
  # Command: repair
  # ------------------------

  if [ "$1" == "repair" ]; then
    if [ -z "$2" ]; then
      echo
      echo "Nothing specified after ${bold}${yellow}repair${reset} command."
      echo
      echo "Options: ${bold}${yellow}backup_dir${reset} | ${bold}${yellow}database${reset} | ${bold}${yellow}permalinks${reset}"
      echo
    fi

    if [ "$2" == "backup_dir" ]; then
      thermal_repair_backup_dir
    fi

    if [ "$2" == "database" ]; then
      thermal_repair_database
    fi

    if [ "$2" == "permalinks" ]; then
      thermal_repair_permalinks
    fi
  fi

  # ------------------------
  # Command: restore
  # ------------------------

  if [ "$1" == "restore" ]; then
    if [ -z "$2" ] || [ "$2" == "local" ]; then
      thermal_restore_local
    fi

    if [ "$2" == "remote" ]; then
      thermal_restore_remote
    fi

    if [ "$2" == "database" ]; then
      if [ -z "$3" ] || [ "$3" == "local" ]; then
        thermal_restore_db_local
      fi

      if [ "$3" == "remote" ]; then
        thermal_restore_db_remote
      fi
    fi

    if [ "$2" == "old" ]; then
      if [ -z "$3" ] || [ "$3" == "local" ]; then
        thermal_restore_local_old
      fi

      if [ "$3" == "remote" ]; then
        thermal_restore_remote_old
      fi
    fi

    if [ "$2" == "wp-content" ]; then
      if [ -z "$3" ] || [ "$3" == "local" ]; then
        thermal_restore_wp_content_local
      fi

      if [ "$3" == "remote" ]; then
        thermal_restore_wp_content_remote
      fi
    fi
  fi

  # ------------------------
  # Command: status
  # ------------------------

  if [ "$1" == "status" ]; then
    thermal_status
  fi

  # ------------------------
  # Command: sync
  # ------------------------

  if [ "$1" == "sync" ]; then
    if [ -z "$2" ] || [ "$2" == "up" ]; then
      thermal_sync_up
    fi

    if [ "$2" == "down" ]; then
      thermal_sync_down
    fi

    if [ "$2" == "database" ]; then
      if [ -z "$3" ] || [ "$3" == "up" ]; then
        thermal_sync_database_up
      fi

      if [ "$3" == "down" ]; then
        thermal_sync_database_down
      fi
    fi

    if [ "$2" == "uploads" ]; then
      if [ -z "$3" ] || [ "$3" == "up" ]; then
        thermal_sync_uploads_up
      fi

      if [ "$3" == "down" ]; then
        thermal_sync_uploads_down
      fi
    fi

    if [ "$2" == "wp-content" ]; then
      if [ -z "$3" ] || [ "$3" == "up" ]; then
        thermal_sync_wp_content_up
      fi

      if [ "$3" == "down" ]; then
        thermal_sync_wp_content_down
      fi
    fi
  fi

  # ------------------------
  # Command: version
  # ------------------------

  if [ "$1" == "-v" ] || [ "$1" == "--version" ] || [ "$1" == "version" ]; then
    thermal_version
  fi
}