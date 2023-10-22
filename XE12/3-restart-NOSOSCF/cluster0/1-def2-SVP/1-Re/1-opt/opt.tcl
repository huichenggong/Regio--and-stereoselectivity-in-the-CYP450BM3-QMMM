# chemshell opt for p450

# defines the topology and coordiante file for the chemshell
set top ../../../0-leap/full.prmtop
set pdb ../../../cluster.pdb
set cor ./in.c
set output_cor result.c

# New orca/Chemshell interface
source ../../../../orca-chemsh.tcl

# Define which atoms are active
source ../../../active_atoms-10A.dat

#Set tolerance 0.00045 is the default
set tole [expr 0.00045 * 1 ]

#Set Energy tolerance tolerance/450 is default
set tol_E [expr $tole / 450 * 10 ]

set pdb_residues [ pdb_to_res $pdb  ]

set qm_atoms { 6078-6081 7020-7135 } 

# ORCA settings for simple input line
set orcasimpleinput " ! B3LYP D3BJ RIJCOSX def2-SVP def2/J TightSCF Grid4 GridX4 nofinalgrid slowconv NOSOSCF"

# ORCA block settings are specified here.
set orcablocks \
{
%scf 
  HFTyp uhf
  MaxIter 300
  ConvForced 1
  DirectResetFreq 12
end
%pal
  nprocs 48
end
}


# read in atom charges
source ../../../atom_charges.tcl


# Geometry Optimization
dl-find coords=$cor \
        coordinates=hdlc \
        active_atoms= $active \
        residues= $pdb_residues \
        maxcycle=100 \
        dump=1 \
        list_option=full \
        result= $output_cor \
        tolerance=$tole \
        tolerance_e=$tol_E \
        theory=hybrid : [   list \
                            coupling= shift \
                            qm_region= $qm_atoms \
                            atom_charges= $atom_charges \
                            qm_theory= orca : [ list  \
                                                executable=/work/e89/e89/meilan/Software/Programfile/orca_4_2_0_linux_x86-64_shared_openmpi314/orca \
                                                orcasimpleinput= $orcasimpleinput \
                                                orcablocks= $orcablocks \
                                                restart=yes moinp= save.gbw \
                                                charge=-2 \
                                                mult=2 ]\
                            mm_theory= dl_poly  : [ list \
                                                    amber_prmtop_file=$top \
                                                    exact_srf=yes \
                                                    use_pairlist=yes \
                                                    mxlist=16000 \
                                                    cutoff=1000 \
                                                    mxexcl=2000  \
                                                    debug_memory=no \
                                                    scale14 = { 1.0 1.0 } \
                                                    conn=$cor  \
                                                    save_dl_poly_files = yes \
                                                    list_option=none ]]

# chemsh.c to pdb
# read pdb for residue information
read_pdb file= $pdb
write_pdb file=output.pdb coords= $output_cor

# Finally, analyse the runtime
times

