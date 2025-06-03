clc
clear 
close all;

%% --------------Calculation of all Combinations of Twiddle Factor for General N-FFT--------------%%

% ------------------ Define Main Parameters-------------------------%
N = 32;                              % Number of FFT points
INTEGER_SIZE = 1;                    % Number of Bits assigned to the integer part
FRACTION_SIZE = 15;                  % Number of Bits assigned to the fraction part [Format Q1.15]
M = INTEGER_SIZE + FRACTION_SIZE;    % Number of bits that represent each FFT point
SCALE = 2^(FRACTION_SIZE);           % Fixed-point parameters 

% ------------------- Calculation of Twiddle factors----------------%
k = 0:N/2-1;
theta = 2*pi*k/N;
real_float = cos(theta);            % Compute real (cosine) Component of Twiddle factor in Float format
imag_float = -sin(theta);           % Compute imaginary (-sine) Component of Twiddle factor in Float format

% Convert to fixed-point
real_int = int16(round(real_float * SCALE));        % Compute real (cosine) Component of Twiddle factor in integer format
imag_int = int16(round(imag_float * SCALE));        % Compute imaginary (-sine) Component of Twiddle factor in integer format

% -------------Generate Verilog array assignments-------------------%
for idx = 1:length(k)
    % Get binary strings
    real_bin = dec2bin(typecast(real_int(idx),'uint16'),M);
    imag_bin = dec2bin(typecast(imag_int(idx),'uint16'),M);
    % Format array assignments
    fprintf('twiddle_real_arr[%d] <= 16''b%s;\n',idx-1,real_bin);
    fprintf('twiddle_img_arr [%d] <= 16''b%s;\n',idx-1,imag_bin);
end
