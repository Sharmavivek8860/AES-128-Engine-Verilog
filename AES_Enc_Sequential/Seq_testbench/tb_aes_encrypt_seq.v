`timescale 1ns/1ps
module tb_aes_encrypt_seq;

    reg clk, rst, start;
    reg [127:0] plaintext, key;
    wire [127:0] ciphertext;
    wire done;

    // DUT
    aes_encrypt_seq uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext),
        .done(done)
    );

    // Clock: 100 MHz
    always #5 clk = ~clk;

    initial begin
        $display("Starting AES Sequential Testbench...");
        clk = 0; rst = 1; start = 0;
        #20 rst = 0;

        // Apply inputs (NIST example)
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key       = 128'h000102030405060708090a0b0c0d0e0f;

        #10 start = 1;
        #10 start = 0;   // single-cycle pulse to start

        // Wait for done
        wait(done);
        #10;
        $display("Ciphertext = %h", ciphertext);

        if (ciphertext == 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
            $display("✅ AES Sequential Encryption Successful!");
        end else begin
            $display("❌ AES Sequential Encryption FAILED!");
        end

        $finish;
    end
endmodule
