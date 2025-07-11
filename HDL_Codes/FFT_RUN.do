vlib work
vlog MAC.v Twiddle_factor_ROM.v FFT_32.v FFT_32_tb.sv +cover -covercells
vsim -voptargs=+acc work.FFT_32_tb -cover -sv_seed random
add wave *
add wave -position insertpoint  \
sim:/FFT_32_tb/DUT/Input_arr \
sim:/FFT_32_tb/input_data \
sim:/FFT_32_tb/DUT/E1_real \
sim:/FFT_32_tb/DUT/E1_imag \
sim:/FFT_32_tb/DUT/O1_real \
sim:/FFT_32_tb/DUT/O1_imag \
sim:/FFT_32_tb/DUT/E2_real \
sim:/FFT_32_tb/DUT/E2_imag \
sim:/FFT_32_tb/DUT/O2_real \
sim:/FFT_32_tb/DUT/O2_imag \
sim:/FFT_32_tb/DUT/E3_real \
sim:/FFT_32_tb/DUT/E3_imag \
sim:/FFT_32_tb/DUT/O3_real \
sim:/FFT_32_tb/DUT/O3_imag \
sim:/FFT_32_tb/DUT/E4_real \
sim:/FFT_32_tb/DUT/E4_imag \
sim:/FFT_32_tb/DUT/O4_real \
sim:/FFT_32_tb/DUT/O4_imag \
sim:/FFT_32_tb/DUT/Output_arr_real \
sim:/FFT_32_tb/DUT/Output_arr_imag
run -all
#quit -sim