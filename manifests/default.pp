# ---------------------------------------------------
# Basic system stuff
# ---------------------------------------------------

package {'apparmor':
	ensure => absent,
}
package { 'unzip':
	ensure => present,
	require => Exec['apt-get update'],
}

package { 'curl':
	ensure => present,
	require => Exec['apt-get update'],
}

package { 'nano':
	ensure => present,
	require => Exec['apt-get update'],
}

package { 'git':
	ensure => present,
	require => Exec['apt-get update'],
}

package { 'tig':
	ensure => present,
	require => Exec['apt-get update'],
}

exec { "Import repo signing key to apt keys for php":
	path   => "/usr/bin:/usr/sbin:/bin",
	command     => "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C",
	unless      => "apt-key list | grep E5267A6C",
}

file { '/etc/apt/sources.list.d/php-5.4-repos.list':
	ensure => present,
	source => "/vagrant/manifests/files/apt/php-5.4-repos.list",
	notify => Service['php5-fpm'],
}

exec { "Import repo signing key to apt keys for nginx":
	path   => "/usr/bin:/usr/sbin:/bin",
	command     => "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7BD9BF62",
	unless      => "apt-key list | grep 7BD9BF62",
}

file { '/etc/apt/sources.list.d/nginx-repos.list':
	ensure => present,
	source => "/vagrant/manifests/files/apt/nginx-repos.list",
	notify => Service['nginx'],
}

exec { "Import repo signing key to apt keys for nodejs":
	path   => "/usr/bin:/usr/sbin:/bin",
	command     => "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C7917B12",
	unless      => "apt-key list | grep C7917B12",
}

file { '/etc/apt/sources.list.d/nodejs-repos.list':
	ensure => present,
	source => "/vagrant/manifests/files/apt/nodejs-repos.list",
}


exec { 'apt-get update':
	command => '/usr/bin/apt-get update',
	onlyif => "/bin/bash -c 'exit $(( $(( $(date +%s) - $(stat -c %Y /var/lib/apt/lists/$( ls /var/lib/apt/lists/ -tr1 | tail -1 )) )) <= 604800 ))'",
	require => [
		File['/etc/apt/sources.list.d/php-5.4-repos.list'],
		Exec["Import repo signing key to apt keys for php"],
		File['/etc/apt/sources.list.d/nginx-repos.list'],
		Exec["Import repo signing key to apt keys for nginx"],
		File['/etc/apt/sources.list.d/nodejs-repos.list'],
		Exec["Import repo signing key to apt keys for nodejs"],
	],
}


# ---------------------------------------------------
# Install dnsmasq
# ---------------------------------------------------

package { "dnsmasq":
	ensure => present,
	require => Exec['apt-get update'],
}

service { 'dnsmasq':
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	enable => true,
	require => Package["dnsmasq"],
}

file { '/etc/dnsmasq.conf':
	ensure => present,
	source => "/vagrant/manifests/files/dnsmasq/dnsmasq.conf",
	require => Package["dnsmasq"],
	notify => Service['dnsmasq'],
}




# ---------------------------------------------------
# Install MySQL
# ---------------------------------------------------

package { "mysql-server":
	ensure => present,
	require => Exec['apt-get update'],
}

service { 'mysql':
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	enable => true,
	require => Package["mysql-server"],
}

file { '/etc/mysql/my.cnf':
	ensure => present,
	source => "/vagrant/manifests/files/mysql/my.cnf",
	owner => "root",
	group => "root",
	require => Package["mysql-server"],
	notify => Service["mysql"]
}

exec { 'mysql-root-password':
	command => '/usr/bin/mysqladmin -u root password vagrant',
	onlyif => '/usr/bin/mysql -u root mysql -e "show databases;"',
	require => File['/etc/mysql/my.cnf'],
}

