module xMem(
    input wire Enable, 
    input wire Sclk,
    input wire WMode,
    input wire RMode,
    input wire [7:0] WAddr,
    input wire [15:0] DataIn,
    input wire [7:0] x_address,
    output reg [15:0] x
);

    reg [15:0] mem [255:0];

    always @(posedge Sclk) begin
        if(Enable && WMode) begin
            mem[WAddr] <= DataIn;
                $strobe("X MEMORY: Write %h to addr %h", DataIn, WAddr);
        end  
    end
    
    always @(*) begin
        if (RMode) begin
            x = mem[x_address];
        end
        else 
            x = 16'h0000;
        
    end

endmodule