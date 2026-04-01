# Mini-Stereo-Digital-Audio-Processor

# Introduction

This block implements the **Arithmetic Logic Unit (ALU)** of the MSDAP architecture. The ALU processes the **Rj parameters**, **filter coefficients**, and **input samples (x(n))** required for the computation.

The operation of the ALU is controlled by a **finite state machine (FSM)** implemented in the _ALU_Controller_ module. The controller sequentially iterates through the input data using **address counters**, which determine the appropriate timing and ordering of arithmetic operations.

The ALU datapath performs the required arithmetic processing, including **sign extension**, **addition/subtraction**, and **shifted accumulation**. These operations support the iterative computation required by the MSDAP algorithm.


# Block Name: MSDAP ALU


# Revisions

| Date (YYYY-MM-DD) | Version   | Description of Changes         | Author               | Reviewer
|-------------------|-----------|--------------------------------|----------------------|----------------------|
| 2026-02-26        | `0.0.2`   | Document creation.             | Areeb Iqbal, Arham Virendra Dodal  | Dr. Alice Wang 


## Features

This section summarizes the key capabilities and design characteristics of the ALU block within the MSDAP architecture:

### Integration

-   Integrates with the **ALU_Controller FSM** to coordinate arithmetic operations and control signal sequencing.
    
-   Interfaces with memory or register blocks containing **Rj parameters, filter coefficients, and input samples (x(n))**.
    
-   Utilizes **address counters** to iterate through input datasets and synchronize datapath operations.
    

### Performance

-   Supports efficient **iterative arithmetic processing** required by the MSDAP algorithm.
    
-   **Addition and subtraction operations are performed in parallel with the fetching of the next input sample**, improving datapath utilization and reducing idle cycles.
    

### Design

-   Implements a datapath capable of **sign extension**, **addition/subtraction**, and **accumulation with shifting**.
    
-   Structured using modular RTL components to improve readability and maintainability.
    
-   Operates under FSM-based control to ensure deterministic execution of arithmetic sequences.
    

### Debugging

-   Address counters and control signals allow **step-by-step verification of datapath operations**.
    
-   Internal signals can be monitored during simulation to validate arithmetic correctness.
    
-   Modular structure facilitates **unit-level testing and waveform analysis** during verification.
-  Includes **\$strobe** and  **\$display** lines to track the execution of the **FSM**.


# Top-Level Block Diagram

The top-level block diagram illustrates the structural organization of the **MSDAP_ALU** module and its major functional components. The design is divided into a control unit and a datapath that together implement the arithmetic operations required by the MSDAP algorithm.

The **ALU_Controller** module implements the finite state machine (FSM) responsible for coordinating the operation of the ALU. It generates control signals for the datapath modules and manages the iteration through the input data using address counters. These counters produce the addresses for the **input samples (x(n))**, **filter coefficients**, and **Rj parameters**.

The datapath consists of three primary submodules. The **signExt** module performs sign extension on the input samples, expanding the input width from 16 bits to 40 bits to match the internal datapath width. The **addSub** module performs addition or subtraction depending on the opcode provided by the controller. The **oneBitShift** module performs a single-bit shift operation on the intermediate result to support the accumulation process required by the algorithm.

A feedback path is used to store and reuse the accumulated result during iterative computation. The output of the shifting stage is fed back into the arithmetic unit, enabling sequential accumulation across multiple cycles. The final computed value is exposed at the output (y), while the controller generates a **done** signal to indicate completion of the computation.

All functional elements are encapsulated within dedicated submodules, ensuring that the top-level module primarily performs structural integration of the control and datapath components.

## Diagram


# Configuration

The `MSDAP_ALU` module does not expose user-configurable parameters. The behavior of the block is defined by the RTL implementation and controlled through the input data (`x`, `coeff`, `rj`) and control signals (`Sclk`, `en_ALU`). The module generates address signals for external memory interfaces and produces the computed output value `y`.

## Parameters

This module does not expose configurable top-level parameters. The state encodings used by the controller are defined internally in the RTL and are not intended to be modified.

## Typedefs

This design does not declare any typedefs, enumerations, structures, or unions.

## Interfaces

The top-level ports of the `MSDAP_ALU` module are grouped into **control**, **data**, and **address** interfaces.

### Control Interface

