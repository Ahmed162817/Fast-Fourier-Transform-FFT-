create_project project_2 E:/FFT_Project/RTL_Implementation -part xcvu440-flga2892-3-e -force

add_files MAC.v Twiddle_factor_ROM.v FFT_32.v

synth_design -rtl -top FFT_32 > elab.log    

write_schematic Elaborated_Schematic.pdf -format pdf -force

launch_runs synth_1 > synth.log

wait_on_run synth_1
open_run synth_1

write_schematic Synthesized_Schematic.pdf -format pdf -force  

# Note : Replace any back slash "\" exist in the project path with front slash "/"

# Note : any space found in the name of the path directory we put back slash "\" between space 

# Note : to run this file in vivado --->    TCL console    -->    1] cd path      --->     2] source run_file_name.tcl 
