
`include "behavioral_sv/dataController.v"
`include "behavioral_sv/MSDAP_ALU.v"
`include "behavioral_sv/RjMem.v"
`include "behavioral_sv/CoeffMem.v"
`include "behavioral_sv/xMem.v"
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
    // wire [15:0] Datain;
    wire [15:0] DatainL;
    wire [15:0] DatainR;

    wire EnRj;
    wire EnCoeff;
    wire EnX;
    wire WMode;
    wire xWMode;
    wire [8:0] WAddr;
    wire [7:0] xWAddr;
    wire en_ALU;
    wire done, doneL, doneR;

    wire en_P2S;
    wire DataDone;

    // wire [15:0] rj_data;
    // wire [15:0] coeff_data;
    // wire [15:0] x_data;
    // wire zeroFlagD2S2P;
    wire [15:0] rj_dataL;
    wire [15:0] rj_dataR;
    wire [15:0] coeff_dataL;
    wire [15:0] coeff_dataR;
    wire [15:0] x_dataL;
    wire [15:0] x_dataR;
    wire zeroFlagD2S2PL;
    wire zeroFlagD2S2PR;

    wire [3:0] rj_addressL;
    wire [8:0] coeff_addressL;
    wire [7:0] x_addressL;
    wire [3:0] rj_addressR;
    wire [8:0] coeff_addressR;
    wire [7:0] x_addressR;
    // wire [39:0] y;
    wire [39:0] yL;
    wire [39:0] yR;
    wire RModeL;
    wire RModeR;

    wire Reset_inALU;
    wire ClockGateEnable;
    wire Sclk_out;

    and u0(Sclk_out, Sclk, ClockGateEnable);
    and u1(Reset_inALU, Reset_in, Reset_ALU);
    and u2(done, doneL, doneR);

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
    //    .DatainL(DatainL),
    //    .DatainR(DatainR),
        .zeroFlagfromS2PL(zeroFlagD2S2PL),
        .zeroFlagfromS2PR(zeroFlagD2S2PR),

        .EnRj(EnRj),
        .EnCoeff(EnCoeff),
        .EnX(EnX),
        .WMode(WMode),
        .xWMode(xWMode),
        .WAddr(WAddr),
        .xWAddr(xWAddr),
        .en_ALU(en_ALU),
        .Reset_ALU(Reset_ALU),
        .done(done),

        .en_P2S(en_P2S),
        .DataDone(DataDone)
    );
    // .Datain(Datain),
    // .zeroFlagfromS2P(zeroFlagD2S2P),

    // S2P s2p_in (
    //     .InputL_R(InputL),
    //     .Dclk(Dclk),
    //     .Frame(Frame),
    //     .Reset_n(Reset_in),
    //     .en_S2P(en_S2P),
    //     .Input_Ready(InputReady),
    //     .zeroFlag(zeroFlagD2S2P),
    //     .DataIn(Datain)
    // );
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

    // RjMem rj_mem (
    //     .Enable(EnRj),
    //     .Sclk(Sclk_out),
    //     .WMode(WMode),
    //     .WAddr(WAddr[3:0]),
    //     .DataIn(Datain),
    //     .rj_address(rj_address),
    //     .rj(rj_data),
    //     .RMode(RMode)
    // );
    //
    // CoeffMem coeff_mem (
    //     .Enable(EnCoeff),
    //     .Sclk(Sclk_out),
    //     .WMode(WMode),
    //     .WAddr(WAddr),
    //     .DataIn(Datain),
    //     .coeff_address(coeff_address),
    //     .coeff(coeff_data),
    //     .RMode(RMode)
    // );
    //
    // xMem x_mem (
    //     .Enable(EnX),
    //     .Sclk(Sclk_out),
    //     .WMode(xWMode),
    //     .WAddr(xWAddr),
    //     .DataIn(Datain),
    //     .x_address(x_address),
    //     .x(x_data),
    //     .RMode(RMode)
    // );
    RjMem rj_mem_l (
        .Enable(EnRj),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .WAddr(WAddr[3:0]),
        .DataIn(DatainL),
        .rj_address(rj_addressL),
        .rj(rj_dataL),
        .RMode(RModeL)
    );

    RjMem rj_mem_r (
        .Enable(EnRj),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .WAddr(WAddr[3:0]),
        .DataIn(DatainR),
        .rj_address(rj_addressR),
        .rj(rj_dataR),
        .RMode(RModeR)
    );

    CoeffMem coeff_mem_l (
        .Enable(EnCoeff),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .WAddr(WAddr),
        .DataIn(DatainL),
        .coeff_address(coeff_addressL),
        .coeff(coeff_dataL),
        .RMode(RModeL)
    );

    CoeffMem coeff_mem_r (
        .Enable(EnCoeff),
        .Sclk(Sclk_out),
        .WMode(WMode),
        .WAddr(WAddr),
        .DataIn(DatainR),
        .coeff_address(coeff_addressR),
        .coeff(coeff_dataR),
        .RMode(RModeR)
    );

    xMem x_mem_l (
        .Enable(EnX),
        .Sclk(Sclk_out),
        .WMode(xWMode),
        .WAddr(xWAddr),
        .DataIn(DatainL),
        .x_address(x_addressL),
        .x(x_dataL),
        .RMode(RModeL)
    );

    xMem x_mem_r (
        .Enable(EnX),
        .Sclk(Sclk_out),
        .WMode(xWMode),
        .WAddr(xWAddr),
        .DataIn(DatainR),
        .x_address(x_addressR),
        .x(x_dataR),
        .RMode(RModeR)
    );

    // MSDAP_ALU alu_path (
    //     .x(x_data),
    //     .rj(rj_data),
    //     .rj_address(rj_address),
    //     .coeff(coeff_data),
    //     .coeff_address(coeff_address),
    //     .x_address(x_address),
    //     .y(y),
    //     .Sclk(Sclk_out),
    //     .en_ALU(en_ALU),
    //     .Reset_n(Reset_inALU),
    //     .done(done),
    //     .Enable(RMode)
    // );
   MSDAP_ALU alu_pathL (
        .x(x_dataL),
        .rj(rj_dataL),
        .rj_address(rj_addressL),
        .coeff(coeff_dataL),
        .coeff_address(coeff_addressL),
        .x_address(x_addressL),
        .y(yL),
        .Sclk(Sclk_out),
        .en_ALU(en_ALU),
        .Reset_n(Reset_inALU),
        .done(doneL),
        .Enable(RModeL)
    );

    MSDAP_ALU alu_pathR (
        .x(x_dataR),
        .rj(rj_dataR),
        .rj_address(rj_addressR),
        .coeff(coeff_dataR),
        .coeff_address(coeff_addressR),
        .x_address(x_addressR),
        .y(yR),
        .Sclk(Sclk_out),
        .en_ALU(en_ALU),
        .Reset_n(Reset_inALU),
        .done(doneR),
        .Enable(RModeR)
    );

    // P2S p2s_out (
    //     .DataOut(y),
    //     .done(done),
    //     .Sclk(Sclk_out),
    //     .en_P2S(en_P2S),
    //     .Reset_n(Reset_in),
    //     .OutputL_R(OutputL),
    //     .DataDone(DataDone),
    //     .OutputReady(OutReady)
    // );
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
