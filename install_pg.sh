#!/bin/bash
## Reference
##https://opensourcedbms.com/dbms/setup-pgbouncer-connection-pooling-for-postgresql-on-centosredhatfedora/
##http://www.unixmen.com/install-postgresql-9-4-phppgadmin-ubuntu-14-10/
##http://www.unixmen.com/postgresql-9-4-released-install-centos-7/
##w.if-not-true-then-false.com/2012/install-postgresql-on-fedora-centos-red-hat-rhel/



function getOSVersion {
  if [ -f "/etc/os-release" ]; then
  	##It is likely Ubuntu
    osname=`cat /etc/os-release | grep ID= | head -1 | sed 's/\"//g'`
    osname=${osname:3}                                 
    osversion=`cat /etc/os-release | grep VERSION_ID= | head -1 |  sed 's/\"//g'`
    osversion=${osversion:11}
    return
  fi

  if [ -f "/etc/system-release" ]; then
    sysrelease=`cat /etc/system-release`
    ## CentOS
    if [[ $sysrelease == CentOS* ]]; then        
      ##https://www.centos.org/forums/viewtopic.php?t=488
      osversion=`rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)`
      osname="centos"      
      return
    fi
    ## Fedora
    if [[ $sysrelease == Fedora* ]]; then
    	osversion=`rpm -q --qf "%{VERSION}" fedora-release`
    	osname="fedora$osversion"
    	return
    fi
  else
    echo "Sorry my script only supports CentOS and Ubuntu"
    exit
  fi
}

# check file /etc/yum.repos.d/CentOS-Base.repo, nếu tồn tại thì sửa file đó 
function checkFileCentOSBase {
  # check file 
 if [ -f "/etc/yum.repos.d/CentOS-Base.repo" ];then
  sed -i '/.*exclude=postgresql\*.*/d' /etc/yum.repos.d/CentOS-Base.repo
  sed -i '/\[base\]/a exclude=postgresql\*' /etc/yum.repos.d/CentOS-Base.repo
  sed -i '/\[updates\]/a exclude=postgresql\*' /etc/yum.repos.d/CentOS-Base.repo
  return
 else
    exit
 fi
}

function changePassOfPostgres {
  echo -e  "\e[41mYou are required to change password of postgres user\e[49m"
  passwd postgres
  echo -e  "\e[42mPlease take note the password you just change\e[49m"
}

function getPGConfigPath {
  hbaconf=`sudo -u postgres -H -- psql -c "SHOW hba_file;" | grep pg_hba.conf`
  echo $hbaconf
}
# Return 0 if psql is not found
function checkPGInstalled {
  psql=`which psql`
  if [ -z "$psql" ]; then
    echo 0
  else
    echo 1
  fi
}

function getPGVersion {
  psqlver=`psql --version`
  if [ -z "$psqlver" ]; then
    echo "0.0.0"
  else
    echo ${psqlver:18}
  fi 
}

# checkPGActiveCenOS

function checkPGActiveCenOS6 {
  pg_active=`service  --status-all| grep postgres | grep running`
}

function checkPGActiveCenOS7 {
  pg_active=`systemctl --state=active | grep postgresql`
}

function checkPGActiveCenOS {
 case "$osversion" in
  6)
   checkPGActiveCenOS6
    ;;
  7)
   checkPGActiveCenOS7
    ;;
  *) echo "general content"
    ;;
  esac
}

function checkPGActive {
  case "$osname" in
  ubuntu)
    pg_status=`service postgresql status`

    pg_dead=`echo $pg_status | grep dead` #check if postgresql service is dead in new Ubuntu

    if [ ! -z "$pg_dead" ]; then
      echo 0 #postgresql service stops
      return
    fi

    pg_active=`echo $pg_status | grep exited` #check if postgresql service is running

    if [ -z "$pg_active" ]; then
      #Check Ubuntu 12.x
      pg_active=`echo $pg_status | grep Running | grep main`      
    fi
    ;;
  centos)
    checkPGActiveCenOS
    ;;
  esac

  if [ -z "$pg_active" ]; then
    echo 0
  else
    echo 1
  fi
}

# startPostgresCenOS

function startPostgresCenOS6 {
   pgservice=`service  --status-all| grep postgres`
    spaceIndex=`expr index "$pgservice" " "`
    pgservice=${pgservice:0:spaceIndex}
    service $pgservice start
}
function startPostgresCenOS7 {
   pgservice=`systemctl --state=inactive | grep postgresql`   
    pgservice=${pgservice/.service*/}
    systemctl start $pgservice
}

