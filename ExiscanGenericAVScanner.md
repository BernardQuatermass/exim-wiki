Non-daemon AV scanners
======================

AV scanners using the av\_scanner generic cmdline interface.

Avira AntiVir (formerly H+B EDV)
--------------------------------

    av_scanner = <; cmdline ; \
      /usr/bin/antivir --scan-in-archive --archive-max-size=20480 --archive-max-recursion=10 \
      --allfiles --scan-in-mbox -nolnk -noboot -nombr -rs -s %s ; \
      ^ALERT: ; \[([^\]]*)\]

* * * * *

> [CategoryHowTo](CategoryHowTo)
