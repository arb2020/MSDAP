# Mini-Stereo-Digital-Audio-Processor (MSDAP)

# Introduction

This repository implements the **Mini-Stereo Digital Audio Processor (MSDAP)**, a custom ASIC designed to perform real-time FIR filtering on stereo audio input samples. The design accepts serial input data through a **Serial-to-Parallel (S2P)** converter, processes each sample using an **ALU-based FIR filter**, and serializes the output through a **Parallel-to-Serial (P2S)** converter.

The operation of the entire chip is orchestrated by a **Data Controller** finite state machine (FSM), which coordinates data flow between all subsystems: memory initialization, coefficient and parameter loading, input sample processing, output serialization, sleep mode, and reset handling.

The MSDAP architecture supports an efficient sleep mode that automatically suspends processing when a sustained sequence of zero-valued input samples is detected, and resumes upon detection of a non-zero input.

# Block Name: MSDAP

# Revisions

| Date (YYYY-MM-DD) | Version | Description of Changes | Author | Reviewer |
|-------------------|---------|------------------------|--------|----------|
| 2026-04-01 | `0.1.0` | Initial full-design documentation. | Areeb Iqbal, Arham Virendra Dodal | Dr. Alice Wang |

---

## Features

### Integration

- Integrates the **Data Controller FSM**, **S2P**, **P2S**, **ALU**, **coefficient memory**, **Rj memory**, and **x(n) circular buffer** into a single top-level module.
- Interfaces with an external serial data source via `InputL`, `InputR`, `Frame`, and `InReady`.
- Produces serial output via `OutputL` and `OutputR`.
- Supports external reset via the asynchronous `Reset_n` signal.

### Performance

- FIR filter computation runs **in parallel with input serialization**, reducing idle cycles.
- **Sleep mode** automatically disables ALU and P2S processing when 800 consecutive zero-valued input samples are detected, reducing power consumption.
- Processing resumes automatically upon detection of a non-zero input sample.

### Design

- Fully synchronous datapath on `Sclk` with a separate `Dclk` for serial data input.
- Modular RTL structure with dedicated submodules for control, arithmetic, serialization, and memory.
- FSM-based control ensures deterministic sequencing of all operations.
- Circular buffer architecture for efficient x(n) sample management.

### Debugging

- `$display` and `$strobe` statements embedded in the Data Controller to trace FSM state transitions and reset events.
- Internal counters and control signals allow step-by-step verification of datapath operations.
- Modular structure facilitates unit-level testing and waveform analysis.

---

# Top-Level Block Diagram

The top-level MSDAP module integrates the following major functional blocks:

The **Data Controller** implements the top-level FSM that manages system initialization, data loading, sample processing, sleep mode, and reset. It generates all control signals for the subsystems and coordinates data flow across clock domains.

The **S2P (Serial-to-Parallel)** block receives serial input bits from `InputL` and `InputR` on `Dclk` and assembles them into 16-bit parallel words, which are presented to the Data Controller and memories on `InputReady`.

The **Rj Memory** stores up to 16 Rj parameters used by the ALU to control the number of accumulation iterations per output sample.

The **Coefficient Memory** stores up to 512 filter coefficients used by the ALU during FIR computation.

The **x(n) Circular Buffer** stores up to 256 input samples in a circular addressing scheme, allowing the ALU to access previous samples required for the FIR filter computation.

The **ALU** performs sign extension, addition/subtraction, and shifted accumulation to compute each output sample. It is documented separately in the ALU subdirectory.

The **P2S (Parallel-to-Serial)** block receives the 40-bit ALU output and serializes it for transmission via `OutputL` and `OutputR`.

## Diagram

*(To be added)*

---

# Configuration

The `MSDAP` top-level module does not expose user-configurable parameters. Behavior is determined by the RTL implementation and the input data stream. Internal parameters such as memory depths and address widths are fixed by the implementation.

## Parameters

This module does not expose configurable top-level parameters. State encodings, memory depths, and counter widths are defined internally in the RTL.

## Typedefs

This design does not declare any typedefs, enumerations, structures, or unions.

## Interfaces

The top-level ports of the `MSDAP` module are grouped into **control**, **serial input**, and **serial output** interfaces.

### Control Interface

