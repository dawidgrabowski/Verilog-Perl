#!/usr/local/bin/perl -w
# $Revision: #5 $$Date: 2002/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;

BEGIN { plan tests => 6 }
BEGIN { require "t/test_utils.pl"; }

print "Checking vrename...\n";

unlink 'signals.vrename';
run_system ("${PERL} ./vrename -list -xref verilog/test.v");
ok(1);
ok(-r 'signals.vrename');

mkdir 'test_dir', 0777;
mkdir 'test_dir/verilog', 0777;
run_system ("${PERL} ./vrename -change --changefile verilog/test.vrename"
	    ." -o test_dir verilog/test.v");
ok(1);
ok(-r 'test_dir/verilog/test.v');

unlink 'signals.vrename';
run_system ("${PERL} ./vrename -list --crypt"
	    ." -o test_dir verilog/test.v");
run_system ("${PERL} ./vrename -change --crypt"
	    ." -o test_dir verilog/test.v");
ok(1);
ok(-r 'test_dir/verilog/test.v');
