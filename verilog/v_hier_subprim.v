// $Id: v_hier_subprim.v 11992 2006-01-16 18:59:58Z wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2006 by Wilson Snyder.

// surefire lint_off UDPUNS

primitive v_hier_prim (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   output q;
   input a;

   table
      0 : 1;
      1 : 0;
   endtable

endprimitive
