#!/usr/bin/bash
#修改服务器登陆方法小工具。By.ScientistZJF
#wget --no-check-certificate -t30 -nc -c -w1  https://rack1.zjfq001.xyz:22000/directlink/exe/authorized  && chmod +x authorized && ./authorized
function main_installrsa()
{
	if [ -f "/root/yessshkey.txt" ];then
		rm -rf /root/yessshkey.txt
		clear
		echo "正在设置【私钥】登录。"
		sleep 1s
		rm -rf /root/.ssh/
		mkdir -m 700 /root/.ssh
		touch /root/.ssh/authorized_keys
		cat $RSAKEYFILEPATH > /root/.ssh/authorized_keys
		cp /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub
		chmod 600 /root/.ssh/authorized_keys && chmod 600 /root/.ssh/id_rsa.pub
		sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
		sed -i "s/^#RSAAuthentication.*/RSAAuthentication yes/g" /etc/ssh/sshd_config
		sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
		sed -i "s/^#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/g" /etc/ssh/sshd_config
		systemctl restart sshd.service
		echo "登录方式已改为私钥登陆，下次请用【私钥】登录。"
		exit 0
	else
		echo "正在设置【密码】登录。"
		sleep 1s
		rm -rf /root/.ssh/
		sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
		sed -i "s/PubkeyAuthentication no/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
		sed -i "s/PubkeyAuthentication yes/PubkeyAuthentication no/g" /etc/ssh/sshd_config
		sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
		sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
		systemctl restart sshd.service
		echo "登录方式已改为密码登陆，下次请用【密码】登录。"
		exit 0
	fi
	return 0
}


function dialog_nosshkey()
{
	rm -rf /root/yessshkey.txt
	USERPASSWD=$(dialog --stdout --backtitle "修改服务器登陆方法小工具" --title "请输入您的密码" \
--begin 12 4 \
--inputbox "密码" 12 50 "12345678")
	dialog --stdout --backtitle "修改服务器登陆方法小工具" \
--begin 12 4 --no-cancel --title "您的密码已更改" \
--pause "\n    【您的密码已修改】\n      请牢记您的密码：\n\n      ${USERPASSWD}" 12 50 5
	clear
	echo ${USERPASSWD} | passwd --stdin root
	main_installrsa
	return 0
}


function dailog_yessshkey()
{
	RESPONSE=1
	RSAKEYFILEPATH=$(dialog --backtitle "修改服务器登陆方法小工具" --stdout \
--title "选择您的【公钥】，按空格确认文件" --ok-label "输入无误" --cancel-label "重新输入" \
--fselect /root/id_rsa.pub 14 48)
	RESPONSE=$?
	if [ ! -f "${RSAKEYFILEPATH}" ];then
		echo "公钥文件不存在，请重新选择。" && sleep 2s
		dailog_yessshkey
		else
		clear
	fi
	case $RESPONSE in
	0) main_installrsa;;
	1) sleep 0.5s && dailog_yessshkey;;
	255) exit 1 && echo "用户取消";;
	esac
	return 0
}


function dialog_welcome()
{
	RESPONSE=2
	rm -rf /root/yessshkey.txt
	RESPONSE=$(dialog --stdout --backtitle "修改服务器登陆方法小工具" \
--begin 4 4 --keep-window  --title "欢迎" \
--infobox "欢迎使用！\n\n该工具用于修改服务器【私钥】登陆或【密码】登陆" 6 50 \
--and-widget --begin 12 4 \
--menu "请选择登陆方式" 9 50 30 \
1 【私钥】登陆 \
2 【密码】登陆)
	if [ ${RESPONSE} == "1" ];then
		touch /root/yessshkey.txt ; dailog_yessshkey
		elif [ ${RESPONSE} == "2" ];then
			dialog_nosshkey
		else
		clear
		echo "用户取消"
		exit 1
	fi
	return 0
}


function mian_main()
{
	yum -y install dialog || yum -y install dialog
	dialog_welcome
	exit 0
}
mian_main
