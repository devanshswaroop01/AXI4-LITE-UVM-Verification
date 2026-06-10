`ifndef AXI4LITE_PKG_SV
`define AXI4LITE_PKG_SV

//////////////////////////////////////////////////////////////////////////////////
// Package Name : axi4lite_pkg
// Description:Central package for the AXI4-Lite UVM Verification Environment.
//
// Purpose:
//   - Provides a single compilation unit for all UVM classes
//   - Defines the verification environment hierarchy
//   - Controls dependency ordering between components
//   - Simplifies testbench compilation and maintenance
//
// Architecture Overview:
//
//                AXI4LITE_PKG
//                       │
//      ┌────────────────┼────────────────┐
//      │                │                │
//      ▼                ▼                ▼
// Transaction      Agent Layer      Environment
//      │                │                │
//      ▼                ▼                ▼
// Sequences       Driver/Monitor     RefModel
//      │                │             Scoreboard
//      ▼                │             Coverage
//      └────────────────┴─────────────────┐
//                                         ▼
//                                      Tests
//
// Notes:
//
//   - Every UVM class is compiled through this package.
//   - Include order is intentional and dependency-driven.
//   - Changing include order may introduce compilation errors.
//   - Serves as the single import point:
//
//         import axi4lite_pkg::*;
//
//   - All tests, sequences, agents, and environment components
//     become visible after package import.
//
//////////////////////////////////////////////////////////////////////////////////

package axi4lite_pkg;

   //===========================================================================
   // UVM Infrastructure
   //===========================================================================
   //
   // Imports:
   //   - UVM base classes
   //   - TLM infrastructure
   //   - Factory support
   //   - Reporting infrastructure
   //
   // Macros:
   //   - Factory registration
   //   - Field automation
   //   - Reporting macros
   //
   //===========================================================================

   import uvm_pkg::*;

   `include "uvm_macros.svh"

   //===========================================================================
   // Transaction Layer
   //===========================================================================
   //
   // Fundamental transaction object used by:
   //
   //   Sequence
   //      ↓
   //   Sequencer
   //      ↓
   //   Driver
   //      ↓
   //   Monitor
   //      ↓
   //   RefModel / Coverage / Scoreboard
   //
   // Must be compiled first because most classes depend on it.
   //
   //===========================================================================

   `include "axi4lite_txn.sv"

   //===========================================================================
   // Configuration Layer
   //===========================================================================
   //
   // Configuration objects control:
   //
   //   - Agent mode
   //   - Coverage enable
   //   - Scoreboard enable
   //   - Protocol checking enable
   //
   // Used during build_phase().
   //
   //===========================================================================

   `include "axi4lite_agent_cfg.sv"
   `include "axi4lite_env_cfg.sv"

   //===========================================================================
   // Reference Model
   //===========================================================================
   //
   // Golden functional model.
   //
   // Responsibilities:
   //   - Register memory modeling
   //   - WSTRB handling
   //   - Read prediction
   //   - Write prediction
   //
   // Generates expected transactions for the scoreboard.
   //
   //===========================================================================

   `include "axi4lite_ref_model.sv"

   //===========================================================================
   // Scoreboard
   //===========================================================================
   //
   // Functional checking engine.
   //
   // Compares:
   //
   //   Expected Transactions
   //           vs
   //   Actual Transactions
   //
   // Produces PASS / FAIL verification results.
   //
   //===========================================================================

   `include "axi4lite_scoreboard.sv"

   //===========================================================================
   // Functional Coverage
   //===========================================================================
   //
   // Measures verification completeness.
   //
   // Coverage Areas:
   //   - Address coverage
   //   - Transaction coverage
   //   - WSTRB coverage
   //   - RAW coverage
   //   - Protocol coverage
   //
   //===========================================================================

   `include "axi4lite_coverage.sv"

   //===========================================================================
   // Agent Layer
   //===========================================================================
   //
   // Active AXI4-Lite verification agent.
   //
   // Components:
   //
   //      Agent
   //        │
   //   ┌────┴────┐
   //   │         │
   // Driver   Monitor
   //   │
   // Sequencer
   //
   //===========================================================================

   `include "axi4lite_sequencer.sv"
   `include "axi4lite_driver.sv"
   `include "axi4lite_monitor.sv"
   `include "axi4lite_agent.sv"

   //===========================================================================
   // Environment Layer
   //===========================================================================
   //
   // Top-level reusable verification environment.
   //
   // Integrates:
   //
   //   Agent
   //   Coverage
   //   Reference Model
   //   Scoreboard
   //
   //===========================================================================

   `include "axi4lite_env.sv"

   //===========================================================================
   // Sequence Library
   //===========================================================================
   //
   // Stimulus generation layer.
   //
   // Includes:
   //
   //   Base Sequences
   //   Single Read/Write Sequences
   //   Directed Sequences
   //   Random Sequences
   //   Stress Sequences
   //   WSTRB Sequences
   //
   // Sequence Library Structure:
   //
   //   axi4lite_base_seq
   //           │
   //   ┌───────┼────────┐
   //   │       │        │
   // Directed Random  Stress
   //
   //===========================================================================

   // Individual sequence includes consolidated into a
   // single sequence library file.

   `include "axi4lite_seq_lib.sv"

   //===========================================================================
   // Test Layer
   //===========================================================================
   //
   // Verification scenarios built on top of the environment.
   //
   // Test Hierarchy:
   //
   //   axi4lite_base_test
   //          │
   //   ┌──────┼───────────────┐
   //   │      │       │       │
   // Sanity Directed Random Stress
   //                     │
   //                 Boundary
   //
   // Responsibilities:
   //   - Configure environment
   //   - Start sequences
   //   - Define verification goals
   //
   //===========================================================================

   `include "axi4lite_base_test.sv"

   `include "axi4lite_sanity_test.sv"
   `include "axi4lite_directed_test.sv"
   `include "axi4lite_random_test.sv"
   `include "axi4lite_stress_test.sv"

   `include "axi4lite_boundary_test.sv"

endpackage : axi4lite_pkg

`endif 
