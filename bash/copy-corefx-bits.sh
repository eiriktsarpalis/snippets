#!/usr/bin/env bash

usage()
{
    echo "Usage:"
    echo "    -s <path>     source corefx repo. Can also be specified using COREFX_ROOT environment variable."
    echo "    -t <path>     target dotnet sdk to copy bits to. Can also be specified using DOTNET_ROOT environment variable."
    echo "    -c <path>     Build configuration to copy artifacts from. Defaults to Release."
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

while getopts "hs:t:c:" opt; do
    case $opt in
        s)
            COREFX_ROOT=$OPTARG
            ;;
        d)
            DOTNET_ROOT=$OPTARG
            ;;
        c)
            CONFIGURATION=$OPTARG
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

[ -z $COREFX_ROOT ] && fail "COREFX_ROOT not specified"
[ -z $DOTNET_ROOT ] && fail "DOTNET_ROOT not specified"
[ -z $CONFIGURATION ] && CONFIGURATION=Release

dirname_p()
{
    if read data && [ ! -z $data ]; then
        dirname $data
    else
        echo "$1"
        return 1
    fi
}

getSourceDirectory()
{
    find "$COREFX_ROOT/artifacts/bin/testhost" -type f -name 'System.Net.Http.dll' \
    | grep "$CONFIGURATION-[^/]*/shared/Microsoft.NETCore.App" \
    | head -n 1 \
    | dirname_p "could not find appropriate corefx bits in $COREFX_ROOT for $CONFIGURATION. Have you built the repo?"
}

getTargetDirectory()
{
    find "$DOTNET_ROOT/shared/Microsoft.NETCore.App" -type f -name 'System.Net.Http.dll' \
    | head -n1 \
    | dirname_p "could not find target bits in $DOTNET_ROOT"
}

SOURCE=$(getSourceDirectory)
TARGET=$(getTargetDirectory)

cp -fRv "$SOURCE/." "$TARGET/"

if [ $? -eq 0 ]; then
    echo "Sucessfully copied corefx artifacts"
else
    echo "Failed to copy corefx artifacts"
    return 1
fi