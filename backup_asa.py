#!/usr/bin/python3
from napalm import get_network_driver
from ftplib import FTP
import sys, time, paramiko, os, cmd, datetime, fileinput

now = datetime.datetime.now()
import time
print ("===========[ "+time.strftime(r"%d.%m.%Y %H:%M:%S", time.localtime()) +" Подключение к FTP серверу ]=============================")
ftp = FTP()
ftp.set_debuglevel(0)
ftp.connect('ftp_server', 21)
ftp.login('ftpuser','ftppass')
#ftp.cwd('backup_asa')
user = "cisco"
password = "cisco"
enable_password = "cisco"
port=22
save_path = '/path_to_backup/'
f0 = open('ip_asa')
for ip in f0.readlines():
        ip = ip.strip()
        print("===========[ "+time.strftime(r"%d.%m.%Y %H:%M:%S", time.localtime()) +" Подключение к ASA: "+ip +" ]")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,port, user, password, look_for_keys=False)
        chan = ssh.invoke_shell()
        time.sleep(2)
########### on enable ##################
#      chan.send('enable\n')
#      chan.send(enable_password +'\n')
########################################
        print("===========[ "+time.strftime(r"%d.%m.%Y %H:%M:%S", time.localtime()) +" Получение конфигурации ASA: "+ip +" ]")
        time.sleep(1)
        chan.send('terminal pager 0\n')
        time.sleep(1)
        chan.send('more system:running-config\n')
        time.sleep(20)
        output = chan.recv(999999)
        filename =  os.path.join(save_path, "%s_%.2i%.2i%i_%.2i%.2i%.2i" % (ip,now.year,now.month,now.day,now.hour,now.minute,now.second))
        f1 = open(filename, 'a')
        f1.write(output.decode("utf-8") )
        f=open(filename).readlines()
        for i in [0,0,0,0,0,-1]:
            f.pop(i)
        with open(filename,'w') as F:
            F.writelines(f)
        print("===========[ "+time.strftime(r"%d.%m.%Y %H:%M:%S", time.localtime()) +" Загрузка конфигурации ASA: "+ip +" на FTP сервер]")
        fp = open(filename, 'rb')
        ftp.storbinary('STOR %s' % os.path.basename(filename), fp, 1024)
        fp.close()
        f1.close()
        ssh.close()
        f0.close()
print ("===========[ "+time.strftime(r"%d.%m.%Y %H:%M:%S", time.localtime()) +" Резервное копирование конфигураций завершено! ]")
print("=========================================================================================")