| Port Name | Direction | Type | Description |
|-----------|-----------|------|-------------|
| `Sclk` | Input | `wire` | System clock used for sequential state updates in the ALU controller and datapath. |
| `en_ALU` | Input | `wire` | Enables execution of the ALU. When low, the controller resets its internal state and counters. |
| `done` | Output | `wire` | Indicates that the current ALU computation has completed. |

**Protocol Use:** None. This is a simple synchronous control interface.

### Data Interface

| Port Name | Direction | Type | Description |
|-----------|-----------|------|-------------|
| `x` | Input | `wire [15:0]` | Input sample used as part of the ALU computation. |
| `coeff` | Input | `wire [15:0]` | Filter coefficient used to determine arithmetic operations and address calculations. |
| `rj` | Input | `wire [15:0]` | Parameter controlling the number of iterations performed during accumulation. |
| `y` | Output | `wire [39:0]` | Output result produced by the ALU after completion of the computation. |

**Protocol Use:** None. These signals represent direct datapath inputs and outputs.

### Address Interface

| Port Name | Direction | Type | Description |
|-----------|-----------|------|-------------|
| `rj_address` | Output | `wire [3:0]` | Address used to select the current `rj` parameter. |
| `coeff_address` | Output | `wire [8:0]` | Address used to index the filter coefficient memory. |
| `x_address` | Output | `wire [7:0]` | Address used to select the current input sample `x(n)`. |

**Protocol Use:** None. These outputs provide direct addressing for external memory or register blocks.

## Design Assumptions

- Input values `x`, `coeff`, and `rj` are **16-bit signed values**.
- The ALU datapath operates on **40-bit internal precision**, producing a **40-bit output `y`**.
- Address widths are fixed by the RTL implementation:
  - `rj_address`: 4 bits (up to 16 entries)
  - `coeff_address`: 9 bits (up to 512 entries)
  - `x_address`: 8 bits (up to 256 entries)
- All interfaces operate synchronously with the system clock `Sclk`.

# Clock Domains

The `MSDAP_ALU` block operates entirely within a **single clock domain** driven by the system clock `Sclk`. All submodules, including the controller and datapath components (`signExt`, `addSub`, `oneBitShift`), operate synchronously with this clock.

Since the design uses a single clock domain, **no clock domain crossings (CDC)** exist within the block.

## Clock Domain Table

| Clock Domain | Nominal Frequency | Supported Dynamic Range |
|---------------|------------------|-------------------------|
| `Sclk` | System dependent | Determined by system integration |
| `Dclk` | System dependent | Determined by system integration |

**Notes**

- All sequential elements in the controller and datapath are triggered on the **rising edge of `Sclk`** so far. An additional `Dclk` will be added in the coming release.
- The clock frequency is determined by the ASIC implementation. Recommended frequency for this device is **26.88 MHz** to **37.2 ns**.
- 
## Annotated Block Diagram

The same top-level block diagram shown previously applies here. All submodules currently belong to the **`Sclk` clock domain**, including:

- `ALU_Controller`
- `signExt`
- `addSub`
- `oneBitShift`

Since the entire block operates within a single clock domain, no clock-domain crossing logic is required thus far. 

---

# Reset Domains

The `MSDAP_ALU` design includes two reset mechanisms: a dedicated hardware reset signal `Reset_in` and a software-controlled enable signal `en_ALU`.

## Reset Domains Table

| Reset Name | Synchronous/Asynchronous | Active High/Low | Associated Clock (if synchronous) | Description |
|---|---|---|---|---|
| `Reset_in` | Asynchronous | Active Low | N/A | Clears all internal registers, counters, addresses, and FSM state immediately on deassertion, regardless of clock. |
| `en_ALU` | Synchronous | Active Low (reset when `0`) | `Sclk` | Clears counters, addresses, and FSM state on the next rising edge of `Sclk` when the ALU is disabled. xVal value is retained |

## Annotated Block Diagram
 
Both reset mechanisms affect the `ALU_Controller` submodule. When either reset is active, the following elements are cleared:
 
- FSM state register (`currentState`) → `IDLE_S`
- Address counters (`coeffCounter`, `rjCounter`, `rjAddr`, `xAddr`) → zero
- Address outputs (`rj_address`, `coeff_address`, `x_address`) → zero
- Control outputs (`load`, `shift_en`, `feedbackLoad`, `done`, `opcode`, `Enable`) → deasserted
 
