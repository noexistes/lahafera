#!/bin/bash

file=$1
lista=$2
path=$3

mapfile -t myArray < $lista

if [[ $# -eq 0 ]] ; then

{

    echo 'Falta ingresar parametro'

    exit 1

}

else

{

for equipos in "${myArray[@]}"; do
/usr/bin/sudo /usr/local/seguridad/bin/fttput $equipos $file $path$file
done

}

fi


