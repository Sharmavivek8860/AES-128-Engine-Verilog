`timescale 1ns/1ps
module testbench_decrypt;
    reg  [127:0] cipher_in;
    reg  [127:0] key;
    wire [127:0] plain_out;

    // Instantiate decryption core
    aes_decrypt_core DEC (.ciphertext(cipher_in), .cipher_key(key), .plaintext(plain_out));

    initial begin
        // Known vector (FIPS-197)
        cipher_in = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        key       = 128'h000102030405060708090a0b0c0d0e0f;

        #5;

        $display("Ciphertext : %h", cipher_in);
        $display("Key        : %h", key);
        $display("Plaintext  : %h", plain_out);
        $display("Expected   : %h", 128'h00112233445566778899aabbccddeeff);

        if (plain_out === 128'h00112233445566778899aabbccddeeff)
            $display("DECRYPT TEST PASSED!");
        else
            $display("DECRYPT TEST FAILED!");

        $finish;
    end
endmodule
