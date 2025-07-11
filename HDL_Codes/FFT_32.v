module FFT_32 (clk,rst_n,fft_start,data_in,data_out_real,data_out_imag);

// Parameters Declaration
localparam N = 32;                                     // N --> refer to the FFT size
localparam WIDTH = 16;                                // Output size of each FFT point

// Inputs & Outputs Declaration 
input clk,rst_n,fft_start;                          // < fft_start > may be an optional signal from the ADC to startup the FFT block
input [N*WIDTH-1:0] data_in;                       // Input real 32 point from the 8-bit ADC with Q4.4
output [N*WIDTH-1:0] data_out_real;               // Output 32 real points from FFT with Q8.8
output [N*WIDTH-1:0] data_out_imag;              // Output 32 imaginary points from FFT with Q8.8

// Internal Signals Declaration
reg signed [WIDTH-1:0] Input_arr [0:N-1];                         // index bit-reversed samples (Samples ordered with the order in bit-reversed)
wire signed [WIDTH-1:0] Output_arr_real [0:N-1];                 // Output real samples arranged in an array to be flattened into 1D bus
wire signed [WIDTH-1:0] Output_arr_imag [0:N-1];                // Output imaginary samples arranged in an array to be flattened into 1D bus
wire [(N/2)*WIDTH-1:0] twiddle_factor_real;          
wire [(N/2)*WIDTH-1:0] twiddle_factor_img; 
wire signed [WIDTH-1:0] twiddle_real_arr [0:(N/2)-1];
wire signed [WIDTH-1:0] twiddle_img_arr  [0:(N/2)-1];
// [For each MAC ---> There exists 2 signals called E(Even) , O(Odd)]
// Internal signals for the outputs that result from the First stage 
wire signed [WIDTH-1:0] E1_real [0:(N/2)-1];
wire signed [WIDTH-1:0] E1_imag [0:(N/2)-1];
wire signed [WIDTH-1:0] O1_real [0:(N/2)-1];
wire signed [WIDTH-1:0] O1_imag [0:(N/2)-1];
// Internal signals for the outputs that result from the second stage
wire signed [WIDTH-1:0] E2_real [0:(N/2)-1];
wire signed [WIDTH-1:0] E2_imag [0:(N/2)-1];
wire signed [WIDTH-1:0] O2_real [0:(N/2)-1];
wire signed [WIDTH-1:0] O2_imag [0:(N/2)-1];
// Internal signals for the outputs that result from the Third stage
wire signed [WIDTH-1:0] E3_real [0:(N/2)-1];
wire signed [WIDTH-1:0] E3_imag [0:(N/2)-1];
wire signed [WIDTH-1:0] O3_real [0:(N/2)-1];
wire signed [WIDTH-1:0] O3_imag [0:(N/2)-1];
// Internal signals for the outputs that result from the fourth stage
wire signed [WIDTH-1:0] E4_real [0:(N/2)-1];
wire signed [WIDTH-1:0] E4_imag [0:(N/2)-1];
wire signed [WIDTH-1:0] O4_real [0:(N/2)-1];
wire signed [WIDTH-1:0] O4_imag [0:(N/2)-1];

// Reverse the order of the samples for the decimation in time algorithm (DIT)
integer j;
function [$clog2(N)-1:0] Indx_Reverse(input [$clog2(N)-1:0] Indx);
    for (j = 0 ; j < $clog2(N) ; j = j + 1) begin
        Indx_Reverse[j] = Indx[$clog2(N)-1-j];
    end
endfunction

// Register the reversed-order input samples
integer k;
always @(posedge clk) begin
    if(!rst_n) begin
        for (k = 0 ; k < N ; k = k + 1) begin
            Input_arr[k] <= 0;
        end
    end
    else if (fft_start) begin                   // Assume the input samples are listed as x(0) ---> x(N-1) from MSB to LSB in the input vector
        for (k = 0 ; k < N ; k = k + 1) begin
            Input_arr[k] <= data_in[(N-Indx_Reverse(k))*WIDTH-1 -: WIDTH];
        end
    end
