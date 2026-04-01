module P2S #(parameter INWIDTH = 40)(
    input wire [INWIDTH-1:0] DataOut,
    input wire Sclk,
    input wire en_P2S,
    input wire Reset_n,
    input wire done,
    output reg OutputL_R,
    output reg DataDone,
    output reg OutputReady
);

    reg [INWIDTH-1:0] shiftReg;
    reg [5:0] Counter;

    always @(posedge Sclk or negedge Reset_n) begin
        if (!Reset_n) begin
            shiftReg   <= {INWIDTH{1'b0}};
            Counter    <= 6'd0;
            OutputL_R  <= 1'b0;
            DataDone   <= 1'b0;
            OutputReady <= 1'b0;
        end
        else if (en_P2S) begin
             if (done) begin
                // Load new result and output MSB
                shiftReg    <= DataOut;
                OutputL_R   <= DataOut[INWIDTH-1];
                Counter     <= 6'd1;
                DataDone    <= 1'b0;
                OutputReady <= 1'b1;
                $display("[%0t] P2S loaded: DataOut = %h", $time, DataOut);
            end
            else if (Counter > 0) begin
                // Keep shifting
                shiftReg  <= {shiftReg[INWIDTH-2:0], 1'b0};
                OutputL_R <= shiftReg[INWIDTH-2];

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