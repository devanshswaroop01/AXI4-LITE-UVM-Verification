
`ifndef AXI4LITE_BASE_SEQ_SV
`define AXI4LITE_BASE_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_base_seq
// Description: Base sequence for all AXI4-Lite stimulus sequences.
//
// Purpose:
//   - Provides a common parent class for sequence reuse
//   - Supplies a shared transaction handle
//   - Implements standardized sequence start/end logging
//   - Serves as the foundation for all derived sequences
//
// Derived Sequences:
//
//   axi4lite_reset_seq
//   axi4lite_single_write_seq
//   axi4lite_single_read_seq
//   axi4lite_write_read_seq
//   axi4lite_directed_seq
//   axi4lite_random_seq
//   axi4lite_back_to_back_seq
//   axi4lite_corner_case_seq
//   axi4lite_stress_seq
//   axi4lite_wstrb_seq
//
// Notes:
//   - This sequence does not generate stimulus.
//   - All transaction generation is implemented in child sequences.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_base_seq extends uvm_sequence #(axi4lite_txn);

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_base_seq)

   //--------------------------------------------------------------------------
   // Common Transaction Handle
   //
   // Available to derived sequences for transaction creation and reuse.
   // Protected visibility prevents direct external access.
   //--------------------------------------------------------------------------

   protected axi4lite_txn txn;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_base_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // pre_body()
   //
   // Automatically executed before the sequence body().
   //
   // Used to:
   //   - Mark sequence start
   //   - Improve simulation trace readability
   //   - Assist debug and regression analysis
   //--------------------------------------------------------------------------

   virtual task pre_body();

     `uvm_info( get_type_name(),$sformatf("Starting Sequence: %s",
            get_name()),UVM_MEDIUM)

   endtask

   //--------------------------------------------------------------------------
   // post_body()
   //
   // Automatically executed after the sequence body().
   //
   // Used to:
   //   - Mark sequence completion
   //   - Simplify debugging
   //   - Improve regression log traceability
   //--------------------------------------------------------------------------

   virtual task post_body();

     `uvm_info(get_type_name(), $sformatf("Completed Sequence: %s",
              get_name()),UVM_MEDIUM)

   endtask

endclass : axi4lite_base_seq

`endif 


`ifndef AXI4LITE_RESET_SEQ_SV
`define AXI4LITE_RESET_SEQ_SV

///////////////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_reset_seq
// Description: Reset synchronization sequence for the AXI4-Lite verification environment.
//
// Purpose:
//   - Provides a common reset-related sequence object
//   - Establishes a synchronization point before traffic generation
//   - Improves regression readability through explicit reset phase logging
//   - Can be extended in future environments where reset is sequence-controlled
//
// Notes:
//   - Does NOT drive rst_n.
//   - Reset is controlled externally by the testbench top.
//   - Primarily used for sequencing and simulation trace visibility.
//
// Typical Flow:
//
// Base Test
//     |
//     v
// Reset Sequence
//     |
//     v
// Functional Sequences
//
// Example:
//
//   axi4lite_reset_seq reset_seq;
//   reset_seq.start(sequencer);
//
//   axi4lite_random_seq rand_seq;
//   rand_seq.start(sequencer);
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_reset_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_reset_seq)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_reset_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Provides a reset synchronization window before normal
   // stimulus generation begins.
   //
   // No interface activity is generated during this sequence.
   // The delay simply allows externally controlled reset logic
   // to complete before traffic generation starts.
   //--------------------------------------------------------------------------

   virtual task body();

      `uvm_info(get_type_name(),"Reset sequence started",UVM_LOW)

      //-----------------------------------------------------------------------
      // Reset is managed by TB Top or Base Test.
      //
      // This sequence intentionally remains passive and acts as a
      // synchronization marker within the sequence flow.
      //-----------------------------------------------------------------------

      #100ns;

      `uvm_info(get_type_name(),"Reset sequence completed",UVM_LOW)

   endtask

endclass : axi4lite_reset_seq

`endif 


