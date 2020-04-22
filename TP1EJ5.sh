#!/bin/bash

#Funcion que muestra la ayuda
function ayuda(){
    echo "Este script se ha creado con la finalidad de procesar las notas de un archivo de notas"
    echo "Este script contabilizará la cantidad de alumnos que abandonaron, recursan, pueden recuperar o pueden rendir final de una materia"
    echo "La ejecución del script se hace de la siguiente forma:"
    echo "./TP1EJ.sh -f archivo_de_notas"
    echo "La ruta del archivo de notas puede ser absoluta o relativa"
	exit 0
} 

if [ $1 = "-h" -o $1 = "-?" -o $1 = "-help" ]; then
    ayuda
fi

if [ $# -ne 2 ]; then
    echo "La cantidad de parámetros no es correcta. Escriba './TP1EJ5.sh -h', './TP1EJ5.sh -?', o './TP1EJ5.sh -help' (sin comillas) para recibir ayuda"
    exit 1
fi

if  [ $1 != "-f" ];then
    echo "El segundo parámetro debe ser '-f'"
    exit 2
fi

if [ ! -f "$2" ];then
    echo "El archivo que pasó por parámetro no existe"
    exit 3
fi

if [ ! -s "$2" ];then
    echo "El archivo que pasó por parámetro está vacío"
    exit 4
fi

archivo="$2"

declare -a array
i=0

declare -A Final
declare -A Recursan
declare -A Recuperan
declare -A Abandonaron
declare -A materias

cantmaterias=0

a=0

while IFS= read -r line
do
    array[$i]+=$line
    let "i++"
done < $archivo

for i in ${array[@]}
do
    IFS='| ' read -r -a nuevoArray <<< "$i"
    if [ ${nuevoArray[0]} != 'DNI' ]; then

        materia=${nuevoArray[1]}    #Guardo el número de la materia

        seRepitio=1             #Reviso si el número de la materia está en el array de materias. Si no está, se agrega
        for a in ${materias[@]}
        do
            if [ $a -eq $materia ]; then
                seRepitio=0
            fi
        done

        if [ $seRepitio -eq 1 ];then
            materias[$cantmaterias]+=$materia
            let "cantmaterias++"
        fi

        if [[ -z "${Final[$materia]}" ]];then   #reviso si los arrays con el numero de materia están vacíos. Si lo están, los inicializo en 0 
            Final[$materia]=0
            Recursan[$materia]=0
            Recuperan[$materia]=0
            Abandonaron[$materia]=0
        fi
        
        #BORRAR ESTO
        echo "DNI: ${nuevoArray[0]}"
        echo "Materia: ${nuevoArray[1]}"
        echo "Nota parcial 1: ${nuevoArray[2]}"
        echo "Nota parcial 2: ${nuevoArray[3]}"
        echo "Rinde recuperatorio: ${nuevoArray[4]}"
        echo "Nota Recuperatorio: ${nuevoArray[5]}"
        echo "Nota Final: ${nuevoArray[6]}"

        if [[ ! -z "${nuevoArray[6]}" ]]; then  #Reviso si tiene nota en el final
           if [ ${nuevoArray[6]} -gt 3 ]; then  #Si tiene nota en el final, reviso si es mayor o igual a 4
                let "a++"                       #Si se cumple, no es necesario guardarla 
           else
                Recursan[$materia]=$((${Recursan[$materia]}+1)) #si no se cumple, el alumno recursa
           fi   
        else                                    #Si llego hasta acà, el alumno no tiene nota en el final
            if [[ ! -z "${nuevoArray[4]}" ]]; then  #Pregunto si tiene nota en el recuperatorio
                if [ ${nuevoArray[4]} -eq 1 ]; then #Si tiene nota, pregunto si es en el primero
                    if [ ${nuevoArray[3]} -gt 6 -a ${nuevoArray[5]} -gt 6 ]; then #Si la nota de ambos es mayor a 6, no lo guardo
                        let "a++"
                    elif [ ${nuevoArray[3]} -lt 4 -o ${nuevoArray[5]} -lt 4 ]; then #Si la nota de uno de los dos es menor a 4, recursa
                        Recursan[$materia]=$((${Recursan[$materia]}+1))
                    else
                        Final[$materia]=$((${Final[$materia]}+1))
                    fi
                else                            #Si llega hasta acà, es porque rindió recuperatorio del segundo
                    if [ ${nuevoArray[2]} -gt 6 -a ${nuevoArray[5]} -gt 6 ]; then #Si la nota de ambos es mayor a 6, no lo guardo
                        let "a++"
                    elif [ ${nuevoArray[2]} -lt 4 -o ${nuevoArray[5]} -lt 4 ]; then #Si la nota de uno de los dos es menor a 4, recursa
                        Recursan[$materia]=$((${Recursan[$materia]}+1))
                    else
                        Final[$materia]=$((${Final[$materia]}+1))
                    fi
                fi
            else                            #Si llegò hasta acá, no tienen nota ni en el final, ni en el recuperatorio
                if [[ -z "${nuevoArray[2]}" ]]; then #Si le falta nota en al menos un parcial, abandonó
                    Abandonaron[$materia]=$((${Abandonaron[$materia]}+1))
                elif [[ -z "${nuevoArray[3]}" ]]; then
                    Abandonaron[$materia]=$((${Abandonaron[$materia]}+1))
                else    #Si llegò hasta acá, el alumno no abandonó
                    if [ ${nuevoArray[2]} -gt 6 -a ${nuevoArray[3]} -gt 6 ]; then #Si la nota de ambos es mayor a 6, no lo guardo
                        let "a++"
                    elif [ ${nuevoArray[2]} -lt 4 -a ${nuevoArray[5]} -lt 4 ]; then #Si la nota los dos es menor a 4, recursa
                        Recursan[$materia]=$((${Recursan[$materia]}+1))
                    elif [ ${nuevoArray[2]} -lt 4 -o ${nuevoArray[5]} -lt 4 ]; then #Si la nota de solo uno de los dos es menor a 4, recupera
                        Recuperan[$materia]=$((${Recuperan[$materia]}+1))
                    else                #Si llegó hasta acá, en los dos parciales sacó más de 3 pero menos de 7
                        Final[$materia]=$((${Final[$materia]}+1))
                    fi
                fi
            fi
        fi
        echo "----"
    fi
done

string='"Materia","Final","Recursa","Recuperan","Abandonaron"'
echo $string
#echo $string > salida.out

for subject in ${materias[@]}
do
    string=''
    string+='"'
    string+=$subject
    string+='",'
    string+='"'
    string+=${Final[$subject]}
    string+='",'
    string+='"'
    string+=${Recursan[$subject]}
    string+='",'
    string+='"'
    string+=${Recuperan[$subject]}
    string+='",'
    string+='"'
    string+=${Abandonaron[$subject]}
    string+='",'
    linea=`echo $string | sed 's/.$//g'`
    echo $linea
done