end

// Instantiate the Twiddle Factors' ROM ---> Provide the twiddle factors upon startup
Twiddle_factor_ROM TWIDDLE_ROM (.clk(clk),.rst_n(rst_n),.twiddle_factor_real(twiddle_factor_real),.twiddle_factor_img(twiddle_factor_img)); 

// Generate block to convert Single bus twiddle factor into 2D array
genvar u;
generate 
    for (u = 0; u < N/2; u = u + 1) begin
        assign twiddle_real_arr[u] = twiddle_factor_real[((N/2-u)*WIDTH)-1 -: WIDTH];
        assign twiddle_img_arr[u]  = twiddle_factor_img[((N/2-u)*WIDTH)-1 -: WIDTH];
    end
endgenerate

// Main generate block that instantiate all the MAC modules across all the stages
genvar i;
generate
    // Stage 1
    for (i = 0 ; i < N ; i = i + 2) begin : Stage_1
        MAC MAC_inst_1 (.clk(clk),.rst_n(rst_n),
        .In1_real(Input_arr[i]),.In1_imag(16'b0),                                          // Assume Real Samples only
        .In2_real(Input_arr[i+1]),.In2_imag(16'b0),                                       // Assume Real Samples only
        .Twiddle_real(twiddle_real_arr[0]),.Twiddle_imag(twiddle_img_arr[0]),            // W^0
        .Out1_real(E1_real[i/2]),.Out1_imag(E1_imag[i/2]),
        .Out2_real(O1_real[i/2]),.Out2_imag(O1_imag[i/2]));
    end

    // Stage 2
    for (i = 0 ; i < WIDTH-1 ; i = i + 2) begin : Stage_2
        MAC MAC_inst_2_1 (.clk(clk),.rst_n(rst_n),
        .In1_real(E1_real[i]),.In1_imag(E1_imag[i]),
        .In2_real(E1_real[i+1]),.In2_imag(E1_imag[i+1]),
        .Twiddle_real(twiddle_real_arr[0]),.Twiddle_imag(twiddle_img_arr[0]),       // W^0
        .Out1_real(E2_real[i]),.Out1_imag(E2_imag[i]),
        .Out2_real(O2_real[i]),.Out2_imag(O2_imag[i]));
        
        MAC MAC_inst_2_2 (.clk(clk),.rst_n(rst_n),
        .In1_real(O1_real[i]),.In1_imag(O1_imag[i]),
        .In2_real(O1_real[i+1]),.In2_imag(O1_imag[i+1]),
        .Twiddle_real(twiddle_real_arr[8]),.Twiddle_imag(twiddle_img_arr[8]),    // W^8
        .Out1_real(E2_real[i+1]),.Out1_imag(E2_imag[i+1]),
        .Out2_real(O2_real[i+1]),.Out2_imag(O2_imag[i+1]));
    end
  
    // Stage 3
    for (i = 0 ; i < WIDTH-3 ; i = i + 4) begin : Stage_3           
        MAC MAC_inst_3_1 (.clk(clk),.rst_n(rst_n),
        .In1_real(E2_real[i]),.In1_imag(E2_imag[i]),
        .In2_real(E2_real[i+2]),.In2_imag(E2_imag[i+2]),
        .Twiddle_real(twiddle_real_arr[0]),.Twiddle_imag(twiddle_img_arr[0]),       // W^0
        .Out1_real(E3_real[i]),.Out1_imag(E3_imag[i]),
        .Out2_real(O3_real[i]),.Out2_imag(O3_imag[i]));
        
        MAC MAC_inst_3_2 (.clk(clk),.rst_n(rst_n),
        .In1_real(E2_real[i+1]),.In1_imag(E2_imag[i+1]),
        .In2_real(E2_real[i+3]),.In2_imag(E2_imag[i+3]),
        .Twiddle_real(twiddle_real_arr[4]),.Twiddle_imag(twiddle_img_arr[4]),       // W^4
        .Out1_real(E3_real[i+1]),.Out1_imag(E3_imag[i+1]),
        .Out2_real(O3_real[i+1]),.Out2_imag(O3_imag[i+1]));

        MAC MAC_inst_3_3 (.clk(clk),.rst_n(rst_n),
        .In1_real(O2_real[i]),.In1_imag(O2_imag[i]),
        .In2_real(O2_real[i+2]),.In2_imag(O2_imag[i+2]),
        .Twiddle_real(twiddle_real_arr[8]),.Twiddle_imag(twiddle_img_arr[8]),       // W^8
        .Out1_real(E3_real[i+2]),.Out1_imag(E3_imag[i+2]),
        .Out2_real(O3_real[i+2]),.Out2_imag(O3_imag[i+2]));
        
        MAC MAC_inst_3_4 (.clk(clk),.rst_n(rst_n),
        .In1_real(O2_real[i+1]),.In1_imag(O2_imag[i+1]),
        .In2_real(O2_real[i+3]),.In2_imag(O2_imag[i+3]),
        .Twiddle_real(twiddle_real_arr[12]),.Twiddle_imag(twiddle_img_arr[12]),       // W^12
        .Out1_real(E3_real[i+3]),.Out1_imag(E3_imag[i+3]),
        .Out2_real(O3_real[i+3]),.Out2_imag(O3_imag[i+3]));
    end

    // Stage 4
    for (i = 0 ; i < WIDTH-7 ; i = i + 8) begin : Stage_4
        MAC MAC_inst_4_1 (.clk(clk),.rst_n(rst_n),
        .In1_real(E3_real[i]),.In1_imag(E3_imag[i]),
        .In2_real(E3_real[i+4]),.In2_imag(E3_imag[i+4]),
        .Twiddle_real(twiddle_real_arr[0]),.Twiddle_imag(twiddle_img_arr[0]),       // W^0
        .Out1_real(E4_real[i]),.Out1_imag(E4_imag[i]),
        .Out2_real(O4_real[i]),.Out2_imag(O4_imag[i]));
        
        MAC MAC_inst_4_2 (.clk(clk),.rst_n(rst_n),
        .In1_real(E3_real[i+1]),.In1_imag(E3_imag[i+1]),
        .In2_real(E3_real[i+5]),.In2_imag(E3_imag[i+5]),
        .Twiddle_real(twiddle_real_arr[2]),.Twiddle_imag(twiddle_img_arr[2]),       // W^2
        .Out1_real(E4_real[i+1]),.Out1_imag(E4_imag[i+1]),
        .Out2_real(O4_real[i+1]),.Out2_imag(O4_imag[i+1]));

        MAC MAC_inst_4_3 (.clk(clk),.rst_n(rst_n),
        .In1_real(E3_real[i+2]),.In1_imag(E3_imag[i+2]),
        .In2_real(E3_real[i+6]),.In2_imag(E3_imag[i+6]),
        .Twiddle_real(twiddle_real_arr[4]),.Twiddle_imag(twiddle_img_arr[4]),       // W^4
        .Out1_real(E4_real[i+2]),.Out1_imag(E4_imag[i+2]),
        .Out2_real(O4_real[i+2]),.Out2_imag(O4_imag[i+2]));
        
        MAC MAC_inst_4_4 (.clk(clk),.rst_n(rst_n),
        .In1_real(E3_real[i+3]),.In1_imag(E3_imag[i+3]),
        .In2_real(E3_real[i+7]),.In2_imag(E3_imag[i+7]),
        .Twiddle_real(twiddle_real_arr[6]),.Twiddle_imag(twiddle_img_arr[6]),       // W^6
        .Out1_real(E4_real[i+3]),.Out1_imag(E4_imag[i+3]),
        .Out2_real(O4_real[i+3]),.Out2_imag(O4_imag[i+3]));
    
        MAC MAC_inst_4_5 (.clk(clk),.rst_n(rst_n),
        .In1_real(O3_real[i]),.In1_imag(O3_imag[i]),
        .In2_real(O3_real[i+4]),.In2_imag(O3_imag[i+4]),
        .Twiddle_real(twiddle_real_arr[8]),.Twiddle_imag(twiddle_img_arr[8]),       // W^8
        .Out1_real(E4_real[i+4]),.Out1_imag(E4_imag[i+4]),
        .Out2_real(O4_real[i+4]),.Out2_imag(O4_imag[i+4]));
        
        MAC MAC_inst_4_6 (.clk(clk),.rst_n(rst_n),
        .In1_real(O3_real[i+1]),.In1_imag(O3_imag[i+1]),
        .In2_real(O3_real[i+5]),.In2_imag(O3_imag[i+5]),
        .Twiddle_real(twiddle_real_arr[10]),.Twiddle_imag(twiddle_img_arr[10]),    // W^10
        .Out1_real(E4_real[i+5]),.Out1_imag(E4_imag[i+5]),
        .Out2_real(O4_real[i+5]),.Out2_imag(O4_imag[i+5]));

        MAC MAC_inst_4_7 (.clk(clk),.rst_n(rst_n),
        .In1_real(O3_real[i+2]),.In1_imag(O3_imag[i+2]),
        .In2_real(O3_real[i+6]),.In2_imag(O3_imag[i+6]),
        .Twiddle_real(twiddle_real_arr[12]),.Twiddle_imag(twiddle_img_arr[12]),   // W^12
        .Out1_real(E4_real[i+6]),.Out1_imag(E4_imag[i+6]),
        .Out2_real(O4_real[i+6]),.Out2_imag(O4_imag[i+6]));
        
        MAC MAC_inst_4_8 (.clk(clk),.rst_n(rst_n),
        .In1_real(O3_real[i+3]),.In1_imag(O3_imag[i+3]),
        .In2_real(O3_real[i+7]),.In2_imag(O3_imag[i+7]),
        .Twiddle_real(twiddle_real_arr[14]),.Twiddle_imag(twiddle_img_arr[14]),  // W^14
        .Out1_real(E4_real[i+7]),.Out1_imag(E4_imag[i+7]),
        .Out2_real(O4_real[i+7]),.Out2_imag(O4_imag[i+7]));
    end

    // Stage 5
    for (i = 0 ; i < WIDTH ; i = i + 1) begin : Stage_5
        if(i < WIDTH/2) begin
            MAC MAC_inst_5_1 (.clk(clk),.rst_n(rst_n),
            .In1_real(E4_real[i]),.In1_imag(E4_imag[i]),
            .In2_real(E4_real[i+8]),.In2_imag(E4_imag[i+8]),
            .Twiddle_real(twiddle_real_arr[i]),.Twiddle_imag(twiddle_img_arr[i]),       // W^0 ---> W^7
            .Out1_real(Output_arr_real[i]),.Out1_imag(Output_arr_imag[i]),
            .Out2_real(Output_arr_real[i+WIDTH]),.Out2_imag(Output_arr_imag[i+WIDTH]));
        end
        else begin
            MAC MAC_inst_5_2 (.clk(clk),.rst_n(rst_n),
            .In1_real(O4_real[i-WIDTH/2]),.In1_imag(O4_imag[i-WIDTH/2]),
            .In2_real(O4_real[i]),.In2_imag(O4_imag[i]),
            .Twiddle_real(twiddle_real_arr[i]),.Twiddle_imag(twiddle_img_arr[i]),       // W^8 ---> W^15
            .Out1_real(Output_arr_real[i]),.Out1_imag(Output_arr_imag[i]),
            .Out2_real(Output_arr_real[i+WIDTH]),.Out2_imag(Output_arr_imag[i+WIDTH]));
        end
    end  
endgenerate

// Flatten the output array saving output FFT bins into 1D bus
generate
    for ( i = 0 ; i < N  ; i = i + 1 ) begin
        assign data_out_real[(N-i)*WIDTH-1 -: WIDTH] = Output_arr_real[i];
        assign data_out_imag[(N-i)*WIDTH-1 -: WIDTH] = Output_arr_imag[i];
    end
endgenerate

endmodule