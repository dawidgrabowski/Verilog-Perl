// $Id: v_hier_subsub.v 11992 2006-01-16 18:59:58Z wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2006 by Wilson Snyder.

module v_hier_subsub (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   parameter IGNORED;
   input  signed a;
   output q;
   wire   q = a;
endmodule