| Port Name | Direction | Type | Description |
|-----------|-----------|------|-------------|
| `Sclk` | Input | `wire` | System clock used for all sequential logic in the datapath and FSM. |
| `Dclk` | Input | `wire` | Data clock used for serial input sampling in the S2P block. |
| `Start` | Input | `wire` | Initializes all internal registers and resets the FSM to the `INIT_S` state. |
| `Reset_n` | Input | `wire` | Active-low asynchronous reset. Clears the x(n) buffer and returns the FSM to the `CLEARING_S` state. |

### Serial Input Interface

| Port Name | Direction | Type | Description |
|-----------|-----------|------|-------------|
| `Frame` | Input | `wire` | Indicates the start of a new 16-bit serial word. |
| `InputL` | Input | `wire` | Serial data input for the left channel. |
| `InputR` | Input | `wire` | Serial data input for the right channel. |
| `InReady` | Output | `wire` | Indicates that the chip is ready to accept input data. |

### Serial Output Interface

| Port Name | Direction | Type | Description |
|-----------|-----------|------|-------------|
| `OutputL` | Output | `wire` | Serial data output for the left channel. |
| `OutputR` | Output | `wire` | Serial data output for the right channel. |
| `OutReady` | Output | `wire` | Indicates that the chip is producing valid serial output data. |

## Design Assumptions

- Input values are **16-bit signed** serial words, transmitted MSB first.
- The ALU datapath operates on **40-bit internal precision**, producing a **40-bit output**.
- Memory depths are fixed:
  - Rj memory: 16 entries (4-bit address)
  - Coefficient memory: 512 entries (9-bit address)
  - x(n) circular buffer: 256 entries (8-bit address)
- All datapath operations are synchronous with `Sclk`.
- Serial input sampling is synchronous with `Dclk`.
- `Reset_n` is assumed to be asserted in the **first half of a data frame** to allow clean frame discarding.

---

# Clock Domains

The MSDAP design operates across **two clock domains**.

## Clock Domain Table

| Clock Domain | Nominal Frequency | Description |
|---|---|---|
| `Sclk` | 26.88 MHz (37.2 ns period) | Drives all sequential logic in the Data Controller, ALU, memories, and P2S. |
| `Dclk` | 768 kHz (1032.08 ns period) | Drives the S2P serializer for input data sampling. |

**Notes**

- All sequential elements in the Data Controller, ALU, and P2S are triggered on the **rising edge of `Sclk`**.
- The S2P block operates on `Dclk`.
- The `InReady` and `Frame` signals cross from the `Dclk` domain into the `Sclk` domain and is treated as clock domain crossing (CDC) paths.

## Annotated Block Diagram

- `Data Controller` — `Sclk` domain
- `ALU` — `Sclk` domain
- `Coefficient Memory` — `Sclk` domain
- `Rj Memory` — `Sclk` domain
- `x(n) Circular Buffer` — `Sclk` domain
- `P2S` — `Sclk` domain
- `S2P` — `Dclk` domain

---

# Reset Domains

The MSDAP design has two reset mechanisms.

## Reset Domains Table

| Reset Name | Synchronous/Asynchronous | Active High/Low | Associated Clock | Description |
|---|---|---|---|---|
| `Start` | Synchronous | Active High | `Sclk` | Initializes all registers, counters, and FSM state to known initial values at power-on or system start. |
| `Reset_n` | Asynchronous | Active Low | N/A | Clears the x(n) sample buffer and returns the FSM to `CLEARING_S`. Does not reinitialize coefficients or Rj parameters. |

## Reset Behavior

### Start Reset

When `Start` is asserted, the following are initialized on the next rising edge of `Sclk`:

- All counters (`initCounter`, `rjCounter`, `coeffCounter`, `xCounter`, `zeroCounter`) reset to zero.
- All control outputs (`en_S2P`, `en_P2S`, `en_ALU`, `EnRj`, `EnCoeff`, `EnX`, `WMode`, `xWMode`) deasserted.
- FSM transitions to `INIT_S`.

### Reset_n Reset

When `Reset_n` is deasserted (low), the following occur:

- FSM transitions to `CLEARING_S` from any active state.
- `xCounter` is reset to zero and the x(n) buffer is swept and zeroed.
- After the buffer sweep completes (`xCounter == 0xFF`), the FSM returns to `WAIT_INPUT_S`.
- Coefficient memory and Rj memory are **not** affected.

## Custom Reset Procedures