`ifndef AXI4LITE_DIRECTED_SEQ_SV
`define AXI4LITE_DIRECTED_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_directed_seq
// Description: Deterministic AXI4-Lite register verification sequence.
//
// Purpose:
//   - Verify accessibility of all DUT registers
//   - Perform full register write sweep
//   - Perform full register read sweep
//   - Validate register decode logic
//   - Provide repeatable debug-friendly stimulus
//
// Verification Strategy:
//
// Phase 1:
//   Write all 32 registers
//
//      Reg0  -> 0x00
//      Reg1  -> 0x04
//      ...
//      Reg31 -> 0x7C
//
// Phase 2:
//   Read back all 32 registers
//
// Coverage Contribution:
//   - Register Address Coverage
//   - Read Coverage
//   - Write Coverage
//   - Transaction/Register Cross Coverage
//
// Notes:
//   - Fully deterministic sequence
//   - No random delays inserted
//   - Excellent for debug and regression sanity checking
//   - Commonly executed before constrained-random testing
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_directed_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_directed_seq)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_directed_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Executes a complete register sweep:
   //
   //   1. Write all registers
   //   2. Read all registers
   //
   // Each register receives a unique data pattern,
   // simplifying debug and scoreboard analysis.
   //--------------------------------------------------------------------------

   virtual task body();

      axi4lite_txn txn;

     `uvm_info( get_type_name(),
         "Starting Directed Register Test",UVM_LOW)

      //-----------------------------------------------------------------------
      // WRITE PHASE
      //
      // Write every register in the DUT address space.
      //
      // Address Pattern:
      //   0x00 -> Register 0
      //   0x04 -> Register 1
      //   ...
      //   0x7C -> Register 31
      //
      // Data Pattern:
      //   32'hA5A5A500 + register_index
      //
      // Unique values make mismatches easy to identify.
      //-----------------------------------------------------------------------

      for (int i = 0; i < 32; i++) begin

         txn = axi4lite_txn::type_id::create($sformatf("write_txn_%0d", i));

         start_item(txn);

         if (!txn.randomize() with {

               txn_type     == WRITE;
               addr         == (i * 4);
               data         == (32'hA5A5A500 + i);
               delay_cycles == 0; })
           
         begin
            `uvm_fatal(get_type_name(),$sformatf("Failed to randomize write transaction %0d",i))

         end

         finish_item(txn);

      end

      //-----------------------------------------------------------------------
      // READ PHASE
      //
      // Read back every register previously written.
      //
      // Expected data will be checked by:
      //   - Reference Model
      //   - Scoreboard
      //
      // This validates:
      //   - Register storage
      //   - Address decoding
      //   - Read path functionality
      //-----------------------------------------------------------------------

      for (int i = 0; i < 32; i++) begin

         txn = axi4lite_txn::type_id::create($sformatf("read_txn_%0d", i));

         start_item(txn);

         if (!txn.randomize() with {

               txn_type     == READ;
               addr         == (i * 4);
               delay_cycles == 0; })
           
         begin
            `uvm_fatal(get_type_name(),$sformatf("Failed to randomize read transaction %0d",i))

         end

         finish_item(txn);

      end

      //-----------------------------------------------------------------------
      // Sequence Completion
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"Directed Register Test Complete",UVM_LOW)

   endtask

endclass : axi4lite_directed_seq


`endif 

`ifndef AXI4LITE_RANDOM_SEQ_SV
`define AXI4LITE_RANDOM_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_random_seq
// Description: Constrained-random AXI4-Lite traffic generation sequence.
//
// Purpose:
//   - Generate randomized AXI4-Lite transactions
//   - Exercise different register addresses
//   - Exercise READ and WRITE operations
//   - Exercise WSTRB patterns
//   - Exercise PROT values
//   - Improve overall functional coverage
//
// Coverage Contribution:
//
//   • Address Coverage
//   • Transaction Type Coverage
//   • WSTRB Coverage
//   • PROT Coverage
//   • Data Pattern Coverage
//   • RAW Coverage (when applicable)
//
// Notes:
//   - Uses transaction-level constraints defined in axi4lite_txn
//   - Transaction count is randomized per sequence instance
//   - Intended for coverage-driven verification
//   - Complements deterministic directed testing
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_random_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_random_seq)

   //--------------------------------------------------------------------------
   // Sequence Configuration
   //
   // Number of transactions generated during one sequence run.
   // Randomized to vary simulation workload and coverage.
   //--------------------------------------------------------------------------

   rand int unsigned num_txns;

   //--------------------------------------------------------------------------
   // Transaction Count Constraint
   //
   // Generates a moderate amount of traffic suitable for:
   //   - Functional coverage collection
   //   - Regression execution
   //   - Randomized protocol testing
   //--------------------------------------------------------------------------

   constraint c_num_txns {
     num_txns inside {[10:50]}; }

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_random_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Generates a stream of randomized AXI4-Lite transactions.
   //
   // Transaction fields are randomized according to constraints
   // defined inside axi4lite_txn:
   //
   //   - Address
   //   - Data
   //   - Transaction Type
   //   - Delay Cycles
   //   - PROT
   //   - WSTRB
   //
   // The generated transactions are subsequently driven by the
   // driver and verified through:
   //
   //   Monitor
   //      ↓
   //   Reference Model
   //      ↓
   //   Scoreboard
   //--------------------------------------------------------------------------

   virtual task body();

      axi4lite_txn txn;

     `uvm_info( get_type_name(), $sformatf( "Starting Random Sequence (%0d transactions)",
                                           num_txns),UVM_LOW)

      //-----------------------------------------------------------------------
      // Generate Random Transaction Stream
      //-----------------------------------------------------------------------

      for (int i = 0; i < num_txns; i++) begin

         //--------------------------------------------------------------------
         // Create Transaction
         //--------------------------------------------------------------------

        txn = axi4lite_txn::type_id::create($sformatf("random_txn_%0d", i) );

         start_item(txn);

         //--------------------------------------------------------------------
         // Randomize Transaction
         //
         // Uses all constraints defined in axi4lite_txn.
         //--------------------------------------------------------------------

         if (!txn.randomize())
         begin

           `uvm_fatal( get_type_name(), $sformatf("Failed to randomize transaction %0d",i))

         end

         //--------------------------------------------------------------------
         // Send Transaction to Sequencer/Driver
         //--------------------------------------------------------------------

         finish_item(txn);

      end

      //-----------------------------------------------------------------------
      // Sequence Completion
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"Random Sequence Complete",UVM_LOW)

   endtask

