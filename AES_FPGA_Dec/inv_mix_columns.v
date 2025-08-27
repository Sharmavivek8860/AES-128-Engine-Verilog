// inv_mix_columns.v
module inv_mix_columns (
    input  [127:0] state_in,
    output [127:0] state_out
);
    wire [7:0] b[0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : SPLIT
            assign b[i] = state_in[127 - 8*i -: 8];
        end
    endgenerate

    function [7:0] xtime; input [7:0] a; begin xtime = a[7] ? ((a<<1) ^ 8'h1b) : (a<<1); end endfunction
    function [7:0] mul2; input [7:0] a; begin mul2 = xtime(a); end endfunction
    function [7:0] mul4; input [7:0] a; begin mul4 = xtime(mul2(a)); end endfunction
    function [7:0] mul8; input [7:0] a; begin mul8 = xtime(mul4(a)); end endfunction

    function [7:0] mul9; input [7:0] a; begin mul9  = mul8(a) ^ a; end endfunction
    function [7:0] mul11; input [7:0] a; begin mul11 = mul8(a) ^ mul2(a) ^ a; end endfunction
    function [7:0] mul13; input [7:0] a; begin mul13 = mul8(a) ^ mul4(a) ^ a; end endfunction
    function [7:0] mul14; input [7:0] a; begin mul14 = mul8(a) ^ mul4(a) ^ mul2(a); end endfunction

    `define INVCOL(a0,a1,a2,a3,r0,r1,r2,r3) \
        assign r0 = mul14(a0) ^ mul11(a1) ^ mul13(a2) ^ mul9(a3); \
        assign r1 = mul9(a0)  ^ mul14(a1) ^ mul11(a2) ^ mul13(a3); \
        assign r2 = mul13(a0) ^ mul9(a1)  ^ mul14(a2) ^ mul11(a3); \
        assign r3 = mul11(a0) ^ mul13(a1) ^ mul9(a2)  ^ mul14(a3)

    wire [7:0] r0,r1,r2,r3, r4,r5,r6,r7, r8,r9,r10,r11, r12,r13,r14,r15;

    `INVCOL(b[0], b[1], b[2], b[3],    r0,  r1,  r2,  r3);
    `INVCOL(b[4], b[5], b[6], b[7],    r4,  r5,  r6,  r7);
    `INVCOL(b[8], b[9], b[10], b[11],  r8,  r9,  r10, r11);
    `INVCOL(b[12],b[13],b[14],b[15],  r12, r13, r14, r15);

    assign state_out = {
        r0, r1, r2, r3,
        r4, r5, r6, r7,
        r8, r9, r10, r11,
        r12, r13, r14, r15
    };

    `undef INVCOL
endmodule
