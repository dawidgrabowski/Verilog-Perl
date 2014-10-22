// $Id: v_hier_sub.v 4373 2005-08-03 15:33:48Z wsnyder $
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


   generate
      genvar 	K;
      for (K=0; K<1; K=K+1) begin : genloop
	 // By pin position, inside generate
	 v_hier_subsub subsub2 (qvec[2], 1'b0);
      end
   endgenerate

endmodule
