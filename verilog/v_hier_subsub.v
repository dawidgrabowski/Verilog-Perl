// $Revision: #6 $$Date: 2004/11/10 $$Author: ws150726 $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2004 by Wilson Snyder.

module v_hier_subsub (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   parameter IGNORED;
   input a;
   output q;
   wire   q = a;
endmodule
