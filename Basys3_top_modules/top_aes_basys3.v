`timescale 1ns / 1ps

module top_aes_basys3(
    input wire clk,          // 100 MHz Basys3 clock
    input wire btnC,         // Center button -> reset
    input wire btnU,         // Up button -> start encryption
    output wire [15:0] led   // LEDs show part of ciphertext + done
);

    // Internal signals
    wire rst, start;
    wire done;
    wire [127:0] ciphertext;

    // Hardcoded test vector (NIST example)
    reg [127:0] plaintext = 128'h00112233445566778899aabbccddeeff;
    reg [127:0] key       = 128'h000102030405060708090a0b0c0d0e0f;

    // Reset & start from buttons
    assign rst   = btnC;   // Active high reset
    assign start = btnU;   // Pulse when button pressed

    // AES encryption core instantiation
    aes_encrypt_seq uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext),
        .done(done)
    );

    // Display: lowest 15 bits of ciphertext + done flag
    assign led[15:1] = ciphertext[15:1];
    assign led[0]    = done;

endmodule
