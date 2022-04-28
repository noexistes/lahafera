#!/bin/bash

file=$1
lista=$2
path=$3

mapfile -t myArray < $lista

if [[ $# -eq 0 ]] || [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then

{

    echo 'Falta ingresar parametro'
    echo 'Se ingresan en este orden'
    echo '1- Archivo '
    echo '2- Lista de equipos '
    echo '3- Path a donde dejar el archivo '
    exit 1

}

else

{

for equipos in "${myArray[@]}"; do
/usr/bin/sudo /usr/local/seguridad/bin/fttput $equipos $file $path$file
done

}

fi


