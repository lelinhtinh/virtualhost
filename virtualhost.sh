#!/bin/bash

### Set default parameters
action=$1
domain=$2

sitesAvailable='/etc/apache2/sites-available/'
userHome=$(eval echo ~${SUDO_USER})
wwwDir=$userHome'/www/'
userName=${userHome##*/}
sitesAvailabledomain=$sitesAvailable$domain.conf
wwwConf='/etc/apache2/conf-enabled/www.conf'

### don't modify from here unless you know what you are doing

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete). Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain (e.g., abc.test)"
	read domain
done

rootDir=$wwwDir${domain//.[a-z]*/}
email="webmaster@$domain"

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi

		### check if www directory exists or not
		if ! [ -d $wwwDir ]; then
			mkdir $wwwDir
			chown -R $userName:$userName $wwwDir
		fi

		### create www directory rules file
		if ! [ -e $wwwConf ]; then
			if ! echo "
<Directory $wwwDir>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
" > $wwwConf
			then
				echo -e $"There is an ERROR creating www.conf file"
				exit;
			fi
		fi

		### check if directory exists or not
		if ! [ -d $rootDir ]; then
			mkdir $rootDir
			chown -R $userName:$userName $rootDir

			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $rootDir/phpinfo.php
			then
				echo $"ERROR: Not able to write in file $rootDir/phpinfo.php. Please check permissions"
				exit;
			else
				echo $"Added content to $rootDir/phpinfo.php"
			fi
		fi

		### create virtual host rules file
		if ! echo "
<VirtualHost *:80>
	ServerAdmin $email
	ServerName $domain
	ServerAlias $domain
	DocumentRoot $rootDir
	<Directory />
		AllowOverride All
	</Directory>
	<Directory $rootDir>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride all
		Require all granted
	</Directory>
	ErrorLog $rootDir/$domain-error.log
	LogLevel error
	CustomLog $rootDir/$domain-access.log combined
</VirtualHost>
" > $sitesAvailabledomain
		then
			echo -e $"There is an ERROR creating $domain.conf file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### Add domain in /etc/hosts
		if ! echo "127.0.0.1	$domain" >> /etc/hosts
		then
			echo $"ERROR: Not able to write in /etc/hosts"
			exit;
		else
			echo -e $"Host added to /etc/hosts file \n"
		fi

		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 reload

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 reload

			### Delete virtual host rules files
			rm $sitesAvailabledomain
		fi

		### check if directory exists or not
		if [ -d $rootDir ]; then
			echo -e $"Delete host root directory ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
				### Delete the directory
				rm -rf $rootDir
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
