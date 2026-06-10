
`ifndef AXI4LITE_REF_MODEL_SV
`define AXI4LITE_REF_MODEL_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_ref_model
// Description:  AXI4-Lite Reference Model (Predictor)
//
// Purpose:
//   - Models expected DUT behavior
//   - Maintains a mirror copy of DUT registers
//   - Predicts expected read data
//   - Applies write updates using WSTRB semantics
//   - Generates expected transactions for scoreboard checking
//
// Architecture:
//
// Monitor
//    |
//    v
// Reference Model
//    |
//    v
// Expected Transaction Stream
//    |
//    v
// Scoreboard
//
// DUT Register Map:
//
// Register 0   -> 0x00
// Register 1   -> 0x04
// ...
// Register 31  -> 0x7C
//
// Notes:
//   - Models 32 x 32-bit registers
//   - Supports byte-enable writes (WSTRB)
//   - Generates expected transactions only
//   - Does not directly compare results
//
//////////////////////////////////////////////////////////////////////////////////

`uvm_analysis_imp_decl(_ref)

class axi4lite_ref_model extends uvm_component;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_ref_model)

   //--------------------------------------------------------------------------
   // Analysis Interfaces
   //
   // item_collected_export:  Receives observed transactions from monitor.
   //
   // expected_port: Sends predicted transactions to scoreboard.
   //--------------------------------------------------------------------------

  uvm_analysis_imp_ref #( axi4lite_txn, axi4lite_ref_model ) item_collected_export;

  uvm_analysis_port #(axi4lite_txn) expected_port;

   //--------------------------------------------------------------------------
   // Internal Register Model
   //
   // Mirror representation of DUT register bank.
   //
   // Memory Size:
   //   32 Registers
   //   32 Bits/Register
   //--------------------------------------------------------------------------

   bit [31:0] mem [0:31];

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_ref_model",
      uvm_component parent = null   );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // Build Phase
   //
   // Creates analysis interfaces and initializes internal memory model.
   //--------------------------------------------------------------------------

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      //-----------------------------------------------------------------------
      // Input analysis implementation
      //-----------------------------------------------------------------------

      item_collected_export = new("item_collected_export", this);

      //-----------------------------------------------------------------------
      // Output prediction port
      //-----------------------------------------------------------------------

      expected_port = new("expected_port", this);

      //-----------------------------------------------------------------------
      // Initialize mirrored memory
      //-----------------------------------------------------------------------

      reset_model();

   endfunction

   //--------------------------------------------------------------------------
   // reset_model()
   //
   // Resets the mirrored register bank to its power-on state.
   //
   // Current DUT reset behavior:
   // All registers reset to zero.
   //--------------------------------------------------------------------------

   function void reset_model();

      foreach(mem[i])
         mem[i] = '0;

   endfunction

   //--------------------------------------------------------------------------
   // write_ref()
   //
   // Main prediction function.
   //
   // Called automatically whenever the monitor publishes a completed transaction.
   //
   // Responsibilities:
   //   - Update mirrored memory for writes
   //   - Predict read return values
   //   - Generate expected transactions
   //--------------------------------------------------------------------------

   function void write_ref(axi4lite_txn txn);

      axi4lite_txn exp_txn;
      int reg_idx;

      //-----------------------------------------------------------------------
      // Create expected transaction object
      //-----------------------------------------------------------------------

      exp_txn =axi4lite_txn::type_id:: create("exp_txn");

      //-----------------------------------------------------------------------
      // Copy common transaction fields
      //-----------------------------------------------------------------------

      exp_txn.copy(txn);

      //-----------------------------------------------------------------------
      // Decode register index
      //
      // AXI4-Lite Address Mapping:
      //
      // 0x00 -> Register 0
      // 0x04 -> Register 1
      // ...
      // 0x7C -> Register 31
      //-----------------------------------------------------------------------

      reg_idx = txn.addr[6:2];

      //-----------------------------------------------------------------------
      // WRITE Transaction Prediction
      //
      // Update mirrored register contents using
      // AXI4-Lite byte-enable semantics.
      //-----------------------------------------------------------------------

      if (txn.txn_type == WRITE) begin

         //--------------------------------------------------------------------
         // Apply WSTRB byte enables
         //
         // Example:
         //   WSTRB = 4'b0101
         //
         // Updates:
         //   Byte0
         //   Byte2
         //--------------------------------------------------------------------

        for (int byte_lane = 0; byte_lane < 4; byte_lane++)
         begin

            if (txn.strb[byte_lane]) begin

              mem[reg_idx] [8*byte_lane +: 8]= txn.data [8*byte_lane +: 8];

            end

         end

         //--------------------------------------------------------------------
         // Forward expected write transaction
         //--------------------------------------------------------------------

         expected_port.write(exp_txn);

      end

      //-----------------------------------------------------------------------
      // READ Transaction Prediction
      //
      // Expected read data is retrieved from the mirrored register bank.
      //-----------------------------------------------------------------------

      else if (txn.txn_type == READ) begin

         //--------------------------------------------------------------------
         // Predict expected read value
         //--------------------------------------------------------------------

         exp_txn.data = mem[reg_idx];

         //--------------------------------------------------------------------
         // Forward expected read transaction
         //--------------------------------------------------------------------

         expected_port.write(exp_txn);

      end

   endfunction

endclass : axi4lite_ref_model

`endif 