1. Assert `Reset_n = 0` at the start of a data frame (first half of frame per specification).
2. The current frame is discarded and `xCounter` is cleared.
3. The FSM enters `CLEARING_S` and sweeps the x(n) buffer to zero over 256 cycles.
4. On completion, the FSM returns to `WAIT_INPUT_S` and normal processing resumes.

---

# Arbitration, Fairness, QoS, and Forward Progress Guarantees

The MSDAP block does not implement arbitration between multiple traffic classes or concurrent transactions. All data processing follows a single sequential flow controlled by the Data Controller FSM.

## Arbitration and Fairness

- **Arbitration Policy:** None. A single computation flow is active at all times.
- **Fairness:** Not applicable. No competing requesters exist.
- **Configurability:** No arbitration or QoS configuration parameters are exposed.

## Quality-of-Service (QoS)

- **QoS Features:** None.
- **Performance:** Determined by the FSM sequencing, memory access latency, and ALU computation time.

## Forward Progress Guarantees

Forward progress is guaranteed by the deterministic state transitions of the Data Controller FSM.

- **Deadlock and Livelock Prevention:** The FSM contains a finite number of states with deterministic transitions. Each state either advances a counter toward a fixed bound or waits on an externally driven signal (`Frame`, `InputReady`, `done`, `DataDone`).
- **Sleep Mode:** The FSM enters `SLEEPING_S` when 800 consecutive zero-valued samples are detected. It exits automatically when a non-zero sample is received, ensuring forward progress resumes without external intervention.
- **Assumptions:** External logic correctly drives `Frame`, `InputReady`, `done`, and `DataDone` according to protocol.

---

# Debugging

## System Tasks for Simulation Debugging

The Data Controller includes embedded `$display` statements to trace FSM execution:

- FSM state transitions: current state and next state are printed every clock cycle.
- Reset events: a message is printed on every cycle the FSM is in `CLEARING_S`, including the current `xCounter` value.
- Zero counter tracking: optional display of `zeroCounter` and `xCounter` values during `WORKING_S` (currently commented out, can be re-enabled for debug).

Example debug output includes:

- `[time] mainSTATE=X -> NEXT=Y`
- `[time] RESET SUCCESS | xCounter=Z`

## DPI-Based Debugging Support

The design supports integration with external debugging utilities through the **SystemVerilog Direct Programming Interface (DPI)**. The ALU submodule uses DPI-C to validate arithmetic results against a reference C model.

## Mission-Mode Behavior

All `$display` and `$strobe` statements are **non-synthesizable** and are used solely during simulation and verification. They do not affect the functional behavior, timing, or synthesized implementation of the MSDAP.

---

# Synthesis

Synthesis has not yet been performed for the full MSDAP design. This section will be updated once synthesis results are available.

## Synthesis Results Table

| Technology Library | Target Frequency (MHz) | Achieved Frequency (MHz) | Cell Area (µm²) | Combinational Cells | Sequential Cells (FFs) | Comments |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | Pending synthesis |

## Additional Comments

### Observations

- **Performance:** The critical path is expected to run through the ALU datapath, primarily through the addition/subtraction and shift accumulation stages.
- **Area:** The design area will be dominated by the coefficient memory, x(n) circular buffer, and ALU datapath registers.
- **Recommendations:** Potential optimizations include pipelining the ALU datapath and reducing memory access latency through pre-fetching.

---

# Verification

## Test Environment

Verification was conducted using a SystemVerilog testbench that provides serial input stimuli through `InputL`, `Frame`, and `Dclk`, and monitors the serial output via `OutputL` and `OutReady`. Simulation was used to verify FSM transitions, memory initialization, FIR computation, sleep mode entry and exit, and reset behavior.

### Test Environment Table

| Tool | Version | Relevant Configuration |
|---|---|---|
| DSim | Current | RTL simulation with SystemVerilog testbench |
| GTKWave | Current | Signal waveform analysis |

## Tests

### Tests Table

| Test Type | Description | Tools Used |
|---|---|---|
| Functional Simulation | Verified FSM transitions, memory loading, ALU computation, and serial output. | DSim |
| Directed Tests | Specific input sequences applied to validate each FSM state. | DSim |
| Sleep Mode Test | Sustained zero input applied to verify `SLEEPING_S` entry and exit. | DSim |
| Reset Test | `Reset_n` asserted mid-stream to verify buffer clearing and FSM recovery. | DSim |
| Output Comparison | Serial output compared against reference output file (`data_sample.out`). | DSim |

