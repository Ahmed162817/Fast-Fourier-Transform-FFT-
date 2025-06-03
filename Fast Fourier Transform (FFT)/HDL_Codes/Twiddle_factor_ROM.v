module Twiddle_factor_ROM (clk,rst_n,twiddle_factor_real,twiddle_factor_img);

// Parameters Declaration
localparam N = 32;                      // N --> refer to the FFT size
localparam WIDTH = 16;                 // Output size of each FFT point

// Inputs & Outputs Declaration
input clk,rst_n; 
output [((N/2)*WIDTH)-1:0] twiddle_factor_real;
output [((N/2)*WIDTH)-1:0] twiddle_factor_img;

// Internal signals & Counters Declaration
reg signed [WIDTH-1:0] twiddle_real_arr [0:(N/2)-1];
reg signed [WIDTH-1:0] twiddle_img_arr  [0:(N/2)-1];
integer j;

// Sequential Always block that assign the real and imaginary part of twiddle factor From the Twiddle MATLAB Model
always @ (posedge clk) begin
    if (!rst_n) begin
        for (j = 0 ; j < N/2 ; j = j + 1) begin
            twiddle_real_arr[j] <= 0;
            twiddle_img_arr [j] <= 0;
        end
    end
    else begin
        twiddle_real_arr[0] <= 16'b0111111111111111;
        twiddle_img_arr [0] <= 16'b0000000000000000;
        twiddle_real_arr[1] <= 16'b0111110110001010;
        twiddle_img_arr [1] <= 16'b1110011100000111;
        twiddle_real_arr[2] <= 16'b0111011001000010;
        twiddle_img_arr [2] <= 16'b1100111100000100;
        twiddle_real_arr[3] <= 16'b0110101001101110;
        twiddle_img_arr [3] <= 16'b1011100011100011;
        twiddle_real_arr[4] <= 16'b0101101010000010;
        twiddle_img_arr [4] <= 16'b1010010101111110;
        twiddle_real_arr[5] <= 16'b0100011100011101;
        twiddle_img_arr [5] <= 16'b1001010110010010;
        twiddle_real_arr[6] <= 16'b0011000011111100;
        twiddle_img_arr [6] <= 16'b1000100110111110;
        twiddle_real_arr[7] <= 16'b0001100011111001;
        twiddle_img_arr [7] <= 16'b1000001001110110;
        twiddle_real_arr[8] <= 16'b0000000000000000;
        twiddle_img_arr [8] <= 16'b1000000000000000;
        twiddle_real_arr[9] <= 16'b1110011100000111;
        twiddle_img_arr [9] <= 16'b1000001001110110;
        twiddle_real_arr[10] <= 16'b1100111100000100;
        twiddle_img_arr [10] <= 16'b1000100110111110;
        twiddle_real_arr[11] <= 16'b1011100011100011;
        twiddle_img_arr [11] <= 16'b1001010110010010;
        twiddle_real_arr[12] <= 16'b1010010101111110;
        twiddle_img_arr [12] <= 16'b1010010101111110;
        twiddle_real_arr[13] <= 16'b1001010110010010;
        twiddle_img_arr [13] <= 16'b1011100011100011;
        twiddle_real_arr[14] <= 16'b1000100110111110;
        twiddle_img_arr [14] <= 16'b1100111100000100;
        twiddle_real_arr[15] <= 16'b1000001001110110;
        twiddle_img_arr [15] <= 16'b1110011100000111;
    end 
end

// Assign all the combinations of the twiddle factor powers in a single output bus
genvar i;
generate 
    for (i = 0; i < N/2; i = i + 1) begin
        assign twiddle_factor_real[((N/2-i)*WIDTH)-1 -: WIDTH] = twiddle_real_arr[i];
        assign twiddle_factor_img [((N/2-i)*WIDTH)-1 -: WIDTH] = twiddle_img_arr[i];
    end
endgenerate

endmodule