`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : axi4_lite_slave
//
// Description: Simplified AXI4-Lite Slave implementing a 32 x 32-bit register bank.
//
// Features:
// - Supports AXI4-Lite Read and Write transactions
// - 32 memory-mapped registers
// - Byte-wise write support using WSTRB
// - Single outstanding transaction
// - OKAY response only
//
// Design Assumptions:
// 1. AW and W channels arrive together.
// 2. Only one transaction is serviced at a time.
// 3. Write requests have priority over reads.
// 4. No burst support (AXI4-Lite compliant).
//
// Register Map:
// Register 0  -> Address 0x00
// Register 1  -> Address 0x04
// ...
// Register 31 -> Address 0x7C
//
// Suitable for educational, FPGA learning,
// and UVM verification portfolio projects.
//////////////////////////////////////////////////////////////////////////////////

module axi4_lite_slave #(
    parameter ADDRESS    = 32,
    parameter DATA_WIDTH = 32 )(
   
    //----------------------------------------------------------------------
    // Global Signals
    //----------------------------------------------------------------------
    input                           ACLK,
    input                           ARESETN,

    //----------------------------------------------------------------------
    // AXI Read Address Channel
    //----------------------------------------------------------------------
    input  [ADDRESS-1:0]            S_ARADDR,
    input                           S_ARVALID,

    //----------------------------------------------------------------------
    // AXI Read Data Channel
    //----------------------------------------------------------------------
    input                           S_RREADY,

    //----------------------------------------------------------------------
    // AXI Write Address Channel
    //----------------------------------------------------------------------
    input  [ADDRESS-1:0]            S_AWADDR,
    input                           S_AWVALID,

    //----------------------------------------------------------------------
    // AXI Write Data Channel
    //----------------------------------------------------------------------
    input  [DATA_WIDTH-1:0]         S_WDATA,
    input  [3:0]                    S_WSTRB,
    input                           S_WVALID,

    //----------------------------------------------------------------------
    // AXI Write Response Channel
    //----------------------------------------------------------------------
    input                           S_BREADY,

    //----------------------------------------------------------------------
    // AXI Read Address Channel Outputs
    //----------------------------------------------------------------------
    output logic                    S_ARREADY,

    //----------------------------------------------------------------------
    // AXI Read Data Channel Outputs
    //----------------------------------------------------------------------
    output logic [DATA_WIDTH-1:0]   S_RDATA,
    output logic [1:0]              S_RRESP,
    output logic                    S_RVALID,

    //----------------------------------------------------------------------
    // AXI Write Address/Data Channel Outputs
    //----------------------------------------------------------------------
    output logic                    S_AWREADY,
    output logic                    S_WREADY,

    //----------------------------------------------------------------------
    // AXI Write Response Channel Outputs
    //----------------------------------------------------------------------
    output logic [1:0]              S_BRESP,
    output logic                    S_BVALID );

    //--------------------------------------------------------------------------
    // Local Parameters
    //
    // NO_OF_REGISTERS : Total slave registers
    // ADDR_LSB        : Word alignment boundary for 32-bit data
    // REG_ADDR_BITS   : Number of bits needed to index 32 registers
    //--------------------------------------------------------------------------

    localparam int NO_OF_REGISTERS = 32;
    localparam int ADDR_LSB        = 2;
    localparam int REG_ADDR_BITS   = 5;

    //--------------------------------------------------------------------------
    // Register Bank
    //
    // Internal memory-mapped register file.
    // Each register is 32 bits wide.
    //--------------------------------------------------------------------------

    logic [DATA_WIDTH-1:0] register [0:NO_OF_REGISTERS-1];

    // Captured read address
    logic [ADDRESS-1:0] addr;

    // Write handshake indicators
    logic write_addr;
    logic write_data;

    // Register indices extracted from AXI addresses
    logic [REG_ADDR_BITS-1:0] wr_index;
    logic [REG_ADDR_BITS-1:0] rd_index;

    //----------------------------------------------------------------------
    // Address Decoding
    //
    // Address bits [6:2] select one of 32 registers.
    // Example:
    //   0x00 -> Register 0
    //   0x04 -> Register 1
    //   ...
    //   0x7C -> Register 31
    //----------------------------------------------------------------------

    assign wr_index = S_AWADDR[ADDR_LSB + REG_ADDR_BITS - 1 : ADDR_LSB];
    assign rd_index = addr    [ADDR_LSB + REG_ADDR_BITS - 1 : ADDR_LSB];

    //--------------------------------------------------------------------------
    // FSM Declaration
    // Controls AXI-Lite transaction sequencing.
    //--------------------------------------------------------------------------

    typedef enum logic [2:0] {
        IDLE,            // Waiting for transaction
        WRITE_CHANNEL,   // Accept write address/data
        WRESP_CHANNEL,   // Send write response
        RADDR_CHANNEL,   // Accept read address
        RDATA_CHANNEL    // Return read data
    } state_type;

    state_type state, next_state;

    //--------------------------------------------------------------------------
    // Handshake Detection
    //
    // AXI transfer occurs only when VALID and READY are both high.
    //--------------------------------------------------------------------------

    assign write_addr = S_AWVALID && S_AWREADY;
    assign write_data = S_WVALID  && S_WREADY;

    //--------------------------------------------------------------------------
    // AXI Output Logic
    //
    // Outputs are generated directly from FSM state.
    //--------------------------------------------------------------------------

    //---------------- Read Address Channel ----------------

    assign S_ARREADY = (state == RADDR_CHANNEL);

    //---------------- Read Data Channel -------------------

    assign S_RVALID  = (state == RDATA_CHANNEL);

    // Return selected register data during read phase
    assign S_RDATA   = (state == RDATA_CHANNEL) ? register[rd_index] :'0;

    assign S_RRESP = 2'b00; // OKAY response

    //---------------- Write Address/Data Channel ----------

    assign S_AWREADY = (state == WRITE_CHANNEL);
    assign S_WREADY  = (state == WRITE_CHANNEL);

    //---------------- Write Response Channel --------------

    assign S_BVALID = (state == WRESP_CHANNEL);
    assign S_BRESP  = 2'b00; // OKAY response

    //--------------------------------------------------------------------------
    // Register Read/Write Logic
    //
    // Responsibilities:
    // - Reset register bank
    // - Capture read address
    // - Perform byte-wise writes using WSTRB
    //--------------------------------------------------------------------------

    integer i;
    integer byte_lane;

    always_ff @(posedge ACLK) begin

        if (!ARESETN) begin

            //--------------------------------------------------------------
            // Reset all registers and internal address storage
            //--------------------------------------------------------------

            addr <= '0;

            for (i = 0; i < NO_OF_REGISTERS; i++) begin
                register[i] <= '0;
            end

        end
        else begin

            //--------------------------------------------------------------
            // Read Address Capture
            //
            // Store incoming read address for later data lookup.
            //--------------------------------------------------------------

          if (state == RADDR_CHANNEL && S_ARVALID && S_ARREADY) begin

                addr <= S_ARADDR;

            end

            //--------------------------------------------------------------
            // Write Operation
            //
            // WSTRB enables byte-level updates.
            //
            // Example:
            // WSTRB = 4'b0101
            // Updates Byte0 and Byte2 only.
            //--------------------------------------------------------------

          if (state == WRITE_CHANNEL && write_addr && write_data) begin

                for (byte_lane = 0; byte_lane < 4; byte_lane++) begin

                    if (S_WSTRB[byte_lane]) begin

                      register[wr_index] [8*byte_lane +: 8] <= S_WDATA [8*byte_lane +: 8];

                    end
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // State Register
    //
    // Stores current FSM state.
    //--------------------------------------------------------------------------

    always_ff @(posedge ACLK) begin

        if (!ARESETN)
            state <= IDLE;
        else
            state <= next_state;

    end

    //--------------------------------------------------------------------------
    // Next-State Logic
    //
    // AXI4-Lite transaction flow:
    //
    // Write: IDLE -> WRITE_CHANNEL -> WRESP_CHANNEL -> IDLE
    //
    // Read: IDLE -> RADDR_CHANNEL -> RDATA_CHANNEL -> IDLE
    //--------------------------------------------------------------------------

    always_comb begin

        next_state = state;

        case (state)

            //--------------------------------------------------------------
            // IDLE
            //
            // Write requests have priority over read requests.
            //--------------------------------------------------------------
            IDLE: begin

                if (S_AWVALID)
                    next_state = WRITE_CHANNEL;

                else if (S_ARVALID)
                    next_state = RADDR_CHANNEL;

            end

            //--------------------------------------------------------------
            // Read Address Phase
            //--------------------------------------------------------------
            RADDR_CHANNEL: begin
                if (S_ARVALID && S_ARREADY)
                    next_state = RDATA_CHANNEL;

            end

            //--------------------------------------------------------------
            // Read Data Phase
            //--------------------------------------------------------------
            RDATA_CHANNEL: begin
                if (S_RVALID && S_RREADY)
                    next_state = IDLE;

            end

            //--------------------------------------------------------------
            // Write Address/Data Phase
            //--------------------------------------------------------------
            WRITE_CHANNEL: begin
                if (write_addr && write_data)
                    next_state = WRESP_CHANNEL;

            end

            //--------------------------------------------------------------
            // Write Response Phase
            //--------------------------------------------------------------
            WRESP_CHANNEL: begin
                if (S_BVALID && S_BREADY)
                    next_state = IDLE;

            end

            //--------------------------------------------------------------
            // Safety Recovery
            //--------------------------------------------------------------
            default: begin
                next_state = IDLE;
            end

        endcase
    end

endmodule
