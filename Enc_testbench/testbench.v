`timescale 1ns/1ps

module aes_testbench;
    reg  [127:0] plaintext;
    reg  [127:0] cipher_key;
    wire [127:0] ciphertext;

    // DUT
    aes_core dut (
        .plaintext(plaintext),
        .cipher_key(cipher_key),
        .ciphertext(ciphertext)
    );

    initial begin
        // NIST FIPS-197 example
        plaintext  = 128'h00112233445566778899aabbccddeeff;
        cipher_key = 128'h000102030405060708090a0b0c0d0e0f;

        #5; // settle

        $display("Plaintext : %h", plaintext);
        $display("Key       : %h", cipher_key);
        $display("Ciphertext: %h", ciphertext);
        $display("Expected  : %h", 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        if (ciphertext === 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
            $display("TEST PASSED!");
        else begin
            $display("TEST FAILED!");
        end

        $finish;
    end
endmodule
