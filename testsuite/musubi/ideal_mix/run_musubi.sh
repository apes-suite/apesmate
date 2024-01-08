#!/bin/bash
# path to executables
seeder_exe=~/apes/seeder/build/seeder
musubi_exe=~/apes/musubi/build/musubi
mus_harvesting_exe=~/apes/musubi/build/mus_harvesting

# remove old files
rm -rf mesh tracking_MS restart_MS *.pdf *.db
# create directories
mkdir mesh tracking_MS restart_MS

# Generate mesh
$seeder_exe seeder.lua

# Run solver
export coupled=false
mpirun -n 4 $musubi_exe musubi_MS.lua

# Run harvester
$mus_harvesting_exe harvester_MS.lua

# create plot
python plot_MS.py
