#!/usr/bin/perl -w
# $Id: 10_keywords.t 29806 2007-01-10 13:04:28Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2000-2007 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 25 }
BEGIN { require "t/test_utils.pl"; }

use Verilog::Language;
ok(1);

ok (Verilog::Language::is_keyword("input"));
ok (!Verilog::Language::is_keyword("not_input"));
ok (Verilog::Language::is_compdirect("`define"));

ok (Verilog::Language::language_standard() eq 'sv31');
ok (Verilog::Language::is_keyword("do"));
ok (Verilog::Language::language_standard(2001) eq 2001);
ok (Verilog::Language::is_keyword("generate"));
ok (Verilog::Language::language_standard(1995) eq 1995);
ok (!Verilog::Language::is_keyword("generate"));

ok (Verilog::Language::number_value("5'h13")==19);
ok (Verilog::Language::number_value("5'd13")==13);
ok (Verilog::Language::number_value("5'o13")==11);
ok (Verilog::Language::number_value("5'B11")==3);
ok (Verilog::Language::number_value("5 'B 11")==3);
ok (Verilog::Language::number_value("'b10")==2);
ok (Verilog::Language::number_value("2'sb10")==2);
ok (Verilog::Language::number_bits("8'b10")==8);
ok (Verilog::Language::number_bits("8 'b 10")==8);
ok (Verilog::Language::number_signed("8 'sb 1")==1);
ok (!defined Verilog::Language::number_bits("'b10"));

ok (Verilog::Language::strip_comments("he/**/l/**/lo") eq "hello");
ok (Verilog::Language::strip_comments("he//xx/*\nllo") eq "he\nllo");
ok (Verilog::Language::strip_comments("he/*xx//..*/llo") eq "hello");
ok (Verilog::Language::strip_comments("he\"//llo\"") eq "he\"//llo\"");
