// $Id: v_hier_top.v 29806 2007-01-10 13:04:28Z wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2007 by Wilson Snyder.

`define hsub v_hier_sub

module v_hier_top (/*AUTOARG*/
   // Inputs
   clk
   );
   input clk;	/* pragma jsc_clk */
   `hsub sub (/*AUTOINST*/
	      // Outputs
	      .qvec			(qvec[3:0]),
	      // Inputs
	      .clk			(1'b0),
	      .avec			({avec[3],avec[2:0]}));

   missing missing ();

endmodule

// Local Variables:
// eval:(verilog-read-defines)
// End:
