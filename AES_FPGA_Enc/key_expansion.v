// key_expansion.v
// AES-128 key expansion: produces 11 round keys (round 0..10), 128 bits each.
// Output packing: round_keys[i*128 +:128] == round i key, with i=0..10

module key_expansion (
    input  [127:0] cipher_key,
    output [1407:0] round_keys
);
    // Rcon
    wire [7:0] Rcon [0:9];
    assign Rcon[0]=8'h01; assign Rcon[1]=8'h02; assign Rcon[2]=8'h04; assign Rcon[3]=8'h08;
    assign Rcon[4]=8'h10; assign Rcon[5]=8'h20; assign Rcon[6]=8'h40; assign Rcon[7]=8'h80;
    assign Rcon[8]=8'h1b; assign Rcon[9]=8'h36;

    // Round key words (rk[0]..rk[10]) each 128-bit
    wire [127:0] rk [0:10];
    assign rk[0] = cipher_key;

    genvar i;
    generate
        for (i=1; i<=10; i=i+1) begin : GEN_RK
            // Extract previous words
            wire [31:0] w0_prev = rk[i-1][127:96];
            wire [31:0] w1_prev = rk[i-1][95:64];
            wire [31:0] w2_prev = rk[i-1][63:32];
            wire [31:0] w3_prev = rk[i-1][31:0];

            // RotWord on w3_prev
            wire [31:0] rot = {w3_prev[23:0], w3_prev[31:24]};

            // SubWord: apply S-box per byte
            wire [7:0] s3,s2,s1,s0;
            sbox s3u(.data_in(rot[31:24]), .data_out(s3));
            sbox s2u(.data_in(rot[23:16]), .data_out(s2));
            sbox s1u(.data_in(rot[15:8]),  .data_out(s1));
            sbox s0u(.data_in(rot[7:0]),   .data_out(s0));
            wire [31:0] sub = {s3, s2, s1, s0};

            // temp = SubWord(RotWord(w3_prev)) ^ {Rcon[i-1], 24'h000000}
            wire [31:0] temp = sub ^ {Rcon[i-1], 24'h000000};

            // new words
            wire [31:0] w0 = w0_prev ^ temp;
            wire [31:0] w1 = w1_prev ^ w0;
            wire [31:0] w2 = w2_prev ^ w1;
            wire [31:0] w3 = w3_prev ^ w2;

            assign rk[i] = {w0, w1, w2, w3};
        end
    endgenerate

    // Pack round_keys so that slice i*128 +:128 = rk[i]
    assign round_keys = { rk[10], rk[9], rk[8], rk[7], rk[6], rk[5], rk[4], rk[3], rk[2], rk[1], rk[0] };
endmodule
