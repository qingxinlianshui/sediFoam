#!/bin/bash
cd ${0%/*} || exit 1 # Run from this directory

# Read the information of current directory.
# And collect information of the installation of LAMMPS from user.
echo "Installing lammpsFoam (for mac/linux).."
currentDir=$PWD
echo "Enter the directory of your LAMMPS and press [ENTER] "
echo -n "(default directory ./lammps-1Feb14): "
read lammpsDir

# Determine if the directory of LAMMPS exists or not.
# If not, look for LAMMPS in the default directory.
if [ ! -d "$lammpsDir" ]
then
    echo "Directory NOT found! Use default directory instead."
    lammpsDir="$PWD/lammps-1Feb14"
fi

cd $lammpsDir
lammpsDir=$PWD

echo "Directory of LAMMPS is: " $lammpsDir

# Copy/link all the extra implementations
cd $lammpsDir/src
lammpsSRC=$PWD
echo $lammpsSRC
ln -sf $currentDir/interfaceToLammps/*.* . 
cd $lammpsDir/src/MAKE
ln -sf $currentDir/interfaceToLammps/MAKE/*.* .

# Make STUBS 
cd $lammpsDir/src/STUBS
make
cd $lammpsDir/src

# Make packages
make yes-GRANULAR
make yes-KSPACE
make yes-MANYBODY
make yes-MOLECULE
make yes-FLD # lubrication
make yes-RIGID # freeze
make yes-MISC # deposit
make yes-VORONOI # ??

#version=`uname`
version=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
# Use different options according to different versions
if [ $version == "Linux" ]
then
    echo "The version you choose is openmpi version"
    make shanghailinux
    make makeshlib
    make -f Makefile.shlib shanghailinux
    cd $FOAM_USER_LIBBIN
    ln -sf $lammpsDir/src/liblammps_shanghailinux.so .
    cd $currentDir/lammpsFoam
    touch Make/options
    echo "LAMMPS_DIR ="$lammpsSRC > Make/options
    cat Make/options-linux-openmpi >> Make/options
elif [ $version == "Ubuntu" ]
then
    echo "The version you choose is ubuntu version"
    echo "WARNING: voro++ is required. Check $lammpsDir/lib/voronoi/README"
    echo "WARNING: pre-installation packages for LAMMPS are required. Check its latest user manual for details."
#    ln COLLOID/*.* .
    make shanghailinux
    make mode=shlib shanghailinux
    make -f Makefile.shlib shanghailinux
    cd $FOAM_USER_LIBBIN
    ln -sf $lammpsDir/src/liblammps_shanghailinux.so .
    cd $currentDir/lammpsFoam
    touch Make/options
    echo "LAMMPS_DIR ="$lammpsSRC > Make/options
    cat Make/options-ubuntu-openmpi >> Make/options
elif [ $version == "Darwin" ]
then
    echo "The version you choose is mac version"
    make shanghaimac
    make makeshlib
    make -f Makefile.shlib shanghaimac
    cd $FOAM_USER_LIBBIN
    ln -sf $lammpsDir/src/liblammps_shanghaimac.so .
    cd $currentDir/lammpsFoam
    touch Make/options
    echo "LAMMPS_DIR ="$lammpsSRC > Make/options
    cat Make/options-mac-openmpi >> Make/options
else
    echo "Sorry, we haven't got the required version."
    echo "Please contact the developer (sunrui@vt.edu) for help."
fi

wmake libso dragModels
wmake libso chPressureGrad
wmake libso lammpsFoamTurbulenceModels
wmake 

