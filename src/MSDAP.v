
`include "behavioral_sv/dataController.v"
`include "behavioral_sv/MSDAP_ALU.v"
`include "behavioral_sv/memory_macros.v"
`include "behavioral_sv/S2P.v"
`include "behavioral_sv/P2S.v"

module MSDAP(
    input wire Sclk,
    input wire Dclk,
    input wire Start,
    input wire Reset_n,
    input wire Frame,
    input wire InputL,
    input wire InputR,

    output wire InReady,
    output wire OutReady,
    output wire OutputL,
    output wire OutputR
);

    // -----------------------------------------------------------------
    // Internal wiring
    // -----------------------------------------------------------------
    wire Reset_in;
    wire Reset_ALU;
    wire en_S2P;
    wire InputReady;
    wire [15:0] DatainL;
    wire [15:0] DatainR;

    wire EnRj;
    wire EnCoeff;
    wire EnX;
    wire WMode;
    wire xWMode;
    wire [8:0] Addr;
    wire [3:0] rj_raddrL, rj_raddrR;
    wire [3:0] rj_addrL, rj_addrR;
    wire [8:0] coeff_raddrL, coeff_raddrR;
    wire [8:0] coeff_addrL, coeff_addrR;
    wire [7:0] x_raddrL, x_raddrR;
    wire [7:0] x_addrL, x_addrR;
    wire [7:0] xAddr;
    wire en_ALU;
    wire done, doneL, doneR;

    wire en_P2S;
    wire DataDone;

    wire [7:0] rj_dataL;
    wire [7:0] rj_dataR;
    wire [8:0] coeff_dataL;
    wire [8:0] coeff_dataR;
    wire [15:0] x_dataL;
    wire [15:0] x_dataR;
    wire zeroFlagD2S2PL;
    wire zeroFlagD2S2PR;
    wire all_zeros, all_zeros_l, all_zeros_r;
    wire xStart, xClear;

    // wire [39:0] y;
    wire [39:0] yL;
    wire [39:0] yR;

    wire Reset_inALU;
    wire ClockGateEnable;
    wire Sclk_out;

    and u0(Sclk_out, Sclk, ClockGateEnable);
    and u1(Reset_inALU, Reset_in, Reset_ALU);
    and u2(done, doneL, doneR);
    and u3(all_zeros, all_zeros_l, all_zeros_r);

    

    // -----------------------------------------------------------------
    // Controller
    // -----------------------------------------------------------------
    dataController ctrl (
        .Sclk(Sclk),
        .Start(Start),
        .Reset_n(Reset_n),
        .Frame(Frame),

        .InReady(InReady),
        
        .ClockGateEnable(ClockGateEnable),
        .Reset_in(Reset_in),
        .en_S2P(en_S2P),
        .InputReady(InputReady),

        .zeroFlagfromS2PL(zeroFlagD2S2PL),
        .zeroFlagfromS2PR(zeroFlagD2S2PR),

        .EnRj(EnRj),
        .EnCoeff(EnCoeff),
        .EnX(EnX),
        .WMode(WMode),
        .WAddr(Addr),
        .en_ALU(en_ALU),
        .Reset_ALU(Reset_ALU),
        .done(done),
        .all_zeros(all_zeros),
        .xStart(xStart),
        .xClear(xClear),

        .en_P2S(en_P2S),
        .DataDone(DataDone)
    );

    S2P s2p_in (
        .InputL(InputL),
        .InputR(InputR),
        .Dclk(Dclk),
        .Frame(Frame),
        .Reset_n(Reset_in),
        .en_S2P(en_S2P),
        .Input_Ready(InputReady),
        .zeroFlagL(zeroFlagD2S2PL),
        .zeroFlagR(zeroFlagD2S2PR),
        .DataInL(DatainL),
        .DataInR(DatainR)
    );
    /* 
    RjMem rj_mem_l (
        .Enable(EnRj),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .Addr(Addr[3:0]),
        .DataIn(DatainL),
        .rj_raddr(rj_raddrL),
        .rj(rj_dataL),
        .RMode(RModeL)
    );

    RjMem rj_mem_r (
        .Enable(EnRj),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .Addr(Addr[3:0]),
        .DataIn(DatainR),
        .rj_raddr(rj_raddrR),
        .rj(rj_dataR),
        .RMode(RModeR)
    );
    */
    
    assign rj_addrL = WMode ? Addr[3:0] : rj_raddrL;

    R_MEM rj_mem_l (
        .RW0_en(EnRj),
        .RW0_clk(Sclk_out),
        .RW0_addr(rj_addrL),
        .RW0_wdata(DatainL[7:0]),
        .RW0_rdata(rj_dataL),
        .RW0_wmode(WMode)
    );

    assign rj_addrR = WMode ? Addr[3:0] : rj_raddrR;

    R_MEM rj_mem_r (
        .RW0_en(EnRj),
        .RW0_clk(Sclk_out),
        .RW0_addr(rj_addrR),
        .RW0_wdata(DatainR[7:0]),
        .RW0_rdata(rj_dataR),
        .RW0_wmode(WMode)
    );

    /*
    CoeffMem coeff_mem_l (
        .Enable(EnCoeff),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .Addr(Addr),
        .DataIn(DatainL),
        .coeff_radddr(coeff_radddrL),
        .coeff(coeff_dataL),
        .RMode(RModeL)
    );

    CoeffMem coeff_mem_r (
        .Enable(EnCoeff),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .Addr(Addr),
        .DataIn(DatainR),
        .coeff_radddr(coeff_radddrR),
        .coeff(coeff_dataR),
        .RMode(RModeR)
    );
    */

    assign coeff_addrL = WMode ? Addr : coeff_raddrL;

    CO_MEM coeff_mem_l(
        .RW0_clk(Sclk_out),
        .RW0_en(EnCoeff),
        .RW0_addr(coeff_addrL),
        .RW0_rdata(coeff_dataL),
        .RW0_wdata(DatainL[8:0]),
        .RW0_wmode(WMode),
        .Start(1'b0)
    );

    assign coeff_addrR = WMode ? Addr : coeff_raddrR;

    CO_MEM coeff_mem_r(
        .RW0_clk(Sclk_out),
        .RW0_en(EnCoeff),
        .RW0_addr(coeff_addrR),
        .RW0_rdata(coeff_dataR),
        .RW0_wdata(DatainR[8:0]),
        .RW0_wmode(WMode),
        .Start(1'b0)
    );

    /* 
    xMem x_mem_l (
        .Enable(EnX),
        .Sclk(Sclk_out),
        .WMode(xWMode),
        .Addr(xAddr),
        .DataIn(DatainL),
        .x_address(x_addressL),
        .x(x_dataL),
        .RMode(RModeL)
    );

    xMem x_mem_r (
        .Enable(EnX),
        .Sclk(Sclk_out),
        .WMode(xWMode),
        .Addr(xAddr),
        .DataIn(DatainR),
        .x_address(x_addressR),
        .x(x_dataR),
        .RMode(RModeR)
    );

    */

    assign x_addrL = WMode ? Addr[7:0] : x_raddrL;

    X_MEM x_mem_l(
        .RW0_clk(Sclk),
        .RW0_en(EnX),
        .RW0_addr(x_addrL),
        .RW0_rdata(x_dataL),
        .RW0_wdata(DatainL),
        .RW0_wmode(WMode),
        .all_zeros(all_zeros_l),
        .Start(xStart),
        .clear(xClear)
    );

    assign x_addrR = WMode ? Addr[7:0] : x_raddrR;

    X_MEM x_mem_r(
        .RW0_clk(Sclk),
        .RW0_en(EnX),
        .RW0_addr(x_addrR),
        .RW0_rdata(x_dataR),
        .RW0_wdata(DatainR),
        .RW0_wmode(WMode),
        .all_zeros(all_zeros_r),
        .Start(xStart),
        .clear(xClear)
    );


   MSDAP_ALU alu_pathL (
        .x(x_dataL),
        .rj(rj_dataL),
        .rj_address(rj_raddrL),
        .coeff(coeff_dataL),
        .coeff_address(coeff_raddrL),
        .x_address(x_raddrL),
        .y(yL),
        .Sclk(Sclk_out),
        .en_ALU(en_ALU),
        .Reset_n(Reset_inALU),
        .done(doneL)
    );

    MSDAP_ALU alu_pathR (
        .x(x_dataR),
        .rj(rj_dataR),
        .rj_address(rj_raddrR),
        .coeff(coeff_dataR),
        .coeff_address(coeff_raddrR),
        .x_address(x_raddrR),
        .y(yR),
        .Sclk(Sclk_out),
        .en_ALU(en_ALU),
        .Reset_n(Reset_inALU),
        .done(doneR)
    );


    P2S p2s_out (
        .DataOutL(yL),
        .DataOutR(yR),
        .done(done),
        .Sclk(Sclk_out),    
        .en_P2S(en_P2S),
        .Reset_n(Reset_in),
        .OutputL(OutputL),
        .OutputR(OutputR),
        .DataDone(DataDone),
        .OutputReady(OutReady)
    );

endmodule
