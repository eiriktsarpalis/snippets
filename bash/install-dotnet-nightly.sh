#!/usr/bin/env bash

if [[ $0 = $_ ]]; then
    # need to source the script, detect if run standalone
    echo "USAGE: . $0 <args>"
    return 1
fi

usage()
{
    echo "Usage:"
    echo "    -r <track>    Release track to download. Defaults to master, but can also be release/3.0.1xx"
    echo "    -h            this help text."
    echo ""
}

fail()
{
    echo "ERROR: $@"
    echo ""
    usage
    return 1
}

# derived from https://github.com/dotnet/core-sdk/blob/master/README.md#installers-and-binaries
DOTNET_SDK_NIGHTLY_BUILDS_SOURCE=https://dotnetcli.blob.core.windows.net/dotnet/Sdk
RELEASE_TRACK=master

OPTIND=1
while getopts "hr:" opt; do
    case $opt in
        r)
            RELEASE_TRACK=$OPTARG
            ;;
        h)
            usage
            return 0
            ;;
        *)
            fail "Unrecognized argument"
            ;;
    esac
done

getSdkUrl()
{
    # TODO x86? other arches?
    case $OSTYPE in
    *darwin*)
        echo $DOTNET_SDK_NIGHTLY_BUILDS_SOURCE/$RELEASE_TRACK/dotnet-sdk-latest-osx-x64.tar.gz
        ;;
    *linux*)
        echo $DOTNET_SDK_NIGHTLY_BUILDS_SOURCE/$RELEASE_TRACK/dotnet-sdk-latest-linux-x64.tar.gz
        ;;
    *)
        echo $DOTNET_SDK_NIGHTLY_BUILDS_SOURCE/$RELEASE_TRACK/dotnet-sdk-latest-win-x64.zip
        ;;
    esac
}

installSdkToFolder()
{
    target_sdk_folder=$1
    source_sdk_archive=$2

    echo "Downloading dotnet sdk nightly $source_sdk_archive to $target_sdk_folder"

    target_sdk_archive=$target_sdk_folder/$(basename $source_sdk_archive)
    mkdir -p $target_sdk_folder
    curl -q $source_sdk_archive --output $target_sdk_archive
    
    case $target_sdk_archive in
    *.zip)
        unzip -q $target_sdk_archive -d $target_sdk_folder
        ;;
    *.tar.gz|*tgz)
        tar xfz $target_sdk_archive -C $target_sdk_folder
        ;;
    *)
        echo "do not know how to extract file $target_sdk_archive"
        ;;
    esac
}

installEnvironmentVariables()
{
    target_sdk_folder=$1
    export PATH=$target_sdk_folder:$PATH
    export DOTNET_ROOT=$target_sdk_folder
    export DOTNET_MULTILEVEL_LOOKUP=0
    export DOTNET_ROLL_FORWARD_ON_NO_CANDIDATE_FX=2
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    
    echo "using dotnet sdk $(dotnet --version) from $target_sdk_folder"
}

INSTALL_FOLDER=/tmp/dotnet-nightly-$(echo $RELEASE_TRACK | sed -e 's_^release/__')-$(date +%y%m%d)

if [ ! -d $INSTALL_FOLDER ]; then
    installSdkToFolder $INSTALL_FOLDER $(getSdkUrl)
else
    echo "Nightly installation exists, skipping download."
fi

installEnvironmentVariables $INSTALL_FOLDER