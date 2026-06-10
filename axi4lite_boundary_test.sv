
`ifndef AXI4LITE_BOUNDARY_TEST_SV
`define AXI4LITE_BOUNDARY_TEST_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_boundary_test
// Description: AXI4-Lite register boundary verification test.
//
// Purpose:
//   - Verify first register accessibility
//   - Verify last register accessibility
//   - Verify address decoder boundaries
//   - Verify readback correctness at address limits
//   - Verify important boundary data patterns
//
// Address Boundaries Tested:
//
//   First Register: Address = 0x00000000
//
//   Last Register: Address = 0x0000007C
//
// Data Patterns Tested:
//
//   0x00000000 All zeros
//
//   0xFFFFFFFF All ones
//
//   0xAAAAAAAA Alternating bit pattern
//
//   0x55555555 Complement alternating pattern
//
// Verification Objectives:
//
//   • Address Decode Validation
//   • Register Boundary Validation
//   • Readback Verification
//   • Scoreboard Validation
//   • Reference Model Validation
//
// Environment Components Exercised:
//
//   • Sequencer
//   • Driver
//   • AXI4-Lite Interface
//   • DUT Register File
//   • Monitor
//   • Coverage Collector
//   • Reference Model
//   • Scoreboard
//
// Notes:
//
//   - Fully deterministic test.
//   - Fast execution time.
//   - Excellent debug visibility.
//   - Common regression test for address-map verification.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_boundary_test extends axi4lite_base_test;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_boundary_test)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_boundary_test",
      uvm_component parent = null   );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // run_phase()
   //
   // Executes a series of WRITE→READ verification sequences
   // targeting register-map boundaries.
   //
   // Each access performs:
   //
   //      WRITE(addr,data)
   //              ↓
   //      READ(addr)
   //              ↓
   //      Reference Model Prediction
   //              ↓
   //      Scoreboard Comparison
   //
   // Primary Goal:
   //   Verify correct DUT behavior at the lowest and highest
   //   valid addresses in the register map.
   //--------------------------------------------------------------------------

   task run_phase(uvm_phase phase);

      axi4lite_write_read_seq seq;

      super.run_phase(phase);

      //-----------------------------------------------------------------------
      // Prevent simulation shutdown during boundary verification.
      //-----------------------------------------------------------------------

     phase.raise_objection( this, "Starting AXI4-Lite Boundary Test");

      `uvm_info(get_type_name(),"========== BOUNDARY TEST STARTED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Boundary Case 1
      //
      // First register with all-zero pattern.
      //
      // Verifies:
      //   - Lowest valid address
      //   - Zero-value storage
      //-----------------------------------------------------------------------

      seq = axi4lite_write_read_seq::type_id::create("first_reg_zero");

      seq.addr = 32'h0000_0000;
      seq.data = 32'h0000_0000;

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Boundary Case 2
      //
      // First register with all-one pattern.
      //-----------------------------------------------------------------------

      seq = axi4lite_write_read_seq::type_id::create("first_reg_ones");

      seq.addr = 32'h0000_0000;
      seq.data = 32'hFFFF_FFFF;

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Boundary Case 3
      //
      // Last register with all-zero pattern.
      //
      // Verifies:
      //   - Highest valid address
      //   - Address decoder upper boundary
      //-----------------------------------------------------------------------

      seq = axi4lite_write_read_seq::type_id::create("last_reg_zero");

      seq.addr = 32'h0000_007C;
      seq.data = 32'h0000_0000;

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Boundary Case 4
      //
      // Last register with all-one pattern.
      //-----------------------------------------------------------------------

      seq = axi4lite_write_read_seq::type_id::create("last_reg_ones");

      seq.addr = 32'h0000_007C;
      seq.data = 32'hFFFF_FFFF;

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Boundary Case 5
      //
      // Alternating pattern at lowest address.
      //
      // Useful for exposing bit-level storage issues.
      //-----------------------------------------------------------------------

      seq = axi4lite_write_read_seq::type_id::create("alt_pattern_a");

      seq.addr = 32'h0000_0000;
      seq.data = 32'hAAAA_AAAA;

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Boundary Case 6
      //
      // Complement alternating pattern at highest address.
      //-----------------------------------------------------------------------

      seq = axi4lite_write_read_seq::type_id::create("alt_pattern_b");

      seq.addr = 32'h0000_007C;
      seq.data = 32'h5555_5555;

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Boundary verification completed.
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"========== BOUNDARY TEST COMPLETED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Allow simulation shutdown.
      //-----------------------------------------------------------------------

      phase.drop_objection(this,"AXI4-Lite Boundary Test Complete");

   endtask

endclass : axi4lite_boundary_test

`endif 
