Address Verification For MS Exchange
====================================

Originally posted to the exim-users
[EximMailingLists](EximMailingLists) - archived at
[http://www.exim.org/pipermail/exim-users/Week-of-Mon-20040816/075152.html](http://www.exim.org/pipermail/exim-users/Week-of-Mon-20040816/075152.html)
- original author was Peter Savitch.

This summary is addressed to all heterogeneous (MS + UN\*X)
environments. Its objective is to give the administrators the necessary
information to reduce billions of bounce messages traveling across the
public networks.

Abstract
--------

While MS Exchange is widely used for intranets, Exim internet gateway
capabilities are still unmatched.

Active Directory proxyAddresses attribute could be queried, retrieved
and used by Exim for address verification to reject unknown mail during
SMTP phase. MS Exchange servers (prior to 2003) are considered incapable
of such a functionality. Additional things like SPAMWARE/MALWARE/ETC are
beyond the scope of this memo.

In general, W2K Global Catalog stores the whole AD forest object's
properties marked in AD schema as \`for replication in Global Catalog'.
In particular, attribute proxyAddresses does have this option turned on
and appears in Global Catalog. See also: [PSDK documentation
MSDN](http://search.microsoft.com/search/results.aspx?qu=PSDK).

Active Directory proxyAddresses attribute is created only for
mail-enabled objects (like User, Group or Public Folder) and is subject
to change according to recipient policies (see Exchange docs).

Please note:

a.  Disabling the mail capabilities (deleting mailbox while leaving
    account active) DOES remove the proxyAddresses attribute.

b.  Disabling the account itself while leaving its mailbox DOES NOT
    remove the proxyAddress attribute. Exchange would STILL produce mail
    bounces in this case.

Attribute proxyAddresses has multi-valued syntax with case-less string
matching. The exact address is prefixed by protocol, like this:

    # extended LDIF
    dn: CN=Peter Savitch,OU=Unit,DC=DOMAIN,DC=ORG
    # ...
    proxyAddresses: SMTP:address1@DOMAIN.ORG
    proxyAddresses: smtp:aDdrEss2@DOMAIN.ORG
    proxyAddresses: X400: ...
    # ...

NOTE:: W2K administrator can use Active Directory Users and Computers
snap-in to view/modify the proxyAddresses attribute.

Setup
-----

To utilize AD, Exim administrators should obtain the latest version of
Exim and enable its LDAP support (Exim 4.4x is recommended, 4.3x is
okay, OpenLDAP 2.1.x is recommended, 2.0.27 should be okay).

An Active Directory account must be created for Exim. Its **full**
Distinguished Name is used for USER credential. It could be created in a
separate OU with restricted security policy:

    CN=MTA,OU=Restricted,DC=domain,DC=ORG

[Table not converted]

The Lookup Macro
----------------

W2K Global Catalog is an LDAP server that (usually) listens on TCP port
3268 on any domain controller in the forest. The best-practice approach
for multi-site topologies is to locate the closest GC. This could be
done even dynamically utilizing the new Exim 4.4x DNSDB SRV lookups
(additional \${extract}'s should be used, see Exim docs) and new
\`cache-everything' design:

    ${lookup dnsdb{srv=_gc._tcp.domain.org}{$value}fail}

This returns something like:

    0 100 3268 dc1.domain.org
    0 100 3268 dc2.domain.org

Which can be refined into &lt;host&gt;:&lt;port&gt; form using **map**, a la:

    ${lookup dnsdb{srv=_gc._tcp.domain.org}\
    {${map{<\n $value} \ 
    {${extract{4}{ }{$item}}:\
    ${extract{3}{ }{$item}}}}}}

Which will return something like:

    dc1.domain.org:3268 dc2.domain.org:3268

One may prefer the static setup using serverless URI's in lookups of
this kind:

    ldap_default_servers = <; dc1.domain.org:3268 ; dc2.domain.org:3268

**IMPORTANT NOTE:**  Though it becomes obvious when one reads the Specification, ldap_default_servers **does not** expand any values.  It's a straight, literal, colon-separated list.  Sticking a DNS lookup in here does not work, and will lead to hair-pulling.

One can declare LDAP\_AD\_BINDDN, LDAP\_AD\_PASS, LDAP\_AD\_BASE\_DN
macros. Sample:

    LDAP_AD_BINDDN = "CN=MTA,OU=Restricted,DC=DOMAIN,DC=ORG"
    LDAP_AD_PASS = "VerySecret"
    LDAP_AD_BASE_DN = ${quote_ldap:DC=DOMAIN,DC=ORG}

To verify address one can query AD Global Catalog for exact attribute
matching, using this macro (note serverless LDAP URI):

    LDAP_AD_MAIL_RCPT = \
      user=LDAP_AD_BINDDN \
      pass=LDAP_AD_PASS \
      ldap:///LDAP_AD_BASE_DN\
      ?mail?sub?\
      (&\
        (|\
          (objectClass=user)\
          (objectClass=publicFolder)\
          (objectClass=group)\
        )\
        (proxyAddresses=SMTP:${quote_ldap:${local_part}@${domain}})\
      )

Exim Router
-----------

One can use the \`redirect' router like this:

    adsi_check:
      driver = redirect
      domains = +relay_domains
      allow_fail
      allow_defer
      forbid_file
      forbid_pipe
      redirect_router = adsi_okay
      data = ${lookup ldap {LDAP_AD_MAIL_RCPT}\
        {${local_part}@${domain}}{:fail: User unknown}}

It does not produce any transports, but simply passes the verified
address to another router called \`adsi\_okay' for precise routing.

Security
--------

Exim itself (but not the OpenLDAP client library) is not capable of any
LDAP authentication other than simple. This gives the big security
disadvantage when passwords are being stored and transmitted in clear
text. Even more, Exim shows the passwords during panic and when it's
being run with -d+lookup. Administrators should prevent unauthorized
access to Exim configuration file(s), its log files, its debugging
capabilities, and secure the transmitting channels. TLS/SSL could be
used, but it's beyond the scope of this summary.

Active Directory account given to Exim MTA should not have ANY
permission other than to query the global catalog. Administrators should
remove this account even from default Domain Users group (just make
another group and set it as primary).

Author Notes
------------

MS Exchange server (at least Exchange 2000) applies more strict address
syntax checking. Exim administrators can modify ACL's to accomplish
this:

    # Forbid the .address@domain.org and address.@domain.org
      deny          message =       Invalid address
                    senders =       \N^\.|\.@\N

Additional setup could be made for locating the closest Exchange
bridgehead dynamically.

Additional Notes
----------------

Using port 3268 seems weird, but you have to. If you use AD's port 389,
it seems Active Directory sends "Search references" together with its
answers, this leads Exim to confusion.

Detailed on Exim's mailing list :
[http://www.exim.org/mail-archives/exim-users/Week-of-Mon-20040816/msg00119.html](http://www.exim.org/mail-archives/exim-users/Week-of-Mon-20040816/msg00119.html)

Another method - Callouts
-------------------------

Another method would be to use a callout, which is a lot simpler to set
up. A callout causes your Exim system to do a connection to the
destination mail system and asks it if it will accept mail for this
particular user.

The down side to this is that Exchange may be setup in such a way that
it will decide that your Exim system is trying to do address harvesting
on it, so be careful!

Put these into a RCPT acl. The first stanza will drop the connection on
the fourth incorrect address, Which limits the effectiveness of address
harvesting. The second stanza deals with denying less than four failed
addresses. Due to callout caching this wont incur a double lookup
penalty. You can change the sensitivity to typos by changing the "3" in
the first condition line. Remember to set the domain\_list correctly for
your internal domains.

Use exim -bhc \<an ip address\> to test that things are working as
planned. See the docs for more notes on this.

The \#\#\#nnn things make log grepping easier.

    drop    message               = REJECTED - Too many failed recipients - count = $rcpt_fail_count
            log_message           = REJECTED - Too many failed recipients - count = $rcpt_fail_count ###001
            condition             = ${if > {${eval:$rcpt_fail_count}}{3}{yes}{no}}
            domains               = +internal_domains
            !verify               = recipient/callout=defer_ok

    deny    message               = Not accepting this mail
            log_message           = Failed recipient callout ###002
            domains               = +internal_domains
            !verify               = recipient/callout=defer_ok

* * * * *

## Further Refinement

Based on the above, this configuration was created and is running on production exim instances today:

    AD_ROOT_DOMAIN_NAME = domain.tld
    AD_USER_AND_GROUP = CN=The User Name,cn=users
    AD_LDAP_DC = ${map{<\n AD_ROOT_DOMAIN_NAME}\
    {dc=${extract{1}{.}{$item}},dc=${extract{2}{.}{$item}}}}

    AD_GC_SERVERS = ${lookup dnsdb{srv=_gc._tcp.AD_ROOT_DOMAIN_NAME}\
    {${map{<\n $value} \
    {${extract{4}{ }{$item}}:\
    ${extract{3}{ }{$item}}}}}}

    LDAP_AD_BINDDN = "AD_USER_AND_GROUP,AD_LDAP_DC"
    LDAP_AD_PASSWD = "secret-password"
    LDAP_AD_BASEDN = ${quote_ldap:AD_LDAP_DC}

    LDAP_AD_MAIL_RCPT = \
      user=LDAP_AD_BINDDN \
      pass=LDAP_AD_PASSWD \
      ldap://AD_GC_SERVERS/LDAP_AD_BASEDN\
      ?mail?sub?\
      (&\
        (|\
          (objectClass=user)\
          (objectClass=publicFolder)\
          (objectClass=group)\
        )\
      (proxyAddresses=SMTP:${quote_ldap:${local_part}@${domain}})\
    )

This config requires only three items to be set for the local environment.  Set AD_ROOT_DOMAIN_NAME to the Windows AD DNS-style domain name, set AD_USER_AND_GROUP to a user who is allowed access to the Global Catalog (many articles suggest the creation of a delegated user for this purpose, and some go as far as suggesting a restricted OU as well.)  Finally, set the user's password in LDAP_AD_PASSWD.  

**Caveats:** 
- Only the first GC returned will be used; if it's offline or unavailable, the router will fail
- The password is obviously en clair; future TODO: use certificates and ldap/s?
- If the root domain is more than two parts, only the left-most two parts will be used, and that'll probably break things; if you're using something like corp.bigcompany.com then, you'll need to update AD_LDAP_DC to include <tt>,dc=${extract{3}{.}{$item}</tt>

> [CategoryHowTo](CategoryHowTo)