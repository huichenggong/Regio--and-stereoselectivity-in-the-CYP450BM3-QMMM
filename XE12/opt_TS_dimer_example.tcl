# chemshell opt for p450

# defines the topology and coordiante file for the chemshell
set top ../chem-6649.prmtop
set pdb ../chem-6649.pdb
set cor  coord_in.c
set cor2 coord_in2.c

# New orca/Chemshell interface
source ../orca-chemsh.tcl

# Define which atoms are active
source ../active_atoms-7A.dat

#Set tolerance 0.00045 is the default
set tole [expr 0.00045 * 1 ]

#Set Energy tolerance tolerance/450 is default
set tol_E [expr $tole / 450 * 100 ]

set pdb_residues [ pdb_to_res $pdb  ]

set qm_atoms { 6078-6081 7020-7135 } 

# ORCA settings for simple input line
set orcasimpleinput " ! B3LYP D3BJ RIJCOSX def2-SVP def2/J TightSCF Grid4 GridX4 nofinalgrid"

# ORCA block settings are specified here.
set orcablocks \
{
%basis newgto Fe "def2-TZVP" end
end
%scf 
HFTyp uhf
MaxIter 200
end
%pal
nprocs 24
end
}


# for the time being we have to calculate an energy to be able to call list_amber_atom_charges
source ../atom_charges.tcl


# Geometry Optimization
dl-find coords=$cor \
        coords2=$cor2 \
        dimer=true \
        coordinates=hdlc \
        active_atoms= $active \
        residues= $pdb_residues \
        maxcycle=100 \
        dump=1 \
        list_option=full \
        result=coord_out.c \
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
                                                restart=yes moinp=save.gbw \
                                                charge=-2 \
                                                mult=2 ]\
                            mm_theory= dl_poly : [ list \
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


# Finally, analyse the runtime
times