### Test Results

| Test Case | Description | Result |
|---|---|---|
| Memory Initialization | Verified coefficient, Rj, and x(n) memories zeroed on startup. | Pass |
| Rj Loading | Verified 16 Rj values loaded correctly into Rj memory. | Pass |
| Coefficient Loading | Verified 512 coefficients loaded correctly into coefficient memory. | Pass |
| FIR Computation | Verified ALU output matches expected reference values. | Pass |
| Sleep Mode Entry | Verified FSM enters `SLEEPING_S` after 800 zero samples. | Pass |
| Sleep Mode Exit | Verified FSM returns to `WORKING_S` on non-zero input. | Pass |
| Reset Handling | Verified x(n) buffer is cleared and FSM recovers after `Reset_n`. | Pass |
| Serial Output | Verified 40-bit output words serialized correctly via P2S. | Pass |

## Benchmarks

### Benchmarks Table

| Metric | Value | Comments |
|---|---|---|
| Clock Frequency | 26.88 MHz, 768 kHz | Determined by system integration |
| Input Word Width | 16 bits | Serial, MSB first |
| Output Word Width | 40 bits | Serial, MSB first |
| FIR Filter Depth | Up to 512 taps | Determined by coefficient count |
| Sleep Threshold | 800 consecutive zero samples | Configurable in RTL |

## Issues and Resolutions

### Issues and Resolutions Table

| Issue | Description | Resolution |
|---|---|---|
| Sleep state corruption | Last output word before sleep was corrupted due to P2S being cut off mid-word. | Added `sleepingState` latch and gated FSM transition on `DataDone`. |
| Reset mid-stream | `Reset_n` assertion mid-word caused partial frame to be processed. | Reset now only takes effect at frame boundaries per specification. |
| ALU x address mismatch | ALU was starting from wrong x(n) position after sleep exit. | `xCounter` and ALU x address are now reset to zero on sleep exit. |
| Zero counter runaway | `zeroCounter` continued incrementing past threshold during sleep entry. | Sleep entry logic restructured using `else if` chains to prevent counter overrun. |
| Output count reset on Reset_n | `out_word_count` was reset to zero on `Reset_n`, breaking output file capture. | Output counter decoupled from `Reset_n` in testbench. |

## Verification Summary

The MSDAP design was verified using simulation-based functional testing across all major operating modes. Correct operation was confirmed for memory initialization, Rj and coefficient loading, FIR filter computation, sleep mode entry and exit, reset recovery, and serial output formatting. Output values were compared against a reference file to validate arithmetic correctness across multiple input sequences.

---

# Data Controller

## Description

The `dataController` submodule implements the top-level FSM that orchestrates all operations of the MSDAP chip. It sequences memory initialization, serial input reception, ALU computation, output serialization, sleep mode, and reset handling.

The controller generates all enable signals, write enables, and address signals for the S2P, ALU, memories, and P2S subsystems. It tracks the number of consecutive zero-valued input samples and automatically enters sleep mode when the threshold is exceeded.

## I/O Table

### Input Table

| Input Name | Direction | Type | Description |
|---|---|---|---|
| `Sclk` | Input | `wire` | System clock for all sequential state updates. |
| `Dclk` | Input | `wire` | Data clock (passed through to S2P). |
| `Start` | Input | `wire` | Initializes all internal state on assertion. |
| `Reset_n` | Input | `wire` | Active-low reset. Clears x(n) buffer and returns FSM to `CLEARING_S`. |
| `Frame` | Input | `wire` | Indicates start of a new serial word from the external source. |
| `InputL` | Input | `wire` | Serial left channel input bit. |
| `InputR` | Input | `wire` | Serial right channel input bit. |
| `zeroFlagfromS2P` | Input | `wire` | Asserted by S2P when the current deserialized word is zero. |
| `InputReady` | Input | `wire` | Asserted by S2P when a complete 16-bit word is ready. |
| `Datain` | Input | `wire [15:0]` | Deserialized 16-bit word from the S2P block. |
| `done` | Input | `wire` | Asserted by ALU when computation for the current sample is complete. |
| `DataDone` | Input | `wire` | Asserted by P2S when the current 40-bit output word has been fully serialized. |

