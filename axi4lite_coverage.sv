`ifndef AXI4LITE_COVERAGE_SV
`define AXI4LITE_COVERAGE_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_coverage
// Description:AXI4-Lite Functional Coverage Collector
//
// Purpose:
//   - Measure verification completeness
//   - Track exercised DUT functionality
//   - Identify untested scenarios
//   - Support coverage closure
//
// Coverage Categories:
//   • Transaction Type Coverage
//   • Register Address Coverage
//   • Data Pattern Coverage
//   • Response Coverage
//   • WSTRB Coverage
//   • PROT Coverage
//   • Read-After-Write (RAW) Coverage
//
// Architecture:
//
// Monitor
//     |
//     v
// Analysis Port
//     |
//     v
// AXI4LITE_COVERAGE
//     |
//     +--> Transaction Coverage
//     +--> Protocol Coverage
//     +--> RAW Coverage
//
// DUT Characteristics:
//
//   Registers : 32
//   Addresses : 0x00 - 0x7C
//   Register Decode : addr[6:2]
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_coverage extends uvm_subscriber #(axi4lite_txn);

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_coverage)

   //--------------------------------------------------------------------------
   // Local Transaction Copy
   //
   // Holds cloned transaction used for coverage sampling.
   //--------------------------------------------------------------------------

   axi4lite_txn txn;

   //--------------------------------------------------------------------------
   // Statistics
   //
   // Simple counters used in coverage report generation.
   //--------------------------------------------------------------------------

   int num_read_txns;
   int num_write_txns;

   //--------------------------------------------------------------------------
   // Previous Transaction Tracking
   //
   // Used for Read-After-Write (RAW) coverage detection.
   //--------------------------------------------------------------------------

   axi4lite_txn prev_txn;
   bit          prev_txn_valid;

   //--------------------------------------------------------------------------
   // Main Functional Coverage
   //
   // Covers:
   //   - Transaction type
   //   - Register accesses
   //   - Data patterns
   //   - Response types
   //   - WSTRB patterns
   //   - Transaction/Register cross coverage
   //--------------------------------------------------------------------------

   covergroup cg_axi4lite_transactions;

      option.per_instance = 1;
      option.name         = "cg_axi4lite_transactions";

      //-----------------------------------------------------------------------
      // READ / WRITE Coverage
      //-----------------------------------------------------------------------

      cp_txn_type : coverpoint txn.txn_type {

         bins read  = {READ};
         bins write = {WRITE}; }

      //-----------------------------------------------------------------------
      // Register Coverage
      //
      // Ensures all 32 registers are accessed.
      //-----------------------------------------------------------------------

      cp_reg_index : coverpoint txn.addr[6:2] {

         bins reg1[32] = {[0:31]};

         bins first_reg = {0};
         bins last_reg  = {31}; }

      //-----------------------------------------------------------------------
      // Data Pattern Coverage
      //
      // Common verification patterns:
      //   0x00000000
      //   0xFFFFFFFF
      //   0xAAAAAAAA
      //   0x55555555
      //-----------------------------------------------------------------------

      cp_data_patterns : coverpoint txn.data {

         bins all_zeros = {32'h00000000};

         bins all_ones  = {32'hFFFFFFFF};

         bins alternating =
         {
            32'hAAAAAAAA,
            32'h55555555};

         bins small_vals =  {[32'h00000001 : 32'h000000FF]};

         bins large_vals = {[32'hFFFFFF00 : 32'hFFFFFFFE]};

         bins others = default; }

      //-----------------------------------------------------------------------
      // Response Coverage
      //
      // DUT currently supports only OKAY response.
      //-----------------------------------------------------------------------

      cp_response : coverpoint txn.resp {

         bins okay = {2'b00}; }

      //-----------------------------------------------------------------------
      // WSTRB Coverage
      //
      // Verifies byte-enable behavior.
      //-----------------------------------------------------------------------

      cp_write_strobe :
      coverpoint txn.strb iff(txn.txn_type == WRITE) {

         bins byte0 = {4'b0001};
         bins byte1 = {4'b0010};
         bins byte2 = {4'b0100};
         bins byte3 = {4'b1000};

         bins low_half  = {4'b0011};
         bins high_half = {4'b1100};

         bins non_contiguous =
         {
            4'b0101,
            4'b1010  };

         bins full_word = {4'b1111};   }

      //-----------------------------------------------------------------------
      // Transaction Type vs Register Coverage
      //
      // Example:
      //   READ  Register 0
      //   WRITE Register 0
      //   ...
      //   READ  Register 31
      //   WRITE Register 31
      //-----------------------------------------------------------------------

      cross_txn_reg :
      cross cp_txn_type,
            cp_reg_index;

   endgroup

   //--------------------------------------------------------------------------
   // Protocol Coverage
   //
   // Covers AXI4-Lite PROT field values.
   //--------------------------------------------------------------------------

   covergroup cg_protocol;

      option.per_instance = 1;
      option.name         = "cg_protocol";

      cp_prot : coverpoint txn.prot {

         bins prot[8] = {[0:7]}; }

   endgroup

   //--------------------------------------------------------------------------
   // Read-After-Write Coverage
   //
   // Detects:
   //
   // WRITE(addr)
   //      followed by
   // READ(addr)
   //
   // Useful for validating data coherency behavior.
   //--------------------------------------------------------------------------

   covergroup cg_raw_scenarios;

      option.per_instance = 1;
      option.name         = "cg_raw_scenarios";

      cp_raw :

      coverpoint (
         prev_txn_valid                     &&
         prev_txn.txn_type == WRITE         &&
         txn.txn_type      == READ          &&
         prev_txn.addr     == txn.addr )
      {
         bins raw_occurred = {1};
         bins no_raw       = {0};}

   endgroup

   //--------------------------------------------------------------------------
   // Constructor
   //
   // Creates covergroups and initializes counters.
   //--------------------------------------------------------------------------

   function new(
      string name,
      uvm_component parent);

      super.new(name, parent);

      cg_axi4lite_transactions = new();
      cg_protocol              = new();
      cg_raw_scenarios         = new();

      num_read_txns  = 0;
      num_write_txns = 0;

      prev_txn_valid = 0;

   endfunction

   //--------------------------------------------------------------------------
   // write()
   //
   // Called automatically whenever monitor publishes
   // a transaction through the analysis network.
   //
   // Responsibilities:
   //   - Clone transaction
   //   - Sample coverage
   //   - Update statistics
   //   - Maintain RAW tracking information
   //--------------------------------------------------------------------------

   virtual function void write(axi4lite_txn t);

      //-----------------------------------------------------------------------
      // Clone transaction for coverage sampling
      //-----------------------------------------------------------------------

      $cast(txn, t.clone());

      //-----------------------------------------------------------------------
      // Sample all coverage models
      //-----------------------------------------------------------------------

      cg_axi4lite_transactions.sample();

      cg_protocol.sample();

      cg_raw_scenarios.sample();

      //-----------------------------------------------------------------------
      // Update statistics
      //-----------------------------------------------------------------------

      if(txn.txn_type == READ)
         num_read_txns++;
      else
         num_write_txns++;

      //-----------------------------------------------------------------------
      // Save current transaction for future RAW detection
      //-----------------------------------------------------------------------

      if(prev_txn == null)
         prev_txn = axi4lite_txn::type_id::create("prev_txn");

      $cast(prev_txn, txn.clone());

      prev_txn_valid = 1;

   endfunction

   //--------------------------------------------------------------------------
   // Report Phase
   //
   // Generates final functional coverage summary.
   //--------------------------------------------------------------------------

   virtual function void report_phase(uvm_phase phase);

      real txn_cov;
      real protocol_cov;
      real raw_cov;
      real total_cov;

      super.report_phase(phase);

      //-----------------------------------------------------------------------
      // Collect coverage metrics
      //-----------------------------------------------------------------------

      txn_cov      = cg_axi4lite_transactions.get_coverage();
      protocol_cov = cg_protocol.get_coverage();
      raw_cov      = cg_raw_scenarios.get_coverage();

      //-----------------------------------------------------------------------
      // Overall Coverage Metric
      //-----------------------------------------------------------------------

      total_cov = (txn_cov +protocol_cov +raw_cov) / 3.0;

      //-----------------------------------------------------------------------
      // Coverage Report
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"=================================================",UVM_NONE)

      `uvm_info(get_type_name(),"              COVERAGE REPORT",UVM_NONE)

      `uvm_info(get_type_name(),"=================================================",UVM_NONE)

      `uvm_info(get_type_name(),$sformatf("Reads                : %0d", num_read_txns),UVM_NONE)

      `uvm_info(get_type_name(),$sformatf("Writes               : %0d", num_write_txns),UVM_NONE)

      `uvm_info(get_type_name(),$sformatf("Transaction Coverage : %0.2f%%", txn_cov),UVM_NONE)

      `uvm_info(get_type_name(),$sformatf("Protocol Coverage    : %0.2f%%", protocol_cov),UVM_NONE)

      `uvm_info(get_type_name(),$sformatf("RAW Coverage         : %0.2f%%", raw_cov),UVM_NONE)

      `uvm_info(get_type_name(),"-------------------------------------------------",UVM_NONE)

      `uvm_info(get_type_name(),$sformatf("OVERALL COVERAGE     : %0.2f%%", total_cov),UVM_NONE)

      `uvm_info(get_type_name(),"=================================================",UVM_NONE)

   endfunction

endclass : axi4lite_coverage

`endif
