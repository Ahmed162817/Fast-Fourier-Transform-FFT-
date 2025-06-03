# 32-point-FFT-Verilog-design-based-DIT-butterfly-algorithm
This project aims to design an 32-point FFT (Fast Fourier Transform) based DIT (decimation in time) Butterfly Algorithm with multiple clock domains and time-shared design.

The design procedure is aimed to be work for the both digital designs flow FPGA and ASIC.

The FPGA flow will start from writing the RTL to the bitstream generation on the Xilinx Vivado tool.

The ASIC flow will start from writing the RTL to GDS file generation on Synopsys EDA tools.

# Introduction
Transforms are generally used to convert a function from time domain to frequency domain without any loss of information, The Fast Fourier transforms (FFT) are the numerically efficient algorithms to compute the Discrete Fourier Transform (DFT). 

FFT algorithms are based on the concept of divide and conquer approach. The FFT is used in so many applications as In the field of communications, the FFT is important because of its use in orthogonal frequency division multiplexing (OFDM) systems.

In this project it was implemented the FFT for a 32-points sequence with the help of Decimation In Time algorithm with radix-2.

# 32-point FFT diagram
![image](https://user-images.githubusercontent.com/64384499/127676203-d51eab76-11e9-4a71-af22-0a580097acea.png)
