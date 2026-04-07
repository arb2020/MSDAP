module dataController(
    input wire Sclk,
    input wire Start,
    input wire Reset_n,
    input wire Frame,
    // input wire zeroFlagfromS2P,
    input wire zeroFlagfromS2PL,
    input wire zeroFlagfromS2PR,

    output reg InReady,

    output reg ClockGateEnable,
    output reg Reset_in,
    output reg Reset_ALU,
    output reg en_S2P,
    input wire InputReady,
    // input wire [15:0] Datain,
    //input wire [15:0] DatainL,
    //input wire [15:0] DatainR,

    output reg EnRj,
    output reg EnCoeff,
    output reg EnX,
    output reg WMode,
    output reg xWMode,
    output reg [8:0] WAddr,
    output reg [7:0] xWAddr,
    output reg en_ALU,
    input wire done,

    output reg en_P2S,
    input wire DataDone

);


    parameter INIT_S        = 4'b0000;
    parameter INIT_COUNT_S  = 4'b1001;
    parameter WAIT_RJ_S     = 4'b0001;
    parameter READ_RJ_S     = 4'b0010;
    parameter WAIT_COEFF_S  = 4'b0011;
    parameter READ_COEFF_S  = 4'b0100;
    parameter WAIT_INPUT_S  = 4'b0101;
    parameter WORKING_S     = 4'b0110;
    parameter CLEARING_S    = 4'b0111;
    parameter SLEEPING_S    = 4'b1000; 
    
    reg [3:0] currentState;
    reg [3:0] nextState;
    
    reg [8:0] initCounter, initCounterNext; //For counting upto to 511 in initializing to zero.
    reg [3:0] rjCounter, rjCounterNext; //For counting the values of Rj being stored.
    reg [8:0] coeffCounter, coeffCounterNext; //For counting the values of coeff.
    reg [7:0] xCounter, xCounterNext; //For counting the values of input values being stored in the circular loop.
    reg [9:0] zeroCounter, zeroCounterNext; //For counting the values of zero
    reg InReadyNext;
    reg Reset_inNext, Reset_ALUNext;
    reg en_S2PNext, EnRjNext, EnCoeffNext, EnXNext;
    reg WModeNext, en_ALUNext, en_P2SNext, en_P2SVal;
    reg xWModeVal, xWModeNext;
    reg xStored, xStoredNext;
    reg doneVal, doneValNext;
    reg sleepingState, sleepingStateNext;
    reg inputReceived, inputReceivedNext;
    reg [5:0] p2sCounter, p2sCounterNext;
    reg [8:0] WAddrVal ,WAddrNext; 
    reg [7:0] xWAddrNext, xWAddrVal;
    reg tk, tkNext;
    reg ClockGateEnableNext;
 
    always @(posedge Sclk) begin
        if(Start) begin
            initCounter     <= 9'h000;
            rjCounter       <= 4'h0;
            coeffCounter    <= 9'h000;
            xCounter        <= 8'h00;
            zeroCounter     <= 10'h000;
            doneVal         <= 1'b1;
            en_P2SVal       <= 1'b0;
            en_S2P          <= 1'b0;
            en_P2S          <= 1'b0;
            en_ALU          <= 1'b0;
            EnRj            <= 1'b0;
            EnCoeff         <= 1'b0;
            EnX             <= 1'b0;
            WMode           <= 1'b0;
            WAddr           <= 9'h000;
            WAddrVal        <= 9'h000;
            xWModeVal       <= 1'b0;
            xStored         <= 1'b0;
            sleepingState   <= 1'b0;
            xWMode          <= 1'b0;
            xWAddr          <= 8'h00;
            xWAddrVal       <= 8'h00;
            p2sCounter      <= 6'd0;
            InReady         <= 1'b0;
            Reset_in        <= 1'b0;
            Reset_ALU       <= 1'b0;
            ClockGateEnable <= 1'b1;
            tk              <= 1'b0;
            inputReceived   <= 1'b0;
            currentState    <= INIT_S;
        end
        else begin
        // State update
            currentState <= nextState;

            // Counters
            initCounter  <= initCounterNext;
            rjCounter    <= rjCounterNext;
            coeffCounter <= coeffCounterNext;
            xCounter     <= xCounterNext;
            zeroCounter  <= zeroCounterNext;
            doneVal      <= doneValNext;
            tk           <= tkNext;
            p2sCounter   <= p2sCounterNext;
            inputReceived <= inputReceivedNext;
            sleepingState <= sleepingStateNext;

            // Control signals
            en_S2P      <= en_S2PNext;
            en_P2S      <= en_P2SNext;
            en_P2SVal   <= en_P2SNext;
            en_ALU      <= en_ALUNext;

            EnRj        <= EnRjNext;
            EnCoeff     <= EnCoeffNext;
            EnX         <= EnXNext;

            WMode       <= WModeNext;
            WAddr       <= WAddrNext;
            WAddrVal    <= WAddrNext;
            xWAddr      <= xWAddrNext;
            xWAddrVal   <= xWAddrNext;
            xWMode      <= xWModeNext;
            xWModeVal   <= xWModeNext;
            xStored     <= xStoredNext;

            InReady     <= InReadyNext;

            ClockGateEnable <= ClockGateEnableNext;

            Reset_in    <= Reset_inNext;
            Reset_ALU   <= Reset_ALUNext;

            $display("[%0t] mainSTATE=%0d -> NEXT=%0d",
             $time, currentState, nextState);
        end        
    end

    always @(*) begin
       nextState = currentState;

        // Counters
        initCounterNext     = initCounter;
        rjCounterNext       = rjCounter;
        coeffCounterNext    = coeffCounter;
        xCounterNext        = xCounter;
        zeroCounterNext     = zeroCounter;
        doneValNext         = doneVal;
        tkNext              = tk;
        p2sCounterNext      = p2sCounter;
        inputReceivedNext   = inputReceived;
	    xWModeNext 	        = xWModeVal;
        sleepingStateNext   = sleepingState;



        // Control signals
        InReadyNext  = 1'b0;

        en_S2PNext   = 1'b0;
        en_P2SNext   = en_P2SVal;
        en_ALUNext   = 1'b0;

        EnRjNext     = 1'b0;
        EnCoeffNext  = 1'b0;
        EnXNext      = 1'b0;


        WModeNext    = 1'b0;
        WAddrNext    = WAddrVal;
        xWAddrNext   = xWAddrVal;
        xStoredNext  = xStored;

        Reset_inNext = 1'b1;
        Reset_ALUNext = 1'b1;

        ClockGateEnableNext = 1'b1;

        case(currentState) 

            INIT_S:         begin
                                en_S2PNext = 1'b1;
                                Reset_inNext = 1'b0;
                                // if(InputReady && (Datain == 16'h0000)) begin
                                if(zeroFlagfromS2PL && zeroFlagfromS2PR) begin
                                    nextState = INIT_COUNT_S;
                                end
                                else nextState = INIT_S;
                            end

            INIT_COUNT_S:   begin
                                en_S2PNext  = 1'b1;
                                EnCoeffNext = 1'b1;
                                EnRjNext    = 1'b1;
                                EnXNext     = 1'b1;
                                WModeNext   = 1'b1;
                                xWModeNext  = 1'b1;
                                WAddrNext   = initCounter;
                                xWAddrNext  = initCounter[7:0];
                                initCounterNext = initCounter + 1'b1;

                                if(initCounter >= 9'h1FF) begin
                                    nextState = WAIT_RJ_S;
                                    en_S2PNext = 1'b1;
                                end
                                else nextState = INIT_COUNT_S;
                            end
            WAIT_RJ_S:      begin
                                en_S2PNext  = 1'b1;
                                InReadyNext = 1'b1;
                                if(Frame) begin
                                    nextState =  READ_RJ_S;
                                end
                                else begin
                                    nextState = WAIT_RJ_S;
                                end
                            end
            READ_RJ_S:      begin
                                en_S2PNext  = 1'b1;
                                InReadyNext = 1'b1;
                                if(InputReady && !tk) begin
                                    if(rjCounter <= 4'hF) begin
                                    EnRjNext = 1'b1;
                                    WModeNext = 1'b1;
                                    WAddrNext = {5'h00,rjCounter};
                                    rjCounterNext = rjCounter + 1'b1;
                                    nextState = READ_RJ_S;
                                    tkNext = 1'b1;
                                    end
                                    if(rjCounter == 4'hF) begin
                                        nextState = WAIT_COEFF_S;
                                    end
                                    else begin
                                        nextState = READ_RJ_S;
                                    end
                                end
                                else if(InputReady == 1'b0) begin
                                    tkNext = 1'b0;
                                    EnRjNext = 1'b0;
                                    nextState = READ_RJ_S;
                                end
                                else begin
                                    nextState = READ_RJ_S;
                                end
                            end
            WAIT_COEFF_S:   begin
                                en_S2PNext  = 1'b1;
                                InReadyNext = 1'b1;
                                if(Frame) begin
                                    nextState =  READ_COEFF_S;
                                end
                                else begin
                                    nextState = WAIT_COEFF_S;
                                end
                            end
            READ_COEFF_S:   begin
                                en_S2PNext  = 1'b1;
                                InReadyNext = 1'b1;
                                if(InputReady && !tk) begin
                                    if(coeffCounter <= 9'h1FF) begin
                                    EnCoeffNext = 1'b1;
                                    WModeNext = 1'b1;
                                    WAddrNext = coeffCounter;
                                    coeffCounterNext = coeffCounter + 1'b1;
                                    nextState = READ_COEFF_S;
                                    tkNext = 1'b1;
                                    end    
                                    if(coeffCounter == 9'h1FF) begin
                                        nextState = WAIT_INPUT_S; 
                                    end
                                    else begin
                                        nextState = READ_COEFF_S;
                                    end
                                end    
                                else if(InputReady == 1'b0) begin
                                    tkNext = 1'b0;
                                    EnCoeffNext = 1'b0;
                                    nextState = READ_COEFF_S; 
                                end
                                else begin
                                    nextState = READ_COEFF_S;
                                end
                            end
            WAIT_INPUT_S: begin
                            en_S2PNext        = 1'b1;
                            InReadyNext       = 1'b1;
                            tkNext            = 1'b0;
                            inputReceivedNext = 1'b0;
                            zeroCounterNext   = 10'd0;

                            if(!Reset_n) begin
                                nextState = CLEARING_S;
                                xCounterNext = 8'h00;
                                EnXNext = 1'b1;
                                xWModeNext = 1'b1;
                                xWAddrNext = xCounter;
                                Reset_inNext = 1'b0;
                                en_S2PNext = 1'b1;
                            end
                            else if(Frame && !InputReady) begin
                                nextState = WORKING_S;
                                xCounterNext = 8'h00;
                            end
                            else
                                nextState = WAIT_INPUT_S;
                        end
            WORKING_S:      begin      
                                if(!Reset_n) begin
                                    nextState = CLEARING_S;
                                    InReadyNext = 1'b0;
                                    xStoredNext = 1'b0;
                                    xCounterNext = 8'h00;
                                    Reset_inNext = 1'b0;
                                    en_S2PNext = 1'b1;
                                    EnXNext = 1'b1;
                                    xWModeNext = 1'b1;
                                    xWAddrNext = xCounter;
                                end
                                else begin
                                    en_S2PNext  = 1'b1;
                                    InReadyNext = 1'b1;
                                    en_P2SNext = 1'b1;
                                    //$display("Time=%0t | zeroCounter=%0d | xCounter=%0d", $time, zeroCounterNext, xCounter);
                                    if(InputReady && !xStored) begin
                                        EnXNext = 1'b1;
                                        xStoredNext = 1'b1;
                                        xWModeNext = 1'b1;
                                        xWAddrNext = xCounter;
                                        xCounterNext = xCounter + 1'b1;
                                        // if(zeroFlagfromS2P) begin
                                        //     zeroCounterNext = zeroCounter + 1'b1;
                                        // end
                                        // else begin
                                        //     zeroCounterNext = 10'd0;
                                        // end
                                        if(zeroFlagfromS2PL && zeroFlagfromS2PR) begin
                                            zeroCounterNext = zeroCounter + 1'b1;
                                        end
                                        else begin
                                            zeroCounterNext = 10'd0;
                                        end
                                        nextState = WORKING_S;
                                    end
                                    if(xStored) begin
                                        en_ALUNext = 1'b1;
                                    end
                                    if(done) begin
                                        xStoredNext = 1'b0;
                                    end
                                
                                    if(zeroCounter == 10'd801) begin
                                        sleepingStateNext = 1'b1;
                                    end
                                    if(sleepingState && DataDone) begin
                                        nextState = SLEEPING_S;
                                        en_P2SNext = 1'b0;
                                        InReadyNext = 1'b1;
                                        xStoredNext = 1'b0;
                                        Reset_ALUNext = 1'b0;
                                    end
                                    else
                                        nextState = WORKING_S;
                                end
                            end                    
            CLEARING_S:     begin
                                $display("Time=%0t | RESET SUCCESS | xCounter=%0d", $time, xCounter);
                                InReadyNext = 1'b0;
                                tkNext = 1'b0;
                                xCounterNext = xCounter + 1'b1;
                                EnXNext = 1'b1;
                                xWModeNext = 1'b1;
                                xWAddrNext = xCounter;
                                if(!Reset_n) begin
                                    nextState = CLEARING_S;
                                    xCounterNext = 8'h00;  // restart the sweep from 0
                                    Reset_inNext = 1'b0;
                                    en_S2PNext = 1'b1;
                                end
                                else if(xCounter == 8'hFF) begin
                                    nextState = WAIT_INPUT_S;
                                    InReadyNext = 1'b1;
                                end
                                else begin
                                    nextState = CLEARING_S;
                                    
                                end                             
                            end
            SLEEPING_S:     begin
                                ClockGateEnableNext = 1'b0;
                                InReadyNext = 1'b1;
                                en_S2PNext = 1'b1;
                                if(!Reset_n) begin
                                    nextState       = CLEARING_S; 
                                    xCounterNext    = 8'h00;
                                    xStoredNext     = 1'b0;
                                    sleepingStateNext = 1'b0;    // critical — clear sleep flag
                                    zeroCounterNext = 10'd0;     // clear zero counter
                                    Reset_inNext    = 1'b0;
                                    en_S2PNext      = 1'b1;
                                end

                                else if(InputReady) begin
                                    // if(zeroFlagfromS2P) begin
                                    if(zeroFlagfromS2PL && zeroFlagfromS2PR) begin
                                        nextState = SLEEPING_S;
                                    end
                                    else begin
                                        xCounterNext = 8'h00;
                                        nextState = WORKING_S;
                                        sleepingStateNext = 1'b0;
                                        zeroCounterNext = 10'd0;

                                    end
                                end  
                            end
            
            
            default: nextState = INIT_S;
        endcase 

    end

endmodule
