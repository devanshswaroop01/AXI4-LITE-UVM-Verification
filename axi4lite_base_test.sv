`ifndef AXI4LITE_BASE_TEST_SV
`define AXI4LITE_BASE_TEST_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_base_test
// Description: Base test class for the AXI4-Lite UVM verification environment.
//
// Purpose:
//   - Create and configure the verification environment
//   - Retrieve and distribute the virtual interface
//   - Configure agent operating mode
//   - Enable verification infrastructure
//   - Provide common test functionality
//
// Verification Infrastructure Created:
//
//   AXI4LITE_ENV
//        |
//        +-- AXI4LITE_AGENT
//        |      |
//        |      +-- DRIVER
//        |      +-- SEQUENCER
//        |      +-- MONITOR
//        |
//        +-- AXI4LITE_REF_MODEL
//        |
//        +-- AXI4LITE_SCOREBOARD
//        |
//        +-- AXI4LITE_COVERAGE
//
// Derived Tests:
//
//   axi4lite_sanity_test
//   axi4lite_directed_test
//   axi4lite_random_test
//   axi4lite_stress_test
//   axi4lite_boundary_test
//
// Notes:
//
//   - No stimulus generation occurs here.
//   - Derived tests select and execute sequences.
//   - Provides common configuration and reporting.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_base_test extends uvm_test;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_base_test)

   //--------------------------------------------------------------------------
   // Verification Environment
   //
   // Top-level UVM environment containing all verification components.
   //--------------------------------------------------------------------------

   axi4lite_env env;

   //--------------------------------------------------------------------------
   // Environment Configuration
   //
   // Controls:
   //   - Coverage collection
   //   - Scoreboard creation
   //   - Protocol checks
   //   - Agent configuration
   //--------------------------------------------------------------------------

   axi4lite_env_cfg env_cfg;

   //--------------------------------------------------------------------------
   // Virtual Interface
   //
   // Connects UVM components to the DUT interface.
   // Retrieved from TB Top and distributed throughout the verification hierarchy.
   //--------------------------------------------------------------------------

   virtual axi4lite_if vif;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_base_test",
      uvm_component parent = null );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // build_phase()
   //
   // Responsibilities:
   //
   //   1. Retrieve virtual interface
   //   2. Distribute interface to components
   //   3. Create environment configuration
   //   4. Configure verification features
   //   5. Instantiate environment
   //
   //--------------------------------------------------------------------------

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      //-----------------------------------------------------------------------
      // Retrieve Virtual Interface
      //
      // Provided by the testbench top through the UVM configuration database.
      //-----------------------------------------------------------------------

      if (!uvm_config_db #(virtual axi4lite_if)::get(
              this, "", "vif", vif))
        
      begin
         `uvm_fatal(get_type_name(),"Virtual interface not found in config DB")

      end

      //-----------------------------------------------------------------------
      // Distribute Interface
      //
      // Makes the interface visible to:
      //   - Driver
      //   - Monitor
      //   - Future components requiring bus access
      //-----------------------------------------------------------------------

      uvm_config_db #(virtual axi4lite_if)::set(this,"*","vif",vif);

      //-----------------------------------------------------------------------
      // Create Environment Configuration
      //-----------------------------------------------------------------------

      env_cfg =axi4lite_env_cfg::type_id::create("env_cfg");

      //-----------------------------------------------------------------------
      // Default Verification Configuration
      //
      // Coverage: Functional coverage collection enabled.
      //
      // Scoreboard: Expected vs actual checking enabled.
      //
      // Checks: Protocol verification enabled.
      //
      // Agent: Active mode for stimulus generation.
      //-----------------------------------------------------------------------

      env_cfg.coverage_enable   = 1;
      env_cfg.scoreboard_enable = 1;
      env_cfg.checks_enable     = 1;

      env_cfg.agent_cfg.is_active = UVM_ACTIVE;

      //-----------------------------------------------------------------------
      // Pass Configuration To Environment
      //-----------------------------------------------------------------------

      uvm_config_db #(axi4lite_env_cfg)::set(this,"env","cfg",env_cfg);

      //-----------------------------------------------------------------------
      // Create Verification Environment
      //-----------------------------------------------------------------------

      env = axi4lite_env::type_id::create("env",this);

      //-----------------------------------------------------------------------
      // Global Verbosity Setting
      //
      // Provides balanced simulation logging suitable for debugging and regressions.
      //-----------------------------------------------------------------------

      uvm_top.set_report_verbosity_level_hier(UVM_MEDIUM);

      `uvm_info(get_type_name(),"Base Test Build Complete",UVM_LOW)

   endfunction

   //--------------------------------------------------------------------------
   // end_of_elaboration_phase()
   //
   // Prints complete UVM hierarchy after construction.
   //
   // Useful for:
   //   - Component verification
   //   - Configuration debugging
   //   - Architecture reviews
   //--------------------------------------------------------------------------

   function void end_of_elaboration_phase(
      uvm_phase phase);

      super.end_of_elaboration_phase(phase);

      `uvm_info(get_type_name(),"Printing UVM Topology",UVM_LOW)

      uvm_top.print_topology();

   endfunction

   //--------------------------------------------------------------------------
   // run_phase()
   //
   // Base implementation only.
   //
   // Derived tests perform:
   //   - Sequence creation
   //   - Sequence execution
   //   - Objection control
   //
   //--------------------------------------------------------------------------

   task run_phase(uvm_phase phase);

      `uvm_info(get_type_name(),"Base Test Run Phase Started",UVM_LOW)

   endtask

   //--------------------------------------------------------------------------
   // report_phase()
   //
   // Generates final regression summary.
   //
   // Pass Criteria:
   //   No UVM_FATAL messages
   //   No UVM_ERROR messages
   //
   // Provides a consistent pass/fail report across all  derived tests.
   //--------------------------------------------------------------------------

   function void report_phase(uvm_phase phase);

      uvm_report_server svr;

      super.report_phase(phase);

      svr = uvm_report_server::get_server();

      `uvm_info(get_type_name(),"========================================",UVM_NONE)

      `uvm_info(get_type_name(),"           TEST SUMMARY",UVM_NONE)

      `uvm_info(get_type_name(),"========================================",UVM_NONE)

      //-----------------------------------------------------------------------
      // Regression Result Determination
      //-----------------------------------------------------------------------

      if (svr.get_severity_count(UVM_FATAL) +
          svr.get_severity_count(UVM_ERROR) == 0)
      begin

         `uvm_info(get_type_name(),"*** TEST PASSED ***",UVM_NONE)

      end
      else begin

         `uvm_info(get_type_name(),"*** TEST FAILED ***",UVM_NONE)

      end

      `uvm_info(get_type_name(),"========================================",UVM_NONE)

   endfunction

endclass : axi4lite_base_test

`endif
