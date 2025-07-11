module FFT_32_tb();

// Parameters Declaration
localparam N = 32;                                    // N --> refer to the FFT size
localparam WIDTH = 16;                               // Output size of each FFT point
localparam Number_of_iterations = 1000;             // Number of test Cases 

// Inputs & Outputs Declaration 
logic clk,rst_n,fft_start;                       // < fft_start > may be an optional signal from the ADC to startup the FFT block
logic [(N*WIDTH)-1:0] data_in;                  // Input real 32 point from the 8-bit ADC with Q4.4
logic [(N*WIDTH)-1:0] data_out_real;           // Output 32 real points from FFT with Q8.8
logic [(N*WIDTH)-1:0] data_out_imag;          // Output 32 imaginary points from FFT with Q8.8

// Internal Signals & Counters Declaration
real input_data [0:Number_of_iterations-1][0:N-1];            // Time Domain Vectors Randomized from MATLAB
real output_real_data [0:Number_of_iterations-1][0:N-1];     // Real part of FFT vectors 
real output_imag_data [0:Number_of_iterations-1][0:N-1];    // Imaginary part of FFT vectors 
real epsilon = 0.1;                                        // Error value that is acceptable from the differance between Design results and expected results
real dut_real,dut_imag;                                   // Store each FFT point in real format instead of binary format 
bit Initial_Latency_Flag;                                // A flag used to detect the initial latency when the 1st input is expected to be ready
int pass_counter_real,fail_counter_real;                // Pass and Fail counter for the Output Real part
int pass_counter_imag,fail_counter_imag;               // Pass and Fail counter for the Output Imaginary part
int pass_counter_iteration,fail_counter_iteration;
int file1,file2,file3;


// DUT (Design under Test) Instantiation
FFT_32 DUT (.*);

initial begin
    // Open the MATLAB file that contain input Real data
    file1 = $fopen("../MATLAB_Models/Input_vector.txt", "r");
    if (!file1) begin
      $display("Error: Could not open file!");
      $finish;
    end
    // Read input data into the 2D array
    for (int i = 0; i < Number_of_iterations; i++) begin
      for (int j = 0; j < N; j++) begin
            if ($fscanf(file1, "%f", input_data[i][j]) != 1) begin
                $display("Error reading data at iteration number = %0d, and index = %0d",i+1,j);
                $finish;
            end
        end
    end

    // Open the MATLAB file that contain the real part of FFT vectors
    file2 = $fopen("../MATLAB_Models/Output_real_vector.txt", "r");
    if (!file2) begin
      $display("Error: Could not open file!");
      $finish;
    end
    // Read the real part of the output data into the 2D array
    for (int i = 0; i < Number_of_iterations; i++) begin
      for (int j = 0; j < N; j++) begin
            if ($fscanf(file2, "%f", output_real_data[i][j]) != 1) begin
                $display("Error reading data at iteration number = %0d, and index = %0d",i+1,j);
                $finish;
            end
        end
    end

    // Open the MATLAB file that contain the imaginary part of FFT vectors
    file3 = $fopen("../MATLAB_Models/Output_imag_vector.txt", "r");
    if (!file3) begin
      $display("Error: Could not open file!");
      $finish;
    end
    // Read the imaginary part of the output data into the 2D array
    for (int i = 0; i < Number_of_iterations; i++) begin
      for (int j = 0; j < N; j++) begin
            if ($fscanf(file3, "%f", output_imag_data[i][j]) != 1) begin
                $display("Error reading data at iteration number = %0d, and index = %0d",i+1,j);
                $finish;
            end
        end
    end
end

// Initial block for clock Generation
initial begin
    clk = 0;
    forever 
    #5 clk = ~clk;             // Clock Period = 10 ns (100 MHz)
end

