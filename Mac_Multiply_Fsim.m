clc
clear
close all;

tests = 1000;
p_q_1_15_real = zeros(1,tests);
p_q_1_15_imag = zeros(1,tests);
p_q_1_7_real = zeros(1,tests);
p_q_1_7_imag = zeros(1,tests);
p_q_8_8_real = zeros(1,tests);
p_q_8_8_imag = zeros(1,tests);

for i = 1:tests
    a = complex(generateRandomNumber(-5,5),generateRandomNumber(-5,5));
    b = complex(generateRandomNumber(-1,1),generateRandomNumber(-1,1));

    p_ref = a*b;

    T = numerictype(1, 16, 8);  % signed, 16-bit, 8 fractional


    a_fixed = fi(a,1,16,8);                 % Q8.8
    b_fixed_1 = fi(b,1,16,15);              % Q1.15
    b_fixed_2 = fi(b,1,16,8);               % Q8.8
    b_fixed_3 = fi(b,1,8,7);                %Q1.7

    p_1 = fi(a_fixed*b_fixed_1,T) ;
    p_2 = fi(a_fixed * b_fixed_2 ,T);
    p_3 = fi(a_fixed * b_fixed_3 ,T );
    
    % Compute the relative error for each Quantization Scheme3 
    p_q_1_15_real(i) =  abs(double(real(p_1)) - real(p_ref)) / real(p_ref);
    p_q_1_15_imag(i) =  abs(double(imag(p_1)) - imag(p_ref)) / imag(p_ref);
    p_q_1_7_real(i) =  abs(double(real(p_2)) - real(p_ref)) / real(p_ref);
    p_q_1_7_imag(i) =  abs(double(imag(p_2)) - imag(p_ref)) / imag(p_ref);
    p_q_8_8_real(i) =  abs(double(real(p_3)) - real(p_ref)) / real(p_ref);
    p_q_8_8_imag(i) =  abs(double(imag(p_3)) - imag(p_ref)) / imag(p_ref);
end

figure;
subplot(2,1,1);
plot(p_q_1_15_real,'r');
hold on;
plot(p_q_1_7_real,'k');
plot(p_q_8_8_real,'b');
legend('Q1.15','Q1.7','Q8.8');
title("Real part approximations");

subplot(2,1,2);
plot(p_q_1_15_imag,'r');
hold on;
plot(p_q_1_7_imag,'k');
plot(p_q_8_8_imag,'b');
legend('Q1.15','Q1.7','Q8.8');
title("Imaginary part approximations");

% Calculate mean relative errors
mean_1_15_real = mean(p_q_1_15_real);
mean_1_15_imag = mean(p_q_1_15_imag);
mean_1_7_real = mean(p_q_1_7_real);
mean_1_7_imag = mean(p_q_1_7_imag);
mean_8_8_real = mean(p_q_8_8_real);
mean_8_8_imag = mean(p_q_8_8_imag);

% Calculate mean relative errors
variance_1_15_real = var(p_q_1_15_real);
variance_1_15_imag = var(p_q_1_15_imag);
variance_1_7_real = var(p_q_1_7_real);
variance_1_7_imag = var(p_q_1_7_imag);
variance_8_8_real = var(p_q_8_8_real);
variance_8_8_imag = var(p_q_8_8_imag);

% Display Mean and variance for each Format in Percentage [Q1.15 & Q1.7 & Q8.8]
fprintf('Q1.15 - Mean Relative Error: Real = %.4f, Imag = %.4f\n',mean_1_15_real*100,mean_1_15_imag*100);
fprintf('Q1.15 - Error Variance: Real = %.4f, Imag = %.4f\n',variance_1_15_real*100,variance_1_15_imag*100);
fprintf('======================================================================\n');
fprintf('Q1.7  - Mean Relative Error: Real = %.4f, Imag = %.4f\n',mean_1_7_real*100,mean_1_7_imag*100);
fprintf('Q1.7  - Error Variance: Real = %.4f, Imag = %.4f\n',variance_1_7_real*100,variance_1_7_imag*100);
fprintf('======================================================================\n');
fprintf('Q8.8  - Mean Relative Error: Real = %.4f, Imag = %.4f\n',mean_8_8_real*100,mean_8_8_imag*100);
fprintf('Q8.8  - Error Variance: Real = %.4f, Imag = %.4f\n',variance_8_8_real*100,variance_8_8_imag*100);
fprintf('======================================================================\n');

function random_num = generateRandomNumber(min, max)
    random_num = min + (max - min) * rand;
end

