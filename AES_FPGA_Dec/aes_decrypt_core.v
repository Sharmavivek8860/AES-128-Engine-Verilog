// aes_decrypt_core.v
module aes_decrypt_core (
    input  [127:0] ciphertext,
    input  [127:0] cipher_key,
    output [127:0] plaintext
);
    wire [1407:0] round_keys;
    key_expansion KE(.cipher_key(cipher_key), .round_keys(round_keys));

    // st_dec[0]..st_dec[10], where st_dec[10] = ciphertext ^ round_keys[10]
    wire [127:0] st_dec [0:10];

    assign st_dec[10] = ciphertext ^ round_keys[10*128 +: 128];

    genvar i, b;
    generate
        // produce st_dec[9] down to st_dec[1] by iterating idx = 1..9 and mapping to round = 10 - idx
        for (i = 1; i <= 9; i = i + 1) begin : DEC_LOOP
            // round index we are computing = 10 - i
            localparam integer ROUND = 10 - i;

            wire [127:0] isr;
            wire [127:0] isb;
            wire [127:0] after_xor;
            wire [127:0] imc;

            // InvShiftRows on st_dec[ROUND+1]
            inv_shift_rows ISR (.state_in(st_dec[ROUND+1]), .state_out(isr));

            // InvSubBytes
            wire [7:0] inB[0:15];
            wire [7:0] outB[0:15];
            for (b = 0; b < 16; b = b + 1) begin : INV_SB_BYTES
                assign inB[b] = isr[127 - 8*b -: 8];
                inv_sbox INVSB (.data_in(inB[b]), .data_out(outB[b]));
            end
            assign isb = {
                outB[0], outB[1], outB[2], outB[3],
                outB[4], outB[5], outB[6], outB[7],
                outB[8], outB[9], outB[10], outB[11],
                outB[12], outB[13], outB[14], outB[15]
            };

            // XOR with round key ROUND
            assign after_xor = isb ^ round_keys[ROUND*128 +: 128];

            // InvMixColumns
            inv_mix_columns IMC (.state_in(after_xor), .state_out(imc));

            assign st_dec[ROUND] = imc;
        end
    endgenerate

    // Final (ROUND = 0), using st_dec[1]:
    wire [127:0] isr0;
    wire [127:0] isb0;
    wire [7:0] inBF[0:15];
    wire [7:0] outBF[0:15];

    inv_shift_rows ISR0 (.state_in(st_dec[1]), .state_out(isr0));

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : FINAL_INV_SB
            assign inBF[k] = isr0[127 - 8*k -: 8];
            inv_sbox INVSB_F (.data_in(inBF[k]), .data_out(outBF[k]));
        end
    endgenerate

    assign isb0 = {
        outBF[0], outBF[1], outBF[2], outBF[3],
        outBF[4], outBF[5], outBF[6], outBF[7],
        outBF[8], outBF[9], outBF[10], outBF[11],
        outBF[12], outBF[13], outBF[14], outBF[15]
    };

    assign st_dec[0] = isb0 ^ round_keys[0*128 +: 128];

    assign plaintext = st_dec[0];

endmodule
