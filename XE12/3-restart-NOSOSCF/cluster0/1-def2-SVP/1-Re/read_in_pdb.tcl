set top ../full.prmtop

load_amber_coords inpcrd=../full.inpcrd prmtop=../full.prmtop coords=in.c


energy energy=e coords=in.c theory=dl_poly  : [ list \
					    amber_prmtop_file= $top \
					    exact_srf=yes \
					    mxlist=16000 \
					    cutoff=1000 \
					    mxexcl=2000  \
					    debug_memory=no \
					    list_option=none ]


set fp [ open atom_charges.tcl w ]
    puts $fp [ list_amber_atom_charges ]
close $fp
