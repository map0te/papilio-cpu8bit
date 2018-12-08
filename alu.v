`timescale 1ns / 1ns

module alu(
	operand_a_i,
	operand_b_i,
	result_o,
	opcode_i,
	alu_en_i
	);

	input [7:0] operand_a_i;
	input [7:0] operand_b_i;
	output [7:0] result_o;
	input [2:0] opcode_i;
	input alu_en_i;
	
	reg [7:0] output_r;
	
	always @ (opcode_i, operand_a_i, operand_b_i)
		begin
			if (alu_en_i)
				case (opcode_i)
					3'b000 : output_r = operand_a_i & operand_b_i;
					3'b001 : output_r = ~(operand_a_i & operand_b_i);
					3'b010 : output_r = operand_a_i | operand_b_i;
					3'b011 : output_r = ~(operand_a_i | operand_b_i);
					3'b100 : output_r = operand_a_i ^ operand_b_i;
					3'b101 : output_r = ~(operand_a_i ^ operand_b_i);
					3'b110 : output_r = operand_a_i + operand_b_i;
					3'b111 : output_r = operand_a_i + ~operand_b_i + 1'b1;
				endcase
		end

	assign result_o = output_r;
	
endmodule