### Output Table

| Output Name | Direction | Type | Description |
|---|---|---|---|
| `InReady` | Output | `reg` | Signals to the external source that the chip is ready to receive input. |
| `OutputL` | Output | `reg` | Serial left channel output bit. |
| `OutputR` | Output | `reg` | Serial right channel output bit. |
| `Reset_in` | Output | `reg` | Active-low reset forwarded to S2P and memory blocks. |
| `Reset_ALU` | Output | `reg` | Active-low reset forwarded to the ALU. |
| `en_S2P` | Output | `reg` | Enables the S2P serializer. |
| `EnRj` | Output | `reg` | Enables write to Rj memory. |
| `EnCoeff` | Output | `reg` | Enables write to coefficient memory. |
| `EnX` | Output | `reg` | Enables write to x(n) circular buffer. |
| `WMode` | Output | `reg` | Write mode enable for coefficient and Rj memories. |
| `xWMode` | Output | `reg` | Write mode enable for x(n) circular buffer. |
| `WAddr` | Output | `reg [8:0]` | Write address for coefficient and Rj memories. |
| `xWAddr` | Output | `reg [7:0]` | Write address for x(n) circular buffer. |
| `en_ALU` | Output | `reg` | Enables ALU computation. |
| `en_P2S` | Output | `reg` | Enables P2S serializer output. |

## FSM State Table

| State | Encoding | Description |
|---|---|---|
| `INIT_S` | `4'b0000` | Waits for a zero-valued word to confirm the serial link is active. |
| `WAIT_RJ_S` | `4'b0001` | Waits for a `Frame` pulse before reading Rj parameters. |
| `READ_RJ_S` | `4'b0010` | Reads 16 Rj values into Rj memory. |
| `WAIT_COEFF_S` | `4'b0011` | Waits for a `Frame` pulse before reading filter coefficients. |
| `READ_COEFF_S` | `4'b0100` | Reads 512 filter coefficients into coefficient memory. |
| `WAIT_INPUT_S` | `4'b0101` | Waits for a `Frame` pulse before processing input samples. |
| `WORKING_S` | `4'b0110` | Stores input samples, runs ALU, and serializes output. |
| `CLEARING_S` | `4'b0111` | Sweeps x(n) buffer to zero following a reset event. |
| `SLEEPING_S` | `4'b1000` | Suspends processing while input is silent. Exits on non-zero input. |
| `INIT_COUNT_S` | `4'b1001` | Initializes all memories to zero after startup. |

---

# S2P (Serial-to-Parallel)

## Description

*(To be documented. The S2P block receives serial bits from `InputL` and `InputR` on `Dclk` and assembles them into 16-bit parallel words. It asserts `InputReady` when a complete word is available and `zeroFlagfromS2P` when the word is zero-valued.)*

## I/O Table

*(To be added)*

## Submodule Diagram

*(To be added)*

## SystemVerilog Implementation

*(To be added)*

---

# P2S (Parallel-to-Serial)

## Description

*(To be documented. The P2S block receives the 40-bit ALU output and serializes it for transmission via `OutputL` and `OutputR` on `Sclk`. It asserts `DataDone` when the full 40-bit word has been transmitted.)*

## I/O Table

*(To be added)*

## Submodule Diagram

*(To be added)*

## SystemVerilog Implementation

*(To be added)*

---

# Memories

## Rj Memory

*Stores up to 16 Rj parameters. Written during `READ_RJ_S` and read by the ALU during computation. 4-bit address, 16-bit data width.*

## Coefficient Memory

*Stores up to 512 filter coefficients. Written during `READ_COEFF_S` and read by the ALU during computation. 9-bit address, 16-bit data width.*

## x(n) Circular Buffer

*Stores up to 256 input samples in a circular addressing scheme. Written during `WORKING_S` and read by the ALU. 8-bit address, 16-bit data width. Cleared to zero during `CLEARING_S` and `INIT_COUNT_S`.*

---

# ALU

See [`alu/README.md`](alu/README.md) for full documentation of the ALU submodule, including the ALU_Controller FSM, signExt, addSub, and oneBitShift submodules.

---

## Contributors

- Areeb Iqbal
- Arham Virendra Dodal

**Advisor:** Dr. Alice Wang  
**Course:** MSDAP ASIC Design — UT Dallas
