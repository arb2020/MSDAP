`timescale 1ns/1ps

module Behav_ALU_tb;

  // DUT pins
  logic [15:0] x, rj, coeff;
  logic [3:0]  rj_address;
  logic [8:0]  coeff_address;
  logic [7:0]  x_address;
  logic [39:0] y;
  logic        Sclk, en_ALU;
  wire         done;

  // Instantiate DUT
  MSDAP_ALU dut (
    .x(x),
    .rj(rj),
    .rj_address(rj_address),
    .coeff(coeff),
    .coeff_address(coeff_address),
    .x_address(x_address),
    .y(y),
    .Sclk(Sclk),
    .en_ALU(en_ALU),
    .done(done)
  );

  // -----------------------
  // Clock
  // -----------------------
  initial begin
    Sclk = 1'b0;
    forever #5 Sclk = ~Sclk;
  end

  // -----------------------
  // Memories
  // -----------------------
  localparam int RJ_N     = 16;
  localparam int COEFF_N  = 512;
  localparam int X_N      = 3500;
  localparam int FILE_N   = RJ_N + COEFF_N + X_N;

  logic [15:0] memRead     [0:FILE_N-1];
  logic [15:0] rjVals      [0:RJ_N-1];
  logic [15:0] coeffVals   [0:COEFF_N-1];
  logic [15:0] xVals       [0:X_N-1];

  // circular buffer (STATIC for now)
  logic [15:0] xCirc [0:255];

  // -----------------------
  // Load file + STATIC preload of xCirc[0..9]
  // -----------------------

  integer xCounter = 1;
  initial begin
    $readmemh("data2.in", memRead);

    // split file
    for (int i = 0; i < RJ_N; i++)
      rjVals[i] = memRead[i];

    for (int i = 0; i < COEFF_N; i++)
      coeffVals[i] = memRead[16 + i];

    for (int i = 0; i < X_N; i++)
      xVals[i] = memRead[528 + i];

    // clear entire circular buffer
    for (int i = 0; i < 256; i++)
      xCirc[i] = 16'd0;
    
    xCirc[0] = xVals[0];

    // preload xCirc[0..9] from xVals[0..9]

    // init control
    en_ALU = 1'b0;

    // start DUT
    repeat (2) @(negedge Sclk);
    en_ALU = 1'b1;
  end

  // -----------------------
  // Drive DUT inputs from addresses
  // -----------------------
  always_comb begin
    // rj
    rj = rjVals[rj_address];

    // coeff
    if (coeff_address < COEFF_N)
      coeff = coeffVals[coeff_address];
    else
      coeff = 16'h0000;

    // x from STATIC circular buffer
    x = xCirc[x_address];
  end

  // -----------------------
  // Optional debug
  // -----------------------
  always @(posedge Sclk) begin
    if (en_ALU) begin
     $strobe("[%0t] x_address=%0d  x=%h  xCirc[x_address]=%h",
              $time, x_address, x, xCirc[x_address]);
    end
  end


  always @(negedge Sclk) begin
  if (done) begin
    if (xCounter <= 3500) begin
      xCirc[xCounter % 256] <= xVals[xCounter];
      xCounter <= xCounter + 1;
    end
    else
      $finish;
  end
end

integer outfile;

initial begin
  outfile = $fopen("data2.out","w");
  if(outfile == 0) begin
    $display("File open failed");
    $finish;
  end
end

always @(posedge Sclk) begin
  if(done) begin
    $fdisplay(outfile,"%h", y);
  end
end

final begin
  $fclose(outfile);
end

endmodule