endclass : axi4lite_random_seq

`endif 


`ifndef AXI4LITE_SINGLE_WRITE_SEQ_SV
`define AXI4LITE_SINGLE_WRITE_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_single_write_seq
// Description: Utility sequence that generates a single AXI4-Lite WRITE transaction.
//
// Purpose:
//   - Perform a single register write operation
//   - Support directed debugging
//   - Support register-level verification
//   - Provide reusable write stimulus for higher-level sequences
//
// Typical Usage:
//
//   axi4lite_single_write_seq seq;
//
//   seq = axi4lite_single_write_seq::type_id::create("seq");
//
//   seq.addr = 32'h0000_0010;
//   seq.data = 32'h1234_5678;
//
//   seq.start(sequencer);
//
// Notes:
//   - Address and data are supplied by the user/test.
//   - Transaction is generated with zero delay.
//   - Uses standard AXI4-Lite write protocol.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_single_write_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_single_write_seq)

   //--------------------------------------------------------------------------
   // User-Controlled Fields
   //
   // addr : Target register address.
   //
   // data : Value to be written into the DUT register.
   //--------------------------------------------------------------------------

   rand bit [31:0] addr;
   rand bit [31:0] data;

   //--------------------------------------------------------------------------
   // Address Constraints
   //
   // AXI4-Lite Register Map:
   //   0x00 -> Register 0
   //   ...
   //   0x7C -> Register 31
   //
   // Word alignment is enforced.
   //--------------------------------------------------------------------------

   constraint c_addr {

      addr inside {
        [32'h0000_0000 : 32'h0000_007C] };

      addr[1:0] == 2'b00;  }

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_single_write_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Creates and sends a single WRITE transaction.
   //
   // Transaction Attributes:
   //   - WRITE operation
   //   - User-specified address
   //   - User-specified data
   //   - No insertion delay
   //
   // Flow:
   //
   // Sequence
   //    ↓
   // Transaction
   //    ↓
   // Sequencer
   //    ↓
   // Driver
   //    ↓
   // DUT
   //--------------------------------------------------------------------------

   virtual task body();

      //-----------------------------------------------------------------------
      // Create transaction object
      //-----------------------------------------------------------------------

      txn = axi4lite_txn::type_id::create("single_write_txn");

      start_item(txn);

      //-----------------------------------------------------------------------
      // Configure transaction using sequence parameters
      //-----------------------------------------------------------------------

      if (!txn.randomize() with {

            txn_type     == WRITE;
            addr         == local::addr;
            data         == local::data;
            delay_cycles == 0;   })
        
      begin
         `uvm_fatal(get_type_name(),"Failed to randomize single write transaction")

      end

      //-----------------------------------------------------------------------
      // Send transaction to sequencer/driver
      //-----------------------------------------------------------------------

      finish_item(txn);

      //-----------------------------------------------------------------------
      // Transaction summary for debug visibility
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),$sformatf("WRITE addr=0x%08h data=0x%08h",
            addr,data),UVM_MEDIUM)

   endtask

endclass : axi4lite_single_write_seq


