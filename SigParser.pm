# Verilog::SigParser.pm -- Verilog signal parsing
# $Revision: #36 $$Date: 2003/08/19 $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

=head1 NAME

Verilog::SigParser - Signal Parsing for Verilog language files

=head1 SYNOPSIS

  use Verilog::SigParser;

  my $parser = new Verilog::SigParser;
  $string = $parser->unreadback ();
  $line   = $parser->line ();
  $parser->parse_preproc_file ($pp);

=head1 DESCRIPTION

The C<Verilog::SigParser> package builds upon the Verilog::Parse function
to provide callbacks for when a signal is declared, a module instantiated,
or a module defined.  For a higher level interface to this package, see
C<Verilog::Netlist>.

The external interface to Verilog::SigParser is described in the
Verilog::Parser module.  You will probably want to use the preprocessing
option of Verilog::Parser with this package.

In order to make the parser do anything interesting, you must make a
subclass where you override one or more of the following methods as
appropriate:

=over 4

=item $self->module ( $keyword, $name )

This method is called when a module is defined.

=item $self->task ( $keyword, $name )

This method is called when a module is defined.

=item $self->function ( $keyword, $name )

This method is called when a function is defined.

=item $self->signal_decl ( $keyword, $signame, $vector, $mem )

This method is called when a signal is declared.  The first argument,
$keyword is ('input', 'output', etc), the second argument is the name of
the signal.  The third argument is the vector bits or "".  The fourth
argument is the memory bits or "".

=item $self->instant ( $module, $cell )

This method is called when a instantantiation is defined.  The first
parameter is the name of the module being instantiated, and the second
parameter is the name of the cell.

=back

=head1 SEE ALSO

C<Verilog::Parser>, 
C<Verilog::Language>, 
C<Verilog::Netlist>, 
C<Verilog::Getopt>, 

=head1 BUGS

This is being distributed as a baseline for future contributions.  Don\'t
expect a lot, the Parser is still nieve, and there are many awkward cases
that aren\'t covered.

=head1 DISTRIBUTION

The latest version is available from
C<http://veripool.com/verilog-perl>.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut

######################################################################

package Verilog::SigParser;
require 5.000;
require Exporter;

use strict;
use vars qw($VERSION @ISA $Debug);
use English;
use Carp;
use Verilog::Parser;

@ISA = qw(Verilog::Parser);

######################################################################
#### Configuration Section

# Other configurable settings.
$Debug = 0;		# for debugging

$VERSION = '2.226';

#######################################################################

# parse, parse_file, etc are inherited from Verilog::Parser
sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{last_operator} = "";
    $self->{last_keyword} = "";
    $self->{last_module}  = undef;
    $self->{last_function} = undef;
    $self->{last_task}    = undef;
    @{$self->{last_symbols}} = ();
    $self->{last_vectors} = "";
    $self->{last_param} = "";
    $self->{is_inst_ok}   = 1;
    $self->{is_pin_ok}    = 0;
    $self->{is_signal_ok} = 1;
    $self->{in_preproc_line} = -1;
    $self->{in_vector} = 0;
    $self->{in_param_assign} = 0;
    $self->{possibly_in_param_assign} = 0;
    $self->{pin_name}    = undef;

    bless $self, $class; 
    return $self;
}

#######################################################################
# Null callbacks

# The my's aren't needed since we do nothing, but are useful if the
# user copies them from here to their program.
sub module {
    my $self = shift;
    my $keyword = shift;
    my $name = shift;
}

sub task {
    my $self = shift;
    my $keyword = shift;
    my $name = shift;
}

sub function {
    my $self = shift;
    my $keyword = shift;
    my $name = shift;
}

sub signal_decl {
    my $self = shift;
    my $keyword = shift;
    my $name = shift;
    my $vector = shift;
    my $mem = shift;
}

sub instant {
    my $self = shift;
    my $module = shift;
    my $cell = shift;
}

sub pin {
    my $self = shift;
    my $name = shift;
    my $conn = shift;
    my $number = shift;
}

sub ppdefine {
    my $self = shift;
    my $defvar = shift;
    my $definition = shift;
}

sub ppinclude {
    my $self = shift;
    my $defvar = shift;
    my $definition = shift;
}

######################################################################
# Overrides of Verilog::Parser routines

