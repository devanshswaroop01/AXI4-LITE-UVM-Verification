
`ifndef AXI4LITE_RANDOM_TEST_SV
`define AXI4LITE_RANDOM_TEST_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_random_test
// Description: Constrained-random AXI4-Lite verification test.
//
// Purpose:
//   - Generate randomized AXI4-Lite traffic
//   - Exercise diverse protocol scenarios
//   - Improve functional coverage
//   - Validate reference model predictions
//   - Validate scoreboard comparisons
//   - Support coverage-driven verification
//
// Verification Strategy:
//
//   Multiple Random Sequences
//              |
//              v
//      Random Transactions
//              |
//              v
//             DUT
//              |
//              v
//      Coverage Collection
//
// Environment Components Exercised:
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
// Randomized Transaction Fields:
//
//   - Transaction Type (READ / WRITE)
//   - Address
//   - Data
//   - WSTRB
//   - PROT
//   - Delay Cycles
//
// Notes:
//
//   - Primary coverage-generation test.
//   - Complements directed testing.
//   - Typically executed after sanity testing.
//   - Supports coverage closure activities.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_random_test extends axi4lite_base_test;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_random_test)

   //--------------------------------------------------------------------------
   // Test Configuration
   //
   // Number of independent random sequences executed.
   //
   // Each sequence generates its own randomized set of AXI4-Lite transactions.
   //--------------------------------------------------------------------------

   localparam int NUM_RANDOM_RUNS = 5;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_random_test",
      uvm_component parent = null );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // run_phase()
   //
   // Executes multiple randomized AXI4-Lite sequences.
   //
   // Each sequence generates constrained-random traffic
   // according to axi4lite_txn constraints.
   //
   // Verification Flow:
   //
   //      Random Sequence
   //             ↓
   //         Sequencer
   //             ↓
   //          Driver
   //             ↓
   //            DUT
   //             ↓
   //         Monitor
   //             ↓
   //   ----------------------
   //   |         |          |
   //   ↓         ↓          ↓
   // Coverage RefModel Scoreboard
   //
   // Primary Goal:
   //   Explore the AXI4-Lite transaction space and
   //   accumulate functional coverage.
   //--------------------------------------------------------------------------

   task run_phase(uvm_phase phase);

      axi4lite_random_seq seq;

      super.run_phase(phase);

      //-----------------------------------------------------------------------
      // Prevent simulation termination during stimulus execution.
      //-----------------------------------------------------------------------

      phase.raise_objection(this,"Starting AXI4-Lite Random Test");

      `uvm_info(get_type_name(),"========== RANDOM TEST STARTED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Execute multiple randomized sequences.
      //
      // Each sequence generates:
      //   - Random READ transactions
      //   - Random WRITE transactions
      //   - Random addresses
      //   - Random data values
      //   - Random WSTRB patterns
      //   - Random delays
      //-----------------------------------------------------------------------

      for (int i = 0; i < NUM_RANDOM_RUNS; i++) begin

         //--------------------------------------------------------------------
         // Create sequence instance
         //--------------------------------------------------------------------

         seq =axi4lite_random_seq::type_id::create($sformatf("random_seq_%0d", i));

         //--------------------------------------------------------------------
         // Randomize sequence-level controls
         //--------------------------------------------------------------------

         if (!seq.randomize())
         begin

           `uvm_fatal(get_type_name(), $sformatf("Failed to randomize random sequence %0d",i))

         end

         //--------------------------------------------------------------------
         // Execute sequence on AXI4-Lite sequencer
         //--------------------------------------------------------------------

         seq.start(env.agent.sqr);

      end

      //-----------------------------------------------------------------------
      // Random traffic generation completed.
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"========== RANDOM TEST COMPLETED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Allow simulation shutdown.
      //-----------------------------------------------------------------------

      phase.drop_objection(this,"AXI4-Lite Random Test Complete");

   endtask

endclass : axi4lite_random_test

`endif
