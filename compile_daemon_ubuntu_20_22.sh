#!/bin/bash
# Script for compile Daemon and WalletQt for Ubuntu 20 and 22
installBaseLibs() {
	echo "Updating system"
    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y install \
        software-properties-common \
        build-essential \
        libssl-dev \
        libdb++-dev \
        libboost-all-dev \
        libminiupnpc-dev \
        automake \
        autoconf \
        autotools-dev \
        libzmq3-dev \
        git \
        pkg-config \
        libcurl4-openssl-dev \
        libjansson-dev \
        libgmp-dev \
        make \
        g++ \
        gcc \
        libevent-dev \
        libtool
}

compileBerkeleyDB() {
	BERKELEYDB_VERSION=db-4.8.30.NC
	BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}
	# For Venezuelan people uncomment
	# wget https://labs.bolivarcoin.tech:2908/${BERKELEYDB_VERSION}.tar.gz
	wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
	tar -xzf *.tar.gz
	sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
	sudo mkdir -p ${BERKELEYDB_PREFIX}
	cd ${BERKELEYDB_VERSION}/build_unix
	../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
	make
	make install
	sudo rm -rf ${BERKELEYDB_PREFIX}/docs
}

compileBolivarcoinCore() {
	wget https://github.com/BOLI-Project/BolivarCoin/archive/refs/tags/v2.0.0.2.tar.gz
    tar -xzf v2.0.0.2.tar.gz

    cd BolivarCoin-2.0.0.2

    echo ""
    echo -e "\n----------> EXECUTING AUTOGEN"
    ./autogen.sh

    echo ""
    echo -e "\n----------> EXECUTING CONFIGURE"
    ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon

    echo ""
    echo -e "\n----------> EXECUTING MAKE"
    make

    echo ""
    echo -e "\n----------> Preparing Bolivarcoin Binaries"
    cd src
    strip bolivarcoind
    sudo mv bolivarcoind /usr/bin
    strip bolivarcoin-cli
    sudo mv bolivarcoin-cli /usr/bin
    strip bolivarcoin-tx
    sudo mv bolivarcoin-tx /usr/bin
}

isUbuntu() {
    echo "Checking if Ubuntu"
    . /etc/os-release
    case $(awk -F'=' '/^ID=/ {print $2}' /etc/os-release | tr -d '"' ) in
        ubuntu ) echo "Ubuntu" ;;
        * ) echo "ERROR: Only Ubuntu is supported."; exit 1;;
    esac
}

checkUbuntuVersion() {
    echo "Checking Ubuntu version"
    . /etc/os-release
    case $(awk -F'=' '/VERSION_ID/ {print $2}' /etc/os-release | tr -d '"' | cut -b -2) in
        20 ) echo "Ubuntu 20" ;;
        22 ) echo "Ubuntu 22" ;;
        * ) echo "ERROR: Only Ubuntu 20 or 22 are supported."; exit 1;;
    esac
}

isUbuntu
checkUbuntuVersion

echo "Ready to compile... ENTER to continue or CTRL-C to abort"
read X 

echo "Installing Base libs"
installBaseLibs

echo "Installing BerkeleyDB"
compileBerkeleyDB

echo "Compile Bolivarcoin Core v2.0.0.2"
compileBolivarcoinCore

echo "Bolivarcoin Binaries was installed on /usr/bin (bolivarcoind, bolivarcoin-tx, bolivarcoin-cli)"

echo "Complete!"
