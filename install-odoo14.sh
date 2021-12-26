#!/bin/bash

# =======================================================================
# VARIABLES
# =======================================================================

# -----------------------------------------------------------------------
# distro related settings
# -----------------------------------------------------------------------
SourceCodeFolderOnHost=/mnt/d/DEV/$WSL_DISTRO_NAME/src
SourceCodeFolderInDistribution=~/src
WSLRootFolderOnHost=/mnt/d/DEV/WSL
UserName=sensei
UserPassword=sensei
GitHubUser=my_github_username
GitHubAccessToken=ghp_????????????????????????????????????

# -----------------------------------------------------------------------
# project specific settings
# -----------------------------------------------------------------------



# =======================================================================
# INSTALL/SETUP SCRIPT
# =======================================================================
cd ~

# -----------------------------------------------------------------------
# Install python3 and dev packages
# -----------------------------------------------------------------------
echo -e "\n===== 1 => Install python3 and dev packages"
sudo apt install -y python-is-python3
sudo apt install -y python3-doc
sudo apt install -y python3-pip
sudo pip3 install --upgrade pip
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
sudo apt install -y python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev

# -----------------------------------------------------------------------
# Install and configure PostgreSQL and its main user
# -----------------------------------------------------------------------
echo -e "\n===== 2 => Install PostgreSQL and configure service autostart"
sudo apt install -y postgresql postgresql-client
sudo service postgresql start
sudo -u postgres createuser -s $USER
sudo createdb $USER

# -----------------------------------------------------------------------
# Ensure postgresql service is started automatically (without ? password)
# -----------------------------------------------------------------------
echo -e "\n===== 3 => Configure automatic postgresql service start"
sudo echo -e "\necho 'Starting the postgreSQL service...'\nsudo service postgresql start" >> ~/.profile
sudo bash -c "echo -e '\n%sudo ALL=(ALL) NOPASSWD: /usr/sbin/service postgresql start' >> /etc/sudoers"

# -----------------------------------------------------------------------
echo -e "\n===== 4 => Install Odoo 14.0 Community and Enterprise Editions"
git clone -b 14.0 --single-branch --depth=1 https://github.com/odoo/odoo.git ~/odoo/community
git clone -b 14.0 --single-branch --depth=1 https://$GitHubUser:$GitHubAccessToken@github.com/odoo/enterprise.git ~/odoo/enterprise
cd ~/odoo/community
pip3 install setuptools wheel
pip3 install -r requirements.txt

# -----------------------------------------------------------------------
echo -e "\n===== 5 => Install additional dependencies"
sudo wget -P /var/cache/apt/archives https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
sudo apt install -y /var/cache/apt/archives/wkhtmltox_0.12.6-1.focal_amd64.deb
pip3 install phonenumbers psycopg2-binary watchdog
mkdir -p ~/odoo/3rdparty
~/odoo/community/odoo-bin --save --stop-after-init

# -----------------------------------------------------------------------
echo -e "\n===== 6 => Predefined Configuration files and Odoo Aliases"
mkdir -p ~/odoo/cfg
cp $WSLRootFolderOnHost/odoo-ce.conf ~/odoo/cfg
cp $WSLRootFolderOnHost/odoo-ee.conf ~/odoo/cfg
sudo echo -e "\n# Aliases for starting different Odoo editions" >> ~/.bashrc
sudo echo -e "alias odooce='~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ce.conf' # Odoo Community Edition" >> ~/.bashrc
sudo echo -e "alias odooee='~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ee.conf' # Odoo Enterprise Edition" >> ~/.bashrc

# -----------------------------------------------------------------------
echo -e "\n===== 7 => Generate initial/empty databases for Odoo CE and EE"
~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ce.conf -d ce.initialdb --without-demo=all --stop-after-init
~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ee.conf -d ee.initialdb -i web_enterprise --without-demo=all --stop-after-init

# =======================================================================
# Create/link a folder for source code development (map the mounted dir)
# =======================================================================
echo -e "\n===== 8 => Create and link a folder for source code development"
mkdir -p $SourceCodeFolderOnHost
ln -s $SourceCodeFolderOnHost $SourceCodeFolderInDistribution

# =======================================================================
# Improve the bash prompt (quick and dirty)
# =======================================================================
echo -e "\n===== 9 => Improve the bash prompt"
sudo echo -e "\n# Improve the bash prompt..." >> ~/.bashrc
sudo echo -e "\nparse_git_branch() {\ngit branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ [\\\1]/'\n}" >> ~/.bashrc
sudo echo -e "\nPS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;35m\]\$WSL_DISTRO_NAME \[\033[01;32m\](\u)\[\e[91m\]\$(parse_git_branch)\\\n\[\033[01;36m\]\w\[\033[00m\] \$ '" >> ~/.bashrc

# =======================================================================
# COMPLETED
# =======================================================================
echo -e "\n=============================================================="
echo -e "\n       The Odoo Setup Procedure has been completed"
echo -e "\n=============================================================="
