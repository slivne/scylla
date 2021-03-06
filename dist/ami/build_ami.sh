#!/bin/sh -e

if [ ! -e dist/ami/build_ami.sh ]; then
    echo "run build_ami.sh in top of scylla dir"
    exit 1
fi

print_usage() {
    echo "build_ami.sh --localrpm --unstable"
    echo "  --localrpm  deploy locally built rpms"
    echo "  --unstable  use unstable branch"
    exit 1
}
LOCALRPM=0
while [ $# -gt 0 ]; do
    case "$1" in
        "--localrpm")
            LOCALRPM=1
            INSTALL_ARGS="$INSTALL_ARGS --localrpm"
            shift 1
            ;;
        "--unstable")
            INSTALL_ARGS="$INSTALL_ARGS --unstable"
            shift 1
            ;;
        *)
            print_usage
            ;;
    esac
done

if [ $LOCALRPM -eq 1 ]; then
    rm -rf build/*
    sudo yum -y install git
    if [ ! -f dist/ami/files/scylla-server.x86_64.rpm ]; then
        dist/redhat/build_rpm.sh
        cp build/rpmbuild/RPMS/x86_64/scylla-server-`cat build/SCYLLA-VERSION-FILE`-`cat build/SCYLLA-RELEASE-FILE`.*.x86_64.rpm dist/ami/files/scylla-server.x86_64.rpm
    fi
    if [ ! -f dist/ami/files/scylla-jmx.noarch.rpm ]; then
        cd build
        git clone --depth 1 https://github.com/scylladb/scylla-jmx.git
        cd scylla-jmx
        sh -x -e dist/redhat/build_rpm.sh $*
        cd ../..
        cp build/scylla-jmx/build/rpmbuild/RPMS/noarch/scylla-jmx-`cat build/scylla-jmx/build/SCYLLA-VERSION-FILE`-`cat build/scylla-jmx/build/SCYLLA-RELEASE-FILE`.*.noarch.rpm dist/ami/files/scylla-jmx.noarch.rpm
    fi
    if [ ! -f dist/ami/files/scylla-tools.noarch.rpm ]; then
        cd build
        git clone --depth 1 https://github.com/scylladb/scylla-tools-java.git
        cd scylla-tools-java
        sh -x -e dist/redhat/build_rpm.sh
        cd ../..
        cp build/scylla-tools-java/build/rpmbuild/RPMS/noarch/scylla-tools-`cat build/scylla-tools-java/build/SCYLLA-VERSION-FILE`-`cat build/scylla-tools-java/build/SCYLLA-RELEASE-FILE`.*.noarch.rpm dist/ami/files/scylla-tools.noarch.rpm
    fi
fi

cd dist/ami

if [ ! -f variables.json ]; then
    echo "create variables.json before start building AMI"
    exit 1
fi

if [ ! -d packer ]; then
    wget https://releases.hashicorp.com/packer/0.8.6/packer_0.8.6_linux_amd64.zip
    mkdir packer
    cd packer
    unzip -x ../packer_0.8.6_linux_amd64.zip
    cd -
fi

packer/packer build -var-file=variables.json -var install_args="$INSTALL_ARGS" scylla.json
