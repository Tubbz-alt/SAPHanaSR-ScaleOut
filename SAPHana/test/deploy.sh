#!/bin/sh
#
# Little script to deploy newest version of SAP Hana resource agents in a cluster
#
# by Markus Guertler (SUSE)
#
# Adjust the HOSTS and DOMAIN variables below
# Execute this script on a non-cluster host, that has ssh key constrainsts to all cluster nodes
#
# The script
# - downloads a filelist containing all files that have to be deployed
# - downloads a Makefile, that installs all files into the right directories
# - Copies the downloaded files to all cluster nodes
# - Executes make install on all cluster nodes to install the files
#
# Resource agents are not being installed directly, but copied to .stage files and then moved to the original filenames
# 

HOSTS="vm01 vm02 vm02 vm03 vm04 vm05 vm06 vm07 vm08 vm09 vm11 vm12 vm13 vm14 vm15 vm16 vm17 vm18 vm19" # All cluster node hostnames (ssh key-constraints must be set)
DOMAIN=".hana.lab" # Domain, can be omitted
BASEURL="https://server.guertler.org/saphana/scale-out/" # BaseURL of the Download Server
DEPLOYDIR="HanaSR-files" # Temporally deployment directory (directory will be created)

mkdir -p ${DEPLOYDIR}

# Download files
echo "* Dowloading SAPHanaSR files list"
rm ${DEPLOYDIR}/filelist
wget --directory-prefix=${DEPLOYDIR} ${BASEURL}/filelist
if [ $? -gt 0 ]; then
        echo "Error while downloading SAPHanaSR files list from $BASEURL"
        exit 1
fi

echo "* Dowloading SAPHanaSR files"
for file in $(cat ${DEPLOYDIR}/filelist); do
        rm ${DEPLOYDIR}/${file}
        wget --directory-prefix=${DEPLOYDIR} ${BASEURL}/${file}
        if [ $? -gt 0 ]; then
                echo "Error while downloading SAPHanaSR file ${file} from ${BASEURL}"
                exit 1
        fi
done

# Deploy files
for host in ${HOSTS}; do
        echo "********************************"
        echo " -> $host: Copying SAPHanaSR files"
        ssh root@$host$DOMAIN "mkdir -p $DEPLOYDIR"
        scp -r $DEPLOYDIR/* root@$host$DOMAIN:~/$DEPLOYDIR
        echo "********************************"
        echo " -> $host: Installing SAPHanaSR files"
        ssh root@$host$DOMAIN "cd $DEPLOYDIR && make install"
done
