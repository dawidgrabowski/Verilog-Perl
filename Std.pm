# See copyright, etc in below POD section.
######################################################################

package Verilog::Std;
use Config;
use IO::File;
use File::Path;
use Carp;
use strict;

use vars qw ($VERSION);

######################################################################
#### Configuration Section

$VERSION = '3.211';

#######################################################################
# ACCESSORS

our $_Std_Data;

sub std {
    if (!$_Std_Data) {
	my @out;
	foreach (<DATA>) {
	    last if $_ =~ /^__END__/;
	    push @out, $_;
	}
	$_Std_Data = join('',@out);
    }
    return $_Std_Data;
}

#######################################################################
# It's a PITRA to have pure datafiles get installed properly,
# so we just paste our text into this package.
1;
__DATA__

`line 1 "Perl_Verilog::Std_module" 0
// Verilog-Perl Verilog::Std
// The basis for this package is described in IEEE 1800 Annex C
package std;

class semaphore;
   extern function new(int keyCount = 0);
   extern task put(int keyCount = 1);
   extern task get(int keyCount = 1);
   extern function int try_get(int keyCount = 1);
endclass

class mailbox #(type T = dynamic_singular_type) ;
   extern function new(int bound = 0);
   extern function int num();
   extern task put( T message);
   extern function int try_put( T message);
   extern task get( ref T message );
   extern function int try_get( ref T message );
   extern task peek( ref T message );
   extern function int try_peek( ref T message );
endclass

class process;
   typedef enum { FINISHED, RUNNING, WAITING, SUSPENDED, KILLED } state;
   extern static function process self();
   extern function state status();
   extern task kill();
   extern task await();
   extern task suspend();
   extern task resume();
endclass

//Compiler built-in due to specialized arguments
//function int randomize( ... );
// randomize( variable_identifier {, variable_identifier } ) [ with constraint_block ];

endpackage : std

import std::*;

__END__

=pod

=head1 NAME

Verilog::Std - SystemVerilog Built-in std Package Definition

=head1 SYNOPSIS

Internally used by Verilog::SigParser, etc.

   use Verilog::Std;
   print Verilog::Std::std;

=head1 DESCRIPTION

Verilog::Std contains the built-in "std" package required by the
SystemVerilog standard.

=head1 FUNCTIONS

=over 4

=item std

Return the definition of the std package.

=back

=head1 DISTRIBUTION

Verilog-Perl is part of the L<http://www.veripool.org/> free Verilog EDA
software tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/verilog-perl>.

Copyright 2009-2009 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog-Perl>

=cut

######################################################################
