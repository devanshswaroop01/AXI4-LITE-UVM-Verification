
`ifndef AXI4LITE_ENV_CFG_SV
`define AXI4LITE_ENV_CFG_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_env_cfg
//
// Description: Top-level configuration object for the AXI4-Lite UVM environment.
//
// Purpose:
//   - Centralized environment configuration
//   - Controls optional verification components
//   - Provides agent configuration to the environment
//   - Allows tests to customize environment behavior
//
// Controlled Features:
//   • Agent Configuration
//   • Functional Coverage
//   • Scoreboard
//   • Protocol Checks
//
// Configuration Hierarchy:
//
// AXI4LITE_BASE_TEST
//          │
//          ▼
// AXI4LITE_ENV_CFG
//          │
//          ▼
// AXI4LITE_ENV
//          │
//          ▼
// AXI4LITE_AGENT_CFG
//
// Typical Usage:
//
// env_cfg.coverage_enable   = 1;
// env_cfg.scoreboard_enable = 1;
// env_cfg.checks_enable     = 1;
//
// env_cfg.agent_cfg.is_active = UVM_ACTIVE;
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_env_cfg extends uvm_object;

   //--------------------------------------------------------------------------
   // Factory Registration
   //
   // Enables:
   //   - Factory creation
   //   - Object overrides
   //   - Config object propagation
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_env_cfg)

   //--------------------------------------------------------------------------
   // Agent Configuration
   // Nested configuration object used to control AXI4-Lite agent behavior.
   //
   // Examples:
   //   - Active/Passive mode
   //   - Coverage control
   //   - Protocol checking
   //--------------------------------------------------------------------------

   axi4lite_agent_cfg agent_cfg;

   //--------------------------------------------------------------------------
   // Environment Feature Controls
   //
   // coverage_enable: Enables functional coverage collection.
   //
   // scoreboard_enable: Enables reference-model based checking.
   //
   // checks_enable: Enables protocol/runtime checking features.
   //--------------------------------------------------------------------------

   bit coverage_enable   = 1;

   bit scoreboard_enable = 1;

   bit checks_enable     = 1;

   //--------------------------------------------------------------------------
   // Constructor
   //
   // Creates:
   //   - Environment configuration object
   //   - Nested agent configuration object
   //
   // This guarantees a valid agent_cfg handle
   // before environment construction begins.
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_env_cfg");

      super.new(name);

      //-----------------------------------------------------------------------
      // Create default agent configuration
      //-----------------------------------------------------------------------

      agent_cfg =axi4lite_agent_cfg::type_id::create("agent_cfg" );

   endfunction

   //--------------------------------------------------------------------------
   // do_print()
   //
   // Prints environment configuration settings.
   //
   // Useful for:
   //   - Debugging configuration issues
   //   - Simulation startup reporting
   //   - Regression diagnostics
   //--------------------------------------------------------------------------

   function void do_print(uvm_printer printer);

      super.do_print(printer);

      //-----------------------------------------------------------------------
      // Coverage Control
      //-----------------------------------------------------------------------

      printer.print_field("coverage_enable",coverage_enable,1,UVM_DEC);

      //-----------------------------------------------------------------------
      // Scoreboard Control
      //-----------------------------------------------------------------------

      printer.print_field("scoreboard_enable",scoreboard_enable,1,UVM_DEC);

      //-----------------------------------------------------------------------
      // Protocol Check Control
      //-----------------------------------------------------------------------

      printer.print_field("checks_enable",checks_enable,1,UVM_DEC);

      //-----------------------------------------------------------------------
      // Print Nested Agent Configuration
      //-----------------------------------------------------------------------

      if (agent_cfg != null)

         printer.print_object("agent_cfg",agent_cfg);

   endfunction

endclass : axi4lite_env_cfg

`endif
