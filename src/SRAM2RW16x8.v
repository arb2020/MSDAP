/* Modified to be async read */
module SRAM2RW16x8 (A1,A2,CE1,CE2,WEB1,WEB2,OEB1,OEB2,CSB1,CSB2,I1,I2,O1,O2);

input CE1;
input CE2;
input WEB1;
input WEB2;
input OEB1;
input OEB2;
input CSB1;
input CSB2;

input  [4-1:0]    A1;
input  [4-1:0]    A2;
input  [8-1:0] I1;
input  [8-1:0] I2;
output [8-1:0] O1;
output [8-1:0] O2;

reg     [8-1:0] memory[16-1:0];
wire     [8-1:0] data_out1;
wire     [8-1:0] data_out2;
wire    [8-1:0] O1;
wire    [8-1:0] O2;

wire RE1;
wire RE2;
wire WE1;
wire WE2;
and u1 (RE1, ~CSB1, ~OEB1);
and u2 (RE2, ~CSB2, ~OEB2);
and u3 (WE1, ~CSB1, ~WEB1);
and u4 (WE2, ~CSB2, ~WEB2);

always @ (posedge CE1) begin
//    if (RE1)
//        data_out1 <= memory[A1];
    if (WE1)
        memory[A1] <= I1;
end

always @ (posedge CE2) begin
//    if (RE2)
//        data_out2 <= memory[A2];
    if (WE2)
        memory[A2] <= I2;
end

   assign data_out1 = RE1 ? memory[A1] : 8'd0;
   assign data_out2 = RE2 ? memory[A2] : 8'd0;
   
   
/*Delete the specify block if reported error*/
   /*
reg NOTIFIER;
specify
$setuphold(posedge CE1, posedge I1[0], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[0], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[0], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[0], 0, 0, NOTIFIER);
(CE1 => O1[0]) = 0;
(CE2 => O2[0]) = 0;
$setuphold(posedge CE1, posedge I1[1], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[1], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[1], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[1], 0, 0, NOTIFIER);
(CE1 => O1[1]) = 0;
(CE2 => O2[1]) = 0;
$setuphold(posedge CE1, posedge I1[2], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[2], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[2], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[2], 0, 0, NOTIFIER);
(CE1 => O1[2]) = 0;
(CE2 => O2[2]) = 0;
$setuphold(posedge CE1, posedge I1[3], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[3], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[3], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[3], 0, 0, NOTIFIER);
(CE1 => O1[3]) = 0;
(CE2 => O2[3]) = 0;
$setuphold(posedge CE1, posedge I1[4], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[4], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[4], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[4], 0, 0, NOTIFIER);
(CE1 => O1[4]) = 0;
(CE2 => O2[4]) = 0;
$setuphold(posedge CE1, posedge I1[5], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[5], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[5], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[5], 0, 0, NOTIFIER);
(CE1 => O1[5]) = 0;
(CE2 => O2[5]) = 0;
$setuphold(posedge CE1, posedge I1[6], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[6], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[6], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[6], 0, 0, NOTIFIER);
(CE1 => O1[6]) = 0;
(CE2 => O2[6]) = 0;
$setuphold(posedge CE1, posedge I1[7], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge I2[7], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge I1[7], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge I2[7], 0, 0, NOTIFIER);
(CE1 => O1[7]) = 0;
(CE2 => O2[7]) = 0;
$setuphold(posedge CE1, posedge A1[0], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge A2[0], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge A1[0], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge A2[0], 0, 0, NOTIFIER);
$setuphold(posedge CE1, posedge A1[1], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge A2[1], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge A1[1], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge A2[1], 0, 0, NOTIFIER);
$setuphold(posedge CE1, posedge A1[2], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge A2[2], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge A1[2], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge A2[2], 0, 0, NOTIFIER);
$setuphold(posedge CE1, posedge A1[3], 0, 0, NOTIFIER);
$setuphold(posedge CE2, posedge A2[3], 0, 0, NOTIFIER);
$setuphold(posedge CE1, negedge A1[3], 0, 0, NOTIFIER);
$setuphold(posedge CE2, negedge A2[3], 0, 0, NOTIFIER);

endspecify
*/
assign O1 = data_out1;
assign O2 = data_out2;

endmodule
