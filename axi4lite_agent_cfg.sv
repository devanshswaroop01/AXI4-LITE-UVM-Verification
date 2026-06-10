`ifndef AXI4LITE_AGENT_CFG_SV
`define AXI4LITE_AGENT_CFG_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_agent_cfg
// Description: Configuration object for the AXI4-Lite Agent.
//
// Purpose:
// - Controls how the AXI4-Lite agent is built.
// - Allows tests to customize agent behavior.
// - Passed through UVM Config DB during environment construction.
//
// Supported Controls:
//   • Active / Passive Agent Mode
//   • Coverage Collection Enable
//   • Protocol Check Enable
//
// Typical Usage:
//
//   cfg.agent_cfg.is_active       = UVM_ACTIVE;
//   cfg.agent_cfg.coverage_enable = 1;
//   cfg.agent_cfg.checks_enable   = 1;
//
// Used By:
//   - AXI4-Lite Agent
//   - Environment Configuration
//   - Test Classes
//
// Suitable for reusable UVM environments.
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_agent_cfg extends uvm_object;

   //--------------------------------------------------------------------------
   // Factory Registration
   //
   // Enables:
   // - Factory overrides
   // - Configuration object creation through factory
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_agent_cfg)

   //--------------------------------------------------------------------------
   // Agent Mode Configuration
   //
   // UVM_ACTIVE
   //    - Driver created
   //    - Sequencer created
   //    - Monitor created
   //    - Generates DUT stimulus
   //
   // UVM_PASSIVE
   //    - Only monitor created
   //    - Observes DUT traffic
   //    - Useful for system-level verification
   //--------------------------------------------------------------------------

   uvm_active_passive_enum is_active = UVM_ACTIVE;

   //--------------------------------------------------------------------------
   // Feature Control Flags
   //
   // coverage_enable: Enables functional coverage collection.
   //
   // checks_enable: Enables protocol and consistency checks.
   //--------------------------------------------------------------------------

   bit coverage_enable = 1;

   bit checks_enable   = 1;

   //--------------------------------------------------------------------------
   // Constructor
   //
   // Creates a new agent configuration object.
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_agent_cfg");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // do_print()
   //
   // Provides formatted configuration information when:
   //   - print()
   //   - sprint()
   //   - topology reports
   //
   // Useful for debugging configuration issues.
   //--------------------------------------------------------------------------

   function void do_print(uvm_printer printer);

      super.do_print(printer);

      //-----------------------------------------------------------------------
      // Agent Mode
      //-----------------------------------------------------------------------

     printer.print_string ( "is_active", (is_active == UVM_ACTIVE) ? "UVM_ACTIVE" :"UVM_PASSIVE");

      //-----------------------------------------------------------------------
      // Coverage Enable
      //-----------------------------------------------------------------------

     printer.print_field( "coverage_enable", coverage_enable, 1, UVM_DEC);

      //-----------------------------------------------------------------------
      // Checks Enable
      //-----------------------------------------------------------------------

     printer.print_field("checks_enable", checks_enable,1 ,UVM_DEC );

   endfunction

endclass : axi4lite_agent_cfg

`endif 
