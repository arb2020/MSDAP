module CoeffMem(
    input wire Enable, 
    input wire Sclk,
    input wire WMode,
    input wire RMode,
    input wire [8:0] WAddr,
    input wire [15:0] DataIn,
    input wire [8:0] coeff_address,
    output reg [15:0] coeff
);

    reg [15:0] mem [511:0];

    always @(posedge Sclk) begin
        if(Enable && WMode) begin
            mem[WAddr] <= DataIn;
               // $strobe("COEFF MEMORY: Write %h to addr %h", DataIn, WAddr);
        end  
    end
    
    always @(*) begin
        if (RMode) begin
            coeff = mem[coeff_address];
        end
        else 
            coeff = 16'h0000;
        
    end

endmodule