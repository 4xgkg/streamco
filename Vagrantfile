# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.synced_folder ".", "/home/vagrant/streamco"

  # run librarian-puppet inside the Vagrant box, to avoid the need
  # to install it on the host
  config.vm.provision "shell", inline: "apt-get install -y ruby-dev git"
  config.vm.provision "shell", inline: "gem install --verbose librarian-puppet"
  config.vm.provision "shell", inline: "cd /home/vagrant/streamco/puppet && librarian-puppet install --verbose"

  config.vm.provision "puppet" do |puppet|
    puppet.temp_dir = "/tmp"
    puppet.manifests_path = 'puppet/manifests'
    puppet.module_path = 'puppet/modules'
  end

  config.vm.box = "ubuntu-puppet"
  config.vm.network "forwarded_port", guest: 80, host: 10000

  config.vm.provision :serverspec do |spec|
    spec.pattern = 'tests/spec/*_spec.rb'
  end

end
