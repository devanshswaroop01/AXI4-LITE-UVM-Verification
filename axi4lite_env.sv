
`ifndef AXI4LITE_ENV_SV
`define AXI4LITE_ENV_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_env
// Description: Top-level AXI4-Lite UVM Environment.
//
// Purpose:
//   - Instantiate verification components
//   - Distribute configuration objects
//   - Connect analysis/TLM infrastructure
//   - Assemble the complete verification architecture
//
// Environment Architecture:
//
//                 AXI4LITE_ENV
//                       |
//      ------------------------------------------------
//      |               |              |              |
//      v               v              v              v
//   AGENT         SCOREBOARD      REF_MODEL      COVERAGE
//
// Transaction Flow:
//
// Sequences
//     |
//     v
// Sequencer
//     |
//     v
// Driver
//     |
//     v
// DUT
//     |
//     v
// Monitor
//     |
//     +----------------------------+
//     |                            |
//     v                            v
// Reference Model             Coverage
//     |
//     v
// Scoreboard
//
// Notes:
//   - Supports feature enable/disable through env_cfg
//   - Uses TLM analysis connections
//   - Single AXI4-Lite Agent architecture
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_env extends uvm_env;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_env)

   //--------------------------------------------------------------------------
   // Environment Configuration
   //
   // Controls:
   //   - Agent configuration
   //   - Coverage enable
   //   - Scoreboard enable
   //   - Protocol checking enable
   //--------------------------------------------------------------------------

   axi4lite_env_cfg cfg;

   //--------------------------------------------------------------------------
   // Verification Components
   //
   // agent : Generates and monitors AXI traffic.
   //
   // scb : Compares expected vs actual transactions.
   //
   // cov : Collects functional coverage.
   //
   // refm : Predicts expected DUT behavior.
   //--------------------------------------------------------------------------

   axi4lite_agent      agent;
   axi4lite_scoreboard scb;
   axi4lite_coverage   cov;
   axi4lite_ref_model  refm;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_env",
      uvm_component parent = null );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // Build Phase
   //
   // Responsibilities:
   //   - Retrieve environment configuration
   //   - Pass configuration to child components
   //   - Create verification components
   //   - Honor feature enable controls
   //--------------------------------------------------------------------------

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      //-----------------------------------------------------------------------
      // Retrieve Environment Configuration
      //-----------------------------------------------------------------------

      if (!uvm_config_db #(axi4lite_env_cfg)::get(
              this,"","cfg",cfg))
        
      begin
         `uvm_fatal(get_type_name(),"Failed to get axi4lite_env_cfg")

      end

      //-----------------------------------------------------------------------
      // Pass Agent Configuration
      //
      // Makes cfg.agent_cfg available to AXI agent.
      //-----------------------------------------------------------------------

     uvm_config_db #(axi4lite_agent_cfg)::set( this,"agent","cfg",cfg.agent_cfg);

      //-----------------------------------------------------------------------
      // Create AXI Agent
      //
      // Always required.
      //-----------------------------------------------------------------------

      agent =axi4lite_agent::type_id::create("agent",this);

      //-----------------------------------------------------------------------
      // Create Scoreboard and Reference Model
      //
      // Only instantiated when scoreboard checking
      // is enabled.
      //-----------------------------------------------------------------------

      if (cfg.scoreboard_enable) begin

         scb =axi4lite_scoreboard::type_id::create("scb",this);

         refm = axi4lite_ref_model::type_id::create("refm",this);

      end

      //-----------------------------------------------------------------------
      // Create Coverage Collector
      //
      // Optional functional coverage collection.
      //-----------------------------------------------------------------------

      if (cfg.coverage_enable) begin

         cov = axi4lite_coverage::type_id::create("cov",this);

      end

      `uvm_info(get_type_name(),"Environment Build Completed",UVM_LOW)

   endfunction

   //--------------------------------------------------------------------------
   // Connect Phase
   //
   // Establishes TLM connectivity between verification components.
   //
   // Connection Summary:
   //
   // Monitor -> Scoreboard (Actual)
   // Monitor -> Reference Model
   // Ref Model -> Scoreboard (Expected)
   // Monitor -> Coverage
   //--------------------------------------------------------------------------

   function void connect_phase(uvm_phase phase);

      super.connect_phase(phase);

      //-----------------------------------------------------------------------
      // Scoreboard Infrastructure
      //-----------------------------------------------------------------------

      if (cfg.scoreboard_enable) begin

         //--------------------------------------------------------------------
         // Actual Transaction Path
         //
         // Monitor
         //    ↓
         // Scoreboard Actual FIFO
         //--------------------------------------------------------------------

         agent.item_collected_port.connect(scb.actual_fifo.analysis_export);

         //--------------------------------------------------------------------
         // Prediction Path
         //
         // Monitor
         //    ↓
         // Reference Model
         //--------------------------------------------------------------------

        agent.item_collected_port.connect( refm.item_collected_export);

         //--------------------------------------------------------------------
         // Expected Transaction Path
         //
         // Reference Model
         //       ↓
         // Scoreboard Expected FIFO
         //--------------------------------------------------------------------

         refm.expected_port.connect(scb.expected_fifo.analysis_export);

      end

      //-----------------------------------------------------------------------
      // Coverage Collection Path
      //
      // Monitor
      //    ↓
      // Coverage Collector
      //-----------------------------------------------------------------------

      if (cfg.coverage_enable) begin

         agent.item_collected_port.connect(cov.analysis_export);

      end

      `uvm_info(get_type_name(),"Environment Connections Established",UVM_LOW)

   endfunction

   //--------------------------------------------------------------------------
   // End Of Elaboration Phase
   //
   // Prints complete UVM hierarchy.
   //
   // Useful for:
   //   - Debugging component creation
   //   - Verifying environment structure
   //   - Design reviews
   //--------------------------------------------------------------------------

   function void end_of_elaboration_phase(uvm_phase phase);

      super.end_of_elaboration_phase(phase);

      uvm_top.print_topology();

   endfunction

endclass : axi4lite_env

`endif 
