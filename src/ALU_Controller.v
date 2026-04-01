module ALU_Controller (

    input wire [15:0] rj,
    output reg [3:0] rj_address,
    input wire [15:0] coeff,
    output reg [8:0] coeff_address,
    output reg [7:0] x_address,
    input Sclk, en_ALU, Reset_in,
    output reg opcode,
    output reg Enable,
    output reg load, shift_en, done, feedbackLoad, clear

);

    reg [8:0] coeffCounter, coeffCounterNext;
    reg [15:0] rjCounter, rjCounterNext;
    reg [3:0] rjAddr, rjAddrNext;
    reg [7:0] xVal, xValNext;
    reg [7:0] xAddr, xAddrNext;
    reg shiftEnable;
    reg loadEnable;
    reg doneVal;
    reg feedbackLoadVal;
    reg clearVal;
    reg opcodeVal;

    reg [2:0] currentState;
    reg [2:0] nextState;

    parameter IDLE_S   = 3'b000;
    parameter EXEC_S   = 3'b001;
    parameter ADD_N_SHIFT_S = 3'b010;
    parameter SHIFT_S  = 3'b011;
    parameter RESET_S  = 3'b100;
    parameter DONE_S   = 3'b101;
    parameter FINAL_ANS_S = 3'b110;

    always @(posedge Sclk or negedge Reset_in) begin
        if(!Reset_in) begin
            rjCounter <= 16'h0000;
            rjAddr <= 4'b0000;
            rj_address <= 4'h0;
            coeffCounter <= 9'b000000000;
            coeff_address <= 9'h000;
            xVal <= 8'h00;
            xAddr <= 8'h00;
            x_address <= 8'h00;
            shift_en <= 1'b0;
            load <= 1'b0;
            feedbackLoad <= 1'b0;
            done <= 1'b0;
            currentState <= IDLE_S;
            clear <= 1'b1;
            opcode <= 1'b0;
            Enable <= 1'b0;
        end
        else if(!en_ALU) begin
            rjCounter <= 16'h0000;
            rjAddr <= 4'b0000;
            rj_address <= 4'h0;
            coeffCounter <= 9'b000000000;
            coeff_address <= 9'h000;
            xAddr <= 8'h00;
            x_address <= 8'h00;
            shift_en <= 1'b0;
            load <= 1'b0;
            feedbackLoad <= 1'b0;
            done <= 1'b0;
            Enable <= 1'b0;
            currentState <= IDLE_S;
            opcode <= 1'b0;
        end
        
        else begin
            currentState <= nextState;
            coeffCounter <= coeffCounterNext;
            rjAddr <= rjAddrNext;
            rjCounter <= rjCounterNext;
            xAddr <= xAddrNext;
            xVal <= xValNext;
            rj_address <= rjAddrNext;
            coeff_address <= coeffCounterNext;
            x_address <= xAddrNext;
            shift_en <= shiftEnable;
            load <= loadEnable;
            done <= doneVal;
            clear <= clearVal;
            feedbackLoad <= feedbackLoadVal;
            opcode <= opcodeVal;
            Enable <= 1'b1;
            $display("[%0t] ALUSTATE=%0d -> NEXT=%0d  rjCnt=%0d rjAddr=%0d coeffCnt=%0d xVal=%0d",
             $time, currentState, nextState,
             rjCounter, rjAddr, coeffCounter, xVal);
        end
    end

    always @(*) begin
        nextState          = currentState;

        coeffCounterNext   = coeffCounter;
        rjCounterNext      = rjCounter;
        rjAddrNext         = rjAddr;
        xAddrNext          = xAddr;
        xValNext           = xVal;

        doneVal            = 1'b0;
        loadEnable         = 1'b0;
        shiftEnable        = 1'b0;
        feedbackLoadVal    = 1'b0;
        clearVal           = 1'b0;
        opcodeVal          = 1'b0;

        case(currentState) 
            IDLE_S: begin
                    if(!en_ALU)
                        nextState = IDLE_S;
                    else
                        nextState = EXEC_S;
                    end
            RESET_S: begin
                        rjCounterNext = 16'h0000;
                        rjAddrNext = 4'b0000;
                        coeffCounterNext = 9'b000000000;
                        nextState = IDLE_S;
                        clearVal = 1'b1;
                     end
            EXEC_S: begin
                        xAddrNext   = xVal - coeff[7:0];
                        loadEnable = 1'b1;
                        opcodeVal = coeff[8];
                        if (coeffCounter >= 9'h1FF) begin
                                nextState = FINAL_ANS_S;
                        
                    end else begin
                        // default: we are advancing within this j
                        coeffCounterNext = coeffCounter + 1'b1;

                        // advance rjCounter
                        rjCounterNext = rjCounter + 1'b1;

                        // if that increment completes the inner loop, shift
                        if (rjCounterNext == rj) begin
                            rjCounterNext = 16'h0000;
                            rjAddrNext    = rjAddr + 1'b1;
                            nextState = ADD_N_SHIFT_S;
                        end else begin
                        nextState     = EXEC_S;
                        end
                    end
                    end
           SHIFT_S: begin
                feedbackLoadVal = 1'b1;
                nextState = EXEC_S;
           end

           ADD_N_SHIFT_S: begin
                shiftEnable = 1'b1;
                nextState = SHIFT_S;
           end
           
           FINAL_ANS_S: begin
                    shiftEnable = 1'b1;
                    nextState = DONE_S;
           end
           

           DONE_S: begin
                doneVal = 1'b1;
                xValNext    = xVal + 1'b1;
                nextState = RESET_S;
           end
           
           
            default: nextState = IDLE_S;
        endcase
    end
    
    

endmodule : ALU_Controller
