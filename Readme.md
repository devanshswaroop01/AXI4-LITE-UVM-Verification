# AXI4-Lite Slave Verification  UVM
---

# Project Overview

This project implements a complete **UVM-based verification environment** for an **AXI4-Lite Slave** design.

The objective is to verify both:

* Functional correctness of the RTL
* Compliance with the AXI4-Lite protocol

using industry-standard verification methodologies.

The environment includes:

* UVM Agent Architecture
* Constrained-Random Stimulus
* Functional Coverage
* Reference Model
* Scoreboard
* Protocol Assertions (SVA)
* Directed and Random Testing
* Stress and Boundary Verification

---

# What is AXI4-Lite?

AXI4-Lite is a simplified version of the AMBA AXI protocol used for:

* Register access
* Peripheral configuration
* Control interfaces
* Low-bandwidth communication

Unlike full AXI4, AXI4-Lite:

* Supports only single-beat transactions
* Has no burst transfers
* Uses simple memory-mapped register accesses

It is commonly used inside:

* SoCs
* Microcontrollers
* FPGA designs
* Embedded systems

---

# Project Goals

The verification environment validates:

✅ Register Write Operations

✅ Register Read Operations

✅ Address Decoding

✅ Reset Behavior

✅ WSTRB (Byte Enable) Handling

✅ AXI Handshake Compliance

✅ Response Generation

✅ Protocol Timing Rules

✅ Functional Coverage Closure

---

# DUT Overview

### Device Under Test

AXI4-Lite Slave Register Bank

### Configuration

| Parameter     | Value       |
| ------------- | ----------- |
| Address Width | 32-bit      |
| Data Width    | 32-bit      |
| Registers     | 32          |
| Address Range | 0x00 - 0x7C |

### Register Map

| Register | Address |
| -------- | ------- |
| Reg0     | 0x00    |
| Reg1     | 0x04    |
| Reg2     | 0x08    |
| ...      | ...     |
| Reg31    | 0x7C    |

---

# Verification Architecture

```text
                    UVM TEST

                         │

                         ▼

                 AXI4LITE_ENV

                         │

     ┌──────────┬─────────────┬───────────┐

     ▼          ▼             ▼           ▼

   AGENT    REF MODEL     COVERAGE   SCOREBOARD

     │

     ▼

  SEQUENCER

     ▼

   DRIVER

     ▼

 AXI4 INTERFACE

     ▼

     DUT

     ▼

  MONITOR

     │

     ├────────► COVERAGE

     │

     ├────────► REF MODEL

     │

     └────────► SCOREBOARD
```

---

# UVM Components

## Transaction

**File:** `axi4lite_txn.sv`

Represents a complete AXI transaction.

Contains:

* Address
* Data
* Transaction Type
* WSTRB
* PROT
* Response
* Delay Cycles

Supports:

* Randomization
* Copy
* Compare
* Print
* Pack / Unpack

---

## Sequencer

**File:** `axi4lite_sequencer.sv`

Responsibilities:

* Receives transactions from sequences
* Arbitrates requests
* Supplies transactions to driver

---

## Driver

**File:** `axi4lite_driver.sv`

Responsibilities:

* Converts transactions into AXI bus activity
* Drives all AXI channels
* Waits for protocol handshakes
* Implements timing behavior

Channels Driven:

* AW
* W
* BREADY
* AR
* RREADY

---

## Monitor

**File:** `axi4lite_monitor.sv`

Responsibilities:

* Observes bus activity
* Reconstructs AXI transactions
* Broadcasts transactions through analysis ports

No DUT modification is performed.

The monitor is completely passive.

---

## Agent

**File:** `axi4lite_agent.sv`

Contains:

* Sequencer
* Driver
* Monitor

Supports:

* Active Mode
* Passive Mode

---

## Environment

**File:** `axi4lite_env.sv`

Integrates:

* Agent
* Reference Model
* Scoreboard
* Coverage Collector

Creates the complete verification architecture.

---

# Reference Model

**File:** `axi4lite_ref_model.sv`

A software model that predicts expected DUT behavior.

Features:

* 32 x 32-bit register model
* WSTRB-aware writes
* Read prediction
* Write prediction

Used to generate expected transactions.

---

# Scoreboard

**File:** `axi4lite_scoreboard.sv`

Compares:

Expected Transactions

vs

Actual Transactions

Verification checks:

* Address
* Data
* Transaction Type
* Response

Produces:

PASS / FAIL results

---

# Functional Coverage

**File:** `axi4lite_coverage.sv`

Coverage Areas:

