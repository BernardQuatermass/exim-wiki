Mail Filtering Tips
===================

Using Exim To Filter Mailing Lists into Folders
-----------------------------------------------

The following extract files messages from all the mailing lists I am on
(and thats a lot) each into their own folder. I use Maildir format
mailboxes, and the lists are all subfolders under the *list* folder
under *INBOX*. The list names are sanitized (to prevent someone trying
to write stuff into `../../something` or similar - if they do not match
a basic string then stuff is filed into `.list.unknown` (pretty much
nothing hits that at present).

    # split out the various list forms
    # Mailman & other lists using list-id
    if "${if def:header_list-id:{true}}" is true then
            if $header_list-id: matches "<([a-z0-9-]+)[.@]" then
                    save Maildir/.list.${lc:$1}/
            else
                if $header_list-id: matches "^\\s*<?([a-z0-9-]+)[.@]" then
                    save Maildir/.list.${lc:$1}/
                else
                    save Maildir/.list.unknown/
                endif
            endif
            finish
    # Listar and mailman like
    elif "${if def:header_x-list-id:{true}}" is true then
            if $header_x-list-id: matches "<([a-z0-9-]+)\\\\." then
                    save Maildir/.list.${lc:$1}/
            else
                    save Maildir/.list.unknown/
            endif
            finish
    # Ezmlm
    elif "${if def:header_mailing-list:{true}}" is true then
            if $header_mailing-list: matches "([a-z0-9-]+)@" then
                    save Maildir/.list.${lc:$1}/
            else
                    save Maildir/.list.unknown/
            endif
            finish
    # York lists service
    elif "${if def:header_x-mailing-list:{true}}" is true then
            if $header_x-mailing-list: matches "^\\s*([a-z0-9-]+)@?" then
                    save Maildir/.list.${lc:$1}/
            else
                    save Maildir/.list.unknown/
            endif
            finish
    # Smartlist
    elif "${if def:header_x-loop:{true}}" is true then
            # I don't have any of these to compare against now
            save Maildir/.list.unknown/
            finish
    # poorly identified
    elif $sender_address contains "owner-" then
            if $sender_address matches "owner-([a-z0-9-]+)-outgoing@" then
                    save Maildir/.list.${lc:$1}/
            elif $sender_address matches "owner-([a-z0-9-]+)@" then
                    save Maildir/.list.${lc:$1}/
            elif $header_sender: matches "owner-([a-z0-9-]+)@" then
                    save Maildir/.list.${lc:$1}/
            else
                    save Maildir/.list.unknown/
            endif
            finish
    # other poorly identified
    elif $sender_address contains "-request" then
            if $sender_address matches "([a-z0-9-]+)-request@" then
                    save Maildir/.list.${lc:$1}/
            else
                    save Maildir/.list.unknown/
            endif
            finish
    endif

### Here is the same script translated to Sieve:

    require [ "regex", "variables", "fileinto", "envelope" ];

    # split out the various list forms
    # Mailman & other lists using list-id
    if exists "list-id" {
            if header :regex "list-id" "<([a-z0-9-]+)[.@]" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } else {
                if header :regex "list-id" "^\\s*<?([a-z0-9-]+)[.@]" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
                } else {
                    fileinto "list.unknown";
                }
            }
            stop;}
    # Listar and mailman like
    elsif exists "x-list-id" {
            if header :regex "x-list-id" "<([a-z0-9-]+)\\\\." {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } else {
                    fileinto "list.unknown";
            }
            stop;}
    # Ezmlm
    elsif exists "mailing-list" {
            if header :regex "mailing-list" "([a-z0-9-]+)@" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } else {
                    fileinto "list.unknown";
            }
            stop;}
    # York lists service
    elsif exists "x-mailing-list" {
            if header :regex "x-mailing-list" "^\\s*([a-z0-9-]+)@?" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } else {
                    fileinto "list.unknown";
            }
            stop;}
    # Smartlist
    elsif exists "x-loop" {
            # I don't have any of these to compare against now
            fileinto "list.unknown";
            stop;}
    # poorly identified
    elsif envelope :contains "from" "owner-" {
            if envelope :regex "from" "owner-([a-z0-9-]+)-outgoing@" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } elsif envelope :regex "from" "owner-([a-z0-9-]+)@" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } elsif header :regex "Sender" "owner-([a-z0-9-]+)@" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } else {
                    fileinto "list.unknown";
            }
            stop;}
    # other poorly identified
    elsif  envelope :contains "from" "-request" {
            if envelope :regex "from" "([a-z0-9-]+)-request@" {
                    set :lower "listname" "${1}";
                    fileinto "list.${listname}";
            } else {
                    fileinto "list.unknown";
            }
            stop;}

* * * * *

> [CategoryHowTo](CategoryHowTo)
