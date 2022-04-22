#!/bin/bash

# Author: Juan Gutierrez

#Primero vamos a  https://github.com/s4vitar/evilTrust y copiamos la paleta de colores en el archivo evilTrust.sh

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"


#Ponemos el siguiente comando para cuando apretemos ctrl + c establecer a donde queremos que se redirija el flujo del programa

trap ctrl_c INT

function ctrl_c(){
   echo -e "\n${redColour}[!] Saliendo...\n${endColour}"


   # Al colocar ctrl c lo normal es poner tput cnorm para volver a obtener el cursor y añadimos una salida no exitosa que devuelva que devuelva un 
   #codigo de estado no exitos

   #Para borrar archivos temporales
   rm ut.t* money* total_entrada_salida.tmp entradas.tmp salidas.tmp 2>/dev/null

   tput cnorm; exit 1
}

#Establecemos variables globales

#Transacciones sin confirmar
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
#Ponemos la url de inpeccion de la transaccion
inspect_transaction_url="https://www.blockchain.com/es/btc/tx/"
#Url para inpeccionar un hash específico
inspect_address_url="https://www.blockchain.com/es/btc/address/"



#Panel de ayuda 
function helpPanel(){
    echo -e "\n${redColour}[!] Uso: ./btcAnayzer${endColour}"
    
    #Ponemos una linea delimitadora horizontal con un bucle
    #Para que me haga todos los guiones en la misma lína colocamos -n 
    #Como vamos a poner caracteres especiales colocamos también e 
    for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
   
    echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} Modo exploración${endColour}"
    echo -e "\t\t${purpleColour}unconfirmed_transactions${endColour}${yellowColour}:\t Listar transaccione no confirmadas${endColour}" 
    echo -e "\t\t${purpleColour}inspect${endColour}${yellowColour}:\t\t\t Inspeccionar un hash de transacción${endColour}"
    echo -e "\t\t${purpleColour}address${endColour}${yellowColour}:\t\t\t Inspeccionar una dirección${endColour}"
    #Definimos el numero de resultados que queremos mostrar con -n
    echo -e "\n\t${grayColour}[-n]${endColour}${yellowColour} Limitar el número de resultados${endColour}${blueColour} (Ejemplo: -n 10)${endColour}"
    
    echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour} Proporecionar el identificafor de transacción${endColour}${blueColour} (Ejemplo: -i d0a300fc15a0cff2c74166039570c957bc40c3ffd92f1054b1beabb3a8973bf0)${endColour}"
   
    echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour} Proporcionar una dirección de transacción${endColour}${blueColour} (Ejemplo: -a d0a300fc15a0cff2c74166039570c957bc40c3ffd92f1054b1beabb3a8973bf0)${endColour}"

    echo -e "\n\t${grayColour}[-h]${endColour}${yellowColour} Mostrar este panel de ayuda${endColour}\n"

   #si finaliza es porque lo estas ejecutando mal, finalizamos con un codigo de estado no exitoso y recuperamos el cursor tput cnorm
   
    tput cnorm; exit 1

}


#La siguiente funcion fue extraida de https://github.com/s4vitar/htbExplorer/blob/master/htbExplorer 
#Funciona creando tablas donde se adecuan de manera dinamica al tamaño de la cadena 


function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}


# Utilizamos curl para obtener los datos de la página web y usamos html2text para convertirlo en un formato legible
# Silenciamos el  verbose que trae curl con el parámetro -s 
# Con less -S lo ponemos en formato paging para analizarlo
# Usamos grep "Hash" -A 1 para imprimir la palabra hash y lo que está debajo que seria el hash
# Eliminamos palabras con el parametro -v ponemos múltiples parámetros con -E y a continuacion ponemo los elementos a eliminar "Hash|--"
# Con grep el guion es un carácter especial que puede darte problemas
# por eso es recondable colocar la barra invertida antes de los guiones "Hash|\--|Tiempo" 

