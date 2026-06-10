
`ifndef AXI4LITE_AGENT_SV
`define AXI4LITE_AGENT_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_agent
// Description:  AXI4-Lite UVM Agent.
//
// The agent encapsulates all protocol-specific components required to
// generate and monitor AXI4-Lite transactions.
//
// Components:
//   - Sequencer
//   - Driver
//   - Monitor
//
// Supported Modes:
//
// UVM_ACTIVE
//   - Driver created
//   - Sequencer created
//   - Monitor created
//   - Generates DUT stimulus
//
// UVM_PASSIVE
//   - Monitor only
//   - Observes DUT traffic
//   - Useful for subsystem/system-level verification
//
// Transaction Flow:
//
// Sequence
//    ↓
// Sequencer
//    ↓
// Driver
//    ↓
// DUT
//
// Monitor
//    ↓
// Agent Analysis Port
//    ↓
// Environment Components
//    - Scoreboard
//    - Coverage
//    - Reference Model
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_agent extends uvm_agent;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_agent)

   //--------------------------------------------------------------------------
   // Agent Components
   //
   // sqr : Arbitrates sequence items
   // drv : Converts transactions into AXI signal activity
   // mon : Observes DUT bus transactions
   //--------------------------------------------------------------------------

   axi4lite_sequencer  sqr;
   axi4lite_driver     drv;
   axi4lite_monitor    mon;

   //--------------------------------------------------------------------------
   // Configuration Object
   //
   // Controls:
   //   - Active/Passive mode
   //   - Coverage enable
   //   - Protocol checks
   //--------------------------------------------------------------------------

   axi4lite_agent_cfg cfg;

   //--------------------------------------------------------------------------
   // Analysis Port
   //
   // Broadcasts monitored transactions to higher-level environment components such as:
   //   - Scoreboard
   //   - Coverage Collector
   //   - Reference Model
   //--------------------------------------------------------------------------

   uvm_analysis_port #(axi4lite_txn) item_collected_port;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_agent",
      uvm_component parent = null
   );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // Build Phase
   //
   // Responsibilities:
   //   - Retrieve configuration object
   //   - Create analysis port
   //   - Always create monitor
   //   - Create driver/sequencer if agent is ACTIVE
   //--------------------------------------------------------------------------

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      //-----------------------------------------------------------------------
      // Retrieve agent configuration
      //-----------------------------------------------------------------------

      if (!uvm_config_db #(axi4lite_agent_cfg)::get(
              this,"","cfg", cfg))
        
      begin
         `uvm_fatal(get_type_name(),"Failed to get axi4lite_agent_cfg")

      end

      //-----------------------------------------------------------------------
      // Create analysis port
      //-----------------------------------------------------------------------

      item_collected_port =new("item_collected_port", this);

      //-----------------------------------------------------------------------
      // Monitor is always required
      //
      // Even passive agents must observe DUT activity.
      //-----------------------------------------------------------------------

      mon = axi4lite_monitor::type_id::create("mon",this);

      //-----------------------------------------------------------------------
      // Active Agent Components
      //
      // Driver and Sequencer are only required when generating transactions.
      //-----------------------------------------------------------------------

      if (cfg.is_active == UVM_ACTIVE) begin

        sqr = axi4lite_sequencer::type_id::create( "sqr",this);

         drv = axi4lite_driver::type_id::create("drv",this);

      end

      //-----------------------------------------------------------------------
      // Report selected agent mode
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),
                $sformatf("Agent Mode = %s", (cfg.is_active == UVM_ACTIVE) ?
                          "ACTIVE" :"PASSIVE" ), UVM_MEDIUM)

   endfunction

   //--------------------------------------------------------------------------
   // Connect Phase
   //
   // Responsibilities:
   //
   // ACTIVE MODE: Driver <-> Sequencer connection
   //
   // ALL MODES: Monitor -> Agent Analysis Port
   //--------------------------------------------------------------------------

   function void connect_phase(uvm_phase phase);

      super.connect_phase(phase);

      //-----------------------------------------------------------------------
      // Driver receives sequence items from sequencer
      //-----------------------------------------------------------------------

      if (cfg.is_active == UVM_ACTIVE) begin

        drv.seq_item_port.connect( sqr.seq_item_export );

      end

      //-----------------------------------------------------------------------
      // Forward monitored transactions to environment
      //-----------------------------------------------------------------------

     mon.item_collected_port.connect( item_collected_port );

   endfunction

   //--------------------------------------------------------------------------
   // Report Phase
   //
   // End-of-simulation reporting hook.
   //--------------------------------------------------------------------------

   function void report_phase(uvm_phase phase);

      super.report_phase(phase);

     `uvm_info( get_type_name(),
         "AXI4-Lite Agent Report Phase Complete",UVM_HIGH)

   endfunction

endclass : axi4lite_agent

`endif