exec { 'mysql-remote-permissions':
	command => '/usr/bin/mysql -S /var/run/mysqld/mysqld.sock -u root -pvagrant -e "CREATE USER \'root\'@\'%\' IDENTIFIED BY \'vagrant\'; 	GRANT ALL PRIVILEGES ON *.* TO \'root\'@\'%\' WITH GRANT OPTION; FLUSH PRIVILEGES;"',
    onlyif => '/usr/bin/test -z $(/usr/bin/mysql -u root -pvagrant -B -N -e "select user from mysql.user WHERE user=\'root\' AND host=\'%\' AND grant_priv=\'Y\';")',
	require => Exec['mysql-root-password'],
}



# ---------------------------------------------------
# Install PHP 5.4.x with FPM
# ---------------------------------------------------

package { 'php5-fpm':
	ensure => installed,
	require => Exec['apt-get update'],
}

package { 'libapache2-mod-php5':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['apache2'],
}

package { 'php5-mysql':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['php5-fpm'],
}
package { 'php5-mcrypt':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['php5-fpm'],
}
package { 'php5-curl':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['php5-fpm'],
}
package { 'php5-gd':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['php5-fpm'],
}
package { 'php5-cli':
	ensure => installed,
	require => Exec['apt-get update'],
}
package { 'php-apc':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['php5-fpm'],
}
package { 'php5-sqlite':
	ensure => installed,
	require => Exec['apt-get update'],
	notify => Service['php5-fpm'],
}

service { 'php5-fpm':
	ensure => running,
	require => Package['php5-fpm'],
	hasrestart => true,
	hasstatus => true,
}

file { '/etc/php5/fpm/pool.d/www.conf':
	ensure => present,
	source => "/vagrant/manifests/files/php/www.conf",
	require => [
		Package['php5-fpm']
	],
	notify => [
		Service['php5-fpm'],
	],
}


file { '/etc/php5/apache2/conf.d/99-vagrant.ini':
	ensure => present,
	source => "/vagrant/manifests/files/php/90-vagrant.ini",
	require => [
		Package['libapache2-mod-php5'],
	],
	notify => [
		Service['apache2'],
	],
}

file { '/etc/php5/fpm/conf.d/90-vagrant.ini':
	ensure => present,
	source => "/vagrant/manifests/files/php/90-vagrant.ini",
	require => [
		Package['php5-fpm'],
	],
	notify => [
		Service['php5-fpm'],
	],
}

file { '/etc/php5/cli/conf.d/90-vagrant.ini':
	ensure => present,
	source => "/vagrant/manifests/files/php/90-vagrant.ini",
	require => [
		Package['php5-cli'],
	],
}


# ---------------------------------------------------
# Install Composer
# ---------------------------------------------------

exec { 'install-composer':
	command => 'curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer',
	path => "/usr/local/bin/:/usr/bin/:/bin/",
	timeout => 0,
	creates => "/usr/local/bin/composer",
	require => [
		Package['curl'],
		Package['php5-cli'],
	],
}

exec { 'selfupdate-composer':
	command => 'composer self-update',
	path => "/usr/local/bin/:/usr/bin/",
	require => [
		Exec['install-composer'],
	],
}



# ---------------------------------------------------
# Install Nginx
# ---------------------------------------------------

package { "nginx":
	ensure => present,
	require => Exec['apt-get update'],
}

file { '/etc/nginx/nginx.conf':
	ensure => present,
	source => "/vagrant/manifests/files/nginx/nginx.conf",
	require => [
		Package['nginx'],
	],
	notify => Service['nginx'],
}

service { 'nginx':
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	enable => true,
	require => Package['nginx'],
}



# ---------------------------------------------------
# Install Apache
# ---------------------------------------------------

package { "apache2":
	ensure => present,
	require => Exec['apt-get update'],
}

service { 'apache2':
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	enable => true,
	require => Package['apache2'],
}

file { "/var/www":
	ensure => directory,
	recurse => false,
}

