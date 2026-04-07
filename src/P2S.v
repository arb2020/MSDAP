module P2S #(parameter INWIDTH = 40)(
    // input wire [INWIDTH-1:0] DataOut,
    input wire [INWIDTH-1:0] DataOutL,
    input wire [INWIDTH-1:0] DataOutR,
    input wire Sclk,
    input wire en_P2S,
    input wire Reset_n,
    input wire done,
    // output reg OutputL_R,
    output reg OutputL,
    output reg OutputR,
    output reg DataDone,
    output reg OutputReady
);

    // reg [INWIDTH-1:0] shiftReg;
    reg [INWIDTH-1:0] shiftRegL;
    reg [INWIDTH-1:0] shiftRegR;
    reg [5:0] Counter;

    always @(posedge Sclk or negedge Reset_n) begin
        if (!Reset_n) begin
            // shiftReg   <= {INWIDTH{1'b0}};
            shiftRegL   <= {INWIDTH{1'b0}};
            shiftRegR   <= {INWIDTH{1'b0}};
            Counter    <= 6'd0;
            // OutputL_R  <= 1'b0;
            OutputL    <= 1'b0;
            OutputR    <= 1'b0;
            DataDone   <= 1'b0;
            OutputReady <= 1'b0;
        end
        else if (en_P2S) begin
             if (done) begin
                // shiftReg    <= DataOut;
                // OutputL_R   <= DataOut[INWIDTH-1];
                shiftRegL   <= DataOutL;
                shiftRegR   <= DataOutR;
                OutputL     <= DataOutL[INWIDTH-1];
                OutputR     <= DataOutR[INWIDTH-1];
                Counter     <= 6'd1;
                DataDone    <= 1'b0;
                OutputReady <= 1'b1;
                $display("[%0t] P2S loaded: DataOutL = %h DataOutR = %h", $time, DataOutL, DataOutR);
            end
            else if (Counter > 0) begin
                // shiftReg  <= {shiftReg[INWIDTH-2:0], 1'b0};
                // OutputL_R <= shiftReg[INWIDTH-2];
                shiftRegL <= {shiftRegL[INWIDTH-2:0], 1'b0};
                shiftRegR <= {shiftRegR[INWIDTH-2:0], 1'b0};
                OutputL   <= shiftRegL[INWIDTH-2];
                OutputR   <= shiftRegR[INWIDTH-2];

                if (Counter == INWIDTH-1) begin
                    Counter     <= 6'd0;
                    DataDone    <= 1'b1;
                    OutputReady <= 1'b1;
                end
                else begin
                    Counter     <= Counter + 1'b1;
                    DataDone    <= 1'b0;
                    OutputReady <= 1'b1;
                end
            end
            else begin
                OutputReady <= 1'b0;
            end
            
        end
        else begin
            DataDone    <= 1'b0;
            OutputReady <= 1'b0;
            Counter     <= 6'd0;
        end
    end
endmodule
