# Install Odoo for Development on WSL2 (Ubuntu)

## TL;DR

To setup Odoo 14, **just run the script** `install-odoo14.sh` from the shell of your Linux distro in WSL2.

**Important**: you should adapt the script to match the *windows host mounted device/folders* (used during the setup and used later during development) with your own windows host configuration.

## Summary

The following instructions explain the **Odoo installation from source** procedure implemented in the script, which is suitable to setup an Odoo environment for development purpose. Description for alternative installation procedures can be found in the Odoo official documentation.

The installation procedure is creating the following structure automatically within the distro instance:

```text
~/odoo/cfg           <- configuration files for Odoo CE and EE
~/odoo/community     <- Odoo core 
~/odoo/enterprise    <- Odoo "enterprise" Add-Ons repository
~/odoo/3rdparty      <- 3rd party (OCO, AppStore etc.) Add-Ons repository
~/odoo/src           <- YOUR SOURCE CODE root folder = for development
```

*virtual environments* are not considered here, since *not required at all*:

Using multiple Linux distro instances on WSL2 allow to install different Odoo versions in separated distro instances, as demonstrated in [wsl2-multi-distro](https://github.com/khatastroffik/wsl2-multi-distro).
Though, it is not possible to run 2 WSL2 instances containing Odoo at the same time i.e. in parallel, unless the postgreSQL service of each instance and Odoo are manually configured to use different ports (avoiding an overlapping of the used ports) for accessing the database.

In other words:
- create one WSL2 distro instance per Odoo version (12/13/14...) 
- configure different ports in those instances to run multiple Odoo versions at the same time (if required - not described here).

Furthermore, the installation script can easily be adapted (e.g. mounted disc/folders) to be used directly in a Linux environment, though it was written to be called from within a Linux distro instance running under WSL2.

## Odoo 14 Core Setup

### Prerequisites

#### Install python3 and dev packages

The python3 and pip3 packages as well as additional packages required by Odoo and some supplemental (optional) tools/packages will be installed.

```bash
sudo apt install -y python-is-python3
sudo apt install -y python3-doc
sudo apt install -y python3-pip
sudo pip3 install --upgrade pip
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
sudo apt install -y python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev
```

#### Install PostgreSQL and its service

PostgreSQL is installed and its service is configured to automatically start when the distro is started with the corresponding user.

```bash
sudo apt install -y postgresql postgresql-client
sudo service postgresql start
sudo -u postgres createuser -s $USER
createdb $USER
sudo echo -E "\necho 'Starting the postgreSQL service...'\nsudo service postgresql start" >> ~/.profile
```

Notes:
- The currently *active "sudoer" user* is used to create a corresponding postgreSQL user, which should (for security reasons) manage the DB instead of the "root" user.
- Other options exist to automatically start the postgreSQL service when the distro is started. Usage of the "*.profile*" trick has been prefered here, due to its simplicity and because the postgreSQL service start is made visible to (thus, controllable by) the user.

### Install Odoo 14.0 Community and Enterprise Editions

Odoo Community Edition (CE; public Odoo GitHub repository) and Enterprise Edition (EE; This GitHub repository requires explicit access: granted by Odoo SA.) are installed as well as some additional packages/libraries. An initial configuration is automatically created.

```bash
git clone -b 14.0 --single-branch --depth=1 https://github.com/odoo/odoo.git ~/odoo/community
git clone -b 14.0 --single-branch --depth=1 https://github.com/odoo/enterprise.git ~/odoo/enterprise
cd ~/odoo/community
pip3 install setuptools wheel
pip3 install -r requirements.txt
sudo wget -P /var/cache/apt/archives https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
sudo apt install -y /var/cache/apt/archives/wkhtmltox_0.12.6-1.focal_amd64.deb
pip3 install phonenumbers psycopg2-binary watchdog
mkdir -p ~/odoo/3rdparty
~/odoo/community/odoo-bin --save --stop-after-init
```

Note: the `~/odoo/3rdparty` folder needs to be (manually) added to the `addons_path` of the odoo configuration file. It is intended to contain all 3rd-party modules, such as those from the OCA or from the App-Store.

**Important**: you may need a *personal access token* (to be created in your own github account) to be used as a password when cloning the Odoo-Enterprise repository.

### Create and link a folder for module development

The developed souce code can be accessed directly within the running distro as well as from the WSL2 host computer: a link between an host directory (mounted in the distro) and the source code repository (within the distro) is automatically created.

```bash
mkdir /mnt/d/DEV/odoo-src
ln -s /mnt/d/DEV/odoo-src ~/src
```

Notes:

- the `~/src` needs to be (manually) added to the `addons_path` of the odoo configuration file. The `src` folder is intended to contain the developed modules source code.
- the mounted windows host device/folder used here is `D:\DEV\`. It should be adapted (in the script) to match your own windows host configuration.

## Start Odoo 14

### Start "Odoo Community Edition" server with an initial database

To ease initial work and to test the setup was successfull, a "community" compatible database (empty i.e. without demo data) is used.

```bash
~/odoo/community/odoo-bin -d cc.initialdb
```

See below for instructions on how to "*Generate initial databases for CE and EE*".

### Start "Odoo Enterprise Edition" server with an initial Database

To ease initial work and to test the setup was successfull, an "enterprise" compatible database (empty i.e. without demo data) is used.

Note: For the Enterprise edition, you **must** add the path of the enterprise addons folder into the `addons-path` argument of the CLI Odoo call or in the Odoo configuration file.

```bash
~/odoo/community/odoo-bin -d ee.initialdb
```

Important: the **path** to the "enterprise" folder  **must come before the other paths** in `addons-path` of your odoo configuration (either as parameter of the CLI or within the odoo configuration file).

```ini
addons_path = /home/odoo/centerprise, ...
```

See below for instructions on how to "*Generate initial databases for CE and EE*".

## Odoo 14 additional tools and configuration

### Predefined Odoo Configuration files and aliases

You may start Odoo Community or Enterprise Editions using the simple commands `odooce` or `odooee` (in the distro shell) after the following has been run once:

```bash
cd ~
cp /mnt/d/DEV/wsl2-odoo-setup/odoo-ce.conf ~/odoo/cfg
cp /mnt/d/DEV/wsl2-odoo-setup/odoo-ee.conf ~/odoo/cfg
sudo echo -e "\n# Aliases for starting different Odoo editions\nalias odooce='~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ce.conf'\nalias odooee='~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ee.conf'" >> ~/.bashrc
```

Two Odoo configuration scripts are installed in the user's root folder and used to the started corresponding Odoo editions.

- Those scripts may be adapted if required. See the corresponding Odoo documentation.
- The scripts are copied from the mounted windows device/folder `D:\DEV\wsl2-odoo-setup\` which should contain the files of the cloned `wsl2-odoo-setup` repository. Adapt the installation script to your configuration as needed.

### Generate initial databases for CE and EE

The following script is generating 2 empty "initial" databases (i.e. without demo-data) for Odoo CE and EE:

- Initial DB for Odoo Community Edition:  `ce.initialdb`
- Initial DB for Odoo Enterprise Edition:  `ee.initialdb`

```bash
~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ce.conf -d ce.initialdb --without-demo=all --stop-after-init
~/odoo/community/odoo-bin -c ~/odoo/cfg/odoo-ee.conf -d ee.initialdb -i web_enterprise --without-demo=all --stop-after-init
```

Note: you may disable the automatic database creation in the installation script.

### Install support for right-to-left languages

```bash
sudo apt install -y nodejs
sudo apt install -y npm
sudo npm install -g rtlcss
```

### use pip commands to check your setup

- List all pip3 packages: `sudo pip3 list`
- List all outdated pip3 packages: `sudo pip3 list --outdated`
- Search for a pip3 package/content: `sudo pip3 search <search_term>`
- Install a pip3 package by name: `sudo pip3 install <package_name>`
- Upgrade or install a pip3 package by name: `sudo pip3 install --upgrade <package_name>`
- Display information on a pip3 package: `sudo pip3 show <package_name>`

## License

This project is licensed under the terms of the MIT license.

## Sources:

- [Install Odoo 14 (official Odoo documentation)](https://www.odoo.com/documentation/14.0/administration/install.html#setup-install-source)
- [How to install Odoo 14 on Ubuntu 20.04](https://linuxize.com/post/how-to-install-odoo-14-on-ubuntu-20-04/)
- [How to install Odoo 12 on Ubuntu 18.04](https://linuxize.com/post/how-to-deploy-odoo-12-on-ubuntu-18-04/)
- [How to install python3 on Ubuntu 20.04 and setup a dev environment](https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-20-04-server-de)
- [How to change the default python version on Linuxes](https://www.skillsugar.com/how-to-change-the-default-python-version)
- [How to install python 3.9 on Ubuntu 20.04](https://linuxize.com/post/how-to-install-python-3-9-on-ubuntu-20-04/)
- [How to install wkhtmltopdf on ubuntu 20.04](https://www.osradar.com/how-to-install-wkhtmltopdf-and-wkhtmltoimage-on-ubuntu-20-04/)
- [How to install pip on Ubuntu](https://phoenixnap.com/kb/how-to-install-pip-on-ubuntu)
