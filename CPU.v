`timescale 1ns / 1ns
`include "alu.v"
`include "regfile.v"
`include "branch_unit.v"
`include "instruction_decoder.v"


module CPU(
   switches,
   LEDs,
   stick,
   fpga_clk
   );

   input [7:0] switches;
   output [7:0] LEDs;
   input [3:0] stick;
   input fpga_clk;

   wire f_clk;
   wire clk;
   reg [12:0] program_memory [0:127];
   reg [25:0] counter;

   always @ (posedge f_clk)
         counter <= counter + 1;

   assign f_clk = fpga_clk;
   assign clk = counter[23];

//-----------------------------------
//          State Machine
//-----------------------------------

   parameter IDLE = 3'b000;
   parameter WRITE_LINE_L = 3'b001;
   parameter WRITE_LINE_U = 3'b010;
   parameter WRITE_IDLE = 3'b011;
   parameter INCR_DECR_PC = 3'b100;
   parameter INCR_IDLE = 3'b101;
   parameter RUN_CPU = 3'b110;
   parameter RUN_CPU_IDLE = 3'b111;

   reg [7:0] word_lower_half;
   reg [4:0] word_upper_half;
   reg [6:0] write_pc;
   reg [2:0] state;
   reg rst_pc;

   wire [7:0] reg_3;


   always @ (posedge counter[20])
      case(state)

         IDLE:
            begin
               if (~stick[2] | ~stick[3])
                  state <= INCR_DECR_PC;
               else if (~stick[1])
                  state <= WRITE_LINE_L;
               else if (~stick[0])
                  state <= RUN_CPU;
               else
                  state <= IDLE;

               rst_pc <= 1;
            end

         WRITE_LINE_L:
            begin
               if (stick[1] == 0)
                  state <= WRITE_LINE_L;
               else
                  state <= WRITE_LINE_U;

               word_lower_half <= switches;
            end

         WRITE_LINE_U:
            begin
               if (stick[1] == 0)
                  state <= WRITE_IDLE;
               else
                  state <= WRITE_LINE_U;

               word_upper_half <= switches[4:0];
            end

         WRITE_IDLE:
            begin
               if (stick[1] == 0)
                  state <= WRITE_IDLE;
               else
                  state <= IDLE;

               program_memory[write_pc] <= {word_upper_half, word_lower_half};
            end

         INCR_DECR_PC:
            begin
               if (stick[2] == 0)
                  write_pc <= write_pc - 1;
               else if (stick[3] == 0)
                  write_pc <= write_pc + 1;

               state <= INCR_IDLE;
            end

         INCR_IDLE:
            begin
               if (~stick[2] | ~stick[3])
                  state <= INCR_IDLE;
               else
                  state <= IDLE;
            end

         RUN_CPU:
            begin
               if (~stick[1])
                  state <= RUN_CPU_IDLE;
               else
                  state <= RUN_CPU;
               rst_pc <= 0;
            end

         RUN_CPU_IDLE:
            begin
               if (~stick[1])
                  state <= RUN_CPU_IDLE;
               else
                  state <= IDLE;
            end

      endcase

   assign LEDs = rst_pc ? write_pc : reg_3; //program memory if not running

//-----------------------------------
//          Fetch Stage
//-----------------------------------

   reg [12:0] fetch_latch;

   wire [6:0] pc;
   wire branch_en;
   wire [6:0] branch_addr;
   wire [12:0] instruction;

   branch_unit branch_unit (
    .rst_pc_i(rst_pc),
    .pc_o(pc),
    .branch_en_i(branch_en),
    .branch_addr_i(branch_addr),
    .clk_i(clk)
    );

   assign instruction = program_memory[pc];

   always @ (posedge clk)
      fetch_latch <= instruction;

//-----------------------------------
//          Decode Stage
//-----------------------------------

   reg [22:0] decode_latch;

   wire [12:0] instruction_l;
   wire [2:0] alu_op_a_addr;
   wire [2:0] alu_op_b_addr;
   wire [2:0] alu_opcode;
   wire wr_en_d;
   wire [2:0] wr_addr_d;
   wire branch_d;
   wire [7:0] branch_addr_d;
   wire [7:0] immediate;
   wire immediate_en;

   wire [7:0] op_a;
   wire [7:0] op_b;

   wire flg_gr; //from alu
   wire flg_eq; //from alu

   wire [7:0] rd_a; //from regfile
   wire [7:0] rd_b; //from regfile
   wire [2:0] rd_addr_a; //to regfile
   wire [2:0] rd_addr_b; //to regfile

   assign instruction_l = fetch_latch;

   instruction_decoder instruction_decoder (
    .instruction_i(instruction_l),
    .alu_op_a_addr_o(alu_op_a_addr),
    .alu_op_b_addr_o(alu_op_b_addr),
    .alu_opcode_o(alu_opcode),
    .rd_en_o(rd_en),
    .wr_en_o(wr_en_d),
    .wr_addr_o(wr_addr_d),
    .branch_en_o(branch_d),
    .branch_addr_o(branch_addr_d),
    .immediate_o(immediate),
    .immediate_en_o(immediate_en)
    );

   assign rd_addr_a = alu_op_a_addr; //read a from regfile
   assign rd_addr_b = alu_op_b_addr; //read b from regfile

   //generate branch enable signal for branch unit based on flags from alu
   assign branch_en = branch_d & ((alu_opcode[0] & flg_gr) | (~alu_opcode[0] & flg_eq));
   assign branch_addr = branch_addr_d;

   assign op_a = rd_a | (immediate_en ? immediate : 8'b00000000);
   assign op_b = rd_b;

   always @ (posedge clk)
      decode_latch <= {alu_opcode, op_a, op_b, wr_en_d, wr_addr_d};


//-----------------------------------
//          Execute Stage
//-----------------------------------

   reg [11:0] execute_latch;

   wire [7:0] operand_a;
   wire [7:0] operand_b;
   wire [7:0] result;
   wire [2:0] opcode;
   wire wr_en_e;
   wire [2:0] wr_addr_e;

   assign operand_a = decode_latch[19:12];
   assign operand_b = decode_latch[11:4];
   assign opcode = decode_latch[22:20];
   assign wr_en_e = decode_latch[3];
   assign wr_addr_e = decode_latch[2:0];

   alu alu (
    .operand_a_i(operand_a),
    .operand_b_i(operand_b),
    .result_o(result),
    .opcode_i(opcode),
    .flg_gr_o(flg_gr),
    .flg_eq_o(flg_eq)
    );

   always @ (posedge clk)
      execute_latch <= {result, wr_en_e, wr_addr_e};

//-----------------------------------
//          Writeback Stage
//-----------------------------------

   wire [7:0] wr_data;
   wire [2:0] wr_addr;
   wire wr_en;

   assign wr_data = execute_latch[11:4];
   assign wr_en = execute_latch[3];
   assign wr_addr = execute_latch[2:0];


   regfile regfile (
    .clk_i(clk),
    .wr_data_i(wr_data),
    .rd_addr_a_i(rd_addr_a),
    .rd_addr_b_i(rd_addr_b),
    .wr_addr_i(wr_addr),
    .rd_a_o(rd_a),
    .rd_b_o(rd_b),
    .wr_en_i(wr_en),
    .rd_en_i(rd_en),
    .reg_3_o(reg_3)
    );

   reg [8:0] i;

   initial begin
      for (i=0; i<128; i=1+i)
         begin
            program_memory[i] = 13'b0000000000000;
         end
      fetch_latch = 0;
      decode_latch = 0;
      execute_latch = 0;
      write_pc = 0;
   end

endmodule
