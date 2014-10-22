#!/usr/local/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;
use Cwd;

BEGIN { plan tests => 9 }
BEGIN { require "t/test_utils.pl"; }

use Verilog::Getopt;
ok(1);

$Verilog::Getopt::Debug = 1;

my $opt = new Verilog::Getopt;
ok(1);

my @param = qw ( +libext+t
		 +incdir+t
		 +define+foo=bar
		 +define+foo2
		 -v libdir
		 -y moddir 
		 -Dbaz=bar
		 -Iincdir2
		 -f t/20_getopt.opt
		 passthru
		 );

my @left = $opt->parameter(@param);
print join(" ",@left),"\n";
ok ($#left == 0);	# passthru

ok ($opt->defvalue('read_opt_file'));

my $fp = $opt->file_path('20_getopt.t');
print "fp $fp\n";
ok ($fp eq (Cwd::abs_path("t")."/20_getopt.t"));

my @out = $opt->get_parameters();
print "OUT: ",(join(" ",@out)),"\n";
ok ($#out == 14);

{
    my $opt2 = new Verilog::Getopt ();
    my @left2 = $opt2->parameter(@out);
    print join(" ",@left2),"\n";
    my @out2 = $opt->get_parameters();
    print join(" ",@out2),"\n";
    ok ($#out2 == 14);
}

{
    my $opt2 = new Verilog::Getopt (gcc_style=>1, vcs_style=>0);
    my @left2 = $opt2->parameter(@param);
    print join(" ",@left2),"\n";
    ok ($#left2 == 8);
}

{
    my $opt2 = new Verilog::Getopt (gcc_style=>0, vcs_style=>1);
    my @left2 = $opt2->parameter(@param);
    print join(" ",@left2),"\n";
    ok ($#left2 == 2);
}


