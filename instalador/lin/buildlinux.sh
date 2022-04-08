#!/bin/bash
ARQUITETURA=$(uname -m)
case $(uname -m) in
	i386) 	ARQUITETURA="i386";;
	i686) 	ARQUITETURA="i386";;
	x86_64)	ARQUITETURA="amd64";;
	arm) 	ARQUITETURA="arm";;
esac

echo $ARQUITETURA

if [ $ARQUITETURA = 'amd64' ]; 
then
	echo "AMD64 Script"
	echo "Preparando binarios"
	cp ./src/balanca ./balanca/usr/bin/balanca
	chmod 777 ./balanca/usr/bin/balanca
	cp ./src/balanca.png ./balanca/usr/share/icons/hicolor/balanca.png
	cp ./balanca.desktop_arm ./balanca/usr/share/applications/balanca.desktop
	#ln -s /usr/bin/balanca ./balanca/usr/share/applications/balanca
	echo "Empacotando"
	dpkg-deb --build balanca
	echo "Movendo para pasta repositorio"
	mv balanca.deb balanca-2.9_amd64.deb
	cp ./balanca-2.9_amd64.deb ./bin/
	exit 1;
fi

if [ $ARQUITETURA = 'i686' ];
then
	echo "i686 Script"
	echo "Preparando binarios"
	cp ./src/balanca ./balanca/usr/bin/balanca
	chmod 777 ./balanca/usr/bin/balanca
	cp ./src/balanca.png ./balanca/usr/share/icons/hicolor/balanca.png
	cp ./balanca.desktop_arm ./balanca/usr/share/applications/balanca.desktop
	#ln -s /usr/bin/balanca ./balanca/usr/share/applications/balanca
	echo "Empacotando"
	dpkg-deb --build balanca
	echo "Movendo para pasta repositorio"
	mv balanca.deb balanca-2.9_i686.deb
	cp ./balanca-2.9_i686.deb ./bin/
	exit 1;
fi

if [ $ARQUITETURA = 'i386' ];
then
	echo "i386 Script"
	echo "Preparando binarios"
	cp ./src/balanca ./balanca/usr/bin/balanca
	chmod 777 ./balanca/usr/bin/balanca
	cp ./src/balanca.png ./balanca/usr/share/icons/hicolor/balanca.png
	cp ./balanca.desktop_arm ./balanca/usr/share/applications/balanca.desktop
	#ln -s /usr/bin/balanca ./balanca/usr/share/applications/balanca
	echo "Empacotando"
	dpkg-deb --build balanca
	echo "Movendo para pasta repositorio"
	mv balanca.deb balanca-2.9_i386.deb
	cp ./balanca-2.9_i386.deb ./bin/
	exit 1;
fi

if [ $ARQUITETURA =  'armv7l' ]; then
	echo "ARM Script"
	echo "Preparando binarios"
	cp ./src/balanca ./balanca/usr/bin/balanca
	chmod 777 ./balanca/usr/bin/balanca
	#ln -s /usr/bin/balanca ./balanca/usr/bin/balanca
	cp ./src/balanca.png ./balanca/usr/share/icons/hicolor/balanca.png
	cp ./balanca.desktop_arm ./balanca/usr/share/applications/balanca.desktop
	echo "Empacotando"
	dpkg-deb --build balanca
	echo "Movendo para pasta repositorio"
	mv balanca.deb balanca-2.9_arm.deb
	cp ./balanca-2.9_arm.deb ./bin/	
	exit 1;
fi
