# Quartus will ONLY compile files from here if they are instantiated in your design
set_global_assignment -name SEARCH_PATH ../rtl/axis_rtl
set_global_assignment -name SEARCH_PATH ../rtl/eth_rtl

# Define only the directories containing your custom .sv files
set sv_dirs {
    "../rtl/comms"
    "../rtl/sysarray"
    "../rtl/tpu"
    "../rtl/std"
}

# Loop through and add only the .sv files from those specific directories
foreach dir $sv_dirs {
    set sv_files [glob -nocomplain "$dir/*.sv"]
    foreach f $sv_files {
        set_global_assignment -name SYSTEMVERILOG_FILE $f
        puts "Added SV Core File: $f"
    }
}