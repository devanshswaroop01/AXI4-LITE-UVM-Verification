`ifndef AXI4LITE_TXN_SV
`define AXI4LITE_TXN_SV

//////////////////////////////////////////////////////////////////////////////////
// Type : axi4lite_txn_type_e
// Description: Transaction type for AXI4-Lite operations.
//
// READ  : AXI Read Transaction
// WRITE : AXI Write Transaction
//
//////////////////////////////////////////////////////////////////////////////////

typedef enum bit {
   READ  = 0,
   WRITE = 1
} axi4lite_txn_type_e;

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_txn
// Description: AXI4-Lite transaction object.
//
// Purpose:
//   - Represents a complete AXI4-Lite bus transaction
//   - Serves as the common data structure exchanged between:
//       * Sequences
//       * Sequencer
//       * Driver
//       * Monitor
//       * Reference Model
//       * Coverage Collector
//       * Scoreboard
//
// AXI Signal Mapping:
//
//   addr      -> AWADDR / ARADDR
//   data      -> WDATA / RDATA
//   strb      -> WSTRB
//   prot      -> AWPROT / ARPROT
//   resp      -> BRESP / RRESP
//   txn_type  -> READ / WRITE operation
//
// Verification Usage:
//
//   Sequence
//      ↓
//   Sequencer
//      ↓
//   Driver
//      ↓
//   DUT
//      ↓
//   Monitor
//      ↓
//   Coverage / RefModel / Scoreboard
//
// Notes:
//
//   - Central transaction abstraction for the environment.
//   - Supports constrained-random stimulus generation.
//   - Supports comparison and reporting.
//   - Supports functional coverage collection.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_txn extends uvm_sequence_item;

   //--------------------------------------------------------------------------
   // Factory Registration + Automation
   //
   // Enables:
   //   - Factory overrides
   //   - Copy
   //   - Compare
   //   - Print
   //   - Record
   //   - Pack / Unpack
   //--------------------------------------------------------------------------

   `uvm_object_utils_begin(axi4lite_txn)

      `uvm_field_int(addr,         UVM_ALL_ON)
      `uvm_field_int(data,         UVM_ALL_ON)

      `uvm_field_enum(
         axi4lite_txn_type_e,
         txn_type,
         UVM_ALL_ON
      )

      `uvm_field_int(delay_cycles, UVM_ALL_ON)

      `uvm_field_int(prot,         UVM_ALL_ON)
      `uvm_field_int(strb,         UVM_ALL_ON)

      `uvm_field_int(resp,         UVM_ALL_ON)

   `uvm_object_utils_end

   //--------------------------------------------------------------------------
   // Transaction Fields
   //--------------------------------------------------------------------------

   // Address used for READ or WRITE access.
   rand bit [31:0] addr;

   // Write data for WRITE transactions.
   // Read data captured by monitor for READ transactions.
   rand bit [31:0] data;

   // Transaction direction.
   rand axi4lite_txn_type_e txn_type;

   // Number of cycles inserted before issuing transaction.
   // Used to create realistic traffic spacing.
   rand int unsigned delay_cycles;

   // AXI protection attribute.
   rand bit [2:0] prot;

   // AXI byte enable mask.
   rand bit [3:0] strb;

   // Response returned by DUT.
   //
   // 00 = OKAY
   // 01 = EXOKAY (unused in AXI4-Lite)
   // 10 = SLVERR
   // 11 = DECERR
   //
   bit [1:0] resp;

   // Optional timing information.
   //
   // Can be used for:
   //   - Latency measurements
   //   - Performance analysis
   //   - Debugging
   //
   time start_time;
   time end_time;

   //--------------------------------------------------------------------------
   // Address Alignment Constraint
   //
   // AXI4-Lite uses 32-bit aligned register accesses.
   //--------------------------------------------------------------------------

   constraint c_addr_align {

      addr[1:0] == 2'b00; }

   //--------------------------------------------------------------------------
   // Address Range Constraint
   //
   // DUT Register Map:
   //
   //   Register 0  -> 0x00
   //   Register 1  -> 0x04
   //   ...
   //   Register 31 -> 0x7C
   //
   // Restricts stimulus to valid DUT address space.
   //--------------------------------------------------------------------------

   constraint c_addr_range {

      addr inside {
        [32'h0000_0000 : 32'h0000_007C]}; }

   //--------------------------------------------------------------------------
   // Delay Distribution
   //
   // Traffic Characteristics:
   //
   //   40% -> No delay
   //   40% -> Small delay
   //   20% -> Larger delay
   //
   // Produces realistic transaction spacing while maintaining
   // good simulation throughput.
   //--------------------------------------------------------------------------

   constraint c_delay {

      delay_cycles inside {[0:5]};

      delay_cycles dist {

         0      := 40,

         [1:2]  := 40,

         [3:5]  := 20     };  }

   //--------------------------------------------------------------------------
   // READ / WRITE Distribution
   //
   // Balanced traffic generation.
   //--------------------------------------------------------------------------

   constraint c_txn_type {

      txn_type dist {

         READ  := 50,
         WRITE := 50 };  }

   //--------------------------------------------------------------------------
   // PROT Distribution
   //
   // Most accesses use normal AXI protection settings.
   // Rarely exercise alternative values for coverage.
   //--------------------------------------------------------------------------

   constraint c_prot {

      prot dist {

         3'b000 := 80,

         [3'b001:3'b111] := 20  };   }

   //--------------------------------------------------------------------------
   // WSTRB Distribution
   //
   // Bias toward common software behavior while still
   // exercising partial-write functionality.
   //
   // Coverage Focus:
   //   Single-byte writes
   //   Half-word writes
   //   Sparse writes
   //   Full-word writes
   //--------------------------------------------------------------------------

   constraint c_strb {

      strb dist {

         // Most common software access
         4'b1111 := 70,

         // Single-byte writes
         4'b0001 := 5,
         4'b0010 := 5,
         4'b0100 := 5,
         4'b1000 := 5,

         // Half-word writes
         4'b0011 := 3,
         4'b1100 := 3,

         // Sparse writes
         4'b0101 := 2,
         4'b1010 := 2     };  }

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_txn");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // Helper Function
   //
   // Returns:
   //   1 -> Error response detected
   //   0 -> Normal response
   //
   // Useful for:
   //   - Scoreboard checks
   //   - Protocol checking
   //   - Error coverage
   //--------------------------------------------------------------------------

   function bit is_error_response();

      return (resp inside {2'b10, 2'b11});

   endfunction

   //--------------------------------------------------------------------------
   // convert2string()
   //
   // Generates concise transaction summary.
   //
   // Used by:
   //   - Driver logs
   //   - Monitor logs
   //   - Debug messages
   //--------------------------------------------------------------------------

   virtual function string convert2string();

      return $sformatf(
         "%s ADDR=0x%08h DATA=0x%08h STRB=%b RESP=%0d",
         txn_type.name(),
         addr,
         data,
         strb,
         resp   );

   endfunction

   //--------------------------------------------------------------------------
   // do_compare()
   //
   // Scoreboard comparison support.
   //
   // Fields Compared:
   //   - Address
   //   - Data
   //   - Transaction Type
   //   - WSTRB
   //   - Response
   //
   // Returns:
   //   1 -> Match
   //   0 -> Mismatch
   //--------------------------------------------------------------------------

   virtual function bit do_compare(
      uvm_object rhs,
      uvm_comparer comparer  );

      axi4lite_txn rhs_;

      if (!$cast(rhs_, rhs))
         return 0;

      return (

         addr     == rhs_.addr     &&
         data     == rhs_.data     &&
         txn_type == rhs_.txn_type &&
         strb     == rhs_.strb     &&
         resp     == rhs_.resp );

   endfunction

endclass : axi4lite_txn

`endif 
