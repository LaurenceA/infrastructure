# infrastructure

## Running jobs in Blue Pebble

Making a job script for each run is extremely tedious.  The files in `blue_pebble/bin` automate this.

`lscript` prints a job script to STDOUT based on command line arguments, for instance for a job with 1 CPU, 1 GPU and 22 GB of memory, we would use,
```
lscript -c 1 -g 1 -m 22 --cmd python my_training_script.py --my_command_line_arg
```
where everything that comes after `--cmd` is the run command.  If you need to edit the submission script (e.g. to add extra modules), this is the file to change!

To automatically submit that job, we'd use `lsub_nonblock`,
```
lsub_nonblock -c 1 -g 1 -m 22 --cmd python my_training_script.py --my_command_line_arg
```
Note that I have also included `lsub`, which blocks (waits until the job is completed).  This is useful in some ways (because it makes it easy to kill jobs when you realise something isn't right).  But you need to start the jobs inside `tmux` or `screen`, otherwise the jobs will be terminated when you loose your connection.

Unfortunately, these scripts tend to produce a huge number of files that look like `STDIN.o12389412`.  To rectify that, we use the `--autoname` argument,
```
lsub_nonblock -c 1 -g 1 -m 22 --autoname --cmd python my_training_script.py output_filename --my_command_line_arg
```
`--autoname` assumes that the job's output filename comes in third place (after `python` and `my_training_script.py`), 
and produces logs with the name: `output_filename.o`, which tends to be much more helpful for working out which log-file
belongs to which job.  This may require you to use `print('...', flush=True)`, to make sure that the printed output isn't buffered.

There is a `--venv` command line argument for specifying the Python virtual environment to activate on the remote node (which tends to be quite difficult if it isn't hard-coded).

## Interactive jobs in Blue Pebble
To get an interactive job with one GPU, use:
```
lint -g 1
```
This should only be used for debugging code (not for running it).  And you should be careful to close it after you're done.

## Recommended resource limits
The standard GPU nodes come with 8 CPUs, 96 GB of memory, and 4 GPUs.  
Therefore for maximum usage of the GPUs, it makes sense to use 1 or 2 CPUs and up to 22 GB of memory per CPU (to use some for the system).

## Logging in to Blue Pebble
I have a hatred of VPNs.  You can login to Blue Pebble without going through the VPN using `local_bin/bp_ssh`. (You'll need to update it with your username though!)

I have also included `local_bin/bp_jupyter` which will forward a port from the login-node onto your local computer, so that you can run Jupyter on the login node.

## Disk space in Blue Pebble
Disk space is tightly constrained (only 20 GB in home).  Use your 1T work directory (in my case `/work/ei19760/`) which has fewer guarantees on backup etc.  These directories can be found in `$HOME` and `$WORK`.  To check your disk space, use
```
quota -s
```

## Time limits for different queues
The time limits for various queues are:
* short: 3 hours
* long: 23 hours
* vlong: 72 hours
* gpu: 3 hours


## Deleting all your jobs
Use `lsub` above, then you can just Ctrl-C your unwanted jobs.

Otherwise:
```
qselect -u <username> | xargs qdel
```

## Transfering data
[Transferring Data](https://www.acrc.bris.ac.uk/protected/hpc-docs/transferring_data/index.html).

## Text editing on Blue Pebble
I use `vim`, which is a terminal-based text editor, which works exactly the same way remotely as locally.  There's a steep learning curve, but its eventually very worthwhile.

If you don't want that, there are other approaches such as `sshfs` which loads a remote filesystem, but they are typically much more effort to set up and much more flaky...

### Connecting PyCharm to Blue Pebble
[Instructions](https://github.com/LaurenceA/infrastructure/blob/master/instructions/Pycharm_BluePebble.pdf) from Michele

### Connecting VSCode to Blue Pebble
* Install the [remote extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack).  The necessary extension in this use case is Remote-SSH. 
* Connect to the VPN.
* Select `Remote-SSH: Connect to Host...` from the VSCode Command Palette, then enter user@bp1-login.acrc.bris.ac.uk.
* Local extensions will not be available on the remote initialisation. Remote and local settings can be synced. Solutions to this and further information on all of the above with FAQ and troubleshooting are detailed in the VS Code [documentation](https://code.visualstudio.com/docs/remote/ssh).

