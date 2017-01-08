# Let's Encrypt setup

The logbook of actions taken on the Exim central admin host is in the notes repository.  That is the warts-and-all version.  This should be the cleaner version of what's needed for simple things.

## The pieces

* Certificate Authority: Let's Encrypt
* Client tooling: [lego](https://github.com/xenolf/lego) (Let's Encrypt, Golang -> lego)
* Web-server: nginx
* Non-root account: Phil's, mostly labelled "tlsadmin" below.

## Monthly

A crontab entry for Phil's uid invokes `tls-renew renew` on the 26th of each month.

Assuming most people use the 1st of the month, or the 28th, or so, we pick 26 to be a little bit away.  Certificates last for three months, we renew monthly, if _one_ renewal is missed, we're fine.

We do not want to break in the middle of the night, either in the UK or for Phil (US Eastern), so the renewal invocation is at 15:19 UK time.

`tls-renew renew [optional-specific-list-of-sites]` will renew the certificates of each site, copy each into the nginx tls config dir, chmod as appropriate, and `sudo service nginx reload`.

The changes will be committed by `/etc/cron.daily/etckeeper` performing an autocommit.

## Adding a new web-host

This assumes you're either tlsadmin, or using elevated privileges to act as tlsadmin (or this has moved to a dedicated service account which multiple people can access).  Recommend using `etckeeper` to make sure you have a clean base before making further changes ( `etckeeper commit -m "committing any recent changes"` ).

Invoke as tlsadmin: `./bin/tls-renew register newsite.exim.org second-hostname.exim.org`

Supply as many domains as you want in one certificate.  The first one is canonical, will appear in the CN and must match the directories which we'll create in the srv hierarchy.  Use one `tls-renew` invocation per nginx vhost.

The output will give you a pair of commands to `mkdir`/`chmod` the right directories, and tell you to edit the nginx configs to direct traffic there.  Edit the relevant website's config file, to include handling of `.well-known` via the new location; something like:

```
location /.well-known/ {
  alias /srv/wellknown-web/newsite.exim.org/.well-known/;
  default_type 'text/plain';
}
```

Invoke again, as tlsadmin:  `./bin/tls-renew register newsite.exim.org second-hostname.exim.org`

This time, `lego` should be invoked; if terms of service have changed then you'll be prompted to accept them (we don't automate away accepting legal terms).  In a few moments, you'll see the files on disk and in the right place.

As root, edit the nginx site configs to setup or edit the `:443` HTTPS website.  Use existing sites as a template, because we do a bit of TLS tuning besides just setting a key and certificate, but the relevant lines should look like:

```nginx
ssl_certificate_key     /etc/nginx/tls/lego/newsite.exim.org.key;
ssl_certificate         /etc/nginx/tls/lego/newsite.exim.org.crt;
```

You will need to `service nginx configtest` and `service nginx reload` to pick up these changes.  Because config file editing is required, and the editing requires _judgement_ about per-vhost handling, the `tls-renew register` sub-command does not handle this.

Recommend finishing off with: `etckeeper commit -m 'Set up HTTPS for newsite.exim.org'`

## How it fits together

We have backups of the system and etckeeper backups of `/etc`, so we keep all important state in `/etc`; we want a non-root account which can be given limited sudo (to reload nginx), so that's the tlsadmin account, but with all relevant config living in `/etc/` and owned by tlsadmin, so that it's backed up.  If the relevant user needs to change, read this doc and the logbook, pick a new account, `chown` the relevant files in `/etc` and the wellknown webroot, invoke `sudoers` and switch which account can reload `nginx`, disable old tlsadmin's crontab, put the invocation in someone else's (moving the script too) and you should be good.

There are a few choices for handling challenges; for us, out of "taking down the web-server to bring up a new one", "changing webserver entirely to handle natively", "use API access to edit DNS" or "create some files on disk temporarily" the last is the sanest approach.  It's called "webroot".

We use Golang tooling because of Phil's personal bias, and to avoid having breakage when scripting libraries are updated.

Because some webroots are straight tarball extractions which can be blown away (bugzilla) or automated in their construction, we use a parallel webroot setup just for `.well-known` handling.  The webroot directive for `lego` assumes that it can construct a path including `/.well-known/acme-challenge` so we make it an entire parallel tree, just mostly empty.  root owns most of it, Phil's usercode owns the `acme-challenge` directory.

The Let's Encrypt client tooling holds client id information, renewal state, etc, inside one directory.  That's normally `~/.lego` but we put it in `/etc/opt/lego` so that it's less tied to one user; a recursive chown can switch it.

`tls-renew` invokes `lego`, then copies the key and certificate from `/etc/opt/lego/certificates/${site}.{key,crt}` into `/etc/nginx/tls/lego/`; it opens the permissions on the `.crt` to let others see it for ease of debugging.  The files are left owned by tlsadmin, relying upon nginx being started as root.  Then a passwordless sudo invocation of `sudo service nginx reload` puts this live.

## Initial Setup

Edit mail-handling to make sure that the email address in `tls-renew` as the `EmailContact` variable goes somewhere sane.

```console
# openssl dgst -sha256 go1.7.4.linux-386.tar.gz
SHA256(go1.7.4.linux-386.tar.gz)= 31d27752bada47de84e8884cabe6dc13140e459e3aad540c17abc0fcac370c54
# tar -C /usr/local -xpf ~tlsadmin/go1.7.4.linux-386.tar.gz
```

As tlsadmin, with `/usr/local/go/bin` and `~/go/bin` in `$PATH` already:

```console
% mkdir go
% export GOPATH=~/go
% go get -v github.com/xenolf/lego
  # use -u for later updates
% lego --version
lego version 0.3.1
```

```sh
## as root
mkdir /srv/wellknown-web
for SITE in lists.exim.org bugs.exim.org ; do
  mkdir -p /srv/wellknown-web/${SITE:?}/.well-known/acme-challenge
  chown $tlsadmin /srv/wellknown-web/${SITE:?}/.well-known/acme-challenge
done

vi /etc/nginx/sites-available/lists-exim-org.conf /etc/nginx/sites-available/bugs-exim-org.conf
service nginx configtest
etckeeper commit -m '[...]'
service nginx reload
```

The edited config files set up redirected `/.well-known/` handling; the HTTP one is what matters for Let's Encrypt, not HTTPS.  We set it up in _both_ so that _other_ protocols which use `/.well-known/` can use the HTTPS variant.  Everything _except_ HTTPS setup/renewal should be using HTTPS.

```nginx
location /.well-known/ {
        alias /srv/wellknown-web/lists.exim.org/.well-known/;
        default_type 'text/plain';
}
```

The command `tls-renew register lists.exim.org` can then be called; repeat for `bugs.exim.org`.  (The first time was manual, per log-book, but we renewed with `bugs.exim.org` to test that flow, and the wrapper command was used for adding HTTPS sites for `git.exim.org` and `ftp.exim.org`.)

Once the certificates are in place, edit the nginx config files again to have them be used.

This all worked first time, there was no serving outage.

Add HTTPS for new sites, exercising the tooling.

Set up a crontab entry to auto-renew monthly.

Commit contents of `/etc` and the notes/logbooks repository and force off-site backups of those.

Write this wiki page.

Done.