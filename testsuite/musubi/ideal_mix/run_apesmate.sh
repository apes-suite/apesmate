#!/bin/bash
# path to executables
seeder_exe=~/apes/seeder/build/seeder
apes_exe=~/apes/apesmate/build/apes
mus_harvesting_exe=~/apes/musubi/build/mus_harvesting

# create directories
mkdir mesh tracking_MS restart_MS tracking_Pot restart_Pot

# remove old files
rm mesh/* tracking_MS/* restart_MS/* tracking_Pot/* restart_Pot/* *.pdf *.db

# Generate mesh
$seeder_exe seeder.lua

# Run solver
export coupled=true
mpirun -n 4 $apes_exe apes.lua

# Run harvester
$mus_harvesting_exe harvester_MS.lua
$mus_harvesting_exe harvester_Poisson.lua

# create plot
python plot_MS.py
python plot_Poisson.py