`endif 

`ifndef AXI4LITE_SINGLE_READ_SEQ_SV
`define AXI4LITE_SINGLE_READ_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_single_read_seq
//
// Description: Utility sequence that generates a single AXI4-Lite READ transaction.
//
// Purpose:
//   - Perform a single register read operation
//   - Support directed debugging
//   - Support register access verification
//   - Provide reusable read stimulus for higher-level sequences
//
// Typical Usage:
//
//   axi4lite_single_read_seq seq;
//
//   seq = axi4lite_single_read_seq::type_id::create("seq");
//
//   seq.addr = 32'h0000_0010;
//
//   seq.start(sequencer);
//
// Notes:
//   - Address is supplied by the user/test.
//   - Read data is returned through the AXI read response path.
//   - Transaction is generated with zero delay.
//   - Read data checking is handled by the Reference Model
//     and Scoreboard.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_single_read_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_single_read_seq)

   //--------------------------------------------------------------------------
   // User-Controlled Fields
   //
   // addr : Target register address to be read.
   //--------------------------------------------------------------------------

   rand bit [31:0] addr;

   //--------------------------------------------------------------------------
   // Address Constraints
   //
   // AXI4-Lite Register Map:
   //   0x00 -> Register 0
   //   ...
   //   0x7C -> Register 31
   //
   // Word alignment is enforced.
   //--------------------------------------------------------------------------

   constraint c_addr {

      addr inside {
         [32'h0000_0000 : 32'h0000_007C]  };

      addr[1:0] == 2'b00;  }

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_single_read_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Creates and sends a single READ transaction.
   //
   // Transaction Attributes:
   //   - READ operation
   //   - User-specified address
   //   - No insertion delay
   //
   // Flow:
   //
   // Sequence
   //    ↓
   // Transaction
   //    ↓
   // Sequencer
   //    ↓
   // Driver
   //    ↓
   // DUT
   //    ↓
   // Monitor
   //    ↓
   // Reference Model / Scoreboard
   //--------------------------------------------------------------------------

   virtual task body();

      //-----------------------------------------------------------------------
      // Create transaction object
      //-----------------------------------------------------------------------

      txn = axi4lite_txn::type_id::create("single_read_txn");

      start_item(txn);

      //-----------------------------------------------------------------------
      // Configure transaction using sequence parameters
      //-----------------------------------------------------------------------

      if (!txn.randomize() with {

            txn_type     == READ;
            addr         == local::addr;
            delay_cycles == 0;  })
        
      begin
         `uvm_fatal(get_type_name(),"Failed to randomize single read transaction")

      end

      //-----------------------------------------------------------------------
      // Send transaction to sequencer/driver
      //-----------------------------------------------------------------------

      finish_item(txn);

      //-----------------------------------------------------------------------
      // Transaction summary for debug visibility
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),$sformatf("READ addr=0x%08h",
              addr),UVM_MEDIUM)

   endtask

endclass : axi4lite_single_read_seq

`endif 


`ifndef AXI4LITE_WRITE_READ_SEQ_SV
`define AXI4LITE_WRITE_READ_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_write_read_seq
// Description: AXI4-Lite Write-Read Verification Sequence.
//
// Purpose:
//   - Perform WRITE followed by READ to the same address
//   - Verify register storage functionality
//   - Verify readback correctness
//   - Validate reference model prediction
//   - Validate scoreboard comparison logic
//   - Exercise Read-After-Write (RAW) scenarios
//
// Verification Flow:
//
//      WRITE(addr, data)
//              |
//              v
//       DUT Register Update
//              |
//              v
//        READ(addr)
//              |
//              v
//      Expected Readback
//
// Architecture Interaction:
//
// Driver
//    ↓
// DUT
//    ↓
// Monitor
//    ├── Coverage
//    ├── Reference Model
//    └── Scoreboard
//
// Coverage Contribution:
//
//   • READ Coverage
//   • WRITE Coverage
//   • Address Coverage
//   • RAW Coverage
//   • Scoreboard Validation
//   • Reference Model Validation
//
// Typical Usage:
//
//   axi4lite_write_read_seq seq;
//
//   seq = axi4lite_write_read_seq::type_id::create("seq");
//
//   seq.addr = 32'h0000_0010;
//   seq.data = 32'h1234_5678;
//
//   seq.start(sequencer);
//
// Notes:
//   - Commonly used by Sanity Test
//   - Used extensively for register verification
//   - Generates deterministic WRITE → READ behavior
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_write_read_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_write_read_seq)

   //--------------------------------------------------------------------------
   // User-Controlled Fields
   //
   // addr : Target register address.
   //
   // data : Value written before readback.
   //--------------------------------------------------------------------------

   rand bit [31:0] addr;
   rand bit [31:0] data;

   //--------------------------------------------------------------------------
   // Address Constraints
   //
   // Valid AXI4-Lite Register Space:
   //
   //   0x00 -> Register 0
   //   ...
   //   0x7C -> Register 31
   //
   // Word alignment is enforced.
   //--------------------------------------------------------------------------

   constraint c_addr {

      addr inside {
        [32'h0000_0000 : 32'h0000_007C] };

      addr[1:0] == 2'b00; }

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_write_read_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Executes:
   //
   //   1. WRITE Transaction
   //   2. READ Transaction
   //
   // Both operations target the same register address.
   //
   // The readback value is subsequently checked through:
   //
   //   Reference Model
   //        ↓
   //   Scoreboard
   //--------------------------------------------------------------------------

   virtual task body();

      axi4lite_txn wr_txn;
      axi4lite_txn rd_txn;

      //-----------------------------------------------------------------------
      // WRITE PHASE
      //
      // Write user-specified data into the selected register.
      //-----------------------------------------------------------------------

      wr_txn = axi4lite_txn::type_id::create( "wr_txn");

      start_item(wr_txn);

      if (!wr_txn.randomize() with {

            txn_type     == WRITE;
            addr         == local::addr;
            data         == local::data;
            delay_cycles == 0; })
        
      begin
         `uvm_fatal(get_type_name(),"Failed to randomize write transaction")

      end

      finish_item(wr_txn);

      //-----------------------------------------------------------------------
      // READBACK PHASE
      //
      // Read the same register immediately after write.
      //
      // Creates a Read-After-Write (RAW) scenario that is
      // verified by the Reference Model and Scoreboard.
      //-----------------------------------------------------------------------

      rd_txn =axi4lite_txn::type_id::create("rd_txn");

      start_item(rd_txn);

      if (!rd_txn.randomize() with {

            txn_type     == READ;
            addr         == local::addr;
            delay_cycles == 0;   })
        
      begin
         `uvm_fatal(get_type_name(),"Failed to randomize read transaction")

      end

      finish_item(rd_txn);

      //-----------------------------------------------------------------------
      // Debug Summary
      //
      // Logs address and expected write data associated
      // with this WRITE → READ operation.
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),$sformatf("WRITE_READ addr=0x%08h data=0x%08h",
              addr,data),UVM_MEDIUM)

   endtask

endclass : axi4lite_write_read_seq

`endif  

