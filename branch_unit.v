`timescale 1ns / 1ps

//branch unit
//pc is either pc+1 or branch address (if branch enable is on)
//updated every positive edge of the clock

module branch_unit(
   rst_pc_i,
   pc_o,
   branch_en_i,
   branch_addr_i,
   clk_i
    );

   input rst_pc_i;
   output [6:0] pc_o;
   input branch_en_i;
   input [6:0] branch_addr_i;
   input clk_i;

   reg [7:0] pc;

   always @ (posedge clk_i)
      begin
         if (~rst_pc_i)
            pc = branch_en_i ? branch_addr_i : (pc + 1'b1);
         else
            pc = 8'b00000000;
      end

   assign pc_o = pc;

   initial
      pc = 0;


endmodule