// Initial Block for Generating Test Stimulus
initial begin
    rst_n = 0;          data_in = 0;
    fft_start = 0;
    @(negedge clk);                     // wait one clock cycle then check the output
    if (data_out_real !== 0 || data_out_imag !== 0) begin
        $display("There is an error when resetting the system !!");
        $stop;
    end
    repeat (2) @(negedge clk);          // wait 2 clock cycles when Resetting the System
    rst_n = 1;
    fork
        // Thread for Simulating the ADC Stimulus to the FFT System
        begin : Input_Thread
            fft_start = 1;
            for ( int i = 0 ; i < Number_of_iterations ; i++ ) begin
                for ( int k = 0 ; k < N ; k++ ) begin
                    data_in[(N-k)*WIDTH-1 -: WIDTH] = $rtoi(input_data[i][k] * 256.0);
                end
                @(negedge clk);
            end
            fft_start = 0;
        end
        
        // Thread for checking the output of the FFT System
        begin : Output_Thread
            for ( int i = 0 ; i < Number_of_iterations ; i++ ) begin
                // Reset the counters for validation of each 32-point outputs (Real , Imaginary)
                pass_counter_real = 0;
                fail_counter_real = 0;
                pass_counter_imag = 0;
                fail_counter_imag = 0;

                if(!Initial_Latency_Flag) begin
                    repeat ($clog2(N)+1) @(negedge clk);  
                    Initial_Latency_Flag = 1;
                end
                else begin
                    @(negedge clk);                 // Pipelined Architecture
                end

                // Check the Output Real part only
                for (int k = 0; k < N; k++) begin
                    dut_real = $itor($signed(data_out_real[(N-k)*WIDTH-1 -: WIDTH])) / 256.0;            // Q8.8 fixed-point Output Format
                    if (absolute(dut_real - output_real_data[i][k]) > epsilon) begin
                        $display("Mismatch at index %0d: DUT Real = %f, Expected Real = %f",k,dut_real,output_real_data[i][k]);
                        fail_counter_real++;
                    end
                    else begin
                        pass_counter_real++;
                    end
                end

                // Check the Output Imaginary part only
                for (int k = 0; k < N; k++) begin
                    dut_imag = $itor($signed(data_out_imag[(N-k)*WIDTH-1 -: WIDTH])) / 256.0;          // Q8.8 fixed-point Output Format  
                    if (absolute(dut_imag - output_imag_data[i][k]) > epsilon) begin
                        $display("Mismatch at index %0d: DUT Imaginary = %f, Expected Imaginary = %f",k,dut_imag,output_imag_data[i][k]);
                        fail_counter_imag++;
                    end
                    else begin
                        pass_counter_imag++;
                    end
                end

                // Display All the Counters for each iteration
                $display("============================================================================================");
                $display("For Real Part -------> Iteration (%0d) has been ended with %0d correct index && %0d Fail index",i+1,pass_counter_real,fail_counter_real);
                $display("For Imaginary Part --> Iteration (%0d) has been ended with %0d correct index && %0d Fail index",i+1,pass_counter_imag,fail_counter_imag);
                $display("============================================================================================");
                if (pass_counter_real % 32 == 0 && pass_counter_imag % 32 == 0) 
                    pass_counter_iteration++;
                else 
                    fail_counter_iteration++;
            end
        end
    join

    // Check the reset Mode Once more to cover the Toggle node of the reset signal
    rst_n = 0;          data_in = 0;
    fft_start = 0;
    @(negedge clk);                     // wait one clock cycle then check the output
    if (data_out_real !== 0 || data_out_imag !== 0) begin
        $display("There is an error when resetting the system !!");
        $stop;
    end
    repeat (2) @(negedge clk);          // wait 2 clock cycles when Resetting the System
    // Print the Pass & Fail Iteration counters at the end to show how many fail and pass iterations we have
    $display("Test has been ended with %0d Pass iterations && %0d Fail iterations",pass_counter_iteration,fail_counter_iteration);
    $stop;
end

// Function that return absolute value of any real number [Remove negative sign]
function real absolute (real x);
    if (x >= 0)
        return x;
    else 
        return x * (-1.0);
endfunction

endmodule

