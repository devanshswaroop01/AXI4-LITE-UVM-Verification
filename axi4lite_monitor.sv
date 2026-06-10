
//////////////////////////////////////////////////////////////////////////////////
// Class Name : axi4lite_monitor
//
// Description:
// AXI4-Lite Monitor responsible for observing DUT bus activity and
// reconstructing protocol-level transactions.
//
// Responsibilities:
//   - Observe AXI4-Lite interface activity
//   - Reconstruct completed READ and WRITE transactions
//   - Capture protocol responses
//   - Timestamp transaction execution
//   - Publish transactions through analysis port
//
// Transaction Flow:
//
// DUT Activity
//       ↓
// AXI Monitor
//       ↓
// Analysis Port
//       ↓
// Environment Components
//    ├── Scoreboard
//    ├── Reference Model
//    └── Coverage
//
// Notes:
//   - Passive component
//   - Never drives DUT signals
//   - Operates independently of agent mode
//   - Supports transaction-level abstraction
//////////////////////////////////////////////////////////////////////////////////

class axi4lite_monitor extends uvm_monitor;

   //--------------------------------------------------------------------------
   // Factory Registration
   //--------------------------------------------------------------------------

   `uvm_component_utils(axi4lite_monitor)

   //--------------------------------------------------------------------------
   // Virtual Interface
   //
   // Provides access to DUT interface signals through the monitor clocking block.
   //--------------------------------------------------------------------------

   virtual axi4lite_if vif;

   //--------------------------------------------------------------------------
   // Analysis Port
   //
   // Broadcasts reconstructed transactions to:
   //   - Scoreboard
   //   - Reference Model
   //   - Coverage Collector
   //--------------------------------------------------------------------------

   uvm_analysis_port #(axi4lite_txn) item_collected_port;

   //--------------------------------------------------------------------------
   // Timeout Protection
   //
   // Prevents monitor lockup if protocol handshakes never complete.
   //--------------------------------------------------------------------------

   localparam int TIMEOUT_CYCLES = 1000;

   //--------------------------------------------------------------------------
   // Constructor
   //--------------------------------------------------------------------------

   function new(
      string name = "axi4lite_monitor",
      uvm_component parent = null   );
      super.new(name, parent);
   endfunction

   //--------------------------------------------------------------------------
   // Build Phase
   //
   // Creates analysis port and retrieves virtual interface.
   //--------------------------------------------------------------------------

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      item_collected_port = new("item_collected_port", this);

     if (!uvm_config_db #(virtual axi4lite_if)::get( this,"","vif",vif))
        
      begin
         `uvm_fatal(get_type_name(),"Virtual interface not found in config DB")

      end

   endfunction

   //--------------------------------------------------------------------------
   // Run Phase
   //
   // Launch independent collection threads for:
   //   - Write transactions
   //   - Read transactions
   //
   // Allows simultaneous observation of both channels.
   //--------------------------------------------------------------------------

   virtual task run_phase(uvm_phase phase);

      fork
         collect_write_transactions();
         collect_read_transactions();
      join

   endtask

   //--------------------------------------------------------------------------
   // Write Transaction Collection
   //
   // AXI4-Lite Write Reconstruction Flow:
   //
   // AW Handshake
   //      ↓
   // W Handshake
   //      ↓
   // B Handshake
   //      ↓
   // Build Transaction
   //      ↓
   // Publish Transaction
   //--------------------------------------------------------------------------

   virtual task collect_write_transactions();

      axi4lite_txn txn;

      //-----------------------------------------------------------------------
      // Temporary storage for transaction reconstruction
      //-----------------------------------------------------------------------

      bit [31:0] addr;
      bit [31:0] data;
      bit [3:0]  strb;
      bit [2:0]  prot;
      bit [1:0]  resp;

      time start_time;
      time end_time;

      int timeout;

      forever begin

         //--------------------------------------------------------------------
         // Ignore activity during reset
         //--------------------------------------------------------------------

         wait(vif.rst_n);

         //--------------------------------------------------------------------
         // Capture Write Address Phase
         //
         // Transaction begins when AWVALID and AWREADY handshake.
         //--------------------------------------------------------------------

         @(posedge vif.clk iff
           (vif.monitor_cb.AWVALID && vif.monitor_cb.AWREADY));

         addr       = vif.monitor_cb.AWADDR;
         prot       = vif.monitor_cb.AWPROT;
         start_time = $time;

         //--------------------------------------------------------------------
         // Capture Write Data Phase
         //
         // Data and byte-enable information are collected
         // once WVALID/WREADY handshake occurs.
         //--------------------------------------------------------------------

        if (vif.monitor_cb.WVALID && vif.monitor_cb.WREADY)
         begin

            data = vif.monitor_cb.WDATA;
            strb = vif.monitor_cb.WSTRB;

         end
         else begin

            timeout = 0;

           while (!(vif.monitor_cb.WVALID && vif.monitor_cb.WREADY))
            begin

               @(posedge vif.clk);

               timeout++;

               if (timeout > TIMEOUT_CYCLES) begin

                  `uvm_error(get_type_name(),"Timeout waiting for W handshake")

                  break;
               end
            end

            data = vif.monitor_cb.WDATA;
            strb = vif.monitor_cb.WSTRB;

         end

         //--------------------------------------------------------------------
         // Capture Write Response Phase
         //
         // Wait until BVALID/BREADY handshake completes.
         //--------------------------------------------------------------------

         timeout = 0;

        while (!(vif.monitor_cb.BVALID && vif.monitor_cb.BREADY))
         begin

            @(posedge vif.clk);

            timeout++;

            if (timeout > TIMEOUT_CYCLES) begin

               `uvm_error(get_type_name(),"Timeout waiting for B handshake")

               break;
            end

         end

         resp     = vif.monitor_cb.BRESP;
         end_time = $time;

         //--------------------------------------------------------------------
         // Construct Transaction Object
         //--------------------------------------------------------------------

        txn = axi4lite_txn::type_id::create( $sformatf("write_txn_%0t",$time));

         txn.txn_type = WRITE;

         txn.addr = addr;
         txn.data = data;
         txn.strb = strb;
         txn.prot = prot;
         txn.resp = resp;

         txn.start_time = start_time;
         txn.end_time   = end_time;

         //--------------------------------------------------------------------
         // Report Collected Transaction
         //--------------------------------------------------------------------

        `uvm_info(get_type_name(), $sformatf("Collected WRITE Transaction\n%s",
                       txn.convert2string()),UVM_MEDIUM)

         //--------------------------------------------------------------------
         // Broadcast Transaction
         //--------------------------------------------------------------------

         item_collected_port.write(txn);

      end

   endtask

   //--------------------------------------------------------------------------
   // Read Transaction Collection
   //
   // AXI4-Lite Read Reconstruction Flow:
   //
   // AR Handshake
   //      ↓
   // R Handshake
   //      ↓
   // Build Transaction
   //      ↓
   // Publish Transaction
   //--------------------------------------------------------------------------

   virtual task collect_read_transactions();

      axi4lite_txn txn;

      bit [31:0] addr;
      bit [31:0] data;
      bit [2:0]  prot;
      bit [1:0]  resp;

      time start_time;
      time end_time;

      int timeout;

      forever begin

         //--------------------------------------------------------------------
         // Ignore activity during reset
         //--------------------------------------------------------------------

         wait(vif.rst_n);

         //--------------------------------------------------------------------
         // Capture Read Address Phase
         //--------------------------------------------------------------------

         @(posedge vif.clk iff
           (vif.monitor_cb.ARVALID && vif.monitor_cb.ARREADY));

         addr       = vif.monitor_cb.ARADDR;
         prot       = vif.monitor_cb.ARPROT;
         start_time = $time;

         //--------------------------------------------------------------------
         // Wait for Read Data Response
         //--------------------------------------------------------------------

         timeout = 0;

        while (!(vif.monitor_cb.RVALID && vif.monitor_cb.RREADY))
         begin

            @(posedge vif.clk);

            timeout++;

            if (timeout > TIMEOUT_CYCLES) begin

               `uvm_error(get_type_name(),"Timeout waiting for R handshake")

               break;
            end

         end

         data = vif.monitor_cb.RDATA;
         resp = vif.monitor_cb.RRESP;

         end_time = $time;

         //--------------------------------------------------------------------
         // Construct Transaction Object
         //--------------------------------------------------------------------

        txn = axi4lite_txn::type_id::create( $sformatf("read_txn_%0t",$time));

         txn.txn_type = READ;

         txn.addr = addr;
         txn.data = data;
         txn.prot = prot;
         txn.resp = resp;

         txn.start_time = start_time;
         txn.end_time   = end_time;

         //--------------------------------------------------------------------
         // Report Collected Transaction
         //--------------------------------------------------------------------

        `uvm_info(get_type_name(), $sformatf( "Collected READ Transaction\n%s",
                      txn.convert2string()),UVM_MEDIUM )

         //--------------------------------------------------------------------
         // Broadcast Transaction
         //--------------------------------------------------------------------

         item_collected_port.write(txn);

      end

   endtask

   //--------------------------------------------------------------------------
   // Optional Protocol Checker
   //
   // Reserved for future runtime protocol checks.
   // Current protocol checking is handled through SVA.
   //--------------------------------------------------------------------------

   virtual task check_protocol_violations();

      // Placeholder for future enhancements

   endtask

endclass : axi4lite_monitor 
