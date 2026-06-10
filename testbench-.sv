`include "axi4lite_if.sv"
`include "axi4lite_pkg.sv"
`include "axi4lite_assertions.sv"

`timescale 1ns/1ps

import uvm_pkg::*;
import axi4lite_pkg::*;

`include "uvm_macros.svh"

//////////////////////////////////////////////////////////////////////////////////
// Module : axi4lite_tb_top
//
// Description: Top-level integration module for the AXI4-Lite UVM verification environment.
//
// Responsibilities:
//   - Generate clock and reset
//   - Instantiate AXI4-Lite interface
//   - Instantiate DUT
//   - Instantiate protocol assertions
//   - Configure UVM environment
//   - Launch selected test
//   - Enable waveform dumping
//   - Provide simulation timeout protection
//
// Architecture:
//
//            +-------------------+
//            |   UVM TEST        |
//            +---------+---------+
//                      |
//                      v
//                AXI Interface
//                      |
//          +-----------+-----------+
//          |                       |
//          v                       v
//     Assertions                DUT
//
// Notes:
//   - Single DUT instance
//   - Single AXI4-Lite interface
//   - Protocol assertions connected directly to bus signals
//   - Test selected using run_test()
//
//////////////////////////////////////////////////////////////////////////////////

module axi4lite_tb_top;

   //--------------------------------------------------------------------------
   // Clock and Reset Signals
   //--------------------------------------------------------------------------

   logic clk;
   logic rst_n;

   //--------------------------------------------------------------------------
   // Clock Generation
   //
   // Generates a free-running 100 MHz clock.
   // Clock Period = 10 ns
   //--------------------------------------------------------------------------

   initial begin

      clk = 1'b0;
      forever #5ns clk = ~clk;

   end

   //--------------------------------------------------------------------------
   // Reset Generation
   //
   // Holds DUT in reset for 5 clock cycles before starting normal operation.
   //--------------------------------------------------------------------------

   initial begin

      rst_n = 1'b0;

      repeat (5)
         @(posedge clk);

      rst_n = 1'b1;

      `uvm_info("TB_TOP","Reset Deasserted",UVM_LOW)

   end

   //--------------------------------------------------------------------------
   // AXI4-Lite Interface
   //
   // Shared by:
   //   - Driver
   //   - Monitor
   //   - Assertions
   //   - DUT
   //--------------------------------------------------------------------------

   axi4lite_if vif (
      .clk   (clk),
      .rst_n (rst_n) );

   //--------------------------------------------------------------------------
   // Protocol Assertions
   //
   // Continuously monitor AXI4-Lite protocol compliance.
   //--------------------------------------------------------------------------

   axi4lite_assertions assertions_inst (
      .vif(vif) );

   //--------------------------------------------------------------------------
   // DUT Instance
   //
   // AXI4-Lite Slave RTL under verification.
   //--------------------------------------------------------------------------

   axi4_lite_slave #(

      .ADDRESS    (32),
      .DATA_WIDTH (32)

   ) dut (

      .ACLK       (clk),
      .ARESETN    (rst_n),

      //-------------------------------------------------------
      // Write Address Channel
      //-------------------------------------------------------

      .S_AWADDR   (vif.AWADDR),
      .S_AWVALID  (vif.AWVALID),
      .S_AWREADY  (vif.AWREADY),

      //-------------------------------------------------------
      // Write Data Channel
      //-------------------------------------------------------

      .S_WDATA    (vif.WDATA),
      .S_WSTRB    (vif.WSTRB),
      .S_WVALID   (vif.WVALID),
      .S_WREADY   (vif.WREADY),

      //-------------------------------------------------------
      // Write Response Channel
      //-------------------------------------------------------

      .S_BRESP    (vif.BRESP),
      .S_BVALID   (vif.BVALID),
      .S_BREADY   (vif.BREADY),

      //-------------------------------------------------------
      // Read Address Channel
      //-------------------------------------------------------

      .S_ARADDR   (vif.ARADDR),
      .S_ARVALID  (vif.ARVALID),
      .S_ARREADY  (vif.ARREADY),

      //-------------------------------------------------------
      // Read Data Channel
      //-------------------------------------------------------

      .S_RDATA    (vif.RDATA),
      .S_RRESP    (vif.RRESP),
      .S_RVALID   (vif.RVALID),
      .S_RREADY   (vif.RREADY) );

   //--------------------------------------------------------------------------
   // Optional Waveform Dumping
   //
   // Enable using:
   //
   //   +DUMP_VCD
   //   +DUMP_FST
   //
   //--------------------------------------------------------------------------

   initial begin

      if ($test$plusargs("DUMP_VCD")) begin

         $dumpfile("axi4lite_tb.vcd");
         $dumpvars(0, axi4lite_tb_top);

         `uvm_info("TB_TOP","VCD Dump Enabled",UVM_LOW)

      end

      if ($test$plusargs("DUMP_FST")) begin

         $dumpfile("axi4lite_tb.fst");
         $dumpvars(0, axi4lite_tb_top);

         `uvm_info("TB_TOP","FST Dump Enabled",UVM_LOW)

      end

   end

   //--------------------------------------------------------------------------
   // UVM Configuration and Test Launch
   //
   // Responsibilities:
   //   - Pass virtual interface
   //   - Configure verbosity
   //   - Launch selected test
   //--------------------------------------------------------------------------

   initial begin

      //-------------------------------------------------------
      // Make virtual interface visible throughout UVM hierarchy
      //-------------------------------------------------------

      uvm_config_db #(virtual axi4lite_if)::set(
         null,"*","vif",vif);

      //-------------------------------------------------------
      // Default reporting verbosity
      //-------------------------------------------------------

     uvm_top.set_report_verbosity_level_hier( UVM_MEDIUM  );

      //-------------------------------------------------------
      // Start selected test
      //-------------------------------------------------------

      `uvm_info("TB_TOP","Starting AXI4-Lite UVM Testbench",UVM_LOW)

       // run_test("axi4lite_base_test");
         run_test("axi4lite_sanity_test");
       // run_test("axi4lite_random_test");
       // run_test("axi4lite_directed_test");
       // run_test("axi4lite_stress_test");
       // run_test("axi4lite_boundary_test");

   end

   //--------------------------------------------------------------------------
   // Simulation Timeout Watchdog
   //
   // Prevents infinite simulation hangs caused by:
   //   - Protocol deadlocks
   //   - Missing objection drops
   //   - Driver/monitor lockups
   //--------------------------------------------------------------------------

   initial begin

      #10ms;

      `uvm_fatal("TB_TOP","Simulation Timeout")

   end

   //--------------------------------------------------------------------------
   // Default Waveform Dump
   //
   // Always enabled for quick debug.
   // Can be removed if plusarg-controlled dumping is preferred.
   //--------------------------------------------------------------------------

   initial begin

      $dumpfile("waveform.vcd");
      $dumpvars(0, axi4lite_tb_top);

   end

   //--------------------------------------------------------------------------
   // Simulation Completion Message
   //--------------------------------------------------------------------------

   final begin

      `uvm_info("TB_TOP","Simulation Finished",UVM_LOW)

   end

endmodule : axi4lite_tb_top 
