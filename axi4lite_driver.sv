
//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_driver
// Description:
// AXI4-Lite Driver responsible for converting sequence transactions
// into pin-level AXI4-Lite bus activity.
//
// Responsibilities:
//   - Receive transactions from sequencer
//   - Drive AXI write/read transfers
//   - Handle protocol handshakes
//   - Collect response information
//   - Provide timeout protection
//   - Recover cleanly from reset
//
// Transaction Flow:
//
// Sequencer
//      ↓
// Driver
//      ↓
// AXI Interface
//      ↓
// DUT
//
// Supported Transactions:
//   - WRITE
//   - READ
//
// Notes:
//   - Single outstanding transaction model
//   - AXI4-Lite compliant
//   - Includes response timeout protection
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_driver extends uvm_driver #(axi4lite_txn);

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_driver)

   //--------------------------------------------------------------------------
   // Virtual Interface
   //
   // Connects driver to DUT interface signals through the driver clocking block.
   //--------------------------------------------------------------------------

   virtual axi4lite_if vif;

   //--------------------------------------------------------------------------
   // Timeout Configuration
   //
   // Prevents simulation hangs if DUT fails to respond.
   //--------------------------------------------------------------------------

   localparam int TIMEOUT_CYCLES = 100;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_driver",
      uvm_component parent = null );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // Build Phase
   //
   // Retrieves virtual interface from Config DB.
   //--------------------------------------------------------------------------

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      if (!uvm_config_db#(virtual axi4lite_if)::get(
              this,"","vif",vif))
        
      begin
         `uvm_fatal(get_type_name(),"Virtual interface not found in config DB")

      end

   endfunction

   //--------------------------------------------------------------------------
   // Run Phase
   //
   // Launches:
   //   1. Transaction execution thread
   //   2. Reset monitoring thread
   //--------------------------------------------------------------------------

   virtual task run_phase(uvm_phase phase);

      initialize_signals();

      fork
         get_and_drive();
         reset_monitor();
      join

   endtask

   //--------------------------------------------------------------------------
   // Interface Initialization
   //
   // Drives all master-controlled signals to known idle values.
   // Called:
   //   - At startup
   //   - After reset assertion
   //--------------------------------------------------------------------------

   virtual task initialize_signals();

      //---------------- Write Address ----------------

      vif.driver_cb.AWADDR  <= '0;
      vif.driver_cb.AWPROT  <= '0;
      vif.driver_cb.AWVALID <= 0;

      //---------------- Write Data -------------------

      vif.driver_cb.WDATA   <= '0;
      vif.driver_cb.WSTRB   <= '0;
      vif.driver_cb.WVALID  <= 0;

      //---------------- Write Response ---------------

      vif.driver_cb.BREADY  <= 0;

      //---------------- Read Address -----------------

      vif.driver_cb.ARADDR  <= '0;
      vif.driver_cb.ARPROT  <= '0;
      vif.driver_cb.ARVALID <= 0;

      //---------------- Read Data --------------------

      vif.driver_cb.RREADY  <= 0;

   endtask

   //--------------------------------------------------------------------------
   // Main Driver Loop
   //
   // Sequence:
   //   Wait for reset release
   //   Get transaction from sequencer
   //   Apply optional delay
   //   Execute transaction
   //   Return completion to sequencer
   //--------------------------------------------------------------------------

   virtual task get_and_drive();

      axi4lite_txn txn;

      forever begin

         // Wait until DUT exits reset
         wait(vif.rst_n == 1'b1);

         // Obtain next transaction
         seq_item_port.get_next_item(txn);

         txn.start_time = $time;

        `uvm_info(get_type_name(), $sformatf("Driving Transaction:\n%s",
               txn.convert2string()),UVM_MEDIUM)

         // Optional inter-transaction delay
         repeat (txn.delay_cycles)
            @(vif.driver_cb);

         // Execute transaction type
         case (txn.txn_type)

            WRITE : drive_write(txn);

            READ : drive_read(txn);

            default : `uvm_error(get_type_name(),"Unknown transaction type")

         endcase

         txn.end_time = $time;

         // Notify sequencer transaction completed
         seq_item_port.item_done();

      end

   endtask

   //--------------------------------------------------------------------------
   // Complete Write Transaction
   //
   // AXI4-Lite Write Flow:
   //
   // AW Channel
   //      +
   // W Channel
   //      ↓
   // B Channel Response
   //--------------------------------------------------------------------------

   virtual task drive_write(axi4lite_txn txn);

      // Drive address and data channels concurrently
      fork
         drive_write_address(txn);
         drive_write_data(txn);
      join

      wait_write_response(txn);

   endtask

   //--------------------------------------------------------------------------
   // Write Address Channel
   //
   // Drives:
   //   AWADDR
   //   AWPROT
   //   AWVALID
   //
   // Waits until AWREADY handshake occurs.
   //--------------------------------------------------------------------------

   virtual task drive_write_address(axi4lite_txn txn);

      vif.driver_cb.AWADDR  <= txn.addr;
      vif.driver_cb.AWPROT  <= txn.prot;
      vif.driver_cb.AWVALID <= 1'b1;

      do begin
         @(vif.driver_cb);
      end
      while (!vif.driver_cb.AWREADY);

      // Return channel to idle
      vif.driver_cb.AWVALID <= 1'b0;
      vif.driver_cb.AWADDR  <= '0;
      vif.driver_cb.AWPROT  <= '0;

   endtask

   //--------------------------------------------------------------------------
   // Write Data Channel
   //
   // Drives:
   //   WDATA
   //   WSTRB
   //   WVALID
   //
   // Waits until WREADY handshake occurs.
   //--------------------------------------------------------------------------

   virtual task drive_write_data(axi4lite_txn txn);

      vif.driver_cb.WDATA  <= txn.data;
      vif.driver_cb.WSTRB  <= txn.strb;
      vif.driver_cb.WVALID <= 1'b1;

      do begin
         @(vif.driver_cb);
      end
      while (!vif.driver_cb.WREADY);

      // Return channel to idle
      vif.driver_cb.WVALID <= 1'b0;
      vif.driver_cb.WDATA  <= '0;
      vif.driver_cb.WSTRB  <= '0;

   endtask

   //--------------------------------------------------------------------------
   // Write Response Phase
   //
   // Waits for:
   //   BVALID
   //
   // Captures:
   //   BRESP
   //
   // Includes timeout protection.
   //--------------------------------------------------------------------------

   virtual task wait_write_response(axi4lite_txn txn);

      int timeout_count = 0;

      vif.driver_cb.BREADY <= 1'b1;

      while (!vif.driver_cb.BVALID) begin

         @(vif.driver_cb);

         timeout_count++;

         if (timeout_count > TIMEOUT_CYCLES) begin

            `uvm_error(get_type_name(),"Timeout waiting for BVALID")

            vif.driver_cb.BREADY <= 1'b0;
            return;

         end

      end

      txn.resp = vif.driver_cb.BRESP;

      // Report protocol response errors
      if (txn.resp != 2'b00) begin

        `uvm_warning(get_type_name(), $sformatf("Write Response Error = %0h",txn.resp))

      end

      @(vif.driver_cb);

      vif.driver_cb.BREADY <= 1'b0;

   endtask

   //--------------------------------------------------------------------------
   // Complete Read Transaction
   //
   // AXI4-Lite Read Flow:
   //
   // AR Channel
   //      ↓
   // R Channel
   //--------------------------------------------------------------------------

   virtual task drive_read(axi4lite_txn txn);

      drive_read_address(txn);

      wait_read_data(txn);

   endtask

   //--------------------------------------------------------------------------
   // Read Address Channel
   //
   // Drives:
   //   ARADDR
   //   ARPROT
   //   ARVALID
   //
   // Waits for ARREADY handshake.
   //--------------------------------------------------------------------------

   virtual task drive_read_address(axi4lite_txn txn);

      vif.driver_cb.ARADDR  <= txn.addr;
      vif.driver_cb.ARPROT  <= txn.prot;
      vif.driver_cb.ARVALID <= 1'b1;

      do begin
         @(vif.driver_cb);
      end
      while (!vif.driver_cb.ARREADY);

      // Return channel to idle
      vif.driver_cb.ARVALID <= 1'b0;
      vif.driver_cb.ARADDR  <= '0;
      vif.driver_cb.ARPROT  <= '0;

   endtask

   //--------------------------------------------------------------------------
   // Read Data Phase
   //
   // Waits for:
   //   RVALID
   //
   // Captures:
   //   RDATA
   //   RRESP
   //
   // Includes timeout protection.
   //--------------------------------------------------------------------------

   virtual task wait_read_data(axi4lite_txn txn);

      int timeout_count = 0;

      vif.driver_cb.RREADY <= 1'b1;

      while (!vif.driver_cb.RVALID) begin

         @(vif.driver_cb);

         timeout_count++;

         if (timeout_count > TIMEOUT_CYCLES) begin

            `uvm_error(get_type_name(),"Timeout waiting for RVALID")

            vif.driver_cb.RREADY <= 1'b0;
            return;

         end

      end

      txn.data = vif.driver_cb.RDATA;
      txn.resp = vif.driver_cb.RRESP;

      if (txn.resp != 2'b00) begin

        `uvm_warning(get_type_name(), $sformatf("Read Response Error = %0h",txn.resp))

      end

      @(vif.driver_cb);

      vif.driver_cb.RREADY <= 1'b0;

   endtask

   //--------------------------------------------------------------------------
   // Reset Monitoring Thread
   //
   // Detects asynchronous reset events and immediately
   // returns interface to idle state.
   //--------------------------------------------------------------------------

   virtual task reset_monitor();

      forever begin

         @(negedge vif.rst_n);

         `uvm_info(get_type_name(),"Reset asserted - clearing driver signals",UVM_MEDIUM)

         initialize_signals();

         @(posedge vif.rst_n);

         `uvm_info(get_type_name(),"Reset deasserted",UVM_MEDIUM)

      end

   endtask

endclass : axi4lite_driver
