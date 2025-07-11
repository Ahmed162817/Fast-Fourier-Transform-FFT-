clc;
clear;
close all;

%% ---------------------------Configuration Parameters-------------------------%%
Num_of_tests = 1000;
N = 32;                                                 % FFT size
twiddle_factors = exp(-1j*2*pi/N*(0:N/2-1));            % W^i is found at location i+1
input_integer_length = 4;
input_fractional_length = 4;

RMSE_all = zeros(Num_of_tests, 1);
SNR_all = zeros(Num_of_tests, 1);
FFT_fixed_all = zeros(Num_of_tests, N);
FFT_ref_all = zeros(Num_of_tests, N);
FFT_input_all = generate_input(Num_of_tests, N, input_integer_length, input_fractional_length,"Real");
bitrev = bitrevorder(0:N-1) + 1;

%% ----------------------- Detailed logic for Cooley Tuckey Algorithm----------------------%%
for t = 1:Num_of_tests
    FFT_ref_all(t,:) = fft(FFT_input_all(t,:), 32);
    % Reverse-ordered inputs for the DIT FFT algorithm
    buffered_input = fi(FFT_input_all(t,bitrev), 1, 16, 8);

    %----------------------- Stage 1-------------------------%
    E1 = fi(zeros(1,N/2),1,16,8);
    O1 = fi(zeros(1,N/2),1,16,8);
    j=1;
    for i=1:2:N
        [E1(j) , O1(j) ] = MAC_unit(buffered_input(i),buffered_input(i+1),twiddle_factors(1));
        j = j + 1;
    end

    %----------------------- Stage 2-------------------------%
    E2 = fi(zeros(1,N/2),1,16,8);
    O2 = fi(zeros(1,N/2),1,16,8);
    for i=1:2:N/2 -1
        [E2(i) , O2(i)] = MAC_unit(E1(i),E1(i+1),twiddle_factors(1));
        [E2(i+1) , O2(i+1)] = MAC_unit(O1(i),O1(i+1),twiddle_factors(9));
    end

    %----------------------- Stage 3-------------------------%
    E3 = fi(zeros(1,N/2),1,16,8);
    O3 = fi(zeros(1,N/2),1,16,8);
    for i = 1:4:N/2 - 3
        [E3(i) , O3(i)] = MAC_unit(E2(i),E2(i+2),twiddle_factors(1));
        [E3(i+1) , O3(i+1)] = MAC_unit(E2(i+1),E2(i+3),twiddle_factors(5));
        [E3(i+2) , O3(i+2)] = MAC_unit(O2(i),O2(i+2),twiddle_factors(9));
        [E3(i+3) , O3(i+3)] = MAC_unit(O2(i+1),O2(i+3),twiddle_factors(13));
    end

    %----------------------- Stage 4-------------------------%
    E4 = fi(zeros(1,N/2),1,16,8);
    O4 = fi(zeros(1,N/2),1,16,8);
    for i = 1:8:N/2 - 7
        [E4(i),O4(i)] = MAC_unit(E3(i),E3(i+4),twiddle_factors(1));
        [E4(i+1),O4(i+1)] = MAC_unit(E3(i+1),E3(i+5),twiddle_factors(3));
        [E4(i+2),O4(i+2)] = MAC_unit(E3(i+2),E3(i+6),twiddle_factors(5));
        [E4(i+3),O4(i+3)] = MAC_unit(E3(i+3),E3(i+7),twiddle_factors(7));
        [E4(i+4),O4(i+4)] = MAC_unit(O3(i),O3(i+4),twiddle_factors(9));
        [E4(i+5),O4(i+5)] = MAC_unit(O3(i+1),O3(i+5),twiddle_factors(11));
        [E4(i+6),O4(i+6)] = MAC_unit(O3(i+2),O3(i+6),twiddle_factors(13));
        [E4(i+7),O4(i+7)] = MAC_unit(O3(i+3),O3(i+7),twiddle_factors(15));
    end

    %----------------------- Stage 5-------------------------%
    FFT_out = zeros(1,N);
    j = 1;
    for i = 1:N/2
        if(i<=N/4)
            [FFT_out(i),FFT_out(i+16)] = MAC_unit(E4(i),E4(i+8),twiddle_factors(i));
        else
            [FFT_out(i),FFT_out(i+16)] = MAC_unit(O4(j),O4(j+8),twiddle_factors(i)); 
            j = j + 1;
        end
    end

    % Convert to double
    FFT_fixed = double(FFT_out);

    % Store results
    FFT_fixed_all(t,:) = FFT_fixed;

    % Compute Error Metrics
    error = FFT_fixed - FFT_ref_all(t,:);
    RMSE_all(t) = sqrt(mean(abs(error).^2));
    SNR_all(t) = 20*log10(norm(FFT_ref_all(t,:))/norm(error));
