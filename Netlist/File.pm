# Verilog - Verilog Perl Interface
# $Revision: #22 $$Date: 2003/05/19 $$Author: wsnyder $
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

package Verilog::Netlist::File;
use Class::Struct;
use Carp;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist::File::Struct
	Verilog::Netlist::Subclass);
$VERSION = '2.223';
use strict;

structs('new',
	'Verilog::Netlist::File::Struct'
	=>[name		=> '$', #'	# Filename this came from
	   basename	=> '$', #'	# Basename of the file
	   netlist	=> '$', #'	# Netlist is a member of
	   userdata	=> '%',		# User information
	   is_libcell	=> '$',	#'	# True if is a library cell
	   # For special procedures
	   _modules	=> '%',		# For autosubcell_include
	   ]);
	
######################################################################
######################################################################
#### Read class

package Verilog::Netlist::File::Parser;
use Verilog::SigParser;
use Verilog::Preproc;
use strict;
use vars qw (@ISA);
@ISA = qw (Verilog::SigParser);

sub new {
    my $class = shift;
    my %params = (@_);	# filename=>

    # A new file; make new information
    $params{fileref} or die "No fileref parameter?";
    $params{netlist} = $params{fileref}->netlist;
    my $parser = $class->SUPER::new (%params,
				     modref=>undef,	# Module being parsed now
				     cellref=>undef,	# Cell being parsed now
				     );
    
    my @opt;
    push @opt, (options=>$params{netlist}{options}) if $params{netlist}{options};
    my $preproc = Verilog::Preproc->new(@opt,
					keep_comments=>0,);
    $preproc->open($params{filename});
    $parser->parse_preproc_file ($preproc);
    return $parser;
}

sub module {
    my $self = shift;
    my $keyword = shift;
    my $module = shift;
    my $orderref = shift;

    my $fileref = $self->{fileref};
    my $netlist = $self->{netlist};
    print "Module $module\n" if $Verilog::Netlist::Debug;

    $self->{modref} = $netlist->new_module
	 (name=>$module,
	  is_libcell=>$fileref->is_libcell(),
	  filename=>$self->filename, lineno=>$self->lineno);
    @{$self->{modref}->portsordered} = @$orderref;
    $fileref->_modules($module, $self->{modref});
}

sub signal_decl {
    my $self = shift;
    my $inout = shift;
    my $netname = shift;
    my $vector = shift;
    my $array = shift;
    print " Sig $netname $inout\n" if $Verilog::Netlist::Debug;

    my $msb;
    my $lsb;
    if ($vector && $vector =~ /\[(.*):(.*)\]/) {
	$msb = $1; $lsb = $2;
    } elsif ($vector && $vector =~ /\[(.*)\]/) {
	$msb = $lsb = $1;
    }

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("Signal declaration outside of module definition", $netname);
    }

    if ($inout eq "reg"
	|| $inout eq "wire"
	) {
	my $net = $modref->find_net ($netname);
	$net or $net = $modref->new_net
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     simple_type=>1, type=>'wire', array=>$array,
	     comment=>undef, msb=>$msb, lsb=>$lsb,
	     );
    }
    elsif ($inout =~ /(inout|in|out)(put|)$/) {
	my $dir = $1;
	##
	my $net = $modref->find_net ($netname);
	$net or $net = $modref->new_net
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     simple_type=>1, type=>'wire', array=>$array,
	     comment=>undef, msb=>$msb, lsb=>$lsb,
	     );
	##
	my $port = $modref->new_port
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     direction=>$dir, type=>'wire',
	     array=>$array, comment=>undef,);
    }
    else {
	return $self->error ("Strange signal type: $inout", $inout);
    }
}

sub instant {
    my $self = shift;
    my $submodname = shift;
    my $instname = shift;
    my $hasnamedports = shift;

    print " Cell $instname\n" if $Verilog::Netlist::Debug;
    my $modref = $self->{modref};
    if (!$modref) {
	 return $self->error ("CELL outside of module definition", $instname);
    }
    $self->{cellref} = $modref->new_cell
	 (name=>$instname, 
	  filename=>$self->filename, lineno=>$self->lineno,
	  submodname=>$submodname);
}

sub pin {
    my $self = shift;
    my $pin = shift;
    my $net = shift;
    my $number = shift;
    my $hasnamedports = shift;

    print "   Pin $pin  $net $number \n" if $Verilog::Netlist::Debug;
    my $cellref = $self->{cellref};
    if (!$cellref) {
	return $self->error ("PIN outside of cell definition", $net);
    }
    $cellref->new_pin (name=>$pin,
		       portname=>$pin,
		       portnumber=>$number,
		       filename=>$self->filename, lineno=>$self->lineno,
		       netname=>$net, );
    # If any pin uses call-by-name, then all are assumed to use call-by-name
    $cellref->namedports(1) if $hasnamedports;
}

sub ppdefine {
    my $self = shift;
    my $defvar = shift;
    my $definition = shift;
    if ($self->{netlist}{options}) {
	$self->{netlist}{options}->defvalue($defvar,$definition);
    }
}

sub ppinclude {
    my $self = shift;
    my $defvar = shift;
    my $definition = shift;
    $self->error("No `includes yet.\n");
}

sub error {
    my $self = shift;
    my $text = shift;

    my $fileref = $self->{fileref};
    # Call Verilog::Netlist::Subclass's error reporting, it will track # errors
    my $fileline = $self->filename.":".$self->lineno;
    $fileref->error ($self, "$text\n");
}

package Verilog::Netlist::File;

######################################################################
######################################################################
#### Functions

sub read {
    my %params = (@_);	# filename=>

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::read_file (filename=>) parameter required, stopped";
    my $netlist = $params{netlist} or croak ("Call Verilog::Netlist::read_file instead,");

    my $filepath = $netlist->resolve_filename($filename);
    if (!$filepath) {
	if ($params{error_self}) { $params{error_self}->error("Cannot find $filename\n"); }
	elsif (!defined $params{error_self}) { die "%Error: Cannot find $filename\n"; }  # 0=suppress error
	return undef;
    }
    print __PACKAGE__."::read_file $filepath\n" if $Verilog::Netlist::Debug;

    my $fileref = $netlist->new_file (name=>$filepath,
				      is_libcell=>$params{is_libcell}||0,
				      );

    my $parser = Verilog::Netlist::File::Parser->new
	( fileref=>$fileref,
	  filename=>$filepath,	# for ->read
	  );
    return $fileref;
}

sub _link {
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"File:",$self->name(),"\n";
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Verilog::Netlist::File - File containing Verilog code

=head1 SYNOPSIS

  use Verilog::Netlist;

  my $nl = new Verilog::Netlist;
  my $fileref = $nl->read_file (filename=>'filename');

=head1 DESCRIPTION

Verilog::Netlist::File allows Verilog files to be read and written.

=head1 ACCESSORS

See also Verilog::Netlist::Subclass for additional accessors and methods.

=over 4

=item $self->basename

The filename of the file with any path and . suffix stripped off.

=item $self->name

The filename of the file.

=back

=head1 MEMBER FUNCTIONS

See also Verilog::Netlist::Subclass for additional accessors and methods.

=over 4

=item $self->read

Generally called as $netlist->read_file.  Pass a hash of parameters.  Reads
the filename=> parameter, parsing all instantiations, ports, and signals,
and creating Verilog::Netlist::Module structures.

=item $self->dump

Prints debugging information for this file.

=back

=head1 SEE ALSO

L<Verilog::Netlist::Subclass>
L<Verilog::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
