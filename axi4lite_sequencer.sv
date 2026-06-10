`ifndef AXI4LITE_SEQUENCER_SV
`define AXI4LITE_SEQUENCER_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_sequencer
// Description: AXI4-Lite UVM Sequencer.
//
// The sequencer acts as the transaction arbitration layer between
// sequences and the driver.
//
// Responsibilities:
//   - Receives transaction requests from sequences
//   - Arbitrates multiple sequence requests (if present)
//   - Provides transactions to the driver
//
// Transaction Flow:
//
// Sequence
//     ↓
// AXI4LITE_SEQUENCER
//     ↓
// AXI4LITE_DRIVER
//
// Notes:
//   - No protocol-specific logic implemented
//   - Uses standard UVM sequencer arbitration
//   - Suitable for single-agent AXI4-Lite environments
//   - Easily extendable for virtual sequence support
//
// Architecture Position:
//
// AXI4LITE_AGENT
// ├── AXI4LITE_SEQUENCER
// ├── AXI4LITE_DRIVER
// └── AXI4LITE_MONITOR
//
// Typical Sequences:
//
//   • axi4lite_write_read_seq
//   • axi4lite_directed_seq
//   • axi4lite_random_seq
//   • axi4lite_stress_seq
//   • axi4lite_corner_case_seq
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_sequencer extends uvm_sequencer #(axi4lite_txn);

   //--------------------------------------------------------------------------
   // Factory Registration
   //
   // Enables:
   //   - Factory-based creation
   //   - Component overrides
   //   - UVM topology visibility
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_sequencer)

   //--------------------------------------------------------------------------
   // Constructor
   //
   // Creates the AXI4-Lite sequencer instance.
   //
   // No additional resources are required because:
   //   - Standard UVM arbitration is sufficient
   //   - No custom sequence control is needed
   //   - Single sequencer architecture is used
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_sequencer",
      uvm_component parent = null );
      super.new(name, parent);
   endfunction

endclass : axi4lite_sequencer

`endif 
