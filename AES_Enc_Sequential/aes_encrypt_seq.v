// aes_encrypt_seq.v
// Sequential AES-128 encryption (iterative): 1 round per clock.
// Uses external modules:
//  - sbox (8-bit in/out)         : provided by you
//  - shift_rows (128-bit)       : provided by you
//  - mix_columns (128-bit)      : provided by you
//  - key_expansion (128-bit in, 1408-bit out) : provided by you
//
// Protocol:
//  - start (pulse) begins operation
//  - done asserted one cycle after final round completes
//  - ciphertext holds final result when done is high

module aes_encrypt_seq (
    input  wire        clk,
    input  wire        rst,            // synchronous reset (active high)
    input  wire        start,          // pulse to start encryption
    input  wire [127:0] plaintext,     // input block
    input  wire [127:0] key,           // cipher key (128-bit)
    output reg  [127:0] ciphertext,    // output block when done
    output reg         done            // high for one cycle when ciphertext valid
);

    // Key expansion: produce all round keys at once
    // Expectation: key_expansion outputs 11 round keys packed so that
    // round_keys[i*128 +: 128] == round i key (i = 0..10)
    wire [1407:0] round_keys;
    key_expansion KE (
        .cipher_key(key),
        .round_keys(round_keys)
    );

    // Internal state register and control
    reg [127:0] state_reg;
    reg [3:0]   round_cnt;    // will hold values 0..10 (we'll use 1..10 for rounds)
    reg         busy;

    // Combinational nets for round operations (computed from current state_reg)
    wire [127:0] sb_bytes;    // after SubBytes (16 sboxes)
    wire [127:0] sr_bytes;    // after ShiftRows
    wire [127:0] mc_bytes;    // after MixColumns

    // Instantiate 16 S-boxes (each is 8-bit -> 8-bit)
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : SBOX_GEN
            // Map the byte i as MSB-first index: byte i = state_reg[127 - 8*i -: 8]
            sbox SBOX_INST (
                .data_in  ( state_reg[127 - 8*i -: 8] ),
                .data_out ( sb_bytes[127 - 8*i -: 8] )
            );
        end
    endgenerate

    // ShiftRows and MixColumns modules operate on full 128-bit states
    shift_rows SHIFT_INST (
        .state_in  ( sb_bytes ),
        .state_out ( sr_bytes )
    );

    mix_columns MIX_INST (
        .state_in  ( sr_bytes ),
        .state_out ( mc_bytes )
    );

    // Main FSM / datapath
    // Sequence:
    //  - On start: state_reg <= plaintext ^ round_keys[0]
    //  - For round = 1..9: state_reg <= (MixColumns(ShiftRows(SubBytes(state_reg)))) ^ round_keys[round]
    //  - For round = 10: state_reg <= (ShiftRows(SubBytes(state_reg))) ^ round_keys[10]; then done
    always @(posedge clk) begin
        if (rst) begin
            state_reg   <= 128'd0;
            round_cnt   <= 4'd0;
            busy        <= 1'b0;
            ciphertext  <= 128'd0;
            done        <= 1'b0;
        end else begin
            done <= 1'b0; // default, pulse when final completed

            if (!busy) begin
                if (start) begin
                    // Initialize: apply initial AddRoundKey (round 0)
                    state_reg <= plaintext ^ round_keys[0*128 +: 128];
                    round_cnt <= 4'd1; // next we will do round 1
                    busy      <= 1'b1;
                end
            end else begin
                // busy == 1: perform rounds
                if (round_cnt < 4'd10) begin
                    // Rounds 1..9: use MixColumns output
                    // round_keys[round_cnt*128 +: 128] is key for this round
                    state_reg <= mc_bytes ^ round_keys[round_cnt*128 +: 128];
                    round_cnt <= round_cnt + 1;
                end else if (round_cnt == 4'd10) begin
                    // Final round (10): no MixColumns, use ShiftRows(SubBytes) directly
                    state_reg <= sr_bytes ^ round_keys[10*128 +: 128];
                    // produce ciphertext next cycle (we can output immediately or in next cycle)
                    ciphertext <= sr_bytes ^ round_keys[10*128 +: 128];
                    done <= 1'b1;
                    busy <= 1'b0;
                    round_cnt <= 4'd0;
                end
            end
        end
    end

endmodule
