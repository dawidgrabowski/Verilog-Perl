// $Revision: 1.11 $$Date: 2005-01-25 17:10:49 -0500 (Tue, 25 Jan 2005) $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2005 by Wilson Snyder.

module v_hier_sub (/*AUTOARG*/
   input clk,
   input [3:0] avec,
   output [3:0] qvec
   );

   v_hier_subsub #(
		   .IGNORED('sh20)
		   )
     subsub0 (
	      // Outputs
	      .q		(qvec[0]),
	      // Inputs
	      .a		(1'b1));

   // By pin position
   v_hier_subsub subsub2 (qvec[2], 1'b0);

endmodule