**`Reset_in` additionally asserts `clear`** to reset the `addSub` accumulator, which `en_ALU` deassertion does not do.
 
**`xVal` is intentionally NOT cleared by `en_ALU` deassertion.** This preserves the current position in the input sample sequence so that when `en_ALU` is reasserted, the controller begins the next convolution from the correct sample position.
 
## Custom Reset Procedures
 
### Reset_in Procedure
 
1. Deassert `Reset_in = 0`.
2. All internal registers are immediately cleared asynchronously, independent of `Sclk`.
3. The FSM returns to `IDLE_S` and `clear` is asserted to zero the accumulator.
4. Assert `Reset_in = 1` to release reset. Normal operation begins when `en_ALU` is also asserted.
 
### en_ALU Procedure
 
1. Deassert `en_ALU = 0`.
2. On the next rising edge of `Sclk`, all counters, addresses, and FSM state are cleared — **except `xVal`, which is intentionally preserved**.
3. The FSM returns to `IDLE_S`. Note that `clear` is **not** asserted, so the accumulator retains its value to be transferred to `P2S` module.
4. Assert `en_ALU = 1` to resume operation. The controller picks up from the next `xVal` position, allowing it to continue the convolution sequence.
 
## References to External Documents
 
None. The reset behavior is fully defined within the RTL implementation of the `ALU_Controller` submodule.

# Arbitration, Fairness, QoS, and Forward Progress Guarantees

The `MSDAP_ALU` block does not implement arbitration between multiple traffic classes or concurrent transactions. The design processes a single stream of computation under the control of the `ALU_Controller` finite state machine (FSM). As a result, arbitration policies, fairness mechanisms, and QoS features are not required.

## Arbitration and Fairness

The design does not contain shared resources accessed by multiple independent requesters. All datapath operations are scheduled and controlled by the `ALU_Controller` FSM, which sequences operations deterministically.

- **Arbitration Policy**: None. Only one computation flow is active at a time.
- **Fairness**: Not applicable since no competing traffic classes exist.
- **Configurability**: No arbitration or QoS configuration parameters are provided.

## Quality-of-Service (QoS)

The `MSDAP_ALU` block does not implement Quality-of-Service (QoS) mechanisms. The block performs a single computation sequence initiated by the `en_ALU` signal and continues until completion.

- **QoS Features**: None.
- **Impact on Performance**: Performance is determined solely by the controller state machine and datapath latency.

## Forward Progress Guarantees

Forward progress is guaranteed by the deterministic state transitions of the `ALU_Controller` FSM. The controller iterates through coefficient and input sample addresses until the computation is complete.

- **Deadlock and Livelock Prevention**: The FSM contains a finite number of states and deterministic transitions, ensuring that the computation always progresses toward the `DONE_S` state.
- **Assumptions**: External memory supplying `x`, `coeff`, and `rj` values responds correctly to the generated address signals.
- **Proof Outline**: Since the FSM progresses through a bounded sequence of states (`IDLE_S → EXEC_S → ADD_N_SHIFT_S → SHIFT_S → FINAL_ANS_S → DONE_S → RESET_S`), and counters are monotonically incremented toward fixed bounds, the controller is guaranteed to eventually reach the completion state (`DONE_S`).

# Debugging

The `MSDAP_ALU` block includes several simulation-oriented debugging mechanisms to assist with verification and diagnostics during development. These mechanisms are intended for use in simulation environments only and are not part of the synthesized hardware.

## System Tasks for Simulation Debugging

SystemVerilog system tasks are used to monitor the internal state of the controller during simulation. In particular, the `$display` system task is used to print diagnostic information about the finite state machine and internal counters.

Example debug output includes:

- Current FSM state and next state
- Counter values (`rjCounter`, `coeffCounter`)
- Address values used during iteration
- Intermediate values used in the datapath

These messages allow developers to trace the execution flow of the controller and verify that state transitions and arithmetic sequencing occur as expected.

## DPI-Based Debugging Support

The design supports integration with external debugging utilities through the **SystemVerilog Direct Programming Interface (DPI)**. DPI functions can be used during simulation to export internal signal values or interact with external software tools for advanced diagnostics.

