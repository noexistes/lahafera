#!/bin/bash

## Se pisa el archivo LISTADO para que al ejecutarse de forma continua siempre este vacio
## Asignamos en el primer valor la carpeta de rules
## Se hace un GREP buscando INACTIVOS y se los lista en /tmp/listado
## Se borran todos esos archivos 

hacerCarpetas (){
                    echo "mkdir $1"
                }

carpeta=/var/log
hacerCarpetas $carpeta
echo $?
lll 
echo $?