sub reset {
    # Verilog::Parser calls when a new file is parsed
    my $self = shift;	# Parser invoked
    $self->SUPER::reset();

    $self->{last_operator} = "";
    $self->{last_keyword} = "";
    $self->{last_module} = undef;
    $self->{last_function} = undef;
    $self->{last_task} = undef;
    $self->{last_vectors} = "";
    $self->{last_param} = "";
    $self->{is_inst_ok} = 1;
    $self->{is_pin_ok} = 0;
    $self->{is_signal_ok} = 1;
    $self->{in_preproc_line} = -1;
    $self->{in_vector} = 0;
    $self->{in_param_assign} = 0;
    $self->{possibly_in_param_assign} = 0;
    $self->{pin_name} = undef;

    @{$self->{last_symbols}} = ();
}

sub keyword {
    # Verilog::Parse calls when keyword occurs
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed

    if (defined $self->{last_preproc} && $self->{preprocess}
	&& $self->{in_preproc_line} != $self->line()
	&& $self->{last_preproc} eq "`define") {
	my $def = shift @{$self->{last_ppitem}};
	$self->ppdefine ($def, (join "",@{$self->{last_ppitem}}));
	$self->{last_preproc} = undef;
	@{$self->{last_ppitem}} = ();
    }

    if ($token =~ /^\`/) {
	$self->{last_preproc} = $token;
	$self->{in_preproc_line} = $self->line;
    }
    if ($self->{in_preproc_line} != $self->line()) {
	$self->{last_keyword} = $token;
	@{$self->{last_symbols}} = ();
	$self->{last_vectors} = "";
    }
    if ($token eq "end") {
	# Prepare for next command
	$self->{last_keyword} = "";
	@{$self->{last_symbols}} = ();
	$self->{last_vectors} = "";
	$self->{is_inst_ok} = 1;
	$self->{is_signal_ok} = 1;
	$self->{is_pin_ok} = 0;
	$self->{got_preproc} = 0;
    }
    elsif ($token eq "endtask") {
	$self->{last_task} = undef;
    } elsif ($token eq "endmodule"
	     || $token eq "endprimitive") {
	$self->{last_module} = undef;
    } elsif ($token eq "endfunction") {
	$self->{last_function} = undef;
    }
}

sub symbol {
    # Verilog::Parse calls when symbol occurs
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed

    if ($self->{in_preproc_line} != $self->line()) {
	if ($self->{in_vector} == 1) {
	    $self->{last_vectors} = $self->{last_vectors} . $token;
	} elsif ($self->{in_param_assign} == 1) {
	    $self->{last_param} = $self->{last_param} . $token;
	} else {
	    push @{$self->{last_symbols}}, $token;
	}
    } else {
	push @{$self->{last_ppitem}}, $token;
    }
    if ($self->{is_pin_ok}) {
	if ($self->{last_operator} eq ".") {
	    $self->{pin_name} = $token;
	    @{$self->{last_symbols}} = ();
	    $self->{last_vectors} = "";
	}
    }
}

sub number {
    # Verilog::Parse calls when number occurs
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed

    if ($self->{in_preproc_line} != $self->line()) {
	$self->{last_vectors} = $self->{last_vectors} . $token;
    } else {
	push @{$self->{last_ppitem}}, $token;
    }
}

sub operator {
    # Verilog::Parse calls when operator occurs
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed

    my $lkw = $self->{last_keyword};

    #print "Op $token\n" if $Debug;

    if ($self->{in_preproc_line} != $self->line) {
	if ($token eq "{") { $self->{bracket_level} ++; }
	elsif ($token eq "}") { $self->{bracket_level}-- if $self->{bracket_level}; }
	if ($token eq "(") { $self->{paren_level} ++; }
	elsif ($token eq ")") { $self->{paren_level}-- if $self->{paren_level}; }

	if ($token eq "]") {
	    $self->{in_vector} = 0;
	    $self->{last_vectors} = $self->{last_vectors} . $token;
	}
	elsif ($self->{in_vector} == 1) {
	    $self->{last_vectors} = $self->{last_vectors} . $token;
	}
	elsif ($self->{in_param_assign} == 1) {
	    if ($token eq ")") {
		$self->{in_param_assign} = 0;
	    }
	    $self->{last_param} = $self->{last_param} . $token;
	}
	elsif ($token eq "("
	       && ($lkw eq "" || $lkw =~ /^end/ || $self->{got_preproc})
	       && (defined $self->{last_symbols}[0])
	       && (defined $self->{last_symbols}[1])
	       && $self->{is_inst_ok}
	       ) {
	    my $mod = $self->{last_symbols}[0];
	    my $inst = $self->{last_symbols}[1];
	    @{$self->{last_symbols}} = ();
	    $self->{last_vectors} = "";
	    print "Gotainst $mod $inst\n"    if ($Debug);
	    $self->instant ($mod, $inst);
	    $self->{last_inst_mod} = $mod;
	    $self->{is_inst_ok} = 0;
	    $self->{is_pin_ok} = 1;
	}
	elsif ($token eq "," || $token eq ";") {
	    if ($self->{is_pin_ok}
		&& defined $self->{last_symbols}[0]
		&& !$self->{bracket_level}) {
		my $vec = "";
		my $namedports = 0;
		$vec = $self->{last_vectors} if ($self->{last_vectors} ne "");
		my $pin_name = $self->{pin_name};
		$namedports = 1 if defined $pin_name;
		$pin_name ||= "pin" . $self->{is_pin_ok};
		$self->pin ($pin_name,
			    $self->{last_symbols}[0] . $vec,
			    $self->{is_pin_ok},
			    $namedports);
		$self->{is_pin_ok}++;  # moved to after pin call
		$self->{pin_name} = undef;
		$self->{last_vectors} = "";
		@{$self->{last_symbols}} = ();
	    }
	    if ($token eq "," && $self->{is_pin_ok} && !$self->{paren_level}) {
		# At the , that separates instances
		$self->{last_symbols} = [$self->{last_inst_mod}];
		$self->{last_keyword} = "";
		$self->{is_inst_ok} = 1;
	    }

	    if ($token eq ";") {
		if ($lkw eq "task") {
		    my $mod = $self->{last_symbols}[0];
		    $self->{last_task} = $mod;
		    print "Gota$lkw $mod\n"    if ($Debug);
		    $self->task ($lkw, $mod);
		} elsif ($lkw eq "module"
			 || $lkw eq "primitive") {
		    my $mod = shift @{$self->{last_symbols}};
		    $self->{last_module} = $mod;
		    print "Gota$lkw $mod\n"    if ($Debug);
		    $self->module ($lkw, $mod, $self->{last_symbols});
		} elsif ($lkw eq "function") {
		    my $mod = $self->{last_symbols}[0];
		    $self->{last_function} = $mod;
		    print "Gota$lkw $mod\n"    if ($Debug);
		    $self->function ($lkw, $mod);
		}
		elsif ((($lkw eq "input")
			|| ($lkw eq "output")
			|| ($lkw eq "inout")
			|| ($lkw eq "reg" || $lkw eq "trireg")
			|| ($lkw eq "wire" || $lkw eq "wand" || $lkw eq "wor"
			    || $lkw eq "tri" || $lkw eq "triand" || $lkw eq "trior"
			    || $lkw eq "tri0" || $lkw eq "tri1"
			    || $lkw eq "supply0" || $lkw eq "supply1")
			)
		       && $self->{is_signal_ok}) {
		    my $sig;
		    foreach $sig (@{$self->{last_symbols}}) {
			my $vec = "";
			my $mem = "";
			if ($self->{last_vectors} ne "") {
			    if ($self->{last_vectors} =~ /^(\S+) (\S+)$/) {
				$vec = $1;
				$mem = $2;
			    } else {
				$vec = $self->{last_vectors};
			    }
			}
			#print "Gota$lkw $sig $vec $mem\n"    if ($Debug);
			$self->signal_decl ($lkw, $sig, $vec, $mem);
		    }
		}
		# Prepare for next command
		$self->{last_keyword} = "";
		@{$self->{last_symbols}} = ();
		$self->{last_vectors} = "";
		$self->{is_inst_ok} = 1;
		$self->{is_signal_ok} = 1;
		$self->{is_pin_ok} = 0;
		$self->{got_preproc} = 0;
	    }
	}
	elsif ($token eq "=") {
	    $self->{is_signal_ok} = 0;
	    $self->{is_inst_ok} = 0;
	}
	elsif ($token eq "[") {
	    $self->{in_vector} = 1;
	    if ($self->{last_vectors} eq "") {
		$self->{last_vectors} = $token;
	    } else {
		$self->{last_vectors} = $self->{last_vectors} . ' ' . $token;
	    }
	}
	elsif ($token eq "#") {
	    $self->{possibly_in_param_assign} = 1;
	    $self->{last_param} = $token;
	}
	elsif ($token eq "(" && $self->{possibly_in_param_assign}) {
	    $self->{in_param_assign} = 1;
	    $self->{possibly_in_param_assign} = 0;
	    $self->{last_param} = $self->{last_param} . $token;
	}
	else {
	    $self->{is_inst_ok} = 0;
	}
    }
    else {
	push @{$self->{last_ppitem}}, $token;
    }
    $self->{last_operator} = $token;
}

######################################################################
### Package return
1;