`ifndef AXI4LITE_BACK_TO_BACK_SEQ_SV
`define AXI4LITE_BACK_TO_BACK_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_back_to_back_seq
//
// Description:
// Generates a continuous stream of AXI4-Lite transactions with no intentional
// idle cycles between consecutive transactions.
//
// Purpose:
//   - Stress sequencer-to-driver communication
//   - Exercise maximum transaction throughput
//   - Verify DUT behavior under sustained traffic
//   - Exercise consecutive READ and WRITE operations
//   - Improve protocol and functional coverage
//
// Verification Strategy:
//
//      TXN0
//       ↓
//      TXN1
//       ↓
//      TXN2
//       ↓
//      ...
//
// All transactions are generated with:
//
//      delay_cycles == 0
//
// resulting in back-to-back bus activity.
//
// Coverage Contribution:
//
//   • Read Coverage
//   • Write Coverage
//   • Address Coverage
//   • Protocol Coverage
//   • Driver Stress Testing
//   • Sequencer Arbitration Validation
//
// Notes:
//
//   - Transaction contents remain randomized.
//   - Only inter-transaction delay is constrained.
//   - Commonly used as part of Stress Test regressions.
//   - Helps expose timing-sensitive bugs in drivers,
//     monitors, scoreboards, and DUT implementations.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_back_to_back_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_back_to_back_seq)

   //--------------------------------------------------------------------------
   // Sequence Configuration
   //
   // Number of transactions generated during one sequence run.
   // Randomized to provide varying stress levels.
   //--------------------------------------------------------------------------

   rand int unsigned num_txns;

   //--------------------------------------------------------------------------
   // Transaction Count Constraint
   //
   // Generates a moderate-to-heavy burst of traffic suitable
   // for protocol stress testing.
   //--------------------------------------------------------------------------

   constraint c_num_txns {
      num_txns inside {[20:50]};  }

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_back_to_back_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Generates a stream of randomized transactions with:
   //
   //      delay_cycles == 0
   //
   // This creates continuous bus activity and minimizes idle
   // cycles between transfers.
   //
   // Transaction fields such as:
   //   - Address
   //   - Data
   //   - Transaction Type
   //   - WSTRB
   //   - PROT
   //
   // remain randomized according to axi4lite_txn constraints.
   //--------------------------------------------------------------------------

   virtual task body();

      `uvm_info(get_type_name(),$sformatf("Starting Back-to-Back Sequence (%0d transactions)",
                    num_txns),UVM_LOW)

      //-----------------------------------------------------------------------
      // Generate Continuous Transaction Stream
      //-----------------------------------------------------------------------

      repeat (num_txns) begin

         //--------------------------------------------------------------------
         // Create Transaction
         //--------------------------------------------------------------------

         txn = axi4lite_txn::type_id::create("b2b_txn");

         start_item(txn);

         //--------------------------------------------------------------------
         // Force zero inter-transaction delay
         //
         // Produces maximum traffic density while retaining
         // transaction-level randomization.
         //--------------------------------------------------------------------

         if (!txn.randomize() with {

               delay_cycles == 0; })
           
         begin
            `uvm_fatal(get_type_name(),"Failed to randomize back-to-back transaction")

         end

         //--------------------------------------------------------------------
         // Send transaction to sequencer/driver
         //--------------------------------------------------------------------

         finish_item(txn);

      end

      //-----------------------------------------------------------------------
      // Sequence Completion
      //-----------------------------------------------------------------------

     `uvm_info( get_type_name(),"Back-to-Back Sequence Complete",UVM_LOW)

   endtask

endclass : axi4lite_back_to_back_seq

`endif 