function unconfirmedTransactions(){
    #Generalmente $1 hace referencia al primer argumento de un programa
    number_output=$1

    echo '' > ut.tmp

    while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
	curl -s "$unconfirmed_transactions" | html2text > ut.tmp
    done


    hashes=$(cat ut.tmp | grep "Hash" -A 1 | grep -v -E "Hash|\--|Tiempo" | head -n $number_output)


    # podriamos ver los hashes con un salto de linea con un bucle for de la siguiente forma pero utilizarems tablas

#    for hash in $hashes; do
#        echo $hash
#    done

    #Para crear una tabla, lo que necesitas es especificar un criterio, para saber cuando tiene que hacer un salto de fila

    #Barra baja es el criterio que vamos a utilizar para la funcion print table

    echo "Hash_Dolares_Bitcoin_Tiempo" > ut.table
    
    #Guardo los datos a la tabla
    for hash in $hashes; do
    	echo "${hash}_$(cat ut.tmp | grep "$hash" -A 6 | tail -n 1 | tr -d 'Â US$')_$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 2 | tail -n 1)" >> ut.table
    done
   
   #Guarda el dinero en el fichero money
    cat ut.table | tr '_' ' ' | awk '{print $2}' | grep -v "Dolares" | tr -d 'Â US$' | sed 's/\.//g' > money

   #Sumatoria de dinero

    money=0; cat money | while read money_in_line; do
	let money+=$money_in_line 2>/dev/null 
	echo $money > money.tmp 
    done;
 
   # Creo  el criterio del total y lo guardo en un fichero, luego guardo la cantidad en el mismo fichero
    echo -n "Cantidad total_" > amount.table
    echo "\$$(printf "%'.d\n" $(cat money.tmp))" >> amount.table
    
   # Creo las tablas sin antes comprobar que el el fichero no este vacio
    if [ "$(cat ut.table | wc -l)" != "1" ]; then
	echo -ne "${yellowColour}"
        printTable '_' "$(cat ut.table)"
	echo -ne "${endColour}"
        echo -ne "${blueColour}"
        printTable '_' "$(cat amount.table)"
        echo -ne "${endColour}"
	
	rm ut.* money* amount.table 2>/dev/null
        tput cnorm; exit 0
    else
	rm ut.t* 2>/dev/null

    fi
    #Recuperamos el cursor  y borramos ficheros
    rm ut.* money* amount.table
    tput cnorm
}

function inspectTransaction(){
	inspect_transaction_hash=$1

	echo "Entrada Total_Salida Total" > total_entrada_salida.tmp

 	while [ "$(cat total_entrada_salida.tmp | wc -l)" == "1" ]; do
        	curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | html2text | grep -E "Entradas totales|Gastos totales" -A 1  | grep -v -E "Entradas totales|Gastos totales" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> total_entrada_salida.tmp
        done

	echo -ne "${grayColour}"
	printTable '_' "$(cat total_entrada_salida.tmp)"
	echo -ne "${endColour}"

	rm total_entrada_salida.tmp 2>/dev/null

	echo "Dirección (Entradas)_Valor" > entradas.tmp

	while [ "$(cat entradas.tmp | wc -l)" == "1" ];do

		curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | html2text | grep "Entradas" -A 500 | grep "Gastos" -B 500 | grep "Direcc" -A 3 | grep -v -E "Direcci|Valor|\--" | awk 'NR%2{printf "%s ",$0;next;}1' |  awk '{print $1 "_" $2 " " $3}' >> entradas.tmp

	done

	echo -ne "${greenColour}"
	printTable '_' "$(cat entradas.tmp)"
	echo -ne "${endColour}"

	rm entradas.tmp 2>/dev/null




	echo "Dirección (Salidas)_Valor" > salidas.tmp

        while [ "$(cat salidas.tmp | wc -l)" == "1" ];do

             curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | html2text | grep "Gastos$" -A 500 | grep "Ya lo has pensado" -B 500 | grep "Direcc" -A 3 | grep -v -E "Direcci|Valor|\--" | awk 'NR%2{printf "%s ",$0;next;}1' |  awk '{print $1 "_" $2 " " $3}' >> salidas.tmp

        done

        echo -ne "${greenColour}"
        printTable '_' "$(cat salidas.tmp)"
        echo -ne "${endColour}"

        rm salidas.tmp 2>/dev/null

	tput cnorm

}

