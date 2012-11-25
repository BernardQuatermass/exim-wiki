Git and Trailing Whitespaces
============================

When committing a code change with git, it will not complain about the
commit if any line(s) have trailing whitespace. However, when you do
various git rebase type actions, git will complain about that commit
containing trailing whitespaces.

Hook to Detect Trailing Whitespaces
-----------------------------------

The safest way to handle trailing whitespaces with git is to detect it
before the commit step and abort with output displaying why it was
skipped. By default, a git repo will have a
**.git/hooks/pre-commit.sample** script. Simply rename it to
**.git/hooks/pre-commit** and make sure it is executable. Then any time
you do a **git commit** it will look at the files staged for commit,
report if there are any lines with trailing whitespaces, and will skip
the commit if there are.

In the following example, I added two lines with trailing whitespaces to
a README file:

>     [tlyons@ivwww01 ~/projects/TEST (master)]$ vim README
>     [tlyons@ivwww01 ~/projects/TEST (master)]$ git add README
>     [tlyons@ivwww01 ~/projects/TEST (master)]$ git commit
>     README:3: trailing whitespace.
>     +test    
>     README:6: trailing whitespace.
>     +test....   
>     [tlyons@ivwww01 ~/projects/TEST (master)]$

Hook to Automatically Remove Trailing Whitespaces
-------------------------------------------------

**Commit hook problems in git are difficult to diagnose**

Git expert *shruggar* in the \#git irc channel on Freenode cautions that

> *I would severely recommend against making "commit" do any magic of
> this sort. It invalidates too many assumptions, and will make it
> pretty much impossible for anyone in this channel to ever help you
> sanely again.*

However, if you still want to do this, you can easily perform this
automatic removal of trailing whitespace when making commits in your
local repository. Add this script as **.git/hooks/pre-commit** and make
it executable:

>     if git rev-parse --verify HEAD >/dev/null 2>&1 ; then
>        against=HEAD
>     else
>        # Initial commit: diff against an empty tree object
>        against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
>     fi
>     # Find files with trailing whitespace
>     # Doubled commands are _linux_version_ || _mac_osx_version_
>     for FILE in $(
>         git diff-index --check --cached $against -- | \
>         sed '/^[+-]/d' | \
>         ( sed -r 's/:[0-9]+:.*//' 2>/dev/null || \
>           sed -E 's/:[0-9]+:.*//' ) | \
>         uniq
>     ); do
>       # Fix them!
>       ( sed -i 's/[[:space:]]*$//' "$FILE" > /dev/null 2>&1 || \
>         sed -i '' -E 's/[[:space:]]*$//' "$FILE" )
>       echo "Removed trailing whitespace from $FILE"
>       git add "$FILE"
>     done
>
>     exit

When you perform a **git commit**, this script will be called
automatically. It finds all files which are staged to be committed and
runs a check on them, looking for trailing whitespaces. The script
modifies the working copy of any file(s) it finds, does a **git add** to
stage the new change into the cache, and then commits it like normal.
All of this is invisible to you the user.

### Disable Automatic Whitespace Removal

If you need to disable the whitespace removal once, you add **-n** to
the **git commit** commandline, which bypasses the pre-commit and
commit-msg hooks.

If you want to completely disable the whitespace removal, you can
delete, rename or remove execute permissions from the
**.git/hooks/pre-commit** script.
