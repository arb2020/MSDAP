
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
    wire [15:0] Datain;

    wire EnRj;
    wire EnCoeff;
    wire EnX;
    wire WMode;
    wire xWMode;
    wire [8:0] WAddr;
    wire [7:0] xWAddr;
    wire en_ALU;
    wire done;

    wire en_P2S;
    wire DataDone;

    wire [15:0] rj_data;
    wire [15:0] coeff_data;
    wire [15:0] x_data;
    wire zeroFlagD2S2P;

    wire [3:0] rj_address;
    wire [8:0] coeff_address;
    wire [7:0] x_address;
    wire [39:0] y;
    wire RMode;

    // -----------------------------------------------------------------
    // Controller
    // -----------------------------------------------------------------
    dataController ctrl (
        .Sclk(Sclk),
        .Dclk(Dclk),
        .Start(Start),
        .Reset_n(Reset_n),
        .Frame(Frame),
        .InputL(InputL),
        .InputR(InputR),

        .InReady(InReady),
        .OutputL(),
        .OutputR(),
        
        .Reset_in(Reset_in),
        .en_S2P(en_S2P),
        .InputReady(InputReady),
        .Datain(Datain),
        .zeroFlagfromS2P(zeroFlagD2S2P),

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

    // -----------------------------------------------------------------
    // Serial-to-parallel input
    // Note: uploaded design only provides one S2P datapath, so InputL is used.
    // -----------------------------------------------------------------
    S2P s2p_in (
        .InputL_R(InputL),
        .Dclk(Dclk),
        .Frame(Frame),
        .Reset_n(Reset_in),
        .en_S2P(en_S2P),
        .Input_Ready(InputReady),
        .zeroFlag(zeroFlagD2S2P),
        .DataIn(Datain)
    );

    // -----------------------------------------------------------------
    // Memories
    // Shared WAddr is used for Rj/Coeff writes; x memory uses xWAddr.
    // -----------------------------------------------------------------
    RjMem rj_mem (
        .Enable(EnRj),
        .Sclk(Sclk),
        .WMode(WMode),
        .WAddr(WAddr[3:0]),
        .DataIn(Datain),
        .rj_address(rj_address),
        .rj(rj_data),
        .RMode(RMode)
    );

    CoeffMem coeff_mem (
        .Enable(EnCoeff),
        .Sclk(Sclk),
        .WMode(WMode),
        .WAddr(WAddr),
        .DataIn(Datain),
        .coeff_address(coeff_address),
        .coeff(coeff_data),
        .RMode(RMode)
    );

    xMem x_mem (
        .Enable(EnX),
        .Sclk(Sclk),
        .WMode(xWMode),
        .WAddr(xWAddr),
        .DataIn(Datain),
        .x_address(x_address),
        .x(x_data),
        .RMode(RMode)
    );

    // -----------------------------------------------------------------
    // ALU datapath
    // -----------------------------------------------------------------
    MSDAP_ALU alu_path (
        .x(x_data),
        .rj(rj_data),
        .rj_address(rj_address),
        .coeff(coeff_data),
        .coeff_address(coeff_address),
        .x_address(x_address),
        .y(y),
        .Sclk(Sclk),
        .en_ALU(en_ALU),
        .Reset_n(Reset_ALU),
        .done(done),
        .Enable(RMode)
    );

    // -----------------------------------------------------------------
    // Parallel-to-serial output
    // -----------------------------------------------------------------
    P2S p2s_out (
        .DataOut(y),
        .done(done),
        .Sclk(Sclk),
        .en_P2S(en_P2S),
        .Reset_n(Reset_in),
        .OutputL_R(OutputL),
        .DataDone(DataDone),
        .OutputReady(OutReady)
    );

endmodule