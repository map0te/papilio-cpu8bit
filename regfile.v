`timescale 1ns / 1ps

//register file
//1 write port
//2 read ports
//write occurs in the middle of the cycle (negative edge triggered) because 
//the postive edge triggers the stage latches 

module regfile(
	clk_i,
	wr_data_i,
	rd_addr_a_i,
	rd_addr_b_i,
	wr_addr_i,
	rd_a_o,
	rd_b_o,
	wr_en_i,
	rd_en_i
    );
	 
	 input clk_i;
	 input [7:0] wr_data_i;
	 input [2:0] rd_addr_a_i;
	 input [2:0] rd_addr_b_i;
	 input [2:0] wr_addr_i;
	 output [7:0] rd_a_o;
	 output [7:0] rd_b_o;
	 input wr_en_i;
	 input rd_en_i;
	 
	 reg [7:0] register_1;
	 reg [7:0] register_2;
	 reg [7:0] register_3;
	 reg [7:0] register_4;
	 reg [7:0] register_5;
	 reg [7:0] register_6;
	 reg [7:0] register_7;
	 

	 always @ (negedge clk_i)
		begin
			if (wr_en_i)
				case (wr_addr_i)
					3'b000 : ;
					3'b001 : register_1 <= wr_data_i;
					3'b010 : register_2 <= wr_data_i;
					3'b011 : register_3 <= wr_data_i;
					3'b100 : register_4 <= wr_data_i;
					3'b101 : register_5 <= wr_data_i;
					3'b110 : register_6 <= wr_data_i;
					3'b111 : register_7 <= wr_data_i;
				endcase
		end
		
	assign rd_a_o = ~rd_en_i ? 8'b00000000 :
						(rd_addr_a_i == 3'b001) ? register_1 :
						(rd_addr_a_i == 3'b010) ? register_2 :
						(rd_addr_a_i == 3'b011) ? register_3 :
						(rd_addr_a_i == 3'b100) ? register_4 :
						(rd_addr_a_i == 3'b101) ? register_5 :
						(rd_addr_a_i == 3'b110) ? register_6 :
						(rd_addr_a_i == 3'b111) ? register_7 :
						8'b00000000;

	assign rd_b_o = ~rd_en_i ? 8'b00000000 :
						(rd_addr_b_i == 3'b001) ? register_1 :
						(rd_addr_b_i == 3'b010) ? register_2 :
						(rd_addr_b_i == 3'b011) ? register_3 :
						(rd_addr_b_i == 3'b100) ? register_4 :
						(rd_addr_b_i == 3'b101) ? register_5 :
						(rd_addr_b_i == 3'b110) ? register_6 :
						(rd_addr_b_i == 3'b111) ? register_7 :
						8'b00000000;
						
	initial begin
		register_1 = 8'b00000000;
		register_2 = 8'b00000000;
		register_3 = 8'b00000000;
		register_4 = 8'b00000000;
		register_5 = 8'b00000000;
		register_6 = 8'b00000000;
		register_7 = 8'b00000000;
	end
						
endmodule