# Enable the "vhost_alias" module for apache
exec { "/usr/sbin/a2enmod vhost_alias":
	unless => "/bin/readlink -e /etc/apache2/mods-enabled/vhost_alias.load",
	notify => Exec["force-reload-apache2"],
	require => [
		Package['apache2'],
		File['/etc/apache2/ports.conf'],
	],
}

# Enable the "rewrite" module for apache
exec { "/usr/sbin/a2enmod rewrite":
	unless => "/bin/readlink -e /etc/apache2/mods-enabled/rewrite.load",
	notify => Exec["force-reload-apache2"],
	require => Package['apache2'],
}

exec { "force-reload-apache2":
	command => "/etc/init.d/apache2 force-reload",
	refreshonly => true,
}

file { '/etc/apache2/ports.conf':
	ensure => present,
	source => "/vagrant/manifests/files/apache/ports.conf",
	require => [
		Package['apache2']
	],
	notify => Service['apache2'],
}

file { '/etc/apache2/sites-enabled/mass_vhost.conf':
	ensure => present,
	source => "/vagrant/manifests/files/apache/mass_vhost.conf",
	require => [
		Package['apache2'],
		Exec['/usr/sbin/a2enmod vhost_alias'],
		File['/etc/apache2/ports.conf']
	],
	notify => Service['apache2'],
}



# ---------------------------------------------------
# Install PhpMyAdmin
# ---------------------------------------------------

package { 'phpmyadmin':
	ensure => present,
	require => [
		Exec['apt-get update'],
		Package['apache2'],
	],
}

file { '/etc/apache2/sites-enabled/phpmyadmin.conf':
	source => "/vagrant/manifests/files/apache/phpmyadmin.conf",
	require => Package['phpmyadmin'],
	notify => Service['apache2'],
}



# ---------------------------------------------------
# Install Node Package Manager and some packages we
# use e.g. for web-development
# ---------------------------------------------------

package { 'nodejs':
	ensure => 'present',
	require => Exec['apt-get update'],
}

exec { '/usr/bin/npm install -g bower':
	require => Package['nodejs'],
	creates => "/usr/bin/bower",
}


# ---------------------------------------------------
# Install ruby stuff needed e.g. for mailcatcher
# ---------------------------------------------------
package { 'g++':
	ensure => 'present',
	require => Exec['apt-get update'],
}

package { 'make':
	ensure => 'present',
	require => Exec['apt-get update'],
}

package { 'libsqlite3-dev':
	ensure => 'present',
	require => Exec['apt-get update'],
}



# --------------------------------------------------------------------
# Install and configure the mailcatcher Mock-SMTP-Server
#
# Heavily inspired by https://github.com/actionjack/puppet-mailcatcher
# --------------------------------------------------------------------
package { 'mailcatcher':
	ensure => 'present',
	provider => 'gem',
	require => [
		Package['g++'],
		Package['make'],
		Package['libsqlite3-dev'],
	],
}

user { 'mailcatcher':
	ensure	=> 'present',
	comment	=> 'Mailcatcher Service User',
	home	=> '/var/spool/mailcatcher',
	shell	=> '/bin/true',
}

file {'/var/log/mailcatcher':
	ensure	=> 'directory',
	owner	=> 'mailcatcher',
	group	=> 'mailcatcher',
	mode	=> '0755',
	require	=> User['mailcatcher']
}

file { '/etc/init/mailcatcher.conf':
	ensure	=> 'file',
	source	=> "/vagrant/manifests/files/mailcatcher/mailcatcher.conf",
	mode	=> '0755',
	notify	=> Service['mailcatcher']
}

service {'mailcatcher':
	ensure		=> 'running',
	provider	=> 'upstart',
	hasstatus	=> true,
	hasrestart	=> true,
	require		=> [
		User['mailcatcher'],
		Package['mailcatcher'],
		File['/etc/init/mailcatcher.conf'],
		File['/var/log/mailcatcher'],
	],
}