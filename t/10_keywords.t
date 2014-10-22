#!/usr/bin/perl -w
# $Revision: 1.9 $$Date: 2005-01-24 10:18:02 -0500 (Mon, 24 Jan 2005) $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2000-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 17 }
BEGIN { require "t/test_utils.pl"; }

use Verilog::Language;
ok(1);

ok (Verilog::Language::is_keyword("input"));
ok (!Verilog::Language::is_keyword("not_input"));
ok (Verilog::Language::is_compdirect("`define"));

ok (Verilog::Language::number_value("5'h13")==19);
ok (Verilog::Language::number_value("5'd13")==13);
ok (Verilog::Language::number_value("5'o13")==11);
ok (Verilog::Language::number_value("5'B11")==3);
ok (Verilog::Language::number_value("5 'B 11")==3);
ok (Verilog::Language::number_value("'b10")==2);
ok (Verilog::Language::number_bits("8'b10")==8);
ok (Verilog::Language::number_bits("8 'b 10")==8);
ok (!defined Verilog::Language::number_bits("'b10"));

ok (Verilog::Language::strip_comments("he/**/l/**/lo") eq "hello");
ok (Verilog::Language::strip_comments("he//xx/*\nllo") eq "he\nllo");
ok (Verilog::Language::strip_comments("he/*xx//..*/llo") eq "hello");
ok (Verilog::Language::strip_comments("he\"//llo\"") eq "he\"//llo\"");
