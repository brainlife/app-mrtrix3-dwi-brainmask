#!/bin/bash
#Adapted from code written by Brent McPherson (bcmcpher@iu.edu): 6.22.2020

set -x
set -e

#### parse inputs ####
dwi=`jq -r '.dwi' config.json`
bvals=`jq -r '.bvals' config.json`
bvecs=`jq -r '.bvecs' config.json`
outdir="mask"
NCORE=8

#### create output directory ####
[ ! -d ${outdir} ] && mkdir -p ${outdir}

#### convert input diffusion data into mrtrix format ####
echo "Converting raw data into MRTrix3 format..."
[ ! -f dwi.b ] && mrconvert -fslgrad ${bvecs} ${bvals} ${dwi} dwi.mif --export_grad_mrtrix dwi.b -force -nthreads $NCORE -quiet

#### create mask of dwi data - use bet for more robust mask ####
[ ! -f mask.mif ] && dwi2mask dwi.mif - -force -nthreads $NCORE -quiet | maskfilter - dilate mask.mif -npass 5 -force -nthreads $NCORE -quiet
[ ! -f ${outdir}/mask.nii.gz ] && mrconvert mask.mif ./mask/mask.nii.gz -force -nthreads $NCORE -quiet

if [ ! -f ${outdir}/mask.nii.gz ]; then
	echo "mask failed. see derivatives and logs"
	exit 1
else
	echo "mask completed."
	mkdir -p raw
	mv *dwi.* *.mif ./raw/
fi
