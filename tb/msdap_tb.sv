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
  localparam int X_N       = 7000;
  localparam int FILE_N    = (RJ_N + COEFF_N + X_N) * 2;  
  localparam int OUT_N     = 6394;  //6394

  localparam DCLK_HALF = 651;
  localparam SCLK_HALF = 18.6;

  // =========================================================
  // Memories / bookkeeping
  // =========================================================
  reg [15:0] data_mem [0:FILE_N-1];

  integer InputWord_idx;
  integer InputBit_idx;
  integer OutputBit_idx;
  integer OutputWordCounter;
  integer outfile;
  integer logfile;

  // reg [39:0] out_shift;
  reg [39:0] OutputShiftL;
  reg [39:0] OutputShiftR;

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

    InputWord_idx     = 0;
    InputBit_idx      = 15;
    OutputBit_idx     = 39;
    OutputWordCounter = 0;
    OutputShiftL      = 40'd0;
    OutputShiftR      = 40'd0;

    $readmemh("data1_final.in", data_mem);

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
  // frame boundary (InputBit_idx == 15), discard that frame,
  // and do NOT increment InputWord_idx per spec.
  // =========================================================
  always @(posedge Dclk) begin
    if (!Reset_n) begin

      InputBit_idx  <= 15;
      Frame       <= 1'b0;
      InputL      <= 1'b0;
      InputR      <= 1'b0;

      Reset_n     <= 1'b1;
    end
    else begin
      Frame  <= 1'b0;
      
      if ((InputWord_idx == ((RJ_N + COEFF_N + 4201)*2) - 4 || 
        InputWord_idx == ((RJ_N + COEFF_N + 6001)*2) - 4) && resetFlag == 1'b0) begin
        resetFlag <= 1'b1;
      end
      if (InReady && (InputWord_idx < FILE_N)) begin

        if (InputBit_idx == 15 && resetFlag) begin

          Reset_n  <= 1'b0;
          resetFlag <= 1'b0;
          Frame    <= 1'b0;
          InputL   <= 1'b0;
          InputR   <= 1'b0;
          InputWord_idx <= InputWord_idx + 2;
          $display("[%0t] RESET asserted at frame boundary, discarding word %0d",
                   $time, InputWord_idx);
        end
        else begin

          if (InputBit_idx == 15)
            Frame <= 1'b1;

          InputL <= data_mem[InputWord_idx][InputBit_idx];
          InputR <= data_mem[InputWord_idx+1][InputBit_idx];
          $display("[%0t] DATA_MEM: %0h",
                   $time, data_mem[InputWord_idx]);
            
          if (InputBit_idx == 0) begin
            InputBit_idx  <= 15;
            InputWord_idx <= InputWord_idx + 2;
          end
          else begin
            InputBit_idx <= InputBit_idx - 1;
          end
        end

      end
      else begin
        InputL <= 1'b0;
        InputR <= 1'b0;
      end
    end
  end
  

  // =========================================================
  // Output capture (Sclk domain)
  // Sets do_reset after 900th and 1000th output words
  // =========================================================
  
  always @(posedge Sclk) begin
    if (!Reset_n) begin
        OutputShiftL <= 40'd0;
        OutputShiftR <= 40'd0;
        OutputBit_idx <= 39;
    end
    else if (OutReady) begin
      OutputShiftL[OutputBit_idx] <= OutputL;
      OutputShiftR[OutputBit_idx] <= OutputR;

      if (OutputBit_idx == 0) begin
        $fdisplay(outfile, "%h      %h", {OutputShiftL[39:1], OutputL}, {OutputShiftR[39:1], OutputR});
        OutputBit_idx    <= 39;
        OutputWordCounter <= OutputWordCounter + 1;

        if (OutputWordCounter + 1 == OUT_N) begin
          $display("[%0t] INFO: captured %0d output words, finishing simulation.",
                   $time, OUT_N);
          #1;
          $finish;
        end
      end
      else begin
        OutputBit_idx <= OutputBit_idx - 1;
      end
    end
  end

  final begin
    if (outfile != 0)
      $fclose(outfile);
    if (logfile != 0)
      $fclose(logfile);
  end

endmodule
