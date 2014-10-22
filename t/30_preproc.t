#!/usr/bin/perl -w
# $Id: 30_preproc.t 29806 2007-01-10 13:04:28Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2000-2007 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use IO::File;
use strict;
use Test;

BEGIN { plan tests => 12 }
BEGIN { require "t/test_utils.pl"; }

#######################################################################
package MyPreproc;
use Verilog::Preproc;
use vars qw (@ISA);
@ISA = qw(Verilog::Preproc);
sub comment { print $::OUTTO "COMMENT: $_[1]\n";
	      $_[0]->unreadback(' /*CMT*/ '); }
package main;
#######################################################################

sub prep {
    my $opt = new Verilog::Getopt;
    $opt->parameter (qw(
			+incdir+verilog
			));
    return $opt;
}

use Verilog::Getopt;
ok(1);

use Verilog::Preproc;
ok(1);

{
    my $opt = prep();
    my $pp = new Verilog::Preproc (options=>$opt);
    ok(1);

    #$pp->debug(9);
    $pp->open("inc1.v");
    $pp->open("inc2.v");
    ok(1);

    my $fhout = IO::File->new(">test_dir/inc.out");

    my $ln = 1;
    while (defined(my $line = $pp->getline())) {
	#print "LINE: $line";
	print $fhout $pp->filename.":".$pp->lineno.": ".$line;
	die if ++$ln > 2000;
    }
    ok(1);

    $fhout->close();
    ok(files_identical("test_dir/inc.out", "t/30_preproc.out"));
}

test ('_sub', keep_comments=>'sub',);
test ('_on',  keep_comments=>1,);
test ('_nows', keep_comments=>0, keep_whitespace=>0,);

sub test {
    my $id = shift;
    my @args = @_;

    my $opt = prep();
    my $pp = new MyPreproc (options=>$opt, @args);
    $pp->open("inc1.v");
    $pp->open("inc2.v");

    my $fhout = IO::File->new(">test_dir/inc${id}.out");
    $::OUTTO = $fhout;
    while (defined(my $line = $pp->getline())) {
	print $fhout $pp->filename.":".$pp->lineno.": ".$line;
    }
    $fhout->close();
    ok(1);

    ok(files_identical("test_dir/inc${id}.out", "t/30_preproc${id}.out"));
}