`ifndef AXI4LITE_CORNER_CASE_SEQ_SV
`define AXI4LITE_CORNER_CASE_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_corner_case_seq
// Description: Corner-case verification sequence for AXI4-Lite register testing.
//
// Purpose:
//   - Exercise important boundary conditions
//   - Verify handling of common stress data patterns
//   - Verify first and last register accessibility
//   - Improve functional coverage
//   - Validate scoreboard and reference model behavior
//
// Corner Cases Covered:
//
//   Data Patterns:
//      0x00000000  (All Zeros)
//      0xFFFFFFFF  (All Ones)
//      0xAAAAAAAA  (Alternating Pattern A)
//      0x55555555  (Alternating Pattern B)
//
//   Address Boundaries:
//      0x00000000  (First Register)
//      0x0000007C  (Last Register)
//
// Coverage Contribution:
//
//   • Address Coverage
//   • Data Pattern Coverage
//   • Read Coverage
//   • Write Coverage
//   • Register Boundary Coverage
//
// Notes:
//
//   - Uses deterministic transactions.
//   - Designed for debug-friendly execution.
//   - Commonly used within stress and regression testing.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_corner_case_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_corner_case_seq)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_corner_case_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // Helper Task : write_reg()
   //
   // Generates a single WRITE transaction using the supplied address and data values.
   //
   // Used to keep the main sequence body concise and readable.
   //--------------------------------------------------------------------------

   protected task write_reg(
      bit [31:0] addr,
      bit [31:0] data   );

      axi4lite_txn wr_txn;

      wr_txn =axi4lite_txn::type_id::create("corner_wr_txn");

      start_item(wr_txn);

      if (!wr_txn.randomize() with {

            txn_type == WRITE;
            addr     == local::addr;
            data     == local::data;  })
        
      begin
         `uvm_fatal(get_type_name(),"Corner-case write randomization failed")

      end

      finish_item(wr_txn);

   endtask

   //--------------------------------------------------------------------------
   // Helper Task : read_reg()
   //
   // Generates a single READ transaction for the supplied register address.
   //
   // Read data verification is performed by:
   //   - Reference Model
   //   - Scoreboard
   //--------------------------------------------------------------------------

   protected task read_reg(
      bit [31:0] addr );

      axi4lite_txn rd_txn;

      rd_txn =axi4lite_txn::type_id::create("corner_rd_txn");

      start_item(rd_txn);

      if (!rd_txn.randomize() with {

            txn_type == READ;
            addr     == local::addr;    })
        
      begin
         `uvm_fatal(get_type_name(),"Corner-case read randomization failed")

      end

      finish_item(rd_txn);

   endtask

   //--------------------------------------------------------------------------
   // body()
   //
   // Executes a predefined set of corner-case accesses:
   //
   //   1. Special data pattern writes
   //   2. First register access
   //   3. Last register access
   //   4. Readback operations
   //
   // The resulting transactions are observed by:
   //
   //   Monitor
   //      ↓
   //   Coverage
   //   Reference Model
   //   Scoreboard
   //--------------------------------------------------------------------------

   virtual task body();

      `uvm_info(get_type_name(),"Starting Corner Case Sequence",UVM_LOW)

      //-----------------------------------------------------------------------
      // DATA PATTERN TESTS
      //
      // Exercise commonly used verification patterns that
      // often expose data-path and storage-related bugs.
      //-----------------------------------------------------------------------

      write_reg(32'h00, 32'h00000000);  // All Zeros
      write_reg(32'h04, 32'hFFFFFFFF);  // All Ones
      write_reg(32'h08, 32'hAAAAAAAA);  // Alternating Pattern A
      write_reg(32'h0C, 32'h55555555);  // Alternating Pattern B

      //-----------------------------------------------------------------------
      // REGISTER BOUNDARY TESTS
      //
      // Verify accessibility of the first and last registers
      // in the DUT address map.
      //-----------------------------------------------------------------------

      write_reg(32'h00, 32'hDEADBEEF);  // First Register
      write_reg(32'h7C, 32'hCAFEBABE);  // Last Register

      //-----------------------------------------------------------------------
      // READBACK PHASE
      //
      // Read previously accessed registers.
      //
      // Expected values are predicted by the Reference Model
      // and checked by the Scoreboard.
      //-----------------------------------------------------------------------

      read_reg(32'h00);
      read_reg(32'h04);
      read_reg(32'h08);
      read_reg(32'h0C);
      read_reg(32'h7C);

      //-----------------------------------------------------------------------
      // Sequence Completion
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"Corner Case Sequence Complete",UVM_LOW)

   endtask

endclass : axi4lite_corner_case_seq

`endif 


