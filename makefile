base = exec
sing = singularity exec --nv ~/Dropbox/singularity/singularity18.img
janelia = run_lsf -c 5 -g 1 singularity exec --nv ~/Dropbox/singularity/singularity18.img
bp_cpu = lsub -m 8 --autoname --cmd
bp_gpu = lsub -g 1 -m 24 --autoname --cmd

bp_cpu_lscript = lsub -m 8 --autoname --cmd
bp_gpu_lscript = lscript -g 1 -m 24 --autoname --cmd