Typical DPI debugging uses include:

- Exporting internal signals to external analysis tools
- Logging intermediate datapath values
- Integrating simulation with higher-level verification frameworks

These DPI hooks are intended for simulation environments and are not included in the synthesized hardware implementation.

## Mission-Mode Behavior

All debugging mechanisms described in this section are **non-synthesizable** and are used solely during simulation and verification. They do not affect the functional behavior, timing, or synthesized implementation of the `MSDAP_ALU` block.


# Synthesis

This section presents the synthesis results for the `MSDAP_ALU` design targeting an ASIC implementation. The design was synthesized using a standard-cell library to evaluate timing performance and hardware resource utilization.

The results summarize the estimated operating frequency, cell area, and register count obtained from logic synthesis.

## Synthesis Results Table

| Technology Library | Target Frequency (MHz) | Achieved Frequency (MHz) | Cell Area (µm²) | Combinational Cells | Sequential Cells (FFs) | Comments |
|--------------------|------------------------|---------------------------|-----------------|---------------------|------------------------|----------|
| LIB_A              | XXX                    | XXX                       | XXXX            | XXXX                | XXXX                   | Summary of synthesis results |

## Additional Comments

### Observations

- **Performance:**  
  The maximum operating frequency is determined by the critical path within the ALU datapath, primarily involving the addition/subtraction and shift operations.

- **Area:**  
  The synthesized area is dominated by the arithmetic datapath components and controller registers. The FSM and address counters contribute a relatively small portion of the overall area.

- **Recommendations:**  
  Potential improvements to performance and area include:
  - Introducing pipelining in the datapath.
  - Optimizing arithmetic operations for the target standard-cell library.
  - Reducing datapath width where algorithmically feasible.

# Verification

This section describes the verification methodology used to validate the functional correctness of the `MSDAP_ALU` design. Verification was primarily performed using RTL simulation and waveform analysis to ensure that the controller state machine, datapath operations, and address generation behaved according to the design specification.

## Test Environment

Verification was conducted using a SystemVerilog testbench that provides input stimuli (`x`, `coeff`, `rj`) and monitors the output signals (`y`, `done`). Simulation was used to verify correct FSM transitions, arithmetic operations, and address generation during execution.

### Test Environment Table

| Tool | Version | Relevant Configuration |
|-----|------|------------------------|
| Synopsys VCS / ModelSim / Xcelium | [version] | RTL simulation with SystemVerilog testbench |
| DVT IDE | [version] | Waveform inspection and design visualization |
| GTKWave / Built-in Viewer | [version] | Signal waveform analysis |

## Tests

Several categories of tests were used to validate the functionality of the design.

### Tests Table

| Test Type | Description | Tools Used |
|----------|-------------|-----------|
| Functional Simulation | Verified correct arithmetic operations, FSM transitions, and address generation. | Simulator |
| Directed Tests | Specific input patterns applied to validate controller behavior and datapath operations. | Simulator |
| Regression Tests | Multiple input vectors tested to ensure stable operation across different conditions. | Simulator |

### Test Results

| Test Case | Description | Result |
|----------|-------------|--------|
| Basic Operation | Verified ALU execution for a single iteration of input data. | Pass |
| Address Generation | Verified correct incrementing of `x_address`, `coeff_address`, and `rj_address`. | Pass |
| FSM Operation | Verified correct transitions between controller states. | Pass |
| Completion Signal | Verified `done` signal assertion upon completion of computation. | Pass |

All tests completed successfully without functional errors.

## Benchmarks

Basic performance benchmarks were collected to evaluate latency and execution characteristics of the design.

### Benchmarks Table

| Metric | Value | Comments |
|------|------|---------|
| Clock Frequency | System dependent | Determined by synthesis constraints |
| Latency | Dependent on `rj` and coefficient count | Determined by FSM iterations |
| Throughput | One output per execution cycle sequence | Controlled by FSM |

### Benchmarks Results

The latency of the design is determined by the number of iterations performed by the controller. Each iteration corresponds to arithmetic operations followed by shift and feedback stages.

## Issues and Resolutions

### Issues and Resolutions Table

| Issue | Description | Resolution |
|-----|-------------|-----------|
| Address calculation mismatch | Incorrect address values observed during early testing. | Corrected counter update logic in the controller. |
| FSM transition bug | Incorrect transition between execution states detected. | Adjusted next-state logic in the FSM. |

