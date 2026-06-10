
`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name : axi4lite_assertions
// Description: AXI4-Lite protocol assertion module.
//
// Purpose:
//   - Verify protocol compliance
//   - Detect handshake violations
//   - Detect signal stability violations
//   - Verify response generation
//   - Verify reset behavior
//
// Assertion Categories:
//
//   1. Channel Stability Checks
//        AW Channel
//        W Channel
//        B Channel
//        AR Channel
//        R Channel
//
//   2. Response Ordering Checks
//        Write Response
//        Read Response
//
//   3. Reset Checks
//
// Verification Philosophy:
//
//   Scoreboard  -> Functional Correctness
//   Coverage    -> Verification Completeness
//   Assertions  -> Protocol Correctness
//
// Notes:
//
//   - Assertions are passive checkers.
//   - No stimulus generation.
//   - No DUT modification.
//   - Continuously active throughout simulation.
//
//////////////////////////////////////////////////////////////////////////////////

module axi4lite_assertions (
    axi4lite_if vif);

   //===========================================================================
   // AW CHANNEL STABILITY
   //===========================================================================
   //
   // AXI Rule: 
  //            Once AWVALID is asserted, address/control information must
   //           remain stable until AWREADY completes the handshake.
   //
   // Checks:
   //   AWADDR
   //   AWPROT
   //   AWVALID
   //
   // Detects:
   //   - Address corruption
   //   - Premature address changes
   //   - Invalid master behavior
   //
   //===========================================================================

   property p_awvalid_stable;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.AWVALID && !vif.AWREADY)

      |=> vif.AWVALID &&
          $stable(vif.AWADDR) &&
          $stable(vif.AWPROT);

   endproperty

   a_awvalid_stable :
      assert property(p_awvalid_stable)
      else
         $error("AW channel changed before handshake");

   //===========================================================================
   // W CHANNEL STABILITY
   //===========================================================================
   //
   // AXI Rule: Write data must remain stable while waiting for WREADY.
   //
   // Checks:
   //   WDATA
   //   WSTRB
   //   WVALID
   //
   // Detects:
   //   - Data corruption
   //   - Byte-enable corruption
   //   - Illegal write-data updates
   //
   //===========================================================================

   property p_wvalid_stable;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.WVALID && !vif.WREADY)

      |=> vif.WVALID &&
          $stable(vif.WDATA) &&
          $stable(vif.WSTRB);

   endproperty

   a_wvalid_stable :
      assert property(p_wvalid_stable)
      else
         $error("W channel changed before handshake");

   //===========================================================================
   // B CHANNEL STABILITY
   //===========================================================================
   //
   // AXI Rule: 
   //    Once BVALID is asserted, BRESP must remain stable until
   //    BREADY acknowledges the response.
   //
   // Detects:
   //   - Response corruption
   //   - DUT protocol violations
   //
   //===========================================================================

   property p_bvalid_stable;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.BVALID && !vif.BREADY)

      |=> vif.BVALID &&
          $stable(vif.BRESP);

   endproperty

   a_bvalid_stable :
      assert property(p_bvalid_stable)
      else
         $error("B channel changed before handshake");

   //===========================================================================
   // AR CHANNEL STABILITY
   //===========================================================================
   //
   // AXI Rule:
   // Read address information must remain stable until
   // ARREADY completes the address handshake.
   //
   // Checks:
   //   ARADDR
   //   ARPROT
   //   ARVALID
   //
   //===========================================================================

   property p_arvalid_stable;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.ARVALID && !vif.ARREADY)

      |=> vif.ARVALID &&
          $stable(vif.ARADDR) &&
          $stable(vif.ARPROT);

   endproperty

   a_arvalid_stable :
      assert property(p_arvalid_stable)
      else
         $error("AR channel changed before handshake");

   //===========================================================================
   // R CHANNEL STABILITY
   //===========================================================================
   //
   // AXI Rule:
   // Read data and response must remain stable until accepted by RREADY.
   //
   // Checks:
   //   RDATA
   //   RRESP
   //   RVALID
   //
   //===========================================================================

   property p_rvalid_stable;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.RVALID && !vif.RREADY)

      |=> vif.RVALID &&
          $stable(vif.RDATA) &&
          $stable(vif.RRESP);

   endproperty

   a_rvalid_stable :
      assert property(p_rvalid_stable)
      else
         $error("R channel changed before handshake");

   //===========================================================================
   // WRITE RESPONSE ORDERING
   //===========================================================================
   //
   // AXI Rule:
   // Every completed write transaction must eventually  generate a write response.
   //
   // Handshake Required:
   //
   //   AW Handshake
   //        +
   //   W Handshake
   //
   // Followed by:
   //
   //   BVALID
   //
   // Timing Window:
   //   1 to 10 cycles
   //
   // Detects:
   //   - Missing write responses
   //   - Deadlocked write path
   //
   //===========================================================================

   property p_write_response_order;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.AWVALID && vif.AWREADY &&
       vif.WVALID  && vif.WREADY)

      |-> ##[1:10] vif.BVALID;

   endproperty

   a_write_response_order :
      assert property(p_write_response_order)
      else
         $error("Missing write response");

   //===========================================================================
   // READ RESPONSE ORDERING
   //===========================================================================
   //
   // AXI Rule:
   // Every accepted read request must eventually generate read data.
   //
   // Handshake:
   //
   //   ARVALID && ARREADY
   //
   // Followed by:
   //
   //   RVALID
   //
   // Timing Window:
   //   1 to 10 cycles
   //
   //===========================================================================

   property p_read_response_order;

      @(posedge vif.clk)
      disable iff (!vif.rst_n)

      (vif.ARVALID && vif.ARREADY)

      |-> ##[1:10] vif.RVALID;

   endproperty

   a_read_response_order :
      assert property(p_read_response_order)
      else
         $error("Missing read response");

   //===========================================================================
   // RESET BEHAVIOR
   //===========================================================================
   //
   // AXI Requirement:
   // During reset the DUT must not present outstanding responses.
   //
   // Checks:
   //   BVALID = 0
   //   RVALID = 0
   //
   // Detects:
   //   - Incomplete reset implementation
   //   - Stale response state
   //
   //===========================================================================

   property p_reset_outputs;

      @(posedge vif.clk)

      (!vif.rst_n)

      |=> (!vif.BVALID &&
           !vif.RVALID);

   endproperty

   a_reset_outputs :
      assert property(p_reset_outputs)
      else
         $error("Outputs not reset correctly");

endmodule 
