#!/bin/bash
#quienes.sh - Script para hacer whois masivo 
#v1.0
#el uso es sencillo, tienes que tener una lista de dominios en el archivo "dominios.txt" y luego ejecutar el script. 
#te va a pedir un nombre de archivo para guardar los datos. No puedes tener un archivo con el mismo nombre.

echo "Recuerda completar el archivo dominios.txt con los dominios que vas a procesar"
echo "Dame un nombre para guardar tu archivo con la salida de todo esto (sin extension)"
read nombre
archivo=$nombre".txt"
echo $archivo

while [ -e $archivo ]
do
	echo "ya tienes un archivo con ese nombre, debes elegir otro nombre (recuerda, sin extension)"
	read nombre
	archivo=$nombre".txt"
	echo $archivo
done
echo "Tu nombre de archivo es "$archivo""

for dominio in $(cat dominios.txt)
do
	echo "###########"
	echo "Consultando dominio:"
	echo $dominio
	#definimos algunos textos utiles para luego imprimir los datos
	#
	#funcion para hacer whois
	fquien(){
		whois $dominio | egrep -i -e 'name server' -e 'no match' -e 'no entries found' -e 'registrant name' -e 'registrant organisation' -e 'registrar name' -e 'registrar URL' -e 'creation date' -e 'expiration date' -e 'No Object Found' -e 'NOT FOUND' -e 'No whois server is known' -e 'No Existe' -e 'no se encuentra registrado' -e 'Redemption period' -e 'redemption'
	}
	#guardamos la salida de la funcion para que la utilicemos despues
	quien=$(fquien)

	#revisaremos si existe el dominio:
	#si no existe, deberia entrar en este if
	if [[ $quien == *"No match"* || $quien == *"no entries found"* || $quien == *"No Object Found"* || $quien == *"NOT FOUND"* || $quien == *"No existe"* || $quien == *"no se encuentra registrado"* ]]; then
		noexiste="El dominio "$dominio" no existe"
		cat <<- EOF >> $archivo
		--------------
		$noexiste
		--------------
		EOF
		echo "$noexiste"
		echo "-----------"
		echo " "
	#esto es para cuando es un dominio desconocido o no tiene nic (?)
	elif [[ $quien == *"No whois server is known"* ]]; then
		noexiste="No se conoce ningún servidor whois para el dominio "$dominio". "
		cat <<- EOF >> $archivo
		--------------
		$noexiste
		--------------
		EOF
		echo "$noexiste"
		echo "-----------"
		echo " "
	#esto es para cuando el dominio se encuentre en el periodo de "redemtion", gil que se le olvidó renovar el dominio y aun lo puede recuperar.
	elif [[ $quien == *"Redemption period"* || $quien == *"redemption"* ]]; then
		noexiste="El dominio "$dominio" está en redemption"
		cat <<- EOF >> $archivo
		--------------
		$noexiste
		--------------
		EOF
		echo "$noexiste"
		echo "-----------"
		echo " "
	else
	#Si el dominio existe, guardaremos datos aticionales
		echo "El dominio "$dominio" si existe"
		#dns de google
		dns="@8.8.8.8"
		#A
		a=$(dig $dns +nocmd +noall +answer +ttlid $dominio a)
		echo "El registro A es:"
		echo "$a"
		#reverso
		ip=$(dig $DNS +short $dominio a)
		reverso=$(dig +short -x $ip)
		echo "El reverso del registro A es:"
		echo "$reverso"
		#MX
		mx=$(dig $DNS +nocmd +noall +answer +ttlid +additional mx $dominio)
		echo "Los registros MX son:"
		echo "$mx"
		echo "-----------"
		cat <<- EOF >> $archivo
		--------------
		El dominio $dominio si existe. 
		Este es el Whois e informacion adicional
		---
		$quien
		---
		A:
		$a
		---
		Reverso
		$reverso
		---
		MX
		$mx
		--------------
		EOF
		echo "Los datos fueron guardados"
	fi
done
echo "Datos guardados en "$archivo""
