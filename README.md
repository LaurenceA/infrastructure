# infrastructure

# Running jobs in Blue Pebble

Making a job script for each run is extremely tedious.  The files in `blue_pebble/bin` automate this.  To use these, you need to first download this repo (I downloaded it to `~/git/infrastructure`), then add `blue_pebble/bin` to the path.  You need to add:
```
export PATH="$PATH:/user/home/<userid>/git/infrastructure/blue_pebble/bin"
```
to `.bash_profile`.  (You will need to log out then log back in to load the new path).

`lscript` prints a job script to STDOUT based on command line arguments, for instance for a job with 1 CPU, 1 GPU and 22 GB of memory, we would use,
```
lscript -c 1 -g 1 -m 22 -a hpc_project_code -q queue_name --cmd python my_training_script.py --my_command_line_arg
```
where everything that comes after `--cmd` is the run command.  If you need to edit the submission script (e.g. to add extra modules), this is the file to change!

To automatically submit that job, we'd use `lbatch`,
```
lbatch -c 1 -g 1 -m 22 -a hpc_project_code -q queue_name --cmd python my_training_script.py --my_command_line_arg
```
Note that I have also included `lsub`, which blocks (waits until the job is completed).  This is useful in some ways (because it makes it easy to kill jobs when you realise something isn't right).  But you need to start the jobs inside `tmux` or `screen`, otherwise the jobs will be terminated when you loose your connection.

These scripts tend to produce a huge number of files that look like `STDIN.o12389412`.  To rectify that, we use the `--autoname` argument,
```
lbatch -c 1 -g 1 -m 22 -a hpc_project_code -q queue_name --autoname --cmd python my_training_script.py output_filename --my_command_line_arg
```
`--autoname` assumes that the job's output filename comes in third place (after `python` and `my_training_script.py`),
and produces logs with the name: `output_filename.o`, which tends to be much more helpful for working out which log-file
belongs to which job.  This may require you to use `print('...', flush=True)`, to make sure that the printed output isn't buffered.

There is a `--venv` command line argument for specifying the Python virtual environment to activate on the remote node (which tends to be quite difficult if it isn't hard-coded). Or alternatively you can specify the name of a conda environment with `--conda-env`.

To specify your HPC project code use the `-a` option. Jobs submitted on Blue Pebble will not run without a project code. To get a your project code, ask your PI.  Additionally, accounts can only run with certain project codes.  To see what project code(s) are associated with your account, use 
```
sacctmgr show user withassoc format=account where user=$USER
```
To get a project code added to your account, email `hpc-help@bristol.ac.uk`.

To submit an array job, specify the appropriate array range as a string argument to `--array-range` and replace one of your command inputs with ARRAY_ID. E.g. to run my_training_script.py in parallel with inputs in the range 0 to 10 in intervals of 2
```
lbatch -a hpc_project_code -q queue_name --array-range 0-10:2 --cmd python my_training_script.py ARRAY_ID
```

## Interactive jobs in Blue Pebble
To get an interactive job with one GPU, use:
```
lint -c 1 -g 1 -m 22 -t 12 -a hpc_project_code -q queue_name
```
This should only be used for debugging code (not for running it).  And you should be careful to close it after you're done.

## Choosing different cards, and the corresponding recommended CPU/memory resources (CNU nodes only)
To run a job with only a specific type of GPU, use:
```
lint -c 1 -g 1 -m 22 -t 12 -a hpc_project_code -q queue_name --gputype rtx_2080 rtx_3090
```
(here, a 2080 or a 3090).

We have 40 and 80 GB A100's, but the schduler can't tell the difference.  To exclude the 40 GB cards, use `--exclude_40G_A100`

To make full use of all the GPUs on a system, it is recommended that you only use the following system memory/CPUs per GPU:
| Card | card memory| system memory per GPU  | CPUs per GPU |
| ------ | ----- | ------------- | ---- |
| `rtx_2080` | 11 | 22 | 2 |
| `rtx_3090` | 24 | 62 | 2 |
| `A100` | 40/80 | 124 | 16 |

# Notes

## Logging in to Blue Pebble
I have a hatred of VPNs.  You can login to Blue Pebble without going through the VPN using `local_bin/bp_ssh`. (You'll need to update it with your username though!)

## Jupyter in Blue Pebble

* [Running Jupyter in Blue Pebble](instructions/jupyter-on-blue-pebble.md)

## Disk space in Blue Pebble
Disk space is tightly constrained (only 20 GB in home).  Use your 1T work directory (in my case `/work/ei19760/`) which has fewer guarantees on backup etc.  These directories can be found in `$HOME` and `$WORK`.  To check your disk space, use
```
user-quota
```

## Time limits for different queues
The time limits for various queues are:
* short: 3 hours (cpu)
* long: 23 hours (cpu)
* vlong: 72 hours (cpu)
* gpu: 72 hours
* gpushort: 3 hours

## Seeing your queued jobs
You can use `sacct` to get an overview of all jobs you have run / queued today, including which are queued, running, completed, or failed.

You can also use `squeue -u <username>`, but it won't show you completed / failed jobs.

## Deleting all your jobs
Use `lsub` above, then you can just Ctrl-C your unwanted jobs.

Otherwise:
```
scancel -u ei19760
```

## Transfering data
[Transferring Data](https://www.acrc.bris.ac.uk/protected/hpc-docs/transferring_data/index.html).

I also have scripts `local_bin/bp_put` and `local_bin/bp_get` that put files onto BluePebble, and get files from BluePebble.

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

Note that you can also access Jupyter notebooks on VSCode, which provides useful things like syntax checking, debugging and other useful code tools inside notebooks. Plus it also removes the need to faff around with port forwarding if you have set up your Remote-SSH as above. To do more intensive jupyter notebook things in this way, you can connect to a remote jupyter server (i.e. on a compute node), but you need to set it up in a particular way, see [Running Jupyter in Blue Pebble](instructions/jupyter-on-blue-pebble.md)

## Pushing/pulling to GitHub without a password:
* Generate a "Personal Access Token" with repo permissions + no expiration (you can always delete the token manually through the web interface): (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
* Use that token in place of a password, e.g.
```
~/git/llm_ppl $ git pull
Username for 'https://github.com': LaurenceA
Password for 'https://LaurenceA@github.com':
```
* You can save the PAT using:
```
git config --global credential.helper store
```
* This will save your token in plaintext in `~/.git-credentials`.  So you may want to check permissions on that file...

## Updating paths / installing modules
You can browse available modules through `module avail`, and install a module through `module add ...`.  This is mainly useful for very fundamental things such as `gcc`.  For Python, I usually install my own Anaconda in the `$HOME` or `$WORK` directory.

If you want to install a module by default, use `~/.bashrc`, _not_ `~/.bash_profile`.  (It seems that `.bashrc` is run on interactive jobs, but `.bash_profile` isn't).

## Viewing queued jobs
SLURM comes with a built-in command to view the queue of jobs: `squeue`.
Some useful parameters for this:
- `--me`: Only show the current user's jobs
- `-t, --states=<state_list>`: Only show jobs of certain states. States include `pending`, `running` and `completing`. For example `squeue -t running` will only show running jobs.

Full documentation is [here](https://slurm.schedmd.com/squeue.html).

## Uploading to arXiv

* Check that there aren't any wrong / soon-to-be-outdated notes from the template in the compiled pdf (e.g. "Published in <conference>" or "Preprint; under review at <conference>").  You can remove these relatively easily by editting the style file (just search for the offending string).  To avoid confusion later, you should do these edits in a new style file, e.g. `<conference>_arxiv.sty`.
* Check there aren't any extra files or embarassing comments in the Overleaf.
* Download a zip from Overleaf (Submit -> ArXiv).  MacOS, may automatically unzip the file, in which case you have to zip it again (Finder -> Right click on folder -> Compress "<filename>").
* You can upload the entire zip to arXiv.


## Subtleties when using PEFT and gradient checkpointing

When using the huggingface libraries to train LLMs it pays to be careful when using PEFT with gradient checkpointing because of the way PEFT freezes parameters. If you try to call ``model.gradient_checkpointing_enable()`` AFTER you call ``model = get_peft_model(model, lora_config)`` then a piece of code that activates gradients on the inputs won't be called and you'll get the following errors:

```
UserWarning: None of the inputs have requires_grad=True. Gradients will be None
```
or
```
RuntimeError: element 0 of tensors does not require grad and does not have a grad_fn
```

The UserWarning is especially tricky because it doesn't stop the code from running and it's easy to miss at the top of the output.

To avoid this, make sure you call ``model.gradient_checkpointing_enable()`` BEFORE you call ``model = get_peft_model(model, lora_config)``.

## Associate status mailbox

`engf-honstaff@bristol.ac.uk`

`honorary-associate-enquiries@bristol.ac.uk`