function inspectAddress(){
	address_hash=$1
	echo "Transacciones realizadas_Cantidad total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total en la cuenta (BTC)" > address.information
	curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Transacciones|Total recibido|Total enviado|Saldo final" -A 1 | head -n -2 | grep -v -E "Transacciones|Total recibido|Total enviado|Saldo final" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> address.information

	echo -ne "${grayColour}"
	printTable '_' "$(cat address.information)"
	echo -ne "${endColour}"
	rm address.information 2>/dev/null


###3######################Revisar!!!1 la siguiente parte del codigo no funciona, no realiza la conversion de btc a dolares
#https://github.com/s4vitar/btcAnalyzer/blob/master/btcAnalyzer.sh

        bitcoin_value=$(curl -s "https://cointelegraph.com/bitcoin-price-index" | html2text | grep "Last Price" | head -n 1 | awk 'NF{print $NF}' | tr -d ',')

	curl -s "${inspect_address_url}${address_hash}" | html2text | grep "Transacciones" -A 1 | head -n -2 | grep -v -E "Transacciones|\--" > address.information 

	curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Total recibido|Total enviado|Saldo final" -A 1 | grep -v -E "Total recibido|Total enviado|Saldo final|\--" | tr -d "$" > bitcoin_to_dollars


	cat bitcoin_to_dollars | while read value; do
		echo "\$$(printf "%'.d\n" $(echo "$(echo $value | awk '{print $1}')*$bitcoin_value" | bc) 2>/dev/null)" >> address.information

	done

	line_null=$(cat address.information | grep -n "^\$$" | awk '{print $1}' FS=":")

	if [ "$(echo $line_null | grep -oP '\w')" ]; then
		echo $line_null | tr ' ' '\n' | while read line; do
			sed "${line}s/\$/0.00/" -i address.information
		done
	fi

	cat address.information | xargs | tr ' ' '_' >> address.information2
	rm address.information 2>/dev/null && mv address.information2 address.information
	sed '1iTransacciones realizadas_Cantidad total recibidas (USD)_Cantidad total enviada (USD)_ Saldo actual en la cuenta (USD)' -i address.information

	echo -ne "${grayColour}"
	printTable '_' "$(cat address.information)"
	echo -ne "${endColour}"

	rm address.information bitcoin_to_dollars 2>/dev/null
	tput cnorm


}



#Para establecer un panel de ayuda utilizamos getopts
#arg es la variable  que va responder al parametro que le estemos pasando 
#optarg nos permite almacenar los parametros pasados cuando ejecutamos el script, Ej: ./btcAnalyzer.sh -e loquesea

#definir parameter_counter nos permite hacer comparativas a nivel de condicional para determinar si ha entrado en determinada opción o no

#Si ponemos otra letra nos dice opción ilegal y nos lanza el panel de ayuda

parameter_counter=0; while getopts "e:n:i:a:h:" arg; do
   case $arg in
     e) exploration_mode=$OPTARG; let parameter_counter+=1;;
     n) number_output=$OPTARG; let parameter_counter+=1;;
     i) inspect_transaction=$OPTARG; let parameter_counter+=1;; 
     a) inspect_address=$OPTARG; let parameter_counter+=1;;
     h) helpPanel;;
   esac
done

#tput civis nos permite ocultar el cursor

tput civis


#Si parameter counter tiene el valor 0 significa que no se ha ejecutado el programa correctamente y nos dirige a helpPanel

if [ $parameter_counter -eq 0 ]; then
   helpPanel
else
    if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
         if [ ! "$number_output" ]; then
            number_output=100
            unconfirmedTransactions $number_output
         else
            unconfirmedTransactions $number_output
         fi

     elif [ "$(echo $exploration_mode)" == "inspect" ]; then
            inspectTransaction $inspect_transaction

     elif [ "$(echo $exploration_mode)" == "address" ]; then
            inspectAddress $inspect_address

     fi

fi




