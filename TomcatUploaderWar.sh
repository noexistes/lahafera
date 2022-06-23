#!/bin/bash

file=$1
lista=$2
path=`pwd`/
asubir=$(basename "$file" .war)
fecha=$(date)


mapfile -t myArray < $lista

echo Inicio una nueva subida del archivo $file con fecha $fecha en los equipos ${myArray[@]} >> /tmp/uploader2.log  2>&1 

if [[ $# -eq 0 ]] ; then

{

    echo 'Falta ingresar parametro'

    exit 1

}

else

{

for equipos in "${myArray[@]}"; do
echo $equipos >> /tmp/uploader2.log 2>&1 
curl -T $file 'http://admin:Genesys2018!@'$equipos':8080/manager/text/deploy?path=/'$asubir'&update=true' >> /tmp/uploader2.log 2>&1

done

}

fi

echo Se termina la subida del archivo $file con fecha $fecha >> /tmp/uploader2.log  2>&1
echo  >> /tmp/uploader2.log  2>&1
echo  >> /tmp/uploader2.log  2>&1 

