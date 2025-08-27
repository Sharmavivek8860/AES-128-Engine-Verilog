module top (
    input clk, 
    input btnC,   // reset
    input [15:0] sw, 
    output [15:0] led, 
    output [6:0] seg, 
    output [3:0] an
);

    wire [127:0] ciphertext;
    reg  [3:0] index;
    reg  [15:0] led_out;
    reg  [31:0] counter;

    // Dummy AES module call (replace with your AES)
    aes_encrypt_seq uut (
        .clk(clk),
        .plaintext(128'h00112233445566778899aabbccddeeff),
        .key      (128'h000102030405060708090a0b0c0d0e0f),
        .ciphertext(ciphertext)
    );

    // Counter to change index every ~0.5 sec
    always @(posedge clk) begin
        counter <= counter + 1;
        if(counter == 100_000_000) begin  // adjust for 100MHz clock
            counter <= 0;
            index <= index + 1;
        end
    end

    // Select 16-bit chunk
    always @(*) begin
        case(index)
            4'd0: led_out = ciphertext[15:0];
            4'd1: led_out = ciphertext[31:16];
            4'd2: led_out = ciphertext[47:32];
            4'd3: led_out = ciphertext[63:48];
            4'd4: led_out = ciphertext[79:64];
            4'd5: led_out = ciphertext[95:80];
            4'd6: led_out = ciphertext[111:96];
            4'd7: led_out = ciphertext[127:112];
            default: led_out = 16'h0000;
        endcase
    end

    assign led = led_out;

    // Just blank the 7-seg for now
    assign seg = 7'b1111111;
    assign an  = 4'b1111;
endmodule
