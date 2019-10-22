require "yaml"

setting = YAML.load_file "thermal/thermal-config.yml"

Vagrant.configure("2") do |config|

  # ------------------------
  # Config
  # ------------------------

  site = setting["config"]["name"]
  ip_address = "192.168.55.10"

  # ------------------------
  # Vagrant
  # ------------------------

  config.vm.box = "jstnbr/thermal"
  config.vm.hostname = site
  config.vm.network "private_network", ip: ip_address

  # Provision public key
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"

  config.vm.provision "shell", path: "thermal/bootstrap.sh", keep_color: true, privileged: false
  config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=666"], create: true

  # [Optional] Vagrant Plugin Hostsupdater
  # https://github.com/cogitatio/vagrant-hostsupdater
  config.hostsupdater.aliases = ["status." + site]
end