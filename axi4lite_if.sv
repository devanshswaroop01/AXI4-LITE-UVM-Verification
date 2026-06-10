`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Interface Name : axi4lite_if
// Description: AXI4-Lite interface used to connect:
//
//   - DUT (AXI4-Lite Slave)
//   - UVM Driver
//   - UVM Monitor
//
// Features:
//   - Complete AXI4-Lite channel definition
//   - Driver clocking block for race-free stimulus
//   - Monitor clocking block for synchronized sampling
//   - Dedicated modports for Driver, Monitor and DUT
//
// Supported Channels:
//   - Write Address  (AW)
//   - Write Data     (W)
//   - Write Response (B)
//   - Read Address   (AR)
//   - Read Data      (R)
//
// Suitable for UVM-based AXI4-Lite verification environments.
//////////////////////////////////////////////////////////////////////////////////

interface axi4lite_if (
    input logic clk,
    input logic rst_n );

   //--------------------------------------------------------------------------
   // Write Address Channel (AW)
   //
   // Carries write address and protection information from master to slave.
   //--------------------------------------------------------------------------

   logic [31:0] AWADDR;
   logic [2:0]  AWPROT;
   logic        AWVALID;
   logic        AWREADY;

   //--------------------------------------------------------------------------
   // Write Data Channel (W)
   //
   // Carries write data and byte-enable strobes.
   // WSTRB allows partial-byte updates.
   //--------------------------------------------------------------------------

   logic [31:0] WDATA;
   logic [3:0]  WSTRB;
   logic        WVALID;
   logic        WREADY;

   //--------------------------------------------------------------------------
   // Write Response Channel (B)
   //
   // Slave returns write completion status.
   //--------------------------------------------------------------------------

   logic [1:0]  BRESP;
   logic        BVALID;
   logic        BREADY;

   //--------------------------------------------------------------------------
   // Read Address Channel (AR)
   //
   // Carries read address and protection information.
   //--------------------------------------------------------------------------

   logic [31:0] ARADDR;
   logic [2:0]  ARPROT;
   logic        ARVALID;
   logic        ARREADY;

   //--------------------------------------------------------------------------
   // Read Data Channel (R)
   //
   // Slave returns requested read data and response.
   //--------------------------------------------------------------------------

   logic [31:0] RDATA;
   logic [1:0]  RRESP;
   logic        RVALID;
   logic        RREADY;

   //--------------------------------------------------------------------------
   // Driver Clocking Block
   // Used by the UVM driver.
   //
   // Benefits:
   // - Eliminates race conditions
   // - Drives outputs after clock edge
   // - Samples DUT outputs in a controlled manner
   //--------------------------------------------------------------------------

   clocking driver_cb @(posedge clk);

      // Sample inputs immediately after clock edge
      // Drive outputs slightly later
      default input #1step output #1ns;

      //---------------- Write Address ----------------

      output AWADDR, AWPROT, AWVALID;
      input  AWREADY;

      //---------------- Write Data -------------------

      output WDATA, WSTRB, WVALID;
      input  WREADY;

      //---------------- Write Response ---------------

      input  BRESP, BVALID;
      output BREADY;

      //---------------- Read Address -----------------

      output ARADDR, ARPROT, ARVALID;
      input  ARREADY;

      //---------------- Read Data --------------------

      input  RDATA, RRESP, RVALID;
      output RREADY;

   endclocking

   //--------------------------------------------------------------------------
   // Monitor Clocking Block
   // Used by the UVM monitor.
   //
   // Purpose:
   // - Samples all AXI signals synchronously
   // - Captures complete transactions
   // - Provides stable observations for scoreboard,
   //   coverage, and reference model
   //--------------------------------------------------------------------------

   clocking monitor_cb @(posedge clk);

      default input #1step;

      //---------------- Write Address ----------------

      input AWADDR, AWPROT, AWVALID, AWREADY;

      //---------------- Write Data -------------------

      input WDATA, WSTRB, WVALID, WREADY;

      //---------------- Write Response ---------------

      input BRESP, BVALID, BREADY;

      //---------------- Read Address -----------------

      input ARADDR, ARPROT, ARVALID, ARREADY;

      //---------------- Read Data --------------------

      input RDATA, RRESP, RVALID, RREADY;

   endclocking

   //--------------------------------------------------------------------------
   // Modports
   //
   // Provide controlled access to interface signals for different components.
   //--------------------------------------------------------------------------

   //--------------------------------------------------------------------------
   // DRIVER Modport
   //
   // Used by UVM Driver
   // Accesses signals through driver_cb clocking block.
   //--------------------------------------------------------------------------

   modport DRIVER (
      clocking driver_cb,
      input clk,
      input rst_n );

   //--------------------------------------------------------------------------
   // MONITOR Modport
   //
   // Used by UVM Monitor
   // Accesses signals through monitor_cb clocking block.
   //--------------------------------------------------------------------------

   modport MONITOR (
      clocking monitor_cb,
      input clk,
      input rst_n);

   //--------------------------------------------------------------------------
   // DUT Modport
   //
   // Connects AXI4-Lite Slave DUT to the interface.
   //
   // Signal directions are defined from the DUT's point of view.
   //--------------------------------------------------------------------------

   modport DUT (

      //---------------- Write Address Channel --------

      input  AWADDR,
      input  AWPROT,
      input  AWVALID,
      output AWREADY,

      //---------------- Write Data Channel -----------

      input  WDATA,
      input  WSTRB,
      input  WVALID,
      output WREADY,

      //---------------- Write Response Channel -------

      output BRESP,
      output BVALID,
      input  BREADY,

      //---------------- Read Address Channel ---------

      input  ARADDR,
      input  ARPROT,
      input  ARVALID,
      output ARREADY,

      //---------------- Read Data Channel ------------

      output RDATA,
      output RRESP,
      output RVALID,
      input  RREADY,

      //---------------- Global Signals --------------

      input  clk,
      input  rst_n);

endinterface 
