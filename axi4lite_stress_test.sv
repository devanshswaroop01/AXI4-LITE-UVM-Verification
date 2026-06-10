
`ifndef AXI4LITE_STRESS_TEST_SV
`define AXI4LITE_STRESS_TEST_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_stress_test
// Description:  Comprehensive AXI4-Lite stress and robustness verification test.
//
// Purpose:
//   - Verify DUT operation under sustained traffic
//   - Exercise maximum transaction throughput scenarios
//   - Exercise important corner-case accesses
//   - Execute long-duration randomized traffic
//   - Improve functional coverage closure
//   - Validate verification environment stability
//
// Test Composition:
//
//   1. Back-to-Back Sequence
//        - Continuous traffic generation
//        - Driver/Sequencer stress
//
//   2. Corner Case Sequence
//        - Boundary registers
//        - Special data patterns
//
//   3. Stress Sequence
//        - High-volume random traffic
//        - Coverage closure
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
// Notes:
//
//   - Intended for regression and robustness testing.
//   - Typically executed after sanity, directed,
//     and random verification.
//   - Provides highest confidence level before signoff.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_stress_test extends axi4lite_base_test;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_stress_test)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_stress_test",
      uvm_component parent = null);
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // run_phase()
   //
   // Executes multiple stress-oriented sequences:
   //
   //   1. Back-to-Back Traffic
   //   2. Corner-Case Verification
   //   3. Long Random Stress Traffic
   //
   // Verification Flow:
   //
   //     Back-to-Back Sequence
   //              ↓
   //     Corner Case Sequence
   //              ↓
   //        Stress Sequence
   //              ↓
   //           Driver
   //              ↓
   //             DUT
   //              ↓
   //          Monitor
   //              ↓
   //   -----------------------
   //   |         |           |
   //   ↓         ↓           ↓
   // Coverage RefModel Scoreboard
   //
   // Primary Goal:
   //   Validate DUT and verification environment
   //   stability under demanding operating conditions.
   //--------------------------------------------------------------------------

   task run_phase(uvm_phase phase);

      axi4lite_back_to_back_seq b2b_seq;
      axi4lite_corner_case_seq  corner_seq;
      axi4lite_stress_seq       stress_seq;

      super.run_phase(phase);

      //-----------------------------------------------------------------------
      // Prevent simulation shutdown during stress execution.
      //-----------------------------------------------------------------------

      phase.raise_objection(this,"Starting AXI4-Lite Stress Test");

      `uvm_info(get_type_name(),"========== STRESS TEST STARTED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Phase 1 : Back-to-Back Traffic
      //
      // Generates continuous transactions with no
      // intentional idle cycles.
      //
      // Verifies:
      //   - Driver throughput
      //   - Sequencer throughput
      //   - DUT handling of sustained traffic
      //-----------------------------------------------------------------------

      b2b_seq =axi4lite_back_to_back_seq::type_id::create("back_to_back_seq");

      if (!b2b_seq.randomize())
      begin

         `uvm_fatal(get_type_name(),"Failed to randomize back-to-back sequence")

      end

      b2b_seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Phase 2 : Corner Case Verification
      //
      // Exercises:
      //   - First register
      //   - Last register
      //   - Special data patterns
      //   - Boundary conditions
      //
      // Helps expose corner-case RTL issues.
      //-----------------------------------------------------------------------

      corner_seq =axi4lite_corner_case_seq::type_id::create("corner_case_seq");

      corner_seq.start(env.agent.sqr);
     
      //-----------------------------------------------------------------------
      // Phase 3 : Long Random Stress Traffic
      //
      // Generates large numbers of constrained-random
      // transactions.
      //
      // Primary objectives:
      //   - Coverage closure
      //   - Robustness verification
      //   - Long-duration stability testing
      //-----------------------------------------------------------------------

      stress_seq =axi4lite_stress_seq::type_id::create("stress_seq");

      if (!stress_seq.randomize())
      begin

         `uvm_fatal(get_type_name(),"Failed to randomize stress sequence")

      end

      stress_seq.start(env.agent.sqr);

      //-----------------------------------------------------------------------
      // Stress verification completed successfully.
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"========== STRESS TEST COMPLETED ==========",UVM_LOW)

      //-----------------------------------------------------------------------
      // Allow simulation shutdown.
      //-----------------------------------------------------------------------

      phase.drop_objection(this,"AXI4-Lite Stress Test Complete");

   endtask

endclass : axi4lite_stress_test

`endif
