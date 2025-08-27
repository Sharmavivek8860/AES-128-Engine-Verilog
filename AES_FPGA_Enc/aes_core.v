// aes_core.v
// AES-128 encryption core: combinational unrolled 10 rounds

module aes_core (
    input  [127:0] plaintext,
    input  [127:0] cipher_key,
    output [127:0] ciphertext
);
    // Round keys (11 * 128 = 1408)
    wire [1407:0] round_keys;
    key_expansion KE(.cipher_key(cipher_key), .round_keys(round_keys));

    // Round states 0..10
    wire [127:0] st [0:10];

    // Round 0: AddRoundKey (round 0 located at round_keys[0*128 +:128])
    assign st[0] = plaintext ^ round_keys[0*128 +: 128];

    genvar r, b;
    generate
        for (r=1; r<10; r=r+1) begin : ROUNDS
            wire [127:0] sb, sr, mc;
            // SubBytes: 16 S-boxes
            wire [7:0] inB[0:15];
            wire [7:0] outB[0:15];
            for (b=0; b<16; b=b+1) begin : SB
                assign inB[b] = st[r-1][127 - 8*b -: 8];
                sbox SB_INST(.data_in(inB[b]), .data_out(outB[b]));
            end
            assign sb = {
                outB[0], outB[1], outB[2], outB[3],
                outB[4], outB[5], outB[6], outB[7],
                outB[8], outB[9], outB[10], outB[11],
                outB[12], outB[13], outB[14], outB[15]
            };

            shift_rows SR(.state_in(sb), .state_out(sr));
            mix_columns MC(.state_in(sr), .state_out(mc));

            // AddRoundKey: round i key at round_keys[i*128 +:128]
            assign st[r] = mc ^ round_keys[r*128 +: 128];
        end
    endgenerate

    // Final round (10): SubBytes -> ShiftRows -> AddRoundKey
    wire [127:0] sb_f, sr_f;
    wire [7:0] inBF[0:15];
    wire [7:0] outBF[0:15];
    genvar bf;
    generate
        for (bf=0; bf<16; bf=bf+1) begin : SBF
            assign inBF[bf] = st[9][127 - 8*bf -: 8];
            sbox SBF_INST(.data_in(inBF[bf]), .data_out(outBF[bf]));
        end
    endgenerate
    assign sb_f = {
        outBF[0], outBF[1], outBF[2], outBF[3],
        outBF[4], outBF[5], outBF[6], outBF[7],
        outBF[8], outBF[9], outBF[10], outBF[11],
        outBF[12], outBF[13], outBF[14], outBF[15]
    };
    shift_rows SRF(.state_in(sb_f), .state_out(sr_f));

    assign st[10] = sr_f ^ round_keys[10*128 +: 128];

    // Output
    assign ciphertext = st[10];
endmodule