function startPostgresCenOS {
case "$osversion" in
  6)
   startPostgresCenOS6
    ;;
  7)
   startPostgresCenOS7
    ;;
  *) echo "general content"
    ;;
  esac
}

function startPostgres {
  case "$osname" in
  ubuntu)
    service postgresql start
    ;;
  centos)
    startPostgresCenOS
    ;;
  esac
}



function installPostgreslUbuntu {
    apt-get install postgresql postgresql-client postgresql-contrib libpq-dev
}

# installPostgreslCentOS

function installPostgreslCentOS6 {

  checkFileCentOSBase 

  os64bit=`uname -m | grep 64`
  if [ ! -z "$os64bit" ]; then
    rpm -Uvh http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-1.noarch.rpm
  else
    rpm -Uvh http://yum.postgresql.org/9.4/redhat/rhel-6-i386/pgdg-centos94-9.4-1.noarch.rpm
  fi
  yum update
  yum -y install postgresql94-server postgresql94-contrib
  echo "Initialize database for first time use"
  service postgresql-9.4 initdb
  
  chkconfig postgresql-9.4 on

  if [ $(checkPGActive) -eq 1 ]; then
    echo -e "\e[42mPostgresql is running\e[49m"
  else
    service postgresql-9.4 start
  fi  
}

function installPostgreslCentOS7 { 

    checkFileCentOSBase


    if ! rpm -qa | grep pgdg-centos94-9.4-1 
    then
      echo "install pgdg-centos94-9.4-1.noarch.rpm"
      rpm -Uvh http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm
    else
      echo "pgdg-centos94-9.4-1.noarch.rpm is already installed. Skip"
    fi

    yum update

    if ! yum list installed | grep postgresql94-server 
    then
      echo "Install postgresql94-server"
      yum -y install postgresql94-server
    else
      echo "postgresql94-server is already installed. Skip"
    fi

    if ! yum list installed | grep postgresql94
    then 
      echo "Install postgresql94"
      yum -y install postgresql94
    else
      echo "postgresql94 is already installed. Skip"
    fi

    if ! yum list installed | grep postgresql94-contrib
    then
            echo "Install postgresql94-contrib"
            yum -y install postgresql94-contrib
    else
      echo "postgresql94-contrib is already installed. Skip"
    fi
    echo "Initialize database for first time use"
    /usr/pgsql-9.4/bin/postgresql94-setup initdb
}

function installPostgreslCentOS {
  echo "$osversion"
 case "$osversion" in
  6)
   installPostgreslCentOS6
    ;;
  7)
   installPostgreslCentOS7
    ;;
  *) echo "general content"
    ;;
  esac
}



# Install Postgresql 9.4.1 on RedHat 19/20/21, CentOS 6, 7
# http://www.if-not-true-then-false.com/2012/install-postgresql-on-fedora-centos-red-hat-rhel/
function installPostgresql {
  echo "Install Postgresql on $osname $osversion"
  case "$osname" in
  ubuntu)
    installPostgreslUbuntu
    ;;
  centos)
    installPostgreslCentOS
    ;;
  fedora)
    installPostgreslCentOS7
    ;;
  esac
}

function cleanDataCentOS {
    echo "Destructive remove all existing data in /var/lib/pgsql/9.4/data/"
    rm -rf /var/lib/pgsql/9.4/data/
}

##---------------
## Make sure user runs this bash script as root
if [ $(id -u) -ne 0 ]; then
   echo -e  "\e[41mMust run as root user\e[49m"
   exit
fi

getOSVersion
echo $osname

if [ $(checkPGInstalled) -eq 1 ]; then
  pgversion=$(getPGVersion)
  echo "Postgresql $pgversion is installed"
  if [ $(checkPGActive) -eq 1 ]; then
    echo -e "\e[42mPostgresql is running\e[49m"
  else
    echo -e "\e[41mPostgresql stops\e[49m"
    echo -n "Do you want to start Postgresql [y/n]?"
    read answer
    if [ "$answer" == "y" ]; then
        startPostgres
        if [ $(checkPGActive) -eq 1 ]; then
          echo -e "\e[42mPostgresql is running\e[49m"
        else
          echo -e "\e[41mFail to start Postgresql\e[49m"
          exit
        fi
    fi
  fi
else
  echo -e "\e[43mPostgresql is not installed\e[49m. Do you want to install it[y/n]?"
  read answer
  if [ "$answer" == "y" ]; then
  	installPostgresql
  else
  	exit
  fi
fi


#
#changePassOfPostgres
getPGConfigPath
