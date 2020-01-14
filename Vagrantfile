require "yaml"

if File.exists?('thermal-config.yml')
  setting = YAML.load_file "thermal-config.yml"
else
  setting = YAML.load_file "thermal/thermal-config.yml"
end

if setting["config"]["wp_dir"]
  wp_dir = setting["config"]["wp_dir"]
else
  wp_dir = "."
end

Vagrant.configure("2") do |config|
  config.vm.box = "jstnbr/thermal"
  config.vm.hostname = setting["config"]["name"]
  config.vm.network "private_network", ip: "192.168.55.10"

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--cpus", 2]
    v.customize ["modifyvm", :id, "--memory", 2048]
    v.customize ['modifyvm', :id, '--ioapic', 'on']
  end

  # Provision public key
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"

  config.vm.provision "shell", path: "thermal/bootstrap.sh", keep_color: true, privileged: false
  config.vm.synced_folder ".", "/var/www/" + wp_dir, :mount_options => ["dmode=777", "fmode=666"], create: true

  # [Optional] Vagrant Plugin Hostsupdater
  # https://github.com/cogitatio/vagrant-hostsupdater
  config.hostsupdater.aliases = ["status." + setting["config"]["name"]]

  welcome = <<WELCOME

/__   \\ |__   ___ _ __ _ __ ___   __ _| |
  / /\\/ '_ \\ / _ \\ '__| '_ ` _ \\ / _` | |
 / /  | | | |  __/ |  | | | | | | (_| | |
 \\/   |_| |_|\\___|_|  |_| |_| |_|\\__,_|_|

Vagrant LEMP box for WordPress

----------------------------------------------

Local ip address 192.168.55.10

URLS:
- site        - http://#{setting["config"]["name"]}
- status      - http://status.#{setting["config"]["name"]}
- phpmyadmin  - http://#{setting["config"]["name"]}/phpmyadmin

----------------------------------------------
 
WELCOME

  config.vm.post_up_message = welcome
end