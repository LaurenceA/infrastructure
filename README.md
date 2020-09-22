# infrastructure

Running jobs in Blue Pebble
---------------

Making a job script for each run is extremely tedious.  The files in `blue_pebble/bin` automate this.

`lscript` prints a job script to STDOUT based on command line arguments, for instance for a job with 1 CPU, 1 GPU and 22 GB of memory, we would use,
```
lscript -c 1 -g 1 -m 22 --cmd python my_training_script.py --my_command_line_arg
```
where everything that comes after `--cmd` is the run command.
To automatically submit that job, we'd use `lsub`,
```
lsub -c 1 -g 1 -m 22 --cmd python my_training_script.py --my_command_line_arg
```
Note that lsub blocks (waits until the job is completed).  This is useful in some ways (because it makes it easy to kill jobs when you realise something isn't right), but if you don't want it, you can delete `-W block=True` in `lsub` to get back to the usual non-blocking behaviour.

Unfortunately, these scripts tend to produce a huge number of files that look like `STDIN.o12389412`.  To rectify that, we use the `--autoname` argument,
```
lsub -c 1 -g 1 -m 22 --autoname --cmd python my_training_script.py output_filename --my_command_line_arg
```
`--autoname` assumes that the job's output filename comes in third place (after `python` and `my_training_script.py`), 
and produces logs with the name: `output_filename.o`, which tends to be much more helpful for working out which log-file
belongs to which job.  This may require you to use `print('...', flush=True)`, to make sure that the printed output isn't buffered.

Interactive jobs in Blue Pebble
---------------
To get an interactive job with one GPU, use:
```
lint -g 1
```
This should only be used for debugging code (not for running it).  And you should be careful to close it after you're done.

Recommended resource limits
----------
The standard GPU nodes come with 8 CPUs, 96 GB of memory, and 4 GPUs.  
Therefore for maximum usage of the GPUs, it makes sense to use 1 or 2 CPUs and up to 22 GB of memory per CPU (to use some for the system).

Logging in to Blue Pebble
-------
I have a hatred of VPNs.  You can login to Blue Pebble without going through the VPN using `local_bin/bp_ssh`. (You'll need to update it with your username though!)

I have also included `local_bin/bp_jupyter` which will forward a port from the login-node onto your local computer, so that you can run Jupyter on the login node.

Disk space in Blue Pebble
--------
Disk space is tightly constrained (only 20 GB in home).  Use your 1T work directory (in my case `/work/ei19760/`) which has fewer guarantees on backup etc.  These directories can be found in `$HOME` and `$WORK`.  To check your disk space, use
```
quota -s
```

Time limits for different queues
----
* short: 3 hours
* long: 23 hours
* vlong: 72 hours
