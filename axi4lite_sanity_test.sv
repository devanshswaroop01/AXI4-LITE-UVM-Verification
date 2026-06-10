
`ifndef AXI4LITE_SANITY_TEST_SV
`define AXI4LITE_SANITY_TEST_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_sanity_test
// Description: Basic smoke test for the AXI4-Lite verification environment.
//
// Purpose:
//   - Verify basic AXI4-Lite write/read functionality
//   - Verify end-to-end transaction flow
//   - Validate environment connectivity
//   - Validate reference model operation
//   - Validate scoreboard operation
//   - Provide quick regression confidence
//
// Verification Strategy:
//
//   Repeat:
//
//      WRITE(addr,data)
//             |
//             v
//      READ(addr)
//             |
//             v
//      Scoreboard Check
//
// using the axi4lite_write_read_seq sequence.
//
// Environment Components Verified:
//
//   • Sequencer
//   • Driver
//   • AXI4-Lite Interface
//   • DUT
//   • Monitor
//   • Coverage Collector
//   • Reference Model
//   • Scoreboard
//
// Notes:
//
//   - Intended as the first test executed during bring-up.
//   - Short runtime.
//   - High debug visibility.
//   - Suitable for smoke regressions.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_sanity_test extends axi4lite_base_test;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_sanity_test)

   //--------------------------------------------------------------------------
   // Test Configuration
   //
   // Number of WRITE→READ verification iterations.
   //
   // Each iteration executes a complete write-read sequence
   // and exercises the entire verification data path.
   //--------------------------------------------------------------------------

   localparam int NUM_ITERATIONS = 10;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_sanity_test",
      uvm_component parent = null  );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // run_phase()
   //
   // Executes multiple WRITE→READ transactions using
   // axi4lite_write_read_seq.
   //
   // Verification Flow:
   //
   //      Sequence
   //          ↓
   //      Sequencer
   //          ↓
   //       Driver
   //          ↓
   //    AXI4-Lite Bus
   //          ↓
   //         DUT
   //          ↓
   //      Monitor
   //          ↓
   //   -------------------
   //   |        |        |
   //   ↓        ↓        ↓
   // Coverage RefModel Scoreboard
   //
   // Primary Goal:
   //   Ensure the complete verification architecture is
   //   functioning correctly before running larger regressions.
   //--------------------------------------------------------------------------

   task run_phase(uvm_phase phase);

      axi4lite_write_read_seq seq;

      super.run_phase(phase);

      //-----------------------------------------------------------------------
      // Prevent simulation from ending while test stimulus executes.
      //-----------------------------------------------------------------------

      phase.raise_objection(this,"Starting AXI4-Lite Sanity Test");

      `uvm_info(get_type_name(),"========== SANITY TEST STARTED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Execute multiple WRITE→READ verification sequences.
      //
      // Each sequence:
      //   1. Writes randomized data
      //   2. Reads same address
      //   3. Triggers scoreboard validation
      //   4. Exercises reference model prediction
      //-----------------------------------------------------------------------

      repeat (NUM_ITERATIONS) begin

         //--------------------------------------------------------------------
         // Create sequence instance
         //--------------------------------------------------------------------

        seq =axi4lite_write_read_seq::type_id::create( 
                $sformatf("sanity_seq_%0d",$time));

         //--------------------------------------------------------------------
         // Randomize sequence parameters
         //--------------------------------------------------------------------

         if (!seq.randomize())
         begin

            `uvm_fatal(get_type_name(),"Failed to randomize sanity sequence")

         end

         //--------------------------------------------------------------------
         // Execute sequence on AXI4-Lite agent sequencer
         //--------------------------------------------------------------------

         seq.start(env.agent.sqr);

      end

      //-----------------------------------------------------------------------
      // Test completed successfully.
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"========== SANITY TEST COMPLETED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Release objection and allow simulation shutdown.
      //-----------------------------------------------------------------------

      phase.drop_objection(this,"AXI4-Lite Sanity Test Complete");

   endtask

endclass : axi4lite_sanity_test

`endif
