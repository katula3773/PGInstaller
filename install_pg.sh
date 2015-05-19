#!/bin/bash
## Reference
##https://opensourcedbms.com/dbms/setup-pgbouncer-connection-pooling-for-postgresql-on-centosredhatfedora/
##http://www.unixmen.com/install-postgresql-9-4-phppgadmin-ubuntu-14-10/
##http://www.unixmen.com/postgresql-9-4-released-install-centos-7/
##w.if-not-true-then-false.com/2012/install-postgresql-on-fedora-centos-red-hat-rhel/



function getOSVersion {

echo "#####################"

if [ -f "/etc/os-release" ]; then
    ##Ubuntu, Debian, Lubuntu...
  osname=`cat /etc/os-release | sed -n 's/^ID=// p'`
  osversion=`cat /etc/os-release | sed -n -r 's/^VERSION_ID="(.*)"$/\1/ p' | sed 's/\.//g'`
  if [[ $osname == "fedora" ]]; then
        osversion=`rpm -q --qf "%{VERSION}" fedora-release`
  fi
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
else
    echo "Sorry my script only supports CentOS, Ubuntu, Debian and Fedora"
    exit
fi

}


#======================================================
# return 0 if a command does not exist
#======================================================


function checkIfCommandExist {
  command -v $1 >/dev/null 2>&1 || {
  #not found 
  echo 0
    return
  }
  #found
  echo 1
}

#======================================================
#check file /etc/yum.repos.d in fedora 
#======================================================


function checkFileFedoraRepo {
  # check file 
  sed -i '/.*exclude=postgresql\*.*/d' /etc/yum.repos.d/fedora.repo
  sed -i '/\[fedora\]/a exclude=postgresql\*' /etc/yum.repos.d/fedora.repo

  sed -i '/.*exclude=postgresql\*.*/d' /etc/yum.repos.d/fedora-updates.repo
  sed -i '/\[updates\]/a exclude=postgresql\*' /etc/yum.repos.d/fedora-updates.repo
}


#======================================================
# check file /etc/yum.repos.d/CentOS-Base.repo and edit
#======================================================

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


#======================================================
#     Check PGActive Ubuntu
#======================================================


function checkPGActiveUbuntu1204 {
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
}


function checkPGActiveUbuntu {
  case "$osversion" in
    1204)
      checkPGActiveUbuntu1204
    ;;
    1504)
      checkPGActiveUbuntu1204
    ;;
    *)
      echo "general content"
    ;;
  esac
}


#======================================================
#     Check PGActive CenOS
#======================================================

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
  *) 
    echo "general content"
  ;;
  esac
}


#======================================================
#     Check PGActive Fedora
#======================================================

function checkPGActiveFedora21 {
   pg_active=`service  --status-all| grep postgres | grep running`
}

function checkPGActiveFedora {
    echo "check PGActive Fedpra $osversion"
    case "$osversion" in
      21)
        checkPGActiveFedora21
      ;;
      *)
        echo  "general content"
      ;;
    esac
}


#======================================================
#     Check PGActive 
#======================================================

function checkPGActiveDebian8 {
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
}

function checkPGActiveDebian {
  
  case "$osversion" in
  8)
   checkPGActiveCenOS6
  ;;
  *) 
    echo "general content"
  ;;
  esac
}

#======================================================
#     Check PGActive 
#======================================================

function checkPGActive {
  case "$osname" in
  ubuntu)
    checkPGActiveUbuntu
    ;;
  centos)
    checkPGActiveCenOS
    ;;
  fedora)
    checkPGActiveFedora
    ;;
  debian)
    checkPGActiveDebian
    ;;
  esac

  if [ -z "$pg_active" ]; then
    echo 0
  else
    echo 1
  fi
}


#======================================================
# Start postgrest Centos 
#======================================================

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

#======================================================
# Start postgrest 
#======================================================

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


#======================================================
# Intsall postgrest in Ubuntu
#======================================================


function installPostgreslUbuntu1204 {
  echo "----$osversion----"

  sudo apt-get update
  sudo apt-get install postgresql

  if [ $(checkPGActive) -eq 1 ]; then
    echo -e "\e[42mPostgresql is running\e[49m"
  else
    service postgresql-9.4 start
  fi  
}

function installPostgreslUbuntu1504 {
echo "$osversion"

sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

if [ $(checkPGActive) -eq 1 ]; then
    echo -e "\e[42mPostgresql is running\e[49m"
  else
    service postgresql-9.4 start
  fi  
}

function installPostgreslUbuntu {

  echo "$osversion"

  case "$osversion" in
    1204)
      installPostgreslUbuntu1204
    ;;
    1504)
      installPostgreslUbuntu1504
    ;;
    *)
      installPostgreslUbuntu1204
      echo "general content"
    ;;
  esac
}

#======================================================
# Intsall postgrest in CentOS
#======================================================

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
  *) 
    echo "general content"
    ;;
  esac
}

#======================================================
# Intsall postgrest in Fedora 
#======================================================

function installPostgreslFedora21 {

  echo "-----$osversion-----"

  checkFileFedoraRepo



  # os64bit=`uname -m | grep 64`
  # if [ ! -z "$os64bit" ]; then
  #   rpm -Uvh http://yum.postgresql.org/9.4/fedora/fedora-21-x86_64/pgdg-fedora94-9.4-2.noarch.rpm
  # else
  #   rpm -Uvh http://yum.postgresql.org/9.4/fedora/fedora-21-x86_64/pgdg-fedora94-9.4-2.noarch.rpm
  # fi
    rpm -Uvh http://yum.postgresql.org/9.4/fedora/fedora-21-x86_64/pgdg-fedora94-9.4-2.noarch.rpm
    yum update
    yum -y install postgresql94-server postgresql94-contrib
    echo "Initialize database for first time use"
    

}

function installPostgreslFedora {
  echo "+++++++$osversion +++++++"
  case "$osversion" in
  21)
    installPostgreslFedora21
    ;;
  *) 
    echo "general content"
    ;;
  esac
}


#======================================================
# Intsall postgrest in Debian
#======================================================


function installPostgreslDebian8 {
    printf "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
            # test check " > /etc/apt/sources.list.d/pgdg.list

  if [ $(checkIfCommandExist wget) -eq 0 ]; then
      install curl
  fi
    wget https://www.postgresql.org/media/keys/ACCC4CF8.asc
    apt-key add ACCC4CF8.asc
    apt-get update
    apt-get install postgresql

    echo "----successful----"
}

function installPostgreslDebian {
   echo "^^^^^^^^^$osversion^^^^^^^"
  case "$osversion" in
  8)
    installPostgreslDebian8
    ;;
  *) 
    echo "general content"
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
    installPostgreslFedora
    ;;
  debian)
    installPostgreslDebian
    ;;
  esac
}




function cleanDataCentOS {
    echo "Destructive remove all existing data in /var/lib/pgsql/9.4/data/"
    rm -rf /var/lib/pgsql/9.4/data/
}



#======================================================
## Make sure user runs this bash script as root
#======================================================

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