`ifndef AXI4LITE_STRESS_SEQ_SV
`define AXI4LITE_STRESS_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_stress_seq
//
// Description: High-volume constrained-random AXI4-Lite traffic generation sequence.
//
// Purpose:
//   - Execute long-duration simulations
//   - Drive large numbers of random transactions
//   - Improve functional coverage closure
//   - Stress the complete verification environment
//   - Verify stability during extended operation
//
// Verification Objectives:
//
//   • Driver Robustness
//   • Sequencer Robustness
//   • Monitor Robustness
//   • Reference Model Stability
//   • Scoreboard Stability
//   • Coverage Closure
//
// Traffic Characteristics:
//
//   - Random READ transactions
//   - Random WRITE transactions
//   - Random addresses
//   - Random data patterns
//   - Random WSTRB values
//   - Random PROT values
//   - Random inter-transaction delays
//
// Notes:
//
//   - Uses transaction constraints defined in axi4lite_txn.
//   - Intended for long regression runs.
//   - Commonly executed after sanity and directed testing.
//   - Helps expose rare corner-case interactions.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_stress_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_stress_seq)

   //--------------------------------------------------------------------------
   // Sequence Configuration
   //
   // Number of randomized transactions generated during
   // a single stress-test execution.
   //
   // Large transaction counts help expose:
   //   - Intermittent bugs
   //   - Scoreboard synchronization issues
   //   - Monitor robustness issues
   //   - Coverage holes
   //--------------------------------------------------------------------------

   rand int unsigned num_txns;

   //--------------------------------------------------------------------------
   // Transaction Count Constraint
   //
   // Generates substantial traffic while maintaining practical simulation runtimes.
   //--------------------------------------------------------------------------

   constraint c_num_txns {

      num_txns inside {[200:500]};}

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_stress_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // body()
   //
   // Generates a long stream of randomized AXI4-Lite transactions.
   //
   // Transaction attributes are randomized according to
   // constraints defined in axi4lite_txn:
   //
   //   - Transaction Type
   //   - Address
   //   - Data
   //   - Delay Cycles
   //   - WSTRB
   //   - PROT
   //
   // Generated traffic exercises the complete verification architecture:
   //
   //   Sequencer
   //        ↓
   //      Driver
   //        ↓
   //       DUT
   //        ↓
   //     Monitor
   //        ↓
   //   -------------------
   //   |        |        |
   //   ↓        ↓        ↓
   // Coverage RefModel Scoreboard
   //
   // This sequence is primarily intended for:
   //   - Stress testing
   //   - Coverage closure
   //   - Regression robustness verification
   //--------------------------------------------------------------------------

   virtual task body();

     `uvm_info(get_type_name(), $sformatf( "Starting Stress Sequence (%0d transactions)",
                      num_txns),UVM_LOW)

      //-----------------------------------------------------------------------
      // Generate High-Volume Random Traffic
      //-----------------------------------------------------------------------

      repeat (num_txns) begin

         //--------------------------------------------------------------------
         // Create transaction
         //--------------------------------------------------------------------

         txn = axi4lite_txn::type_id::create("stress_txn");

         start_item(txn);

         //--------------------------------------------------------------------
         // Randomize transaction using all constraints
         // defined in axi4lite_txn.
         //--------------------------------------------------------------------

         if (!txn.randomize()) begin

            `uvm_fatal(get_type_name(),"Failed to randomize stress transaction")

         end

         //--------------------------------------------------------------------
         // Send transaction to sequencer/driver
         //--------------------------------------------------------------------

         finish_item(txn);

      end

      //-----------------------------------------------------------------------
      // Sequence Completion
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"Stress Sequence Complete",UVM_LOW)

   endtask

endclass : axi4lite_stress_seq