## Verification Summary

The `MSDAP_ALU` design was verified using simulation-based functional testing. The verification process confirmed correct operation of the FSM controller, datapath arithmetic operations, and address generation logic. All directed and regression tests passed successfully, and the design produced the expected outputs for the tested input cases.


# ALU_Controller

## Description

The `ALU_Controller` submodule implements the control logic for the MSDAP ALU. It is realized as a finite state machine (FSM) that sequences the arithmetic datapath and generates the address signals required to access the `rj` parameters, filter coefficients, and input samples.

The controller is responsible for:
- generating the control signals `opcode`, `load`, `shift_en`, `feedbackLoad`, `clear`, and `done`
- iterating through coefficients and input samples using internal counters
- determining when addition/subtraction and shift operations must be performed
- resetting the iteration state once a computation is complete

The FSM operates through the states `IDLE_S`, `EXEC_S`, `ADD_N_SHIFT_S`, `SHIFT_S`, `FINAL_ANS_S`, `DONE_S`, and `RESET_S`. During execution, the controller computes the sample address, selects the arithmetic operation using `coeff[8]`, and advances the internal counters until the final result is ready.

## I/O Table

### Input Table

| Input Name | Direction | Type | Description |
|------------|-----------|------|-------------|
| `rj` | Input | `wire [15:0]` | Iteration bound used to determine when the inner accumulation loop is complete. |
| `coeff` | Input | `wire [15:0]` | Filter coefficient input; `coeff[7:0]` contributes to address generation and `coeff[8]` selects add/subtract operation. |
| `Sclk` | Input | `wire` | System clock for sequential state and output updates. |
| `en_ALU` | Input | `wire` | Active-high enable signal. When low, the controller returns to its idle/reset condition. |

### Output Table

| Output Name | Direction | Type | Description |
|-------------|-----------|------|-------------|
| `rj_address` | Output | `reg [3:0]` | Address used to select the current `rj` parameter. |
| `coeff_address` | Output | `reg [8:0]` | Address used to access the current filter coefficient. |
| `x_address` | Output | `reg [7:0]` | Address used to access the current input sample. |
| `opcode` | Output | `reg` | Arithmetic control signal; selects addition or subtraction in the datapath. |
| `load` | Output | `reg` | Enables accumulation in the `addSub` unit. |
| `shift_en` | Output | `reg` | Enables the shift operation in the `oneBitShift` unit. |
| `done` | Output | `reg` | Indicates completion of the current computation. |
| `feedbackLoad` | Output | `reg` | Enables loading of the shifted result back into the accumulator. |
| `clear` | Output | `reg` | Clears datapath state during reset/initialization. |

## Submodule Diagram

The `ALU_Controller` submodule consists of:
- a sequential state register updated on `Sclk`
- combinational next-state and control generation logic
- internal counters for coefficient, `rj`, and sample addressing
- output registers that drive the ALU datapath and memory interfaces

{!diagrams/alu_controller.html!}

## SystemVerilog Implementation

The controller is implemented using two main processes:
- a **sequential always block** triggered on the rising edge of `Sclk`, which updates the current state, counters, addresses, and registered outputs
- a **combinational always block** that computes the next state and next values of all internal registers and control signals

In the `EXEC_S` state, the controller computes the next sample address as `xVal - coeff[7:0]`, asserts `load`, and sets `opcode` from `coeff[8]`. The coefficient and loop counters are incremented until the `rj` limit is reached, at which point the controller transitions to the shift states. After the final shift, the `done` signal is asserted and the controller returns to the reset and idle states.

---

# signExt

## Description

The `signExt` submodule performs sign extension of the 16-bit input sample to the 40-bit internal datapath width. This ensures that signed arithmetic can be performed correctly in the downstream accumulator and shift stages.

In addition to sign extension, the module appends 16 least-significant zero bits to align the input value with the fixed-point format used by the datapath.

## I/O Table

### Input Table

| Input Name | Direction | Type | Description |
|------------|-----------|------|-------------|
| `in` | Input | `wire [INPUTSIZE-1:0]` | Input sample value to be sign-extended. |

### Output Table

