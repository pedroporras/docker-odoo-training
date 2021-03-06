#!/bin/bash
echo """You can install this script using 'root' user (using 'sudo su - root') and running:
apt-get update && apt-get install -y wget
wget https://raw.githubusercontent.com/pedroporras/docker-odoo-training/master/install.sh -O install.sh
chmod +x install.sh
./install.sh myusros odoo_version  # Change 'myusros' to use your custom OS' user name
"""
export USER=$1
export ODOO_VERSION=$2

apt-get update
apt-get install -y python-pip python3-pip libxml2-dev libxslt-dev libevent-dev \
    libsasl2-dev libldap2-dev python-lxml python3-lxml libjpeg-dev \
    libssl-dev python-dev python3-dev \
    curl wget unzip locales tree sudo \
    tmux vim wkhtmltopdf git
apt-get install sassc -y

# Create user of the Operating System.
useradd -d /home/${USER} -m -s /bin/bash -p ${USER}pwd ${USER}

# Upgrade python package manager pip
pip install -U pip
pip3 install -U pip

# Configure locales to avoid coding errors
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen en_US.UTF-8
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
update-locale LANG=en_US.UTF-8
echo -e "export LANG=en_US.UTF-8\nexport LANGUAGE=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8\nexport PYTHONIOENCODING=UTF-8" | tee -a /etc/bash.bashrc
source /etc/bash.bashrc

# Install postgresql (after configure locales to auto-create cluster with encoding UTF-8)
apt-get install -y postgresql
pg_createcluster 9.5 main95 -e=utf8 || true
/etc/init.d/postgresql start
su - postgres -c "createuser -s ${USER}"

# Download odoo and create addon-extra directory
su - ${USER} -c "git clone -b ${ODOO_VERSION} --single-branch --depth=10 https://github.com/odoo/odoo.git odoo-repo"
mkdir /home/${USER}/odoo-repo/addons-extra
chown -R ${USER} /home/${USER}/odoo-repo/addons-extra
sudo chmod -R 777 /home/${USER}/odoo-repo/addons-extra

# Install odoo dependencies for py2 and py3
LC_ALL=C.UTF-8 LANG=C.UTF-8
wget https://raw.githubusercontent.com/pedroporras/docker-odoo-training/master/requirements.txt -O /tmp/requirements.txt
python3.6 -m pip install -Ur /tmp/requirements.txt
wget https://raw.githubusercontent.com/pedroporras/docker-odoo-training/master/missed_requirement.txt -O /tmp/missing_requirements.txt
pip install -r /tmp/missing_requirements.txt

wget https://raw.githubusercontent.com/pedroporras/docker-odoo-training/master/requirements.txt -O /tmp/req10.txt
python2.7 -m pip install -Ur /tmp/req10.txt
rm /tmp/req10.txt

apt-get install -y npm
ln -s /usr/bin/nodejs /usr/bin/node
npm install -g less
(cd /usr/bin && wget -qO- -t 1 --timeout=240 https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz | tar -xJ --strip-components=2 wkhtmltox/bin/wkhtmltopdf)

# Install python tools
python2.7 -m pip install -U bpython
python3.6 -m pip install -U bpython

# configure vim IDE
git clone --depth=1 --single-branch https://github.com/spf13/spf13-vim.git /tmp/spf13-vim
su - ${USER} -c "/tmp/spf13-vim/bootstrap.sh"
su - ${USER} -c "mkdir -p ~/.vim/spell"
su - ${USER} -c "wget -q http://ftp.vim.org/pub/vim/runtime/spell/es.utf-8.spl -O ~/.vim/spell/es.utf-8.spl"
echo -e """filetype plugin indent on
\" show existing tab with 4 spaces width
set tabstop=4
\" when indenting with '>', use 4 spaces width
set shiftwidth=4
\" On pressing tab, insert 4 spaces
set expandtab
colorscheme heliotrope
\" Disable pymode because show ImporError
let g:pymode=0
set spelllang=en,es
""" >> /home/${USER}/.vimrc
sed -i 's/ set mouse\=a/\"set mouse\=a/g' /home/${USER}/.vimrc
sed -i "s/let g:neocomplete#enable_at_startup = 1/let g:neocomplete#enable_at_startup = 0/g" /home/${USER}/.vimrc

