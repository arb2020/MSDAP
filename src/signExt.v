module signExt #(parameter INPUTSIZE = 16, parameter OUTPUTSIZE = 40)(
    input wire [INPUTSIZE-1:0] in,
    output wire [OUTPUTSIZE-1:0] out
);
        
    assign out  = (in[INPUTSIZE-1]) ? {8'hFF, in, 16'h0000} : {8'h00, in, 16'h0000};
    
endmodule
