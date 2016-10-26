LetsEncrypt is picky and wants an addition "host" arg for openssl over the set
used by ocsp_fetch.pl

cd /etc/letsencrypt/live/yourdomain.com
openssl ocsp -respout ocsp.der -issuer chain.pem -cert cert.pem -url http://ocsp.int-x1.letsencrypt.org -header "HOST" "ocsp.int-x1.letsencrypt.org" -verify_other chain.pem