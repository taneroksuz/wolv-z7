import configure::*;

module axi
(
  input  logic rst,
  input  logic clk,
  /////////////////////////////////
  input  logic [0  : 0] axi_valid,
  input  logic [0  : 0] axi_instr,
  input  logic [31 : 0] axi_addr,
  input  logic [31 : 0] axi_wdata,
  input  logic [3  : 0] axi_wstrb,
  output logic [31 : 0] axi_rdata,
  output logic [0  : 0] axi_ready,
  /////////////////////////////////
  // Write address channel
  output logic [31 : 0] m_axi_awaddr,
  output logic [7  : 0] m_axi_awlen,
  output logic [2  : 0] m_axi_awsize,
  output logic [1  : 0] m_axi_awburst,
  output logic [0  : 0] m_axi_awlock,
  output logic [3  : 0] m_axi_awcache,
  output logic [2  : 0] m_axi_awprot,
  output logic [3  : 0] m_axi_awqos,
  output logic [0  : 0] m_axi_awvalid,
  input  logic [0  : 0] m_axi_awready,
  /////////////////////////////////
  // Write data channel
  output logic [31 : 0] m_axi_wdata,
  output logic [3  : 0] m_axi_wstrb,
  output logic [0  : 0] m_axi_wlast,
  output logic [0  : 0] m_axi_wvalid,
  input  logic [0  : 0] m_axi_wready,
  /////////////////////////////////
  // Write response channel
  input  logic [1  : 0] m_axi_bresp,
  input  logic [0  : 0] m_axi_bvalid,
  output logic [0  : 0] m_axi_bready,
  /////////////////////////////////
  // Read address channel
  output logic [31 : 0] m_axi_araddr,
  output logic [7  : 0] m_axi_arlen,
  output logic [2  : 0] m_axi_arsize,
  output logic [1  : 0] m_axi_arburst,
  output logic [0  : 0] m_axi_arlock,
  output logic [3  : 0] m_axi_arcache,
  output logic [2  : 0] m_axi_arprot,
  output logic [3  : 0] m_axi_arqos,
  output logic [0  : 0] m_axi_arvalid,
  input  logic [0  : 0] m_axi_arready,
  /////////////////////////////////
  // Read data channel
  input  logic [31 : 0] m_axi_rdata,
  input  logic [1  : 0] m_axi_rresp,
  input  logic [0  : 0] m_axi_rlast,
  input  logic [0  : 0] m_axi_rvalid,
  output logic [0  : 0] m_axi_rready
  /////////////////////////////////
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam [2:0] idle = 0;
  localparam [2:0] read = 1;
  localparam [2:0] readresponse = 2;
  localparam [2:0] write = 3;
  localparam [2:0] writeresponse = 4;

  logic [2 :0] state;
  logic [2 :0] state_n;

  logic [0 :0] awvalid;
  logic [0 :0] awvalid_n;
  logic [0 :0] wvalid;
  logic [0 :0] wvalid_n;
  logic [0 :0] bready;
  logic [0 :0] bready_n;
  logic [0 :0] arvalid;
  logic [0 :0] arvalid_n;
  logic [0 :0] rready;
  logic [0 :0] rready_n;
  logic [31:0] addr;
  logic [31:0] addr_n;
  logic [2 :0] prot;
  logic [2 :0] prot_n;
  logic [31:0] wdata;
  logic [31:0] wdata_n;
  logic [3 :0] wstrb;
  logic [3 :0] wstrb_n;

  logic [31:0] rdata;
  logic [0 :0] ready;

  always_comb begin
    state = state_n;
    awvalid = 0;
    wvalid = 0;
    bready = 0;
    arvalid = 0;
    rready = 0;
    addr = 0;
    prot = 0;
    wdata = 0;
    wstrb = 0;
    rdata = 0;
    ready = 0;
    case (state_n)
      idle : begin
        if (axi_valid == 1) begin
          state = (|axi_wstrb) == 1 ? write : read;
          awvalid = ~|axi_wstrb;
          wvalid = ~|axi_wstrb;
          bready = ~|axi_wstrb;
          arvalid = ~(|axi_wstrb);
          rready = ~(|axi_wstrb);
          addr = axi_addr;
          prot = {axi_instr,2'b00};
          wdata = axi_wdata;
          wstrb = axi_wstrb;
        end
      end
      read : begin
        arvalid = arvalid_n;
        rready = rready_n;
        addr = addr_n;
        prot = prot_n;
        if (m_axi_awready == 1) begin
          state = readresponse;
          arvalid = 0;
        end
      end
      readresponse : begin
        rready = rready_n;
        if (m_axi_rvalid == 1 && m_axi_rlast == 1 && m_axi_rresp == 0) begin
          state = idle;
          rready = 0;
          rdata = m_axi_rdata;
          ready = 1;
        end
      end
      write : begin
        awvalid = awvalid_n;
        wvalid = wvalid_n;
        bready = bready_n;
        addr = addr_n;
        prot = prot_n;
        wdata = wdata_n;
        wstrb = wstrb_n;
        if (m_axi_awready == 1 && m_axi_wready == 1) begin
          state = writeresponse;
          awvalid = 0;
          wvalid = 0;
        end
      end
      writeresponse : begin
        bready = bready_n;
        if (m_axi_bvalid == 1 && m_axi_bresp == 0) begin
          state = idle;
          bready = 0;
          ready = 1;
        end
      end
    endcase
  end

  assign m_axi_awaddr = addr;
  assign m_axi_awlen = 8'b00000000;
  assign m_axi_awsize = 3'b010; // 4 Byte
  assign m_axi_awburst = 2'b00;
  assign m_axi_awlock = 1'b0;
  assign m_axi_awcache = 4'b0000;
  assign m_axi_awprot = prot;
  assign m_axi_awqos = 4'b0000;
  assign m_axi_awvalid = awvalid;

  assign m_axi_wdata = wdata;
  assign m_axi_wstrb = wstrb;
  assign m_axi_wlast = 1'b1;
  assign m_axi_wvalid = wvalid;

  assign m_axi_bready = bready;

  assign m_axi_araddr = addr;
  assign m_axi_arlen = 8'b00000000;
  assign m_axi_arsize = 3'b010; // 4 Byte
  assign m_axi_arburst = 2'b00;
  assign m_axi_arlock = 1'b0;
  assign m_axi_arcache = 4'b0000;
  assign m_axi_arprot = prot;
  assign m_axi_arqos = 4'b0000;
  assign m_axi_arvalid = arvalid;

  assign m_axi_rready = rready;

  assign axi_rdata = rdata;
  assign axi_ready = ready;

  always_ff @(posedge clk) begin

    if (rst == 0) begin
      state_n <= 0;
      awvalid_n <= 0;
      wvalid_n <= 0;
      bready_n <= 0;
      arvalid_n <= 0;
      rready_n <= 0;
      addr_n <= 0;
      prot_n <= 0;
      wdata_n <= 0;
      wstrb_n <= 0;
    end else begin
      state_n <= state;
      awvalid_n <= awvalid;
      wvalid_n <= wvalid;
      bready_n <= bready;
      arvalid_n <= arvalid;
      rready_n <= rready;
      addr_n <= addr;
      prot_n <= prot;
      wdata_n <= wdata;
      wstrb_n <= wstrb;
    end

  end

endmodule
