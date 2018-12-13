`timescale 1ns / 1ns

//alu
//responsible for all math/logic functions
//outputs "greater than" and "equal to" flags based on carry out and zero flags


module alu(
	operand_a_i,
	operand_b_i,
	result_o,
	opcode_i,
	flg_gr_o,
	flg_eq_o
	);

	input [7:0] operand_a_i;
	input [7:0] operand_b_i;
	output [7:0] result_o;
	input [2:0] opcode_i;
	output flg_gr_o;
	output flg_eq_o;
	
	reg [7:0] output_r;
	reg [8:0] sub_result;
	
	always @ (opcode_i, operand_a_i, operand_b_i)
		begin
			case (opcode_i)
				3'b000 : output_r = operand_a_i & operand_b_i;
				3'b001 : output_r = ~(operand_a_i & operand_b_i);
				3'b010 : output_r = operand_a_i | operand_b_i;
				3'b011 : output_r = ~(operand_a_i | operand_b_i);
				3'b100 : output_r = operand_a_i ^ operand_b_i;
				3'b101 : output_r = ~(operand_a_i ^ operand_b_i);
				3'b110 : output_r = operand_a_i + operand_b_i;
				3'b111 : 
					begin
						sub_result = {1'b0, operand_a_i} + {1'b0, ~operand_b_i} + 1'b1;
						output_r = sub_result[7:0];
					end
			endcase
		end
		
	assign result_o = output_r;
	assign flg_gr_o = sub_result[8] & (output_r != 8'b00000000);
	assign flg_eq_o = sub_result[8] & (output_r == 8'b00000000);
	
	initial begin
		output_r = 0;
		sub_result = 0;
	end
	
endmodule
