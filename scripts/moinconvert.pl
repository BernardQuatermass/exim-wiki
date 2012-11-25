#!/usr/bin/env perl
#
use strict;
use warnings;
use 5.14.0;

use File::Glob ':glob';
use File::Path qw(make_path remove_tree);
use File::Slurp;
use File::Spec;
use Try::Tiny;

# ------------------------------------------------------------------------
# This converts a MoinMoin table row into a MediaWiki table row
# See: http://www.w3.org/2005/MWI/DDWG/wiki/SyntaxReference
# See: http://www.mediawiki.org/wiki/Help:Tables
sub ProcessTableRow {
    chomp( my $mmtr = shift );
    my $x;
    my $style;
    my $celltext;
    my $startspanpos;

    # Convert long colspans into ||<-N> format
    while ( ( $startspanpos = index( $mmtr, '||||' ) ) >= 0 ) {
        my $spans = substr( $mmtr, $startspanpos );
        $spans =~ m/^(\|*)/;
        $spans = $1;
        my $endspanpos = rindex( $mmtr, '|', $startspanpos );
        substr( $mmtr, $startspanpos, length($spans) ) = '||<-' . ( length($spans) / 2 ) . '>';
    }
    my @cells = split( /\|\|/, $mmtr );
    @cells = @cells[ 1 .. @cells - 2 ];
    my $mwcells = '';
    foreach $x (@cells) {
        if ( $x =~ m/^\s*((<.[^>]+>|<\(>|<:>|<\)>)+)(.+)/ ) {
            $style    = $1;
            $celltext = $3;

            # combinations
            $style =~ s/<(\(|:|\)|\^|v)([^>]+)>/<$1><$2>/g;    # e.g.  <:90%>  -->  <:><90%>
                                                               # background colour
            $style =~ s/<(#[^:]*?):>/bgcolor="$1" /g;
            $style =~ s/<bgcolor=([^>]+)>/bgcolor=$1 /g;

            # alignment
            $style =~ s/<\(>/align="left" /g;
            $style =~ s/<style="align\s*:\s*(left|right|center);">/align="$1" /g;

            #      $style =~ s/<style="align\s*:\s*left;">/align="left" /g;
            $style =~ s/<\:>/align="center" /g;

            #      $style =~ s/<style="align\s*:\s*center;">/align="center" /g;
            $style =~ s/<\)>/align="right" /g;

            #      $style =~ s/<style="align\s*:\s*right;">/align="right" /g;
            $style =~ s/<\^>/valign="top" /g;

            #      $style =~ s/<style="vertical-align\s*:\s*top;">/valign="top" /g;
            $style =~ s/<v>/valign="bottom" /g;
            $style =~ s/<style="vertical-align\s*:\s*(top|bottom);">/valign="$1" /g;

            # rowspan
            $style =~ s/<\|(\d+)>/rowspan="$1" /g;
            $style =~ s/<(rowspan=[^>]+)>/$1 /g;

            # colspan
            $style =~ s/<-(\d+)>/colspan="$1" /g;
            $style =~ s/<(colspan=[^>]+)>/$1 /g;

            # width
            $style =~ s/<(\d+)\%>/width="$1%" /g;

            # everything else
            $style =~ s/tablewidth=".+"/ /g;
            $style =~ s/<(rowbgcolor)[^>]+>/ /g;
            $style =~ s/<(\w+=[^>])>/$1 /g;
            $mwcells .= "|$style|$celltext\n";
        }
        else {
            $mwcells .= "| $x\n";
        }
    }
    return $mwcells;
}

# ------------------------------------------------------------------------
sub wikiconvert {
    my $mwname  = shift;
    my $inlines = shift;

    ( my $mwname_ = $mwname ) =~ s/\s/_/g;    # MW name with "_" instead of " "
    my $prev       = '';
    my $listprefix = '';
    my $replacementprefix;
    my $tabledepth = 0;
    my $line;
    my @lines;
    my $replacement;
    my $incode             = 0;
    my $toc                = 0;
    my $previouslistindent = '';
    my @indents;
    my @bullets;

    foreach ( @{$inlines} ) {
        $line = $_;
        next if /^----$/;    # remove unneeded header lines

        if (/\}\}\}/) {
            $incode = 0;     # Current line contains }}} marking end of code
        }
        if ($incode) {
            push( @lines, $line );    # In the middle of 'code', so don't convert the wiki markup
            next;
        }
        if (/\{\{\{(?!.*\}\}\})/) {
            $incode = 1
                ; # Current line contains {{{ with no following }}}, so all subsequent lines will be code. (But wiki-convert this line!)
        }

        # Line-by-line conversions. Most of these will not span across multiple lines.

        # MoinMoin command conversions
        #### $line =~ s/^\#REDIRECT \[\[(.*?)\]\]/[[ConvertToMWName($1)]]/e;    # Redirect
        # Comment out any remaining moinmoin commands (lines starting with #)
        $line =~ s/^(\#.*)$/<!-- $1 -->/;

        # Normalisation of indented lists
        #    A. xxxxxxx                  indent = '   '               bullet = A   level = 0
        #         1. xxxxxx              indent = '        '          bullet = 1   level = 1
        #         1. xxxxxx              indent = '        '          bullet = 1   level = 1
        #      A. xxxxxxxx               indent = '     '             bullet = A   level = 0
        #           a. xxxxxxx           indent = '           '       bullet = a   level = 1
        #                * xxxxxxxx      indent = '                 ' bullet = *   level = 2
        #                * xxxxxxxx      indent = '                 ' bullet = *   level = 2
        # Becomes:
        # * '''A)''' xxxxxxx
        # *# xxxxxx
        # *# xxxxxx
        # * '''B)''' xxxxxxxx
        # ** '''a)''' xxxxxxx
        # *** xxxxxxxx
        # *** xxxxxxxx

        # Common errors #
        $line =~ s/^(\s*)\.\s/$1* /;    # Replace false bullet
        $line =~ s/\x0b/^k/g;           # Replace ^k
        $line =~ s/\x0f/^o/g;           # Replace ^o
        $line =~ s/\x00/^@/g;           # Replace ^@
        $line =~ s/\x08/^h/g;           # Replace ^h
        $line =~ s/\x03/^c/g;           # Replace ^c
        $line =~ s/\x0c/^l/g;           # Replace ^l
        $line =~ s/\x1b/^[/g;           # Replace ^l
        $line =~ s/\x0d//g;             # Replace ^m

        $line =~ s/^(\s*\*)(\S)/$1 $2/; # Insert missing space after bullet in moin-moin list (common error)

        if ( $line =~ /^([A-Za-z]\.|\*)\s+.+$/ ) {
            $line = " $line";    # indent lines that look like list elements that have forgotted their leading space
        }

        if ( $line =~ /^\s(\s*)((\d+|[\*aAi])\.|\*)\s+(.*)$/ ) {
            my $currentindent = $1;
            my $text          = $4;

            #      my $bullet = substr($2,0,1);
            my $bullet = $2;
            $bullet =~ s/\.//;
            my $b;
            if ( $bullet eq 'i' ) { $bullet = '1'; }    # Don't support Roman bullets (not yet, anyway)
            my $indentlevel = scalar(@indents);
            if ( $indentlevel == 0 ) {                  # This is the beginning of a new outermost list
                $indents[0] = $currentindent;           # record the initial indentation
                $bullets[0] = $bullet;                  # and the initial bullet
            }
            else {                                      # At least one line of the list has already been processed
                    # Is this indent bigger, smaller or the same as the previous indent?
                my $previousindent = $indents[ $indentlevel - 1 ];
                if ( length($currentindent) < length($previousindent) ) {    # list is receding
                    while ( $indentlevel > 0 && length($currentindent) <= length($previousindent) ) {    # recede
                        $indentlevel--;
                        $previousindent =
                            $indentlevel ? $indents[ $indentlevel - 1 ] : '';  # examine the "previous previous" indents
                    }

                    # At this point the current indent matches the indent at $indentlevel-1
                    $indentlevel--;    # Now $indentlevel is the correct list level for the current line
                    if ( $indentlevel <= 0 ) {
                        $indentlevel = 0;
                    }                  # Unless the list appears to have started at a level greater than 1 !
                    $#indents = $indentlevel
                        ;    # As we have receded to an outer level, the recorded inner level indents should be removed
                             #$#indents = $indentlevel?$indentlevel-1:0; $indentlevel--;
                    $b = $bullets[$indentlevel]
                        ;    # When you recede to an outer level, you *must* continue that level's bullet type
                    if ( $b =~ /[A-Ya-y]/ ) {
                        $bullets[$indentlevel] =
                            chr( ord($b) + 1 );    # When continuing a level, increment lettered bullets
                    }
                }
                else {                             # list is not receding
                    if ( length($currentindent) > length($previousindent) )
                    {                              # this line is indented further than the previous line
                        $indents[$indentlevel] = $currentindent;    # record the new indentation
                        $bullets[$indentlevel] = $bullet;           # and the new bullet
                    }
                    else {                                          # level has remained the same
                        $indentlevel--;    # have not actually indented further, so undo the level increment
                        $b = $bullets[$indentlevel];    # and examine the bullet from this same level ...
                        if ( $b =~ /[A-Ya-y]/ ) {
                            $bullets[$indentlevel] =
                                chr( ord($b) + 1 );    # ... to see if it is a letter bullet that requires incrementing.
                        }
                    }
                }
            }
            my $bulletleader = '';
            for my $i ( 0 .. $indentlevel ) { # MediaWiki list item starts with sequence of bullets from level 0 upwards
                $b = $bullets[$i];
                if ( $b eq '*' || $b =~ /[A-Za-z]/ ) {
                    $bulletleader .= '*';     # Dot or lettered bullet
                }
                else {
                    $bulletleader .= '#';     # Digit
                }
            }
            if ( $b =~ /[A-Za-z]/ ) {
                $bulletleader .= " '''$b)'''"
                    ;    # MediaWiki syntax doesn't have lettered bullets, so insert the letter as a bold extra
            }
            $line = "$bulletleader $text\n";
        }
        elsif ( $line !~ /^\s*$/ ) {    # We have stopped processing a list; this line is from something else.
            $#indents = -1;
        }
        else {    # This is a blank line. If it occurs in the middle of a list, we can have trouble.
            $line = "<!--BLANK-->\n";    # Use "blank line" marker. Will be removed after all lines are processed.
        }

        $_ = $line;                      # Simplify subsequent regex substitutions

        # List conversion (DEPRECATED. Replaced by code above.)
        #s/^ \*(\s*.*?)/\*$1/;     	       # 1  ' * xxx'    ->  '* xxx'
        #s/^  \*(\s*.*?)/\*\*$1/;	         # 2  '  * xxx'   ->  '** xxx'
        #s/^   \*(\s*.*?)/\*\*\*$1/;        # 3  '   * xxx'  ->  '*** xxx'
        #s/^    \*(\s*.*?)/\*\*\*\*$1/;     # 4             etc.
        #s/^     \*(\s*.*?)/\*\*\*\*\*$1/;  # 5
        #s/^(\s+1\.)#(\d+)/$1 <!-- ! Should start numbering at $2 -->/; # Remove number starts. MW syntax only permits starting at 1
        #s/^(\s+)(\d+)\.\s*$/:$2./;         # Common idiom. A number on its own on a line. Almost like a numbered list, but not.
        #s/^ \d+\.\s+(.*)$/# $1/;           # 1  ' 1. xxx'    ->  '# xxxx'         Note: numbering is forced to start at 1
        #s/^  \d+\.\s+(.*)$/## $1/;         # 2  '  1. xxx'   ->  '## xxxx'
        #s/^   \d+\.\s+(.*)$/### $1/;       # 3  '   1. xxx'  ->  '### xxxx'
        #s/^    \d+\.\s+(.*)$/#### $1/;     # 4             etc.
        #s/^     \d+\.\s+(.*)$/##### $1/;   # 5
        #s/^ (a|A)\.\s+(.*)$/# $2/;         # 1  ' a. xxx'    ->  '# xxxx'
        #s/^  (a|A)\.\s+(.*)$/## $2/;       # 2  '  a. xxx'   ->  '## xxxx'
        #s/^   (a|A)\.\s+(.*)$/### $2/;     # 3  '   a. xxx'  ->  '### xxxx'
        #s/^    (a|A)\.\s+(.*)$/#### $2/;   # 4  '          etc.
        #s/^     (a|A)\.\s+(.*)$/##### $2/; # 5

        # Markup conversion (when on a single line)
        s/\^(.*?)\^/\<sup\>$1\<\/sup\>/g;        # ^ * ^     ->  <sup> * </sup>
        s/\,\,(.*?)\,\,/\<sub\>$1\<\/sub\>/g;    # ,, * ,,   ->  <sub> * </sub>
        s/__(.*?)__/\<u\>$1\<\/u\>/g;            # __ * __   ->  <u> * </u>
        s/--\((.*?)\)--/\<s\>$1\<\/s\>/g;        # --( * )-- ->  <s> * </s>

        # Mediawiki seems to understand ''', '' and '''''
        # 		  s/'''(.*?)'''/\<b\>$1\<\/b\>/g;                        # ''' * ''' ->  <b> * </b>
        # 		  s/''(.*?)''/\<i\>$1\<\/i\>/g;                          # '' * ''   ->  <i> * </i>
        s/~\+(.*?)\+~/\<span style="font-size: larger"\>$1\<\/span\>/g
            ;                                    # ~+xxx+~  ->  <span style="font-size: larger">xxx</span>
        s/~-(.*?)-~/\<span style="font-size: smaller"\>$1\<\/span\>/g
            ;                                    # ~-xxx-~  ->  <span style="font-size: smaller">xxx</span>
        s/^ (.*?):: (.*)$/; $1 : $2/;            # x:: y     ->  ; x : y
        s/\[\[BR\]\]/\<br\>/g;                   # [[BR]]    ->  <br>

        # Categories
        s/\[http:Category(\w+)\]/[[Category:$1]]/g;
        s/\["[^["]*\bCategory(\w+)"\]/[[Category:$1]]/g;    #"
        s/\[\[?CategoryCategory\]?\]//g;
        s/\bCategoryCategory\b//g;
        s/\[\[?Category(([A-Z][a-z0-9]+)+)\]?\]/[[Category:$1]]/g;
        s/\bCategory(([A-Z][a-z0-9]+)+)\b/[[Category:$1]]/g;
        if ( $mwname =~ /^Category/ ) {
            s/----\s*//s;
            s/'''List of pages in this category:'''\s*//s;
            s/To add a page to this category, add a link to this page on the last line of the page. You can add multiple categories to a page\.\s*//s;
            s/Describe the pages in this category\.\.\.\s*//s;
            s/\[\[FullSearch(\([^)]*\))?\]\]\s*//s;
        }

        # Link conversion
        ## comment these out as MoinMoin link syntax has changed since 1.5
        ## see http://moinmo.in/HelpOnLinking
        # s/\[\#([^\s|]+)[\s|]+([^\]]+)\]/\[\[\#$1|$2\]\]/g;     # [#Foo bar]   ->  [[#Foo|bar]]
        #	s/(?<!\[)\[\#([^\s:]+)\]/\[\[\#$1\]\]/g;                      # [# * ]   ->  [[ * ]]
        #	s/\[\"(.*?)\"\]/\[\[$1\]\]/g;                          # [" * "]  ->  [[ * ]]    (This may be covered by Free Link below)
        s/\[:([^:\]]+):([^\]]+)\]/[[$1|$2]]/g;    # [:HTML/AddedElementEmbed:embed] -> [[HTML/AddedElementEmbed|embed]]
        s/\[\:(.*?)\]/\[\[$1\]\]/g;               # [: * ]   ->  [[ * ]]

        # Images
        s/\binline:(\S+\.(png|jpg|gif))/[[Image:$1]]/g;    # inline:mypic.png  ->  [[Image:mypic.png]]

        # One-line wrappers
        s/\{\{\{(.*?)\}\}\}/<code\>\<nowiki\>$1\<\/nowiki\>\<\/code\>/g
            ;                                              # {{{ * }}}  ->  <code><nowiki> * </nowiki></code>

        # Multi-line wrappers
        s/\{\{\{(.*?)/\n\<pre\>\<nowiki\>$1/g;             # {{{ *   ->  <pre><nowiki> *
        s/(.*?)\}\}\}/$1\<\/nowiki\><\/pre\>\n/g;          #  * }}}  ->  * <\pre><\nowiki>
        s/--\(/<span style="text-decoration: line-through">/g
            ;    # --(  ->  <span style="text-decoration: line-through">  # could also use <s>   ?
        s/\)--/<\/span>/g;    # >--  ->  </span>                                       # could also use </s>  ?

        # Smileys
        s/<!>/<span style="font-size: x-large; color: red">!<\/span>/g
            ;                 # <!>  ->  <span style="font-size: x-large; color: red">!</span>
        s/\{\*\}/<span style="font-size: x-large; color: orange">*<\/span>/g
            ;                 # {*}  ->  <span style="font-size: x-large; color: orange">*</span>
        s/\{o\}/<span style="font-size: x-large; color: cyan">&curren;<\/span>/g
            ;                 # {o}  ->  <span style="font-size: x-large; color: cyan">&curren;</span>
        s/\{OK\}/<span style="font-size: large; color: green; background: yellow">OK<\/span>/g
            ;                 # {OK} ->  <span style="font-size: large; color: green; background: yellow">OK</span>
        s/\{X\}/<span style="font-size: large; color: white; background: red">X<\/span>/g
            ;                 # {OK} ->  <span style="font-size: large; color: white; background: red">X</span>
                              # To Do : the rest of the smileys

        # Wiki links
        ## comment these out as MoinMoin link syntax has changed since 1.5
        ## see http://moinmo.in/HelpOnLinking
        # s/\/CommentPage/???/g;                               # To Do
        s/\[\[GetText\((\w+)\)\]\]/$1/g;    # [[GetText(xx)]] -> xx

        #      s/((?<!)[A-Z][a-z]+[A-Z][a-z]+[A-Za-z]*)([^`])/[[$1]]$2/g;  #`# CamelCaseWord -> [[CamelCaseWord]]
        #      s/((?<!\w)[A-Z]\w*[a-z]\w*[A-Z]\w+)/[[$&]]/g;
        s/\[\[(http:[^\|]+)\|([^\]]+)\]\]/[$1 $2]/g;
        s/\[\[(https:[^\|]+)\|([^\]]+)\]\]/[$1 $2]/g;
        s/\[\[(http:[^\|]+)\]\]/$1/g;
        s/\[\[(https:[^\|]+)\]\]/$1/g;

        if (s/<<TableOfContents>>//g) {     # Cannot support TOC mid-text, but can put comment in.
            $toc = 1;
        }
        s/= Table of Contents =//g;
        s/== Table of Contents ==//g;
        s/=== Table of Contents ===//g;
        s/<<FullSearch(\([^)]*\))?>>//g;

        s/(?<![\&!\/#])\b([A-Z][a-z0-9]+){2,}(\/([A-Z][a-z0-9]+){2,})*\b/[[$&]]/g
            ;                               #`# CamelCaseWord -> [[CamelCaseWord]]
        s/!([A-Z][a-z]+[A-Z][a-z]+[A-Za-z]*)([^`])/$1$2/g;    #`# !CamelCaseWord -> CamelCaseWord
        s/\[\[\[(\w+)\]\]\s+(.+?)\]/[[$1|$2]]/g;              # [[[WikiPageName]] words] -> [[WikiPageName|words]]
        s/\[([^\]]+)\[\[(.*?)\]\](.*?)\]/[$1$2$3]/g
            ;    # [...[[...]]...]   ->  [.........]  repair accidental [[CamelCasing]]
        s/<<Anchor\((\w+)\)>>/<span id="$1"><\/span>/g;    # [[Anchor(name)]] -> <span id="name"></span>
        s/<<Include\((.*?)\)>>/{{:$1}}/g;                  # [[Include(OtherPage)]]  ->  {{:OtherPage}}

        # Boilerplate Phrases
        s/This wiki is powered by \[\[MoinMoin\]\]//g;
        s/<<FindPage>>/[[Special:Search|FindPage]]/g;
        s/(<<SyntaxReference>>)/(\[http:\/\/meta.wikimedia.org\/wiki\/Help:Editing SyntaxReference\])/g;
        s/<<SiteNavigation>>/\[\[Special:Specialpages|SiteNavigation\]\]/g;
        s/<<RecentChanges>>/\[\[Special:Recentchanges|RecentChanges\]\]/g;

        # Final tidy
        s/``//g;                                           # NonLinkCamel``CaseWord  ->  NonLinkCamelCaseWord
        s/\{\{attachment:([^\s\/]+\.(png|jpg|gif)) ([^\]]+)\}\}/[[Image:$mwname_\/attachments\/$1|$2]]/g
            ;    # [attachment:file.png/jpg/gif]  ->  [[Image:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:(\S+\.(png|jpg|gif)) ([^\]]+)\}\}/[[Image:$1|$2]]/g
            ;    # [attachment:file.png/jpg/gif]  ->  [[Image:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:([^\s\/]+\.(png|jpg|gif))\}\}/[[Image:$mwname_\/attachments\/$1]]/g
            ;    # [attachment:file.png/jpg/gif]  ->  [[Image:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:(\S+\.(png|jpg|gif))\}\}/[[Image:$1]]/g
            ;    # [attachment:file.png/jpg/gif]  ->  [[Image:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:([^\s\/]+) ([^\]]+)\}\}/[[Media:$mwname_\/attachments\/$1|$2]]/g
            ;    # [attachment:file.ext]  ->  [[Media:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:(\S+) ([^\]]+)\]/[[Media:$1|$2]]/g
            ;    # [attachment:file.ext]  ->  [[Media:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:([^\s\/]+)\}\}/[[Media:$mwname_\/attachments\/$1]]/g
            ;    # [attachment:file.ext]  ->  [[Media:MoinMoinPageName/attachments/file.ext]]
        s/\{\{attachment:(\S+)\}\}/[[Media:$1]]/g
            ;    # [attachment:file.ext]  ->  [[Media:MoinMoinPageName/attachments/file.ext]]

        # Final cleaning in case some pbs got introduced by the CamelCase regexp
        s/\[([^\]]+)\[\[(.*?)\]\](.*?)\]/[$1$2$3]/g
            ;    # [...[[...]]...]   ->  [.........]  repair accidental [[CamelCasing]]

        $replacement = $_;

        # The following code adjusts the markup for typical nested lists.
        # It does not deal with nested indented lists of definitions, though these are not normal in moinmoin
        # NOTE: This list processing may no longer be necessary following the list transform updates
        #if ($listprefix) { # if we are already processing a list
        #  if ($replacement =~ m/^([#\*]+)/) { # if we are continuing a list
        #    $replacementprefix = $1;
        #    if (length($replacementprefix) < length($listprefix)) { # list has un-indented
        #      $listprefix = substr($listprefix,0,length($replacementprefix)); # shrink the prefix accordingly
        #    }
        #    substr($replacement,0,length($listprefix)) = $listprefix; # ensure the current prefix matches the previous
        #    $replacement =~ m/^([#\*]+)/;
        #    $listprefix = $1;
        #  }
        #}
        #else {
        #  if ($replacement =~ m/^([#\*]+)/) { # if we have started a list
        #    $listprefix = $1;
        #  }
        #}
        # end of list processing

        if ( $tabledepth == 0 ) {    # are we outside a table?
            if ( $replacement =~ m/^\|\|/ ) {    # and are we starting a new table?
                $tabledepth++;                   # yes, we are now in a new table
                $replacement = "{| border=\"1\" cellpadding=\"2\" cellspacing=\"0\"\n" . ProcessTableRow($replacement);
            }
        }
        else {                                   # we are possibly in the middle of a table
            if ( $replacement !~ m/^\|\|/ ) {    # no more table markup, so we are exiting the table
                $replacement = "|}\n" . $replacement;
                $tabledepth--;
            }
            else {                               # we are continuing to another row of the table
                $replacement = "|-\n" . ProcessTableRow($replacement);
            }
        }

        # Transform attachment URLs MoinMoinPageName/attachments/filename.ext  ->  MoinMoinPageName$filename.ext   $$
        while ( $replacement =~ m/\[\[(Image|Media):([^\]\/]*?)\// ) {
            $replacement =~ s/\[\[(Image|Media):([^\]\/]*?)\//[[$1:$2\$\$/;
        }
        $replacement =~ s/\$\$attachments\$\$/\$/g;
        while ( $replacement =~ m/\[\[(Image|Media):(.*?)\]\]/g ) {
            #### $wikiAttachmentReferences{$2} += 1;
        }
        $replacement =~ s/\[\[(Image|Media)(:[^\]]+)\$\$([^\]\$]+)]\]/[[$1$2\$$3]]/g;

        push( @lines, $replacement );
        $prev = $replacement;    # remember the previously generated MW line (e.g. for list prefix comparisons)
    }    # end while <line>

    my $doc = "";
    if ( !$toc ) {
        $doc = "__NOTOC__\n";
    }
    $doc .= join( "\n", @lines );

    # Global edits to the entire document
    $doc =~ s/<!--BLANK-->\n(<!--BLANK-->\n)+/<!--BLANK-->\n/gs;             # Collapse multipled BLANK lines into one
    $doc =~ s/([ \t]*[\*\#][^\n]+\n)<!--BLANK-->\n(?=[ \t]*[\*\#])/$1$2/gs
        ;    # Remove BLANKs that occur in the middle of lists
    $doc =~ s/<!--BLANK-->\n/\n/gs;    # Reinstate remaining BLANKs as actual blank lines

    #### if ($diagnosticShowComparisonLink) {
    ####     $doc = "''Compare'': $moinmoinurlbase$mwname_\n\n" . $doc;    # Diagnostic
    #### }
    return @lines;
}

# ------------------------------------------------------------------------

sub process_moin_page {
    my $indir   = shift;
    my $outdir  = shift;
    my $context = shift;
    my $pagedir = shift;

    return unless ( -d File::Spec->catfile( $pagedir, 'revisions' ) );
    my $name = ( File::Spec->splitdir($pagedir) )[-1];

    # see if this page was deleted...
    my $fn = File::Spec->catfile( $pagedir, 'edit-log' );
    die unless ( -f $fn );
    my $content = read_file($fn);

    return if ( $content =~ /Page deleted by Despam action/ );

    # get text filename and page name
    my $textfn = ( sort glob( File::Spec->catfile( $pagedir, 'revisions', '*' ) ) )[-1];
    my $outfn = $name;
    $outfn =~ s/\(([0-9a-zA-Z]+)\)/chr(hex($1))/eg;

    # grab and process file content
    my @lines = read_file($textfn);
    chomp @lines;
    my @newlines = wikiconvert( $outfn, \@lines );

    # output replacement file
    my $foutfn = File::Spec->catfile( $outdir, $outfn . '.mediawiki' );
    my ( $a, $b, $c ) = File::Spec->splitpath($foutfn);
    make_path($b);
    write_file( $foutfn, join( "\n", @newlines, '' ) );
}

# ------------------------------------------------------------------------

sub process_data_dir {
    my $indir   = shift;
    my $outdir  = shift;
    my $context = shift;

    die "No indir"  unless ( -d $indir );
    die "No outdir" unless ( -d $outdir );
    my @names = bsd_glob( File::Spec->catfile( $indir, '*' ) );
    foreach my $name (@names) {
        process_moin_page( $indir, $outdir, $context, $name );
    }
}

# ------------------------------------------------------------------------

sub read_edit_logs {

}

# ------------------------------------------------------------------------

process_data_dir( 'pages', 'out', {} );

