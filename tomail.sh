#!/bin/bash
log=/path_to_nextcloud/app/data/audit.log
tmplog=/path_to_nextclou/app/data/tmpaudit.log
tmpdownlog=/path_to_nextclou/app/data/tmpdownload.log
string=*"has been shared via link"*
string1=*"File accessed"*
string2=*"download"*
### Данные для подключения к БД ###
dbuser="********"
dbpass="*********"
db="***********"
dbhost="*********" # Адрес хоста ДБ может измениться после пересоздания контейнера
dbport="3306"
### ------------------------_- ###
sqlexec="mysql -u $dbuser -h $dbhost -P $dbport $db -p$dbpass -N -se"
tomail="user@mail.com" # Адреса на которые отправлять уведомления

while read -r line; do 
	if [[ $line == $string ]]; then
		datalog=`echo $line |awk -F"\"" '{print$10}'`
		dat1=`date -d "$datalog" +%s`
		dat2=`date -d"-5 minute" +%s`
		dat3=`date -d"$datalog" +%c`
		if [[ $dat1 > $dat2 ]]; then
#			idfile=`echo $line |awk '{print $6}' |cut -c 3- |sed 's/..$//'|sed 's/$..//'` # Получение ID файла из логов
			idfile=`echo $line |awk -F '"' '{print $37}' | rev | cut -c 2- | rev` # Получение ID файла из логов (Исправлено)
			shareip=`echo $line|awk -F '"' '{print$14}'` # Получение ip адреса, с которого пользователь разместил ссылку
			geoip=`curl ipinfo.io/$shareip/city`
			orgip=`curl ipinfo.io/$shareip/org`
			dname=`$sqlexec \
			"select file_target from oc_share where item_source = '$idfile';"| cut -c 2-` # Вывод имени файла из БД
			sharelink=`$sqlexec \
			"select token from oc_share where item_source = '$idfile';"` # Вывод общей ссылки для файла, размещенного в общем доступе
			fuser=`$sqlexec \
			"select uid_owner from oc_share where item_source = '$idfile';"` # Вывод имени пользователя, открывшего общий доступ для файла
			echo $idfile
			echo $dat3": Пользователь "$fuser" с IP-адреса "$shareip" ("$geoip", "$orgip") разместил сведения "$dname" по общедоступной ссылке https://nextcloud.domain.com/s/"$sharelink >> $tmplog
		fi
	elif [[ $line == $string1 ]] && [[ $line == $string2 ]]; then
		datalog=`echo $line |awk -F"\"" '{print$10}'` # Получение даты события
		dat1=`date -d "$datalog" +%s`
		dat2=`date -d"-5 minute" +%s`
		dat3=`date -d"$datalog" +%c`
		if [[ $dat1 > $dat2 ]]; then
			idfile=`echo $line |awk -F '"' '{print$30}'|cut -c 6- |sed 's/..........$//'|sed 's/$..//'` # Получение идентификатора файла из логов
			shareip=`echo $line|awk -F '"' '{print$14}'` # Получение ip адреса, с которого пользователь разместил ссылку
			geoip=`curl ipinfo.io/$shareip/city`
			orgip=`curl ipinfo.io/$shareip/org`
			dname=`$sqlexec \
			"select file_target from oc_share where token = '$idfile';"| cut -c 2-` # Вывод имени файла из БД
			sharelink=`$sqlexec \
			"select token from oc_share where token = '$idfile';"` # Вывод общей ссылки для файла, размещенного в общем доступе
			fuser=`$sqlexec \
			"select uid_owner from oc_share where token = '$idfile';"` # Вывод имени пользователя, открывшего общий доступ для файла
			echo -e $dat3": Размещенный пользователем "$fuser" файл "$dname" был скачен с IP-адреса "$shareip" ("$geoip", "$orgip") по общедоступной ссылке https://nextcloud.domain.com/s/"$sharelink >> $tmpdownlog
		fi
	fi
done < $log
### Отправка сообщения если есть что отправлять ###
if [[ -s $tmplog ]]; then
	cat $tmplog | mutt   -s "Уведомление о публикации общедоступных ссылок" -- $tomail;
fi
tee $tmplog < /dev/null
### Отправка сообщения если есть что отправлять ###
if [[ -s $tmpdownlog ]]; then
	cat $tmpdownlog | mutt   -s "Уведомление о скачивании файлов, размещенных по общедоступным ссылкам" -- $tomail;
fi
tee $tmpdownlog < /dev/null
