`timescale 1ns/1ps

module MSDAP_tb;

  // =========================================================
  // DUT I/O
  // =========================================================
  reg  Sclk;
  reg  Dclk;
  reg  Start;
  reg  Reset_n;
  reg  Frame;
  reg  InputL;
  reg  InputR;

  wire InReady;
  wire OutReady;
  wire OutputL;
  wire OutputR;

  // =========================================================
  // Instantiate DUT
  // =========================================================
  MSDAP dut (
    .Sclk(Sclk),
    .Dclk(Dclk),
    .Start(Start),
    .Reset_n(Reset_n),
    .Frame(Frame),
    .InputL(InputL),
    .InputR(InputR),
    .InReady(InReady),
    .OutReady(OutReady),
    .OutputL(OutputL),
    .OutputR(OutputR)
  );

  // =========================================================
  // Parameters
  //   16 rj values + 512 coeff values + 3500 x values = 4028
  // =========================================================
  localparam int RJ_N      = 16;
  localparam int COEFF_N   = 512;
  localparam int X_N       = 3500;
  localparam int FILE_N    = RJ_N + COEFF_N + X_N;   // 4028
  localparam int OUT_N     = 810;

  localparam DCLK_HALF = 651;
  localparam SCLK_HALF = 18.6;

  // =========================================================
  // Memories / bookkeeping
  // =========================================================
  reg [15:0] data_mem [0:FILE_N-1];

  integer in_word_idx;
  integer in_bit_idx;
  integer out_bit_idx;
  integer out_word_count;
  integer outfile;
  integer logfile;

  reg [39:0] out_shift;

  // Flag set in Sclk domain, consumed in Dclk domain
  reg resetFlag = 1'b0;

  // =========================================================
  // Clock generation
  // =========================================================
  initial begin
    Dclk = 1'b0;
    forever #(DCLK_HALF) Dclk = ~Dclk;
  end

  initial begin
    Sclk = 1'b0;
    forever #(SCLK_HALF) Sclk = ~Sclk;
  end

  // =========================================================
  // Startup sequence
  // =========================================================
  initial begin
    InputL         = 1'b0;
    InputR         = 1'b0;
    Frame          = 1'b0;
    Start          = 1'b0;
    Reset_n        = 1'b0;
    resetFlag      = 1'b0;

    in_word_idx    = 0;
    in_bit_idx     = 15;
    out_bit_idx    = 39;
    out_word_count = 0;
    out_shift      = 40'd0;

    $readmemh("data1_midterm.in", data_mem);

    outfile = $fopen("data_sample.out", "w");
    if (outfile == 0) begin
      $display("ERROR: could not open data_sample.out");
      $finish;
    end

    logfile = $fopen("debug.log", "w");
    if (logfile == 0) begin
      $display("ERROR: could not open debug.log");
      $finish;
    end

    // Initial reset/start sequence
    #20;
    Reset_n = 1'b1;
    #20;
    Start   = 1'b1;
    #20;
    Start   = 1'b0;
  end

  // =========================================================
  // Input serializer (Dclk domain)
  // When do_reset is set, assert Reset_n low at the next
  // frame boundary (in_bit_idx == 15), discard that frame,
  // and do NOT increment in_word_idx per spec.
  // =========================================================
  always @(posedge Dclk) begin
    if (!Reset_n) begin
      // Hold state during reset, do not advance
      in_bit_idx  <= 15;
      Frame       <= 1'b0;
      InputL      <= 1'b0;
      InputR      <= 1'b0;
      // Release reset after one Dclk cycle
      Reset_n     <= 1'b1;
    end
    else begin
      Frame  <= 1'b0;
      InputR <= 1'b0;
      
      if ((in_word_idx == RJ_N + COEFF_N + 900 || 
        in_word_idx == RJ_N + COEFF_N + 1000) && resetFlag == 1'b0) begin
        resetFlag <= 1'b1;
      end
      if (InReady && (in_word_idx < FILE_N)) begin

        if (in_bit_idx == 15 && resetFlag) begin
          // Assert reset at start of frame, discard this frame
          Reset_n  <= 1'b0;
          resetFlag <= 1'b0;
          Frame    <= 1'b0;
          InputL   <= 1'b0;
          // in_word_idx intentionally NOT incremented — frame discarded
          // in_bit_idx stays at 15 to retry this word after reset
          $display("[%0t] RESET asserted at frame boundary, discarding word %0d",
                   $time, in_word_idx);
        end
        else begin
          // Normal operation: send current word bit by bit
          if (in_bit_idx == 15)
            Frame <= 1'b1;

          InputL <= data_mem[in_word_idx][in_bit_idx];
            
          if (in_bit_idx == 0) begin
            in_bit_idx  <= 15;
            in_word_idx <= in_word_idx + 1;
          end
          else begin
            in_bit_idx <= in_bit_idx - 1;
          end
        end

      end
      else begin
        InputL <= 1'b0;
      end
    end
  end
  

  // =========================================================
  // Output capture (Sclk domain)
  // Sets do_reset after 900th and 1000th output words
  // =========================================================
  always @(posedge Sclk) begin
    if (!Reset_n) begin
      out_shift      <= 40'd0;
      out_bit_idx    <= 39;
      out_word_count <= 0;
    end
    else if (OutReady) begin
      out_shift[out_bit_idx] <= OutputL;

      if (out_bit_idx == 0) begin
        $fdisplay(outfile, "%h", {out_shift[39:1], OutputL});
        out_bit_idx    <= 39;
        out_word_count <= out_word_count + 1;

        // Request reset after 900th and 1000th output words

        if (out_word_count + 1 == OUT_N) begin
          $display("[%0t] INFO: captured %0d output words, finishing simulation.",
                   $time, OUT_N);
          #1;
          $finish;
        end
      end
      else begin
        out_bit_idx <= out_bit_idx - 1;
      end
    end
  end

  // =========================================================
  // Debug logging (Sclk domain)
  // =========================================================
  always @(posedge Sclk) begin
    $fstrobe("[%0t] state=%0d en_ALU=%0b done=%0b rj_addr=%0d coeff_addr=%0d x_addr=%0d y=%h",
            $time,
            dut.ctrl.currentState,
            dut.ctrl.en_ALU,
            dut.done,
            dut.rj_address,
            dut.coeff_address,
            dut.x_address,
            dut.y);
  end

  always @(posedge Sclk) begin
    if (OutReady) begin
      $strobe("[%0t] Output bit=%0b  out_bit_idx=%0d  partial_out=%h",
              $time, OutputL, out_bit_idx, out_shift);
    end
  end

  // =========================================================
  // Cleanup
  // =========================================================
  final begin
    if (outfile != 0)
      $fclose(outfile);
    if (logfile != 0)
      $fclose(logfile);
  end

endmodule