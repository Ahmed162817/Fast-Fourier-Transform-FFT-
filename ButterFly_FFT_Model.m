clc
clear 
close all;

%% ------------------ Fast Fourier Transform (FFT) using Cooley-Tukey Algorithm------------------%%

% ------------------ Define Main Parameters-------------------------%
N = 32;                              % Number of FFT points
INTEGER_SIZE = 4;                    % Number of Bits assigned to the integer part
FRACTION_SIZE = 4;                   % Number of Bits assigned to the fraction part [Input Format : Q4.4]
M = INTEGER_SIZE + FRACTION_SIZE;    % Number of bits that represent each FFT point
Stages = log2(N);                    % Number of internal stages from the input to the output
Number_of_iterations = 1000;         % Number of Test vectors

% Initialize the input and output vectors
Input_vector = zeros(Number_of_iterations,N);
Output_real_vector = zeros(Number_of_iterations,N);
Output_imag_vector = zeros(Number_of_iterations,N);

% Calling the Function that Generate the input Stimulus [Time domain vectors]
Input_Stimulus = generate_input(Number_of_iterations,N,INTEGER_SIZE,FRACTION_SIZE,"Real");

for a = 1 : Number_of_iterations
    % ------------------ Generate input vector--------------------------%
    x = Input_Stimulus(a,:);
    fprintf('Iteration Number(%d) :\n',a);
    disp('Time domain Input vector x[n] : ');
    disp(x);
    Input_vector(a,:) = x;
    X_golden = fft(x);          % Expected FFT output that used as a golden reference to check Cooley-Tukey Algorithm
    x = bitrevorder(x);         % Bit-reversal permutation

    % -------- Compute FFT points using Cooley-Tukey Algorithm----------%
    for i = 1:Stages
        m = 2^i;
        Wm = exp((-2*pi*1i)/m);           % Twiddle factor [Fundamental frequency]
        for k = 1 : m : N
            for j = 0 : (m/2 - 1)
                temp1  = Wm^j * x(k+j+(m/2));
                temp2  = x(k+j);
                x(k+j) = temp2 + temp1;
                x(k+j+(m/2)) = temp2 - temp1;
            end
        end
    end
    X = x;
    Output_real_vector(a,:) = real(X);
    Output_imag_vector(a,:) = imag(X);
    
    % Compare between FFT output vector that result from Cooley-Tukey Algorithm FFT bulit-in function
    tolerance = 1e-10;                  % Define acceptable error margin
    comparison = abs(X - X_golden) < tolerance;
    if all(comparison)
        disp('✅ Cooley-Tukey Algorithm Perform Correctly');
        fprintf('\n');
        disp('FFT output vector [Cooley-Tukey Algorithm] : ');
        disp(X);
        disp('FFT output vector [Golden Reference] : ');
        disp(X_golden);
    else
        disp('❌ Mismatch between Cooley-Tukey Algorithm && Golden built-in function');
        fprintf('\n');
        disp('FFT output vector [Cooley-Tukey Algorithm] : ');
        disp(X);
        disp('FFT output vector [Golden Reference] : ');
        disp(X_golden);
        break;
    end
    fprintf('====================================================================================================\n');
end

% ------- Create text files to store input and output data----------%
fileid_1 = fopen('Input_vector.txt','w');           % Open file for writing Time domian input vectors
fileid_2 = fopen('Output_real_vector.txt','w');     % Open file for writing FFT output vectors (Real part only)
fileid_3 = fopen('Output_imag_vector.txt','w');     % Open file for writing FFT output vectors (Imaginary part only)

for a = 1 : Number_of_iterations
    % Store Time domain vector in a text file to use it as an input stimulus
    fprintf(fileid_1,'%.6f ',Input_vector(a,:));    
    fprintf(fileid_1,'\n');
    
    % Store FFT output real vector in a text file
    fprintf(fileid_2,'%.6f ',Output_real_vector(a,:));    
    fprintf(fileid_2,'\n');
    
    % Store FFT output real vector in a text file
    fprintf(fileid_3,'%.6f ',Output_imag_vector(a,:));
    fprintf(fileid_3,'\n');
end

% Close the files after storing the data
fclose(fileid_1);          
fclose(fileid_2);                                  
fclose(fileid_3);

%% ---------------------- Function that Generate the Input test Stimulus--------------------%%
function [Input_Stimulus] = generate_input(Num_of_tests,N,integer_length,fraction_length,mode)
    switch mode
        case "Real"
            int_part = randi([-2^(integer_length-1) , 2^(integer_length-1)-1],Num_of_tests,N);
            fraction_part = randi([0, 2^(fraction_length)-1],Num_of_tests,N);
            Input_Stimulus = int_part + fraction_part /(2^fraction_length);
        case "Complex"
            temp = zeros(Num_of_tests,N,2);
            for i=1:2
                int_part = randi([-2^(integer_length-1) , 2^(integer_length-1)-1],Num_of_tests,N);
                fraction_part = randi([0, 2^(fraction_length)-1],Num_of_tests,N);
                temp(:,:,i) = int_part + fraction_part /(2^fraction_length);
            end
                Input_Stimulus = complex(temp(:,:,1),temp(:,:,2));
        otherwise
            int_part = randi([-2^(integer_length-1) , 2^(integer_length-1)-1],Num_of_tests,N);
            fraction_part = randi([0, 2^(fraction_length)-1],Num_of_tests,N);
            Input_Stimulus = int_part + fraction_part /(2^fraction_length);
    end
end
