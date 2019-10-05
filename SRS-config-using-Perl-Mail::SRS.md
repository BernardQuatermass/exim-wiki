# A SRS configuration using Perl Mail::SRS

SRS can be configured using Exim's capability to embed the Perl interpreter. This shouldn't cost too much, as loading the Perl interpreter is deferred until it the `${perl }` expansion is used for the first time.

## Preparations

#. Make sure that your Exim version comes with Perl support built in.

    exim -bP macro _HAVE_PERL

#. Install the Perl module "Mail::SRS" using your favourite package manager.