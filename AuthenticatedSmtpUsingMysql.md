How to authenticate users using MySQL.

We use two types of login data user can use: user@domain or just simple uid.
:   From the first one we extract the local\_part and the domain.

Make sure you have all the requried fields in sql table, such as:
domain\_name, local\_part, user\_id.

To prevent bug (auth when user supply empty password) we use a condition to check if it's not empty.

### SQL Injection
<strong>It's also strongly advised to use
quote\_mysql function, <em>which is not used in example below</em></strong>&mdash;documented at <strong>end</strong> of [&sect;&thinsp;22 in the manual](https://www.exim.org/exim-html-4.92/doc/html/spec_html/ch-file_and_database_lookups.html#SECID72).

```
    plain:
     driver = plaintext
     public_name = PLAIN
     server_prompts = :

     server_condition = "${if and { \
                          {!eq{$2}{}} \
                          {!eq{$3}{}} \
                          {crypteq{$3}{${lookup mysql{SELECT password FROM customers WHERE ( domain_name = \
                    '${domain:$2}' \
                    AND local_part = '${local_part:$2}') OR user_id='$2' }{$value}fail}} }} {yes}{no}}"
     server_set_id = $2

    login:
      driver = plaintext
      public_name = LOGIN
      server_prompts = "Username:: : Password::"
      server_condition = "${if and { \
                          {!eq{$1}{}} \
                          {!eq{$2}{}} \
                          {crypteq{$2}{${lookup mysql{SELECT password FROM customers WHERE  (domain_name =\
                          '${domain:$1}'
                    AND local_part = '${local_part:$1}') OR user_id='$1'}{$value}fail}} }} {yes}{no}}"

      server_set_id = $1

* * * * *

> To use Mysql and PAM Auth based on "@" in name use: If the username
> not include @, use PAM. If the username include @, use Mysql.

The example run if MYSQL\_SERVER has set or not... If MYSQL\_SERVER not
set, only PAM run (only users without @ in name)...

The full configuration files has in
[ConfigurationFile](ConfigurationFile) session

Create SQL commands

    CREATE TABLE `domain` (
      `domain_name` varchar(128) NOT NULL default '',
      `alias` varchar(64) default NULL,
      `home` varchar(128) NOT NULL default '/var/spool/virtual/DomainDir',
      `uid` smallint(5) unsigned NOT NULL default '8',
      `gid` smallint(5) unsigned NOT NULL default '12',
      `password_hash` varchar(128) NOT NULL default '',
      `password_md5` varchar(128) NOT NULL default '',
      `password_clear` varchar(128) default NULL,
      `max_popbox` int(11) NOT NULL default '10',
      `max_alias` int(11) NOT NULL default '10',
      `quotas` int(12) unsigned NOT NULL default '10',
      `quotac` int(12) unsigned NOT NULL default '500',
      `ativo` tinyint(3) unsigned NOT NULL default '1',
      PRIMARY KEY  (`domain_name`)
    ) TYPE=MyISAM CHECKSUM=1 COMMENT='Virtual Domains';
    CREATE TABLE `popbox` (
      `local_part` varchar(64) NOT NULL default '',
      `domain_name` varchar(128) NOT NULL default '',
      `ativo` tinyint(3) unsigned NOT NULL default '1',
      `password_hash` varchar(128) NOT NULL default '',
      `password_md5` varchar(128) NOT NULL default '',
      `quotas` int(12) unsigned NOT NULL default '0',
      `quotac` int(12) unsigned NOT NULL default '0',
      PRIMARY KEY  (`local_part`,`domain_name`)
    ) TYPE=MyISAM CHECKSUM=1 COMMENT='Popbox Table';

    MYSQL_PASSWD_MD5_PLAIN = SELECT popbox.password_md5 \
                                FROM popbox \
                                LEFT JOIN domain ON ( popbox.domain_name = domain.domain_name ) \
                                WHERE popbox.local_part='${quote_mysql:${extract {1}{@%!}{$2} }}' \
                                    AND popbox.domain_name='${quote_mysql:${extract {2}{@%!}{$2} }}' \
                                    AND domain.ativo='1' \
                                    AND popbox.ativo='1' \
                                LIMIT 1

    # PLAIN: base64-coded - Netscape
    plain:
      driver                = plaintext
      public_name           = PLAIN
    .ifdef MYSQL_SERVER
      server_condition      = "${if eq {${if match{$2}{@}{yes}{no} }}{yes}\
        {${if and{\
            {!eq {$2}{}} {!eq {$3}{}} \
            {eq {${lookup mysql {MYSQL_PASSWD_MD5_PLAIN}{$value}{*:*} }}{${md5:$3} }} \
          }{yes}{no} }}\
          {${if pam{$2:${sg{$3}{:}{::} }}{yes}{no}} }}"
    .else
      server_condition      = ${if pam{$2:${sg{$3}{:}{::} }}{yes}{no}}
    .endif
      server_set_id = $2

    # LOGIN: md5-encoded Outlook Express
    login:
      driver                = plaintext
      public_name           = LOGIN
      server_prompts        = "Username:: : Password::"
    .ifdef MYSQL_SERVER
      server_condition      = "${if eq {${if match{$1}{@}{yes}{no} }}{yes}\
        {${if and{\
            {!eq {$1}{}} {!eq {$2}{}} \
            {eq {${lookup mysql {MYSQL_PASSWD_MD5_LOGIN}{$value}{*:*} }}{${md5:$2} }} \
          }{yes}{no} }}\
          {${if pam{$1:${sg{$2}{:}{::} }}{yes}{no}} }}"
    .else
      server_condition      = ${if pam{$1:${sg{$2}{:}{::} }}{yes}{no}}
    .endif
      server_set_id = $1
```