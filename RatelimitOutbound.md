## Version one
To rate-limit outbound messages requires an assemblage of facilities.  You will need to add a router:

* Early in the chain
* not active for verify
* limited to the items of interest
* redirect
* redirect supplied by an acl expansion (4.82 and later), calling an ACL which
    * tests using a **ratelimit** ACL condition
    * returns either the original recipient, or **:defer:**

You will also need to be starting queue-runners at some reasonable frequency.

## Version two
The above isn't good if your preferred queue-runners use **-qq** mode; you get double-counting, and there's no programmatic visibility of the queue-run phases with which to fix it.

So: split the use of **ratelimit** into a read-only test, and an update.
* Do the test from the router as above
* Do the update from a **msg:delivery** Event
    * If your Exim version is too old for Events (pre 4.87), use a dummy expansion in the transport instead


## Version three
Resource-constrained sites may feel that the processing done by the queue-runners hitting the ratelimit test is excessive.  If there are only a small number of classes of limit needed, consider diverting the mails to an alternate named queue (4.88 and later), one per class.  Instead of a queue-runner, for each holding queue run a cronjob script which moves a defined-size batch of mails back to the main queue for delivery.  Just move the files (there should be two per mail) from one directory to another.