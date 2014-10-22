#!/usr/local/bin/perl -w
# $Revision: #12 $$Date: 2003/09/25 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2000-2003 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use IO::File;
use strict;
use Test;

BEGIN { plan tests => 4 }
BEGIN { require "t/test_utils.pl"; }

print "Checking vpm...\n";

mkdir 'test_dir', 0777;

# Preprocess the files
mkdir "test_dir/.vpm", 0777;
run_system ("${PERL} vpm --nostop -o test_dir/.vpm --date -y verilog/");
ok(1);
ok(-r 'test_dir/.vpm/pli.v');

my $orig_lines = lines_in("verilog/example.v");
my $new_lines = lines_in("test_dir/.vpm/example.v");
print "Line count: $orig_lines =? $new_lines\n";
ok($orig_lines==$new_lines);

# Build the model
unlink "simv";
if (!$ENV{VCS_HOME} || !-r "$ENV{VCS_HOME}/bin/vcs") {
    warn "*** You do not have VCS installed, not running rest of test!\n";
    skip(1,1);
} else {
    chdir 'test_dir';
    run_system (# We use VCS, insert your simulator here
		"$ENV{VCS_HOME}/bin/vcs"
		# vpm uses `pli to point to the hiearchy of the pli module
		." +define+pli=pli"
		# vpm uses `__message_on to point to the message on variable
		." +define+__message_on=pli.message_on"
		# Read files from .vpm BEFORE reading from other directories
		." +librescan +libext+.v -y .vpm"
		# Finally, read the needed top level file
		." .vpm/example.v"
		);
    # Execute the model (VCS is a compiled simulator)
    run_system ("./simv");
    unlink ("./simv");
    chdir '..';
	
    ok(1);
}

sub lines_in {
    my $filename = shift;
    my $fh = IO::File->new($filename) or die "%Error: $! $filename";
    my @lines = $fh->getlines();
    return $#lines;
}
