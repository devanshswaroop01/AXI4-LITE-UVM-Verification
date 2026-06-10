
`include "axi4lite_seq_lib.sv"

`ifndef AXI4LITE_DIRECTED_TEST_SV
`define AXI4LITE_DIRECTED_TEST_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_directed_test
// Description:Deterministic AXI4-Lite register verification test.
//
// Purpose:
//   - Verify accessibility of all 32 DUT registers
//   - Verify deterministic write/read behavior
//   - Validate DUT register storage functionality
//   - Validate reference model predictions
//   - Validate scoreboard comparisons
//   - Provide stable and repeatable regression results
//
// Verification Strategy:
//
//      Register 0  -> WRITE -> READ
//      Register 1  -> WRITE -> READ
//      Register 2  -> WRITE -> READ
//      ...
//      Register 31 -> WRITE -> READ
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
//   - Uses deterministic register accesses.
//   - Easier to debug than random traffic.
//   - Ideal for functional bring-up.
//   - Often executed before random testing.
//   - Provides stable regression behavior.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_directed_test extends axi4lite_base_test;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_directed_test)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_directed_test",
      uvm_component parent = null  );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // run_phase()
   //
   // Executes axi4lite_directed_seq.
   //
   // The directed sequence performs:
   //
   //   1. WRITE to all 32 DUT registers
   //   2. READ back all 32 DUT registers
   //   3. Trigger reference model prediction
   //   4. Trigger scoreboard comparison
   //
   // Verification Flow:
   //
   //      Directed Sequence
   //             ↓
   //         Sequencer
   //             ↓
   //          Driver
   //             ↓
   //            DUT
   //             ↓
   //          Monitor
   //             ↓
   //   ----------------------
   //   |         |          |
   //   ↓         ↓          ↓
   // Coverage RefModel Scoreboard
   //
   // Primary Goal:
   //   Verify complete DUT register-map functionality
   //   using deterministic transactions.
   //--------------------------------------------------------------------------

   task run_phase(uvm_phase phase);

      axi4lite_directed_seq seq;

      super.run_phase(phase);

      //-----------------------------------------------------------------------
      // Prevent simulation termination while stimulus is executing.
      //-----------------------------------------------------------------------

      phase.raise_objection(this,"Starting AXI4-Lite Directed Test");

      `uvm_info(get_type_name(),"========== DIRECTED TEST STARTED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Create directed sequence.
      //
      // Sequence performs a complete register sweep across
      // the DUT address space.
      //-----------------------------------------------------------------------

      seq =axi4lite_directed_seq::type_id::create("directed_seq");

      //-----------------------------------------------------------------------
      // Randomize sequence-level controls.
      //
      // Although register accesses are deterministic,
      // randomization is retained for future extensibility.
      //-----------------------------------------------------------------------

      if (!seq.randomize())
      begin

         `uvm_fatal(get_type_name(),"Failed to randomize directed sequence")

      end

      //-----------------------------------------------------------------------
      // Execute sequence on AXI4-Lite agent sequencer.
      //-----------------------------------------------------------------------

      seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Directed register verification completed.
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"========== DIRECTED TEST COMPLETED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Release objection and allow simulation shutdown.
      //-----------------------------------------------------------------------

      phase.drop_objection(this,"AXI4-Lite Directed Test Complete");

   endtask

endclass : axi4lite_directed_test

`endif 
