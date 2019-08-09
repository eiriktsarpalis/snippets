#!/usr/bin/env bash

# prints location and last modified date of corefx assembly name

if [ -z $1 ]; then
    COREFX_ASSEMBLY="System.Net.Http"
else
    COREFX_ASSEMBLY=$1
fi

FSX_FILE=/tmp/corefx-checker-$RANDOM.fsx
echo 'let info = System.IO.FileInfo((System.Reflection.Assembly.Load("'$COREFX_ASSEMBLY'")).Location) in printfn "%s, Last modified (UTC) %O" info.FullName info.LastWriteTimeUtc' > $FSX_FILE
dotnet fsi $FSX_FILE

rm -f $FSX_FILE