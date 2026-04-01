module RjMem(
    input wire Enable, 
    input wire Sclk,
    input wire WMode,
    input wire RMode,
    input wire [3:0] WAddr,
    input wire [15:0] DataIn,
    input wire [3:0] rj_address,
    output reg [15:0] rj
);
    reg [15:0] mem [15:0];

    always @(posedge Sclk) begin
        if(Enable && WMode) begin
            mem[WAddr] <= DataIn;
               // $strobe("RJ MEMORY: Write %h to addr %h", DataIn, WAddr);
        end  
    end
    
    always @(*) begin
        if (RMode) begin
            rj = mem[rj_address];
        end
        else 
            rj = 16'h0000;
        
    end
    

endmodule