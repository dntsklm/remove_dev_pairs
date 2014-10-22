#!/usr/bin/perl -T

# Remove two lines containing "//DEV//" (the marker lines) and
# everything in between them from specified text files.
#
# Copyright © 2014 Donatas Klimašauskas, GPLv3+
#
# remove_dev_pairs.pl is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# remove_dev_pairs.pl is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with remove_dev_pairs.pl.  If not, see
# <https://www.gnu.org/licenses/>.

use v5.14;
use strict;
use warnings FATAL => 'all';
use autodie;
use utf8;

sub main(@)
{
    my @ARGS = @_;
    my $PN = substr($0, rindex($0, "/") + 1);

    my $print_message = sub($)
    {
	my $msg = shift;

	say "$PN: $msg";
	return;
    };

    my $terminate = sub($)
    {
	my $msg = shift;

	say STDERR "$PN: error: $msg";
	exit 1;
    };

    my $MARKER = '//DEV//';

    if (@ARGS == 0 || $ARGS[0] eq "-h") {
	say "Usage: $PN <file>...\n" .
	    "<file>...	text files with \"$MARKER\" marker pairs\n" .
	    "Note: Removal is done in place -- no back-ups are created";
	return 0;
    }

    my $EVEN = 2;

    my $remove_dev_pairs = sub($)
    {
	my $file = shift;
	my $count = 0;
	my $pass = 1;
	my $tmpstr = "";

	if ($file !~ m/^([\/\.\w]+)$/) {
	    $terminate->("bad file-name: $file");
	} else {
	    $file = $1; # remove taint
	}
	open(my $fh, "<", $file);
	foreach my $line (<$fh>) {
	    if ($line =~ m/$MARKER/) {
		$count++;
		if ($pass) {
		    $pass = 0;
		} else {
		    $pass = 1;
		    next;
		}
	    }
	    if ($pass) {
		$tmpstr .= $line;
	    }
	}
	if (!$count) {
	    $print_message->("no \"$MARKER\" lines found in: $file");
	    return;
	}
	if ($count % $EVEN) {
	    $terminate->("odd number of \"$MARKER\" lines in: $file");
	}
	open($fh, ">", $file);
	print $fh $tmpstr;
	close($fh);
	$print_message->("ok: $file");
	return;
    };

    my $check_modify_files = sub(@)
    {
	my @files = @_;

	$remove_dev_pairs->($_) foreach @files;
	return;
    };

    $check_modify_files->(@ARGS);
    return 0;
}

exit main(@ARGV);
