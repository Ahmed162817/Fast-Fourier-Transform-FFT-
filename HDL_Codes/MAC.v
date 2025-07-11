module MAC (clk,rst_n,In1_real,In1_imag,In2_real,In2_imag,Twiddle_real,Twiddle_imag,Out1_real,Out1_imag,Out2_real,Out2_imag);

// Parameters Declaration
localparam N = 32;                                   // N --> refer to the FFT size
localparam WIDTH = 16;                              // Output size of each FFT point
localparam MAX_POS = (1 << (WIDTH-1)) - 1;         // Equivalent to 2^(width-1)-1
localparam MIN_NEG = -(1 << (WIDTH-1));           // Equivalent to -2^(width-1)

// Inputs & Outputs Declaration
input clk,rst_n;                               // Clock Frequency operate at 100 MHz
input signed [WIDTH-1:0] In1_real,In1_imag;
input signed [WIDTH-1:0] In2_real,In2_imag;
input signed [WIDTH-1:0] Twiddle_real,Twiddle_imag;
output reg signed [WIDTH-1:0] Out1_real,Out1_imag;
output reg signed [WIDTH-1:0] Out2_real,Out2_imag;

// Internal signals Declaration
wire signed [2*WIDTH-1:0] mult_ac,mult_bd;                      // where we assume that Complex Multiplication ---> (a+jb)(c+jd) = (ac-bd)+j(ad+bc)
wire signed [2*WIDTH-1:0] mult_ad,mult_bc;                     // Q8.8 * Q1.15 = Q9.23
wire signed [WIDTH-1:0] mult_ac_scaled,mult_bd_scaled;        // Scaled version of Multipliers to Truncate the output to M bits instead of 2*M
wire signed [WIDTH-1:0] mult_ad_scaled,mult_bc_scaled;
wire signed [WIDTH-1:0] result_real,result_imag;
wire signed [WIDTH:0] sum_real,sum_imag;
wire signed [WIDTH:0] diff_real,diff_imag;

// Assign Statements for intermediate products 
assign mult_ac = In2_real * Twiddle_real;
assign mult_bd = In2_imag * Twiddle_imag;
assign mult_ad = In2_real * Twiddle_imag;
assign mult_bc = In2_imag * Twiddle_real;

// Assign Statements for the Multiplier outputs to truncate them to M bits only [Rounding for Q1.15]
assign mult_ac_scaled = (mult_ac + (1 << 14)) >>> 15;           
assign mult_bd_scaled = (mult_bd + (1 << 14)) >>> 15;
assign mult_ad_scaled = (mult_ad + (1 << 14)) >>> 15;
assign mult_bc_scaled = (mult_bc + (1 << 14)) >>> 15;

// Assign Statements for the final complex Multiplier output
assign result_real = mult_ac_scaled - mult_bd_scaled;
assign result_imag = mult_ad_scaled + mult_bc_scaled;

// Extended precision calculations
assign sum_real  = {In1_real[WIDTH-1], In1_real} + {result_real[WIDTH-1], result_real};
assign sum_imag  = {In1_imag[WIDTH-1], In1_imag} + {result_imag[WIDTH-1], result_imag};
assign diff_real = {In1_real[WIDTH-1], In1_real} - {result_real[WIDTH-1], result_real};
assign diff_imag = {In1_imag[WIDTH-1], In1_imag} - {result_imag[WIDTH-1], result_imag};

// Always block to assign the final outputs of MAC (Multiply Accumulate Block)
always @ (posedge clk) begin
    if(!rst_n) begin
        Out1_real <= 0;
        Out1_imag <= 0;
        Out2_real <= 0;
        Out2_imag <= 0;
    end
    else begin
        Out1_real <= saturate(sum_real);
        Out1_imag <= saturate(sum_imag);
        Out2_real <= saturate(diff_real);
        Out2_imag <= saturate(diff_imag);
    end
end

// Saturation logic Function
function signed [WIDTH-1:0] saturate(input signed [WIDTH:0] val);
    begin
        if (val > MAX_POS)
            saturate = MAX_POS[WIDTH-1:0];          // Saturate to maximum Q8.8 positive
        else if (val < MIN_NEG)
            saturate = MIN_NEG[WIDTH-1:0];         // Saturate to minimum Q8.8 negative
        else 
            saturate = val[WIDTH-1:0];            // Normal case without Overflow
    end
endfunction

endmodule