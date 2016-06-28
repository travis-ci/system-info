PROVISION_SCRIPT = <<-EOF
set -o errexit

if ! rvm version 2>/dev/null ; then
  gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
  curl -sSL https://get.rvm.io | bash -s stable
  source ~/.bash_profile
  rvm install --fuzzy $(< /vagrant/.ruby-version)
fi

if ! grep '# VAGRANT PROVISIONED' ~/.bash_profile ; then
  echo 'cd /vagrant' >> ~/.bash_profile
  echo '# VAGRANT PROVISIONED' >> ~/.bash_profile
fi
EOF

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/trusty64'

  config.vm.provision :shell, inline: PROVISION_SCRIPT, privileged: false
end
