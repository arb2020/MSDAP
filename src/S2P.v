module S2P #(parameter OUTWIDTH = 16)(
    // input wire InputL_R,
    input wire InputL,
    input wire InputR,
    input wire Dclk,
    input wire Frame,
    input wire Reset_n,
    input wire en_S2P,
    output reg Input_Ready,
    // output reg zeroFlag,
    // output reg [OUTWIDTH-1:0] DataIn
    output reg zeroFlagL,
    output reg zeroFlagR,
    output reg [OUTWIDTH-1:0] DataInL,
    output reg [OUTWIDTH-1:0] DataInR
);

    reg [4:0] Counter;
    always @(negedge Dclk or negedge Reset_n) begin
        if (!Reset_n) begin
            // DataIn      <= {OUTWIDTH{1'b0}};
            DataInL      <= {OUTWIDTH{1'b0}};
            DataInR      <= {OUTWIDTH{1'b0}};
            Counter     <= 5'd0;
            Input_Ready <= 1'b1;
            // zeroFlag    <= 1'b0;
            zeroFlagL   <= 1'b1;
            zeroFlagR   <= 1'b1;
        end
        else if (en_S2P) begin
            if (Frame) begin
                // DataIn      <= {{(OUTWIDTH-1){1'b0}}, InputL_R};
                DataInL      <= {{(OUTWIDTH-1){1'b0}}, InputL};
                DataInR      <= {{(OUTWIDTH-1){1'b0}}, InputR};
                Counter     <= 5'd1;
                Input_Ready <= 1'b0;
                // zeroFlag    <= 1'b0;
                zeroFlagL   <= 1'b0;
                zeroFlagR   <= 1'b0;
            end
            else if (Counter > 0 && Counter < OUTWIDTH) begin
                // DataIn <= {DataIn[OUTWIDTH-2:0], InputL_R};
                DataInL <= {DataInL[OUTWIDTH-2:0], InputL};
                DataInR <= {DataInR[OUTWIDTH-2:0], InputR};
                if (Counter == OUTWIDTH-1) begin
                    Counter     <= 5'd0;
                    Input_Ready <= 1'b1;
                    // if (DataIn == 16'h0000)
                    //     zeroFlag <= 1'b1;
                    // else
                    //     zeroFlag <= 1'b0;
                    zeroFlagL   <= ({DataInL[OUTWIDTH-2:0], InputL} == {OUTWIDTH{1'b0}});
                    zeroFlagR   <= ({DataInR[OUTWIDTH-2:0], InputR} == {OUTWIDTH{1'b0}});
                end
                else begin
                    Counter     <= Counter + 1'b1;
                    Input_Ready <= 1'b0;
                    // zeroFlag    <= 1'b0;
                    zeroFlagL   <= 1'b0;
                    zeroFlagR   <= 1'b0;
                end
            end
            else begin
                Input_Ready <= 1'b0;
                zeroFlagL   <= 1'b0;
                zeroFlagR   <= 1'b0;
            end
        end
    end

endmodule
