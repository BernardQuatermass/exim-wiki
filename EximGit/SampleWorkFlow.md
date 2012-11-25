Git Sample Workflow
===================

The git SCM is a very powerful tool. What follows is a sample workflow
of how to use git effectively.

Update an old patch
-------------------

The following is from an email in the Dev mailing list where a
description of how to use git to update a patch from 4.77 to 4.80. There
are other possibly easier ways to do this, but this is just the **clear,
step by step** workflow that I like to use.

1.  If you haven't already obtained a copy of the repository:

        git clone git://git.exim.org/exim.git

2.  If you haven't already read the Exim git docs, please read
    [http://wiki.exim.org/EximGit](http://wiki.exim.org/EximGit)

3.  Check out the 4.77 release:

        git checkout exim-4_77

4.  Create a new local branch from this point, giving it a name to
    indicate it's for your db logging.

        git checkout -b db_logging

5.  Assuming the patch file is named db\_logging.patch and is in the
    root directory of your exim checkout, apply your patch with -p1. (In
    this example from the mailing list) the code should apply cleanly,
    the docs will fail. The reason is that the git tree looks different
    than the tree of the source tarball, and your patch is made against
    the tarball.

        cd src/
        patch -p1 < ../db_logging.patch
         }}
         1. Apply the doc portion of the patch:
         cd ../doc/doc-txt
         patch -p1 ../../src/doc/*.rej
         cd ../..   # should put you back in root of exim repo
         # In the repo, doc/ is valid, but
         # src/doc is not valid, is a remnant of first failed patch
         rm -rf src/doc/
         find . -name *.orig -exec rm -v {} \;
         1. A 'git status' should show something like this:
         {{{
        #       modified:   doc/doc-txt/experimental-spec.txt
        #       modified:   src/src/EDITME
        #       modified:   src/src/config.h.defaults
        #       modified:   src/src/deliver.c
        #       modified:   src/src/exim.c
        #       modified:   src/src/expand.c
        #       modified:   src/src/globals.c
        #       modified:   src/src/globals.h
        #       modified:   src/src/readconf.c
        #       modified:   src/src/transports/smtp.c
        #       modified:   src/src/transports/smtp.h

6.  Do a **git add FILE** for each one of those (can do multiple
    filenames at once on the commandline, separated by spaces). Do not
    do the cheating **git add .** command because that *WILL*
    inadvertently add things to the repo that shouldn't be added. (The
    .gitignore file has been modified since 4.77 to block most of these
    inadvertent commits.)

7.  Run **git commit**, enter a commit message, and save it. Google for
    "*format git commit message*" if you have any questions of how the
    commit message should look.

8.  This command does a lot in the background, but basically you'll tell
    git to un-apply your patch, roll the branch forward to exim 4.80
    release, and then reapply your patch:

        git rebase exim-4_80

9.  If it succeeds (and it usually does), then you're finished. However,
    I tested the above with your patch and it had some merge conflicts
    (not in the code, but in the doc file, the EDITME file, and the
    config.h.defaults file).

10. If it has conflicts it can't resolve, it will give you some brief
    instructions to fix it. It's up to you if you want to try to fix it
    or not. Basically you edit the any files with the merge conflicts.
    (I just search for the string "======" which puts you right in the
    middle of the merge conflict. Fix the code, remove the conflict
    markers, and save the file(s).

11. Add the file(s) back to the cache:

        git add FILE1 FILE2 FILE3

12. Git remembered where you were in the rebase process, tell it you
    want to continue the rebase command:

        git rebase --continue

Now you have an easy way to generate your patch:

>     git format-patch exim-4_80..HEAD

which will create a commit patch file for every commit between
exim-4\_80 branch and your current HEAD. Since HEAD is currently your
local branch that you made, there is only one commit, so only one file
will be created. Send that file to the list or to bug tracker and it's
much easier for the maintainers to work with it.
