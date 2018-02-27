To rate-limit outbound messages requires an assemblage of facilities.  You will need to add a router:

* Early in the chain
* not active for verify
* limited to the items of interest
* redirect
* redirect supplied by an acl expansion, calling an ACL which
    * tests using a **ratelimit** ACL condition
    * returns either the original recipient, or **:defer:**

You will also need to be starting queue-runners at some reasonable frequency.