* Address Coverage
* Transaction Type Coverage
* WSTRB Coverage
* Protocol Coverage
* Read-After-Write Coverage

Purpose:

Measure verification completeness.

---

# Assertion-Based Verification

**File:** `axi4lite_assertions.sv`

SystemVerilog Assertions continuously monitor protocol compliance.

Implemented Checks:

### Write Address Channel

* AW Stability

### Write Data Channel

* W Stability

### Write Response Channel

* B Stability

### Read Address Channel

* AR Stability

### Read Data Channel

* R Stability

### Protocol Ordering

* Write Response Ordering
* Read Response Ordering

### Reset Checks

* Reset State Validation

---

# Test Suite

## Sanity Test

Basic smoke test.

Verifies:

* Write operation
* Read operation
* End-to-end connectivity

---

## Directed Test

Verifies all registers.

Flow:

```text
WRITE Reg0 → READ Reg0

WRITE Reg1 → READ Reg1

...

WRITE Reg31 → READ Reg31
```

---

## Random Test

Constrained-random traffic generation.

Exercises:

* Random addresses
* Random data
* Random WSTRB
* Random delays

---

## Boundary Test

Verifies:

* First register (0x00)
* Last register (0x7C)

Data Patterns:

* 0x00000000
* 0xFFFFFFFF
* 0xAAAAAAAA
* 0x55555555

---

## Stress Test

High-volume traffic verification.

Includes:

* Back-to-back transactions
* Corner cases
* Long random sequences

---

# Assertions vs Scoreboard vs Coverage

Each verification component serves a different purpose.

| Component  | Purpose                   |
| ---------- | ------------------------- |
| Assertions | Protocol correctness      |
| Scoreboard | Functional correctness    |
| Coverage   | Verification completeness |

Together they provide comprehensive verification confidence.

---

# Simulation Flow

```text
Sequence

   ↓

Sequencer

   ↓

Driver

   ↓

AXI Interface

   ↓

DUT

   ↓

Monitor

   ├────► Coverage

   ├────► Reference Model

   └────► Scoreboard
```

---

# Running Simulations

Example:

```bash
run_test("axi4lite_sanity_test")
```

Available Tests:

```text
axi4lite_sanity_test

axi4lite_directed_test

axi4lite_random_test

axi4lite_boundary_test

axi4lite_stress_test
```

---

# Key Verification Concepts Demonstrated

This project demonstrates:

* SystemVerilog
* UVM
* AXI4-Lite Protocol Verification
* Constrained-Random Verification
* Scoreboard Design
* Reference Modeling
* Functional Coverage
* SystemVerilog Assertions
* Verification Planning
* Regression Testing
* Reusable UVM Architecture

---

# Skills Demonstrated

RTL Verification

UVM Methodology

Protocol Verification

Assertion-Based Verification

Functional Coverage

Scoreboard Architecture

Reference Modeling

Transaction-Level Modeling

Constrained-Random Verification

Coverage-Driven Verification

---

# Results

Verified Features:

✅ AXI Write Transactions

✅ AXI Read Transactions

✅ Register Storage

✅ Address Decoding

✅ WSTRB Handling

✅ Response Generation

✅ Protocol Compliance

✅ Functional Coverage Collection

✅ Assertion Checking

✅ Scoreboard Validation

---

# Future Enhancements

Potential extensions:

* AXI4 Full Verification
* AXI Burst Support
* AXI VIP Development
* UVM Register Model (RAL)
* Formal Property Verification
* Coverage Closure Automation

---

# Repository Structure

```text
AXI4LITE_UVM_VERIFICATION/

├── rtl/
│   └── axi4_lite_slave.sv
│
├── interface/
│   └── axi4lite_if.sv
│
├── assertions/
│   └── axi4lite_assertions.sv
│
├── uvm/
│   ├── axi4lite_txn.sv
│   ├── axi4lite_driver.sv
│   ├── axi4lite_monitor.sv
│   ├── axi4lite_sequencer.sv
│   ├── axi4lite_agent.sv
│   ├── axi4lite_ref_model.sv
│   ├── axi4lite_scoreboard.sv
│   ├── axi4lite_coverage.sv
│   ├── axi4lite_env.sv
│   └── tests/
│
└── tb/
    └── axi4lite_tb_top.sv
```

---

# Conclusion

This project implements a complete industry-style UVM verification environment for an AXI4-Lite Slave RTL design.

The environment combines:

* Reusable UVM Architecture
* Constrained-Random Stimulus
* Functional Coverage
* Reference Modeling
* Scoreboard Checking
* Protocol Assertions

to achieve high verification confidence and demonstrate modern ASIC/FPGA Design Verification methodologies.
