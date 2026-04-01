module oneBitShift (
    input  wire        clk,
    input  wire [39:0]  addOp,
    input  wire         clear,
    input  wire         shift_en,
    output reg  [39:0]  yOut
);

    always @(posedge clk) begin
        if (clear) begin
            yOut <= 40'h0000000000;
        end
        else if (shift_en) begin
            yOut <= {addOp[39], addOp[39:1]};
        end

        // Debug strobe (prints AFTER yOut updates)
        //$strobe("[%0t] clear=%b shift_en=%b addOp=%h yOut=%h",
                //$time, clear, shift_en, addOp, yOut);
    end

endmodule : oneBitShift