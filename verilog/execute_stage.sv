import constants::*;
import wires::*;

module execute_stage
(
  input logic reset,
  input logic clock,
  input alu_out_type alu0_out,
  output alu_in_type alu0_in,
  input alu_out_type alu1_out,
  output alu_in_type alu1_in,
  input agu_out_type agu_out,
  output agu_in_type agu_in,
  input bcu_out_type bcu_out,
  output bcu_in_type bcu_in,
  input csr_alu_out_type csr_alu_out,
  output csr_alu_in_type csr_alu_in,
  input div_out_type div_out,
  output div_in_type div_in,
  input mul_out_type mul_out,
  output mul_in_type mul_in,
  input bit_alu_out_type bit_alu_out,
  output bit_alu_in_type bit_alu_in,
  input bit_clmul_out_type bit_clmul_out,
  output bit_clmul_in_type bit_clmul_in,
  input fp_execute_out_type fp_execute_out,
  output fp_execute_in_type fp_execute_in,
  input register_out_type register0_out,
  input register_out_type register1_out,
  input fp_register_out_type fp_register_out,
  input forwarding_out_type forwarding0_out,
  input forwarding_out_type forwarding1_out,
  output forwarding_register_in_type forwarding0_rin,
  output forwarding_register_in_type forwarding1_rin,
  input fp_forwarding_out_type fp_forwarding_out,
  output fp_forwarding_register_in_type fp_forwarding_rin,
  input csr_out_type csr_out,
  input btac_out_type btac_out,
  input execute_in_type a,
  input execute_in_type d,
  output execute_out_type y,
  output execute_out_type q
);
  timeunit 1ns;
  timeprecision 1ps;

  execute_reg_type r,rin;
  execute_reg_type v;

  always_comb begin

    v = r;

    v.instr0 = d.d.instr0;
    v.instr1 = d.d.instr1;
  
    v.taken = d.d.taken;
    v.taddr = d.d.taddr;
    v.tpc = d.d.tpc;

    forwarding0_rin.rden1 = v.instr0.op.rden1;
    forwarding0_rin.rden2 = v.instr0.op.rden2;
    forwarding0_rin.raddr1 = v.instr0.raddr1;
    forwarding0_rin.raddr2 = v.instr0.raddr2;
    forwarding0_rin.rdata1 = register0_out.rdata1;
    forwarding0_rin.rdata2 = register0_out.rdata2;

    v.instr0.rdata1 = forwarding0_out.data1;
    v.instr0.rdata2 = forwarding0_out.data2;

    forwarding1_rin.rden1 = v.instr1.op.rden1;
    forwarding1_rin.rden2 = v.instr1.op.rden2;
    forwarding1_rin.raddr1 = v.instr1.raddr1;
    forwarding1_rin.raddr2 = v.instr1.raddr2;
    forwarding1_rin.rdata1 = register1_out.rdata1;
    forwarding1_rin.rdata2 = register1_out.rdata2;

    v.instr1.rdata1 = forwarding1_out.data1;
    v.instr1.rdata2 = forwarding1_out.data2;

    fp_forwarding_rin.rden1 = v.instr0.op.frden1;
    fp_forwarding_rin.rden2 = v.instr0.op.frden2;
    fp_forwarding_rin.rden3 = v.instr0.op.frden3;
    fp_forwarding_rin.raddr1 = v.instr0.raddr1;
    fp_forwarding_rin.raddr2 = v.instr0.raddr2;
    fp_forwarding_rin.raddr3 = v.instr0.raddr3;
    fp_forwarding_rin.rdata1 = fp_register_out.rdata1;
    fp_forwarding_rin.rdata2 = fp_register_out.rdata2;
    fp_forwarding_rin.rdata3 = fp_register_out.rdata3;

    v.instr0.frdata1 = fp_forwarding_out.data1;
    v.instr0.frdata2 = fp_forwarding_out.data2;
    v.instr0.frdata3 = fp_forwarding_out.data3;

    if ((v.instr0.op.fpu & v.instr0.op.rden1) == 1) begin
      v.instr0.frdata1 = v.instr0.rdata1;
    end

    if ((d.e.stall | d.m.stall) == 1) begin
      v = r;
      v.instr0.op = r.instr0.op_b;
      v.instr1.op = r.instr1.op_b;
    end

    v.stall = 0;

    v.clear = d.e.instr0.op.exception | d.e.instr0.op.mret | csr_out.trap | csr_out.mret | btac_out.pred_miss | btac_out.pred_rest | d.w.clear;

    v.enable = ~(d.e.stall | a.m.stall | v.clear);

    alu0_in.rdata1 = v.instr0.rdata1;
    alu0_in.rdata2 = v.instr0.rdata2;
    alu0_in.imm = v.instr0.imm;
    alu0_in.sel = v.instr0.op.rden2;
    alu0_in.alu_op = v.instr0.alu_op;

    v.instr0.wdata = alu0_out.result;

    alu1_in.rdata1 = v.instr1.rdata1;
    alu1_in.rdata2 = v.instr1.rdata2;
    alu1_in.imm = v.instr1.imm;
    alu1_in.sel = v.instr1.op.rden2;
    alu1_in.alu_op = v.instr1.alu_op;

    v.instr1.wdata = alu1_out.result;

    bcu_in.rdata1 = v.instr0.rdata1;
    bcu_in.rdata2 = v.instr0.rdata2;
    bcu_in.enable = v.instr0.op.branch;
    bcu_in.bcu_op = v.instr0.bcu_op;

    v.instr0.op.jump = v.instr0.op.jal | v.instr0.op.jalr | bcu_out.branch;

    agu_in.rdata1 = v.instr0.rdata1;
    agu_in.imm = v.instr0.imm;
    agu_in.pc = v.instr0.pc;
    agu_in.auipc = v.instr0.op.auipc;
    agu_in.jal = v.instr0.op.jal;
    agu_in.jalr = v.instr0.op.jalr;
    agu_in.branch = v.instr0.op.branch;
    agu_in.load = v.instr0.op.load | v.instr0.op.fload;
    agu_in.store = v.instr0.op.store | v.instr0.op.fstore;
    agu_in.lsu_op = v.instr0.lsu_op;

    v.instr0.address = agu_out.address;
    v.instr0.byteenable = agu_out.byteenable;

    if (v.instr0.op.exception == 0) begin
      v.instr0.op.exception = agu_out.exception;
      v.instr0.ecause = agu_out.ecause;
      v.instr0.etval = agu_out.etval;
      if (v.instr0.op.exception == 1) begin
        if ((v.instr0.op.load | v.instr0.op.fload) == 1) begin
          v.instr0.op.load = 0;
          v.instr0.op.fload = 0;
          v.instr0.op.wren = 0;
        end else if ((v.instr0.op.store | v.instr0.op.fstore) == 1) begin
          v.instr0.op.store = 0;
          v.instr0.op.fstore = 0;
        end else if (v.instr0.op.jump == 1) begin
          v.instr0.op.jump = 0;
          v.instr0.op.wren = 0;
        end
      end
    end

    v.instr0.sdata = (v.instr0.op.fstore == 1) ? v.instr0.frdata2 : v.instr0.rdata2;

    mul_in.rdata1 = v.instr0.rdata1;
    mul_in.rdata2 = v.instr0.rdata2;
    mul_in.mul_op = v.instr0.mul_op;

    v.instr0.mdata = mul_out.result;

    bit_alu_in.rdata1 = v.instr0.rdata1;
    bit_alu_in.rdata2 = v.instr0.rdata2;
    bit_alu_in.imm = v.instr0.imm;
    bit_alu_in.sel = v.instr0.op.rden2;
    bit_alu_in.bit_op = v.instr0.bit_op;

    v.instr0.bdata = bit_alu_out.result;

    div_in.rdata1 = v.instr0.rdata1;
    div_in.rdata2 = v.instr0.rdata2;
    div_in.enable = v.instr0.op.division & v.enable;
    div_in.div_op = v.instr0.div_op;

    v.instr0.ddata = div_out.result;
    v.instr0.dready = div_out.ready;

    bit_clmul_in.rdata1 = v.instr0.rdata1;
    bit_clmul_in.rdata2 = v.instr0.rdata2;
    bit_clmul_in.enable = v.instr0.op.bitc & v.enable;
    bit_clmul_in.op = v.instr0.bit_op.bit_zbc;

    v.instr0.bcdata = bit_clmul_out.result;
    v.instr0.bcready = bit_clmul_out.ready;

    fp_execute_in.data1 = v.instr0.frdata1;
    fp_execute_in.data2 = v.instr0.frdata2;
    fp_execute_in.data3 = v.instr0.frdata3;
    fp_execute_in.fpu_op = v.instr0.fpu_op;
    fp_execute_in.fmt = v.instr0.fmt;
    fp_execute_in.rm = v.instr0.rm;
    fp_execute_in.enable = v.instr0.op.fpu & v.enable;

    v.instr0.fdata = fp_execute_out.result;
    v.instr0.flags = fp_execute_out.flags;
    v.instr0.fready = fp_execute_out.ready;

    if (v.instr0.op.auipc == 1) begin
      v.instr0.wdata = v.instr0.address;
    end else if (v.instr0.op.lui == 1) begin
      v.instr0.wdata = v.instr0.imm;
    end else if (v.instr0.op.jal == 1) begin
      v.instr0.wdata = v.instr0.npc;
    end else if (v.instr0.op.jalr == 1) begin
      v.instr0.wdata = v.instr0.npc;
    end else if (v.instr0.op.crden == 1) begin
      v.instr0.wdata = v.instr0.cdata;
    end else if (v.instr0.op.division == 1) begin
      v.instr0.wdata = v.instr0.ddata;
    end else if (v.instr0.op.mult == 1) begin
      v.instr0.wdata = v.instr0.mdata;
    end else if (v.instr0.op.bitm == 1) begin
        v.instr0.wdata = v.instr0.bdata;
    end else if (v.instr0.op.bitc == 1) begin
        v.instr0.wdata = v.instr0.bcdata;
    end else if (v.instr0.op.fpu == 1) begin
        v.instr0.wdata = v.instr0.fdata;
    end

    csr_alu_in.cdata = v.instr0.cdata;
    csr_alu_in.rdata1 = v.instr0.rdata1;
    csr_alu_in.imm = v.instr0.imm;
    csr_alu_in.sel = v.instr0.op.rden1;
    csr_alu_in.csr_op = v.instr0.csr_op;

    v.instr0.cdata = csr_alu_out.cdata;

    if (v.instr0.op.division == 1) begin
      if (v.instr0.dready == 0) begin
        v.stall = ~(a.m.stall);
      end
    end else if (v.instr0.op.bitc == 1) begin
      if (v.instr0.bcready == 0) begin
        v.stall = ~(a.m.stall);
      end
    end else if (v.instr0.op.fpuc == 1) begin
      if (v.instr0.fready == 0) begin
        v.stall = ~(a.m.stall);
      end
    end
    
    v.instr0.op.valid = ~v.instr0.op.nop;
    v.instr1.op.valid = ~v.instr1.op.nop;

    v.instr0.op_b = v.instr0.op;
    v.instr1.op_b = v.instr1.op;

    if ((v.stall | a.m.stall | v.clear) == 1) begin
      v.instr0.op = init_operation_complex;
      v.instr1.op = init_operation_basic;
    end

    if (v.clear == 1) begin
      v.stall = 0;
    end

    if ((v.instr0.op.fence | v.instr0.op.exception | v.instr0.op.mret | v.instr0.op.jump) == 1) begin
      v.instr1.op = init_operation_basic;
    end

    rin = v;

    y.instr0 = v.instr0;
    y.instr1 = v.instr1;
    y.taken = v.taken;
    y.taddr = v.taddr;
    y.tpc = v.tpc;
    y.stall = v.stall;

    q.instr0 = r.instr0;
    q.instr1 = r.instr1;
    q.taken = r.taken;
    q.taddr = r.taddr;
    q.tpc = r.tpc;
    q.stall = r.stall;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_execute_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
