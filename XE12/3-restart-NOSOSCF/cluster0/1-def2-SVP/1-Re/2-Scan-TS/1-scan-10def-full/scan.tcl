# chemshell scan for p450

# defines the topology file for the chemshell
set top ../../../0-leap/full.prmtop
set pdb ../../../cluster.pdb

# New orca/Chemshell interface
source ../../../../orca-chemsh.tcl

# Define which atoms are active
source ../../../active_atoms-10A.dat

# read in atom charge
source ../../../atom_charges.tcl

# Reaction coordinate - note that distances here are in Ang 
set begin_A  2.354
set end_A    1.0
set step_A   0.1

# Change to Bohr (1 Ang = 1.8897259886 bohr)
set begin [expr $begin_A * 1.8897259886]
set end   [expr $end_A   * 1.8897259886]
set step  [expr $step_A  * 1.8897259886]

#Set tolerance 0.00045 is the default
set tole [expr 0.00045 * 10 ]

#Set Energy tolerance tolerance/450 is default
set tol_E [expr $tole / 450 * 10]

set qm_atoms { 6078-6081 7020-7135 } 

# Need to combine art and hem into same residue for constrained optimisation
set pdb_residues [ pdb_to_res $pdb ]
set residues_c [ inlist function=combine residues= $pdb_residues sets= {HEM ART} target= QM ] 

# ORCA settings for simple input line
set orcasimpleinput " ! B3LYP D3BJ RIJCOSX def2-SVP def2/J TightSCF Grid4 GridX4 nofinalgrid slowconv NOSoscf NoPop"

# ORCA block settings are specified here.
set orcablocks \
{
%scf 
  HFTyp uhf
  MaxIter 300
  ConvForced 1
  DirectResetFreq 10
end
%pal
  nprocs 48
end
}

# Set output file name
set out_traj pes.xyz
set out_ener pes.dat

# Creat a file that will contain the energy surface. This will overwrite the file
set fp [ open $out_ener w ]
close $fp





for {set rc $begin } {$rc > $end} { set rc [ expr $rc - $step ] } {
  
    # Set value of restraint 0.892 Hartree/Bohr^2 is 2000kcal/mol^-1/A^-2
    set rest [ list " bond 7093 7130 $rc 8.9 " ]


    # Geometry Optimization
    dl-find coords=result.c \
            coordinates=hdlc \
            restraints= $rest \
            active_atoms= $active \
            residues= $pdb_residues \
            maxcycle=100 \
            dump=1 \
            list_option=full \
            result=result_out.c \
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
                                mm_theory= dl_poly  : [ list \
                                                        amber_prmtop_file=$top \
                                                        exact_srf=yes \
                                                        use_pairlist=yes \
                                                        mxlist=16000 \
                                                        cutoff=1000 \
                                                        mxexcl=2000  \
                                                        debug_memory=no \
                                                        scale14 = { 1.0 1.0 } \
                                                        conn=result.c  \
                                                        save_dl_poly_files = yes \
                                                        list_option=none ]]
    
    set final_energy [ get_matrix_element matrix=dl-find.energy indices= {0 0 } ]
    set final_energy_kcal [expr $final_energy * 627.509 ]
    set rc_A [expr $rc / 1.8897259886 ]

    # Open file, append energy, close
    set fp [ open $out_ener a ]
    puts $fp "$rc_A $final_energy_kcal"
    close $fp

    # Print energy to standard output
    puts "\n####################"
    puts "#"
    puts "# $step $rc finish"
    puts "# $rc $final_energy"
    puts "#"
    puts "####################\n"
    
    # Read pdb template than Write pdb for this step
    # read pdb write stucture from pdb
    read_pdb file= $pdb    
    write_pdb file=rc_$rc_A.pdb coords=result_out.c


    set tcl_precision 12
    # Write trajectory
    write_xyz file=tmp.xyz coords=result_out.c
    exec cat tmp.xyz >> $out_traj

    # Copy out put file in this step
    exec mkdir $rc_A
    exec cp result.c $rc_A/
    exec cp result_out.c $rc_A/
    exec cp save.gbw $rc_A/
    exec cp orca1.out $rc_A/
    exec cp orca1.inp $rc_A/
    exec cp path.xyz $rc_A/
    exec cp path_active.xyz $rc_A/
    exec cp path_force.xyz $rc_A/

    #copy coordinate for next step (set same file name as input and out in dl-find won't work)
    exec cp result_out.c result.c

}

# Finally, analyse the runtime
times

