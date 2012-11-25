This HOW-TO describes how to add abuse information to each email message
processed by the Exim MTA. The file can be downloaded at
[http://tanaya.net/DynaStop/EximAbuse.tgz](http://tanaya.net/DynaStop/EximAbuse.tgz)

This method requires the zcw program from [CyberAbuse](CyberAbuse)
located at:

[http://www.fr1.cyberabuse.org/whois/?page=downloads](http://www.fr1.cyberabuse.org/whois/?page=downloads)

to be installed on your harddrive. The whoip script assumes zcw is in
/usr/local/bin

Be sure you copy the whoip script included in this distribution to your
/usr/exim folder.

Compile the addtag program and copy it to /usr/local/bin or to /usr/exim
whichever is more convienent for you. The whoip script assumes it is in
/usr/local/bin

Compile and copy with:

{{{./COMPILE cp addtag /usr/local/bin}}}

Add the below lines above your postmaster and abuse sections:

{{{\#\#\# Add abuse info to the message

warn condition = \${if !def:h\_X-[AbuseInfo01](AbuseInfo01):}

> set acl\_m3 = \${run{/usr/exim/whoip \$sender\_host\_address}} message
> = \$acl\_m3}}}

Restart your Exim and it will now begin tagging all mail with abuse
information.

Exim will now insert something like this into each email processed:
{{{X-[AbuseInfo01](AbuseInfo01): IP range : 146.22.0.0 -
146.46.255.255 X-[AbuseInfo02](AbuseInfo02): Network name : CHEVRON
X-[AbuseInfo03](AbuseInfo03): Infos : Chevron Corporation
X-[AbuseInfo04](AbuseInfo04): Infos : 6001 Bollinger Canyon Road
X-[AbuseInfo05](AbuseInfo05): Infos : San Ramon
X-[AbuseInfo06](AbuseInfo06): Infos : CA
X-[AbuseInfo07](AbuseInfo07): Infos : 94583-2324
X-[AbuseInfo08](AbuseInfo08): Country : United States (US)
X-[AbuseInfo09](AbuseInfo09): Abuse E-mail :
[[hostmaster@chevrontexaco.com](mailto:hostmaster@chevrontexaco.com)](mailto:hostmaster@chevrontexaco.com)
X-[AbuseInfo10](AbuseInfo10): Source : ARIN}}}