`endif 

`ifndef AXI4LITE_WSTRB_SEQ_SV
`define AXI4LITE_WSTRB_SEQ_SV

//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_wstrb_seq
//
// Description: Dedicated AXI4-Lite WSTRB verification sequence.
//
// Purpose:
//   - Verify byte-enable functionality
//   - Verify partial register updates
//   - Verify DUT WSTRB decode logic
//   - Validate reference model WSTRB prediction
//   - Improve WSTRB functional coverage
//
// WSTRB Patterns Tested:
//
//   Single Byte:
//      0001
//      0010
//      0100
//      1000
//
//   Half Word:
//      0011
//      1100
//
//   Sparse Bytes:
//      0101
//      1010
//
//   Three Byte:
//      0111
//      1110
//
//   Full Word:
//      1111
//
// Verification Goals:
//
//   - Ensure only enabled byte lanes are updated
//   - Ensure disabled byte lanes retain previous values
//   - Verify DUT and Reference Model behavior match
//   - Exercise all important WSTRB coverage bins
//
// Architecture Interaction:
//
//   Driver
//      ↓
//   DUT
//      ↓
//   Monitor
//      ├── Coverage
//      ├── Reference Model
//      └── Scoreboard
//
// Notes:
//
//   - Deterministic sequence.
//   - Complements random WSTRB traffic.
//   - Targets protocol corner cases often missed by
//     constrained-random testing.
//
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_wstrb_seq extends axi4lite_base_seq;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_object_utils(axi4lite_wstrb_seq)

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(string name = "axi4lite_wstrb_seq");
      super.new(name);
   endfunction

   //--------------------------------------------------------------------------
   // Helper Task : send_write()
   //
   // Generates a WRITE transaction with a user-specified
   // address, data value, and WSTRB pattern.
   //
   // Used to keep the main sequence body concise while
   // exercising different byte-enable combinations.
   //
   // Parameters:
   //
   //   addr : Target register address.
   //
   //   data :  Write data value.
   //
   //   strb : AXI4-Lite byte enable mask.
   //--------------------------------------------------------------------------

   protected task send_write(
      bit [31:0] addr,
      bit [31:0] data,
      bit [3:0]  strb );

      axi4lite_txn wr_txn;

      //-----------------------------------------------------------------------
      // Create transaction object
      //-----------------------------------------------------------------------

      wr_txn = axi4lite_txn::type_id::create($sformatf("wstrb_txn_%0h", strb));

      start_item(wr_txn);

      //-----------------------------------------------------------------------
      // Configure WRITE transaction
      //
      // WSTRB determines which byte lanes will be updated.
      //-----------------------------------------------------------------------

      if (!wr_txn.randomize() with {

            txn_type     == WRITE;

            addr         == local::addr;

            data         == local::data;

            strb         == local::strb;

            delay_cycles == 0;  })
        
      begin
         `uvm_fatal(get_type_name(),$sformatf("WSTRB transaction randomization failed (WSTRB=%b)",strb))

      end

      finish_item(wr_txn);

      //-----------------------------------------------------------------------
      // Debug transaction summary
      //-----------------------------------------------------------------------

      `uvm_info(  get_type_name(),$sformatf("WRITE addr=0x%08h data=0x%08h strb=%b",
                addr, data, strb),UVM_MEDIUM)

   endtask

   //--------------------------------------------------------------------------
   // body()
   //
   // Executes a comprehensive set of deterministic WSTRB scenarios covering:
   //
   //   1. Single-byte writes
   //   2. Half-word writes
   //   3. Sparse byte enables
   //   4. Three-byte writes
   //   5. Full-word writes
   //
   // The sequence intentionally targets patterns most likely
   // to reveal byte-lane update bugs.
   //--------------------------------------------------------------------------

   virtual task body();

      `uvm_info(get_type_name(),"Starting WSTRB Verification Sequence",UVM_LOW)

      //-----------------------------------------------------------------------
      // Register Initialization
      //
      // Establish a known baseline value before performing  partial-byte updates.
      //-----------------------------------------------------------------------

      send_write(
         32'h0000_0000,
         32'hDEAD_BEEF,
         4'b1111 );

      //-----------------------------------------------------------------------
      // Single Byte Enable Tests
      //
      // Verify each individual byte lane independently.
      //-----------------------------------------------------------------------

      send_write(32'h0000_0000, 32'h1122_3344, 4'b0001);
      send_write(32'h0000_0004, 32'h5566_7788, 4'b0010);
      send_write(32'h0000_0008, 32'h99AA_BBCC, 4'b0100);
      send_write(32'h0000_000C, 32'hDDEE_FF11, 4'b1000);

      //-----------------------------------------------------------------------
      // Half Word Enable Tests
      //
      // Verify lower and upper 16-bit updates.
      //-----------------------------------------------------------------------

      send_write(32'h0000_0010, 32'h1234_5678, 4'b0011);
      send_write(32'h0000_0014, 32'h8765_4321, 4'b1100);

      //-----------------------------------------------------------------------
      // Sparse Byte Enable Tests
      //
      // Verify non-contiguous byte-lane updates.
      //-----------------------------------------------------------------------

      send_write(32'h0000_0018, 32'hAAAA_5555, 4'b0101);
      send_write(32'h0000_001C, 32'h5555_AAAA, 4'b1010);

      //-----------------------------------------------------------------------
      // Three Byte Enable Tests
      //
      // Verify partial-word updates affecting three bytes.
      //-----------------------------------------------------------------------

      send_write(32'h0000_0020, 32'hCAFE_BABE, 4'b0111);
      send_write(32'h0000_0024, 32'hDEAD_BEEF, 4'b1110);

      //-----------------------------------------------------------------------
      // Full Word Enable Test
      //
      // Verify standard 32-bit register write operation.
      //-----------------------------------------------------------------------

      send_write(32'h0000_0028, 32'hFACE_CAFE, 4'b1111);

      //-----------------------------------------------------------------------
      // Sequence Completion
      //-----------------------------------------------------------------------

      `uvm_info(get_type_name(),"WSTRB Verification Sequence Complete",UVM_LOW)

   endtask

endclass : axi4lite_wstrb_seq

`endif 