| Output Name | Direction | Type | Description |
|-------------|-----------|------|-------------|
| `out` | Output | `wire [OUTPUTSIZE-1:0]` | Sign-extended and left-shifted output value used by the arithmetic datapath. |

## Submodule Diagram

The `signExt` submodule is purely combinational. It inspects the sign bit of the input and produces either a zero-extended or sign-extended 40-bit output.

{!diagrams/signext.html!}

## SystemVerilog Implementation

The module is parameterized by `INPUTSIZE` and `OUTPUTSIZE`, with default values of 16 and 40, respectively. The output assignment is implemented using a continuous assignment:

- if the input is negative, the upper bits are filled with `1`s
- if the input is non-negative, the upper bits are filled with `0`s
- the lower 16 bits are padded with zeros

This creates a 40-bit fixed-point representation suitable for the ALU datapath.

---

# addSub

## Description

The `addSub` submodule implements the accumulator and arithmetic unit of the datapath. It stores the current accumulated result and updates it based on the control signals generated by the controller.

The module supports three main operations:
- **clear**, which resets the accumulator to zero
- **feedback load**, which loads the shifted result back into the accumulator
- **add/subtract**, which updates the accumulator by adding or subtracting the current input operand

Subtraction is implemented using two's complement arithmetic.

## I/O Table

### Input Table

| Input Name | Direction | Type | Description |
|------------|-----------|------|-------------|
| `clk` | Input | `wire` | Clock used to update the accumulator register. |
| `clear` | Input | `wire` | Asynchronous clear signal that resets the accumulator. |
| `load` | Input | `wire` | Enables arithmetic accumulation. |
| `feedbackLoad` | Input | `wire` | Enables loading of the feedback value into the accumulator. |
| `opcode` | Input | `wire` | Selects arithmetic mode: addition or subtraction. |
| `in` | Input | `wire [39:0]` | Current datapath input operand. |
| `feedback` | Input | `wire [39:0]` | Shifted feedback value loaded into the accumulator. |

### Output Table

| Output Name | Direction | Type | Description |
|-------------|-----------|------|-------------|
| `shiftOp` | Output | `wire [39:0]` | Current accumulator result forwarded to the shift stage. |

## Submodule Diagram

The `addSub` submodule contains a 40-bit result register, arithmetic logic for addition/subtraction, and a feedback path for reloading shifted intermediate values.

{!diagrams/addsub.html!}

## SystemVerilog Implementation

The module is implemented as a clocked process sensitive to `posedge clk` and `posedge clear`. The internal register `result` stores the accumulated value.

Operation priority is as follows:
1. if `clear` is asserted, `result` is reset to zero
2. else if `feedbackLoad` is asserted, `result` is loaded from `feedback`
3. else if `load` is asserted, `result` is updated by either:
   - `result + in` when `opcode = 0`
   - `result + ~in + 1` when `opcode = 1`

The output `shiftOp` is continuously assigned to the internal `result` register.

---

# oneBitShift

## Description

The `oneBitShift` submodule performs a one-bit arithmetic right shift on the accumulator output. This stage is used to scale the intermediate result while preserving the sign of signed values.

The module stores the shifted result in an output register and updates it only when shifting is enabled.

## I/O Table

### Input Table

| Input Name | Direction | Type | Description |
|------------|-----------|------|-------------|
| `clk` | Input | `wire` | Clock used to register the shifted output. |
| `addOp` | Input | `wire [39:0]` | Input value from the accumulator stage. |
| `clear` | Input | `wire` | Clears the output register. |
| `shift_en` | Input | `wire` | Enables the one-bit shift operation. |

### Output Table

| Output Name | Direction | Type | Description |
|-------------|-----------|------|-------------|
| `yOut` | Output | `reg [39:0]` | Shifted output value forwarded to the feedback path or top-level output. |

## Submodule Diagram

The `oneBitShift` submodule contains a registered arithmetic right shifter. The most significant bit is replicated during the shift to preserve signed-number representation.

{!diagrams/onebitshift.html!}

## SystemVerilog Implementation

The module is implemented as a sequential process triggered on the rising edge of `clk`. When `clear` is asserted, the output register is reset to zero. When `shift_en` is asserted, the input `addOp` is shifted right by one bit using arithmetic sign extension:

```systemverilog
yOut <= {addOp[39], addOp[39:1]};