end

%% ------- Create text files to store input and output data----------%%
fileid_1 = fopen('Input_vector.txt','w');           % Open file for writing Time domian input vectors
fileid_2 = fopen('Output_real_vector.txt','w');     % Open file for writing FFT output vectors (Real part only)
fileid_3 = fopen('Output_imag_vector.txt','w');     % Open file for writing FFT output vectors (Imaginary part only)

for a = 1 : Num_of_tests
    % Store Time domain vector in a text file to use it as an input stimulus
    fprintf(fileid_1,'%.6f ',FFT_input_all(a,:));    
    fprintf(fileid_1,'\n');
    
    % Store FFT output real vector in a text file
    fprintf(fileid_2,'%.6f ',real(FFT_fixed_all(a,:)));    
    fprintf(fileid_2,'\n');
    
    % Store FFT output real vector in a text file
    fprintf(fileid_3,'%.6f ',imag(FFT_fixed_all(a,:)));
    fprintf(fileid_3,'\n');
end

% Close the files after storing the data
fclose(fileid_1);          
fclose(fileid_2);                                  
fclose(fileid_3);


%% ----------------- Display & plot the Results---------------%%
fprintf('Mean RMSE over %d tests: %.6f\n', Num_of_tests, mean(RMSE_all));
fprintf('Mean SNR over %d tests: %.2f dB\n', Num_of_tests, mean(SNR_all));

% Plot Average Magnitudes and Error
mean_fixed = mean(abs(FFT_fixed_all), 1);
mean_ref = mean(abs(FFT_ref_all), 1);
mean_error = abs(mean_ref - mean_fixed);

figure;
subplot(2,1,1);
stem(mean_ref, 'b','LineWidth',1.2); hold on;
stem(mean_fixed, 'r--','LineWidth',1.2);
legend('Mean Floating-point FFT','Mean Fixed-point FFT');
title('Average FFT Magnitude Comparison over Tests');
xlabel('Bin Index'); ylabel('Magnitude');
grid on;

subplot(2,1,2);
stem(mean_error,'k','LineWidth',1.2);
title('Average Magnitude Error over Tests');
xlabel('Bin Index'); ylabel('Absolute Error');
grid on;

%% -------------------- Function that return the input stimulus used by FFT algorithm------------%%
function [Input_Stimulus] = generate_input(Num_of_tests , N ,integer_length , fraction_length,mode)
    switch mode
        case "Real"
            int_part = randi([-2^(integer_length-1) , 2^(integer_length-1)-1],Num_of_tests,N);
            fraction_part = randi([0, 2^(fraction_length)-1],Num_of_tests,N);
            Input_Stimulus = int_part + fraction_part /(2^fraction_length);
        case "Complex"
            temp = zeros(Num_of_tests , N , 2);
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

%% ---------------------------------- MAC unit function--------------------------%%
function [Out_1 , Out_2] = MAC_unit(In_1 , In_2 , twiddle_factor)
    In1_temp  = fi(In_1,1,16,8);
    In2_temp  = fi(In_2,1,16,8);
    twiddle_factor_temp = fi(twiddle_factor,1,16,15);
    p = In2_temp * twiddle_factor_temp;
    p_temp = fi(p,1,16,8);
    Out_1 = fi(In1_temp +  p_temp,1,16,8);
    Out_2 = fi(In1_temp - p_temp,1,16,8);
end
