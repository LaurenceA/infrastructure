# infrastructure

## Running jobs in Blue Pebble

Making a job script for each run is extremely tedious.  The files in `blue_pebble/bin` automate this.  To use these, you need to first download this repo (I downloaded it to `~/git/infrastructure`), then add `blue_pebble/bin` to the path.  You need to add:
```
export PATH="$PATH:/user/home/<userid>/git/infrastructure/blue_pebble/bin"
```
to `.bash_profile`.  (You will need to log out then log back in to load the new path).

`lscript` prints a job script to STDOUT based on command line arguments, for instance for a job with 1 CPU, 1 GPU and 22 GB of memory, we would use,
```
lscript -c 1 -g 1 -m 22 --cmd python my_training_script.py --my_command_line_arg
```
where everything that comes after `--cmd` is the run command.  If you need to edit the submission script (e.g. to add extra modules), this is the file to change!

To automatically submit that job, we'd use `lbatch`,
```
lbatch -c 1 -g 1 -m 22 --cmd python my_training_script.py --my_command_line_arg
```
Note that I have also included `lsub`, which blocks (waits until the job is completed).  This is useful in some ways (because it makes it easy to kill jobs when you realise something isn't right).  But you need to start the jobs inside `tmux` or `screen`, otherwise the jobs will be terminated when you loose your connection.

Unfortunately, these scripts tend to produce a huge number of files that look like `STDIN.o12389412`.  To rectify that, we use the `--autoname` argument,
```
lbatch -c 1 -g 1 -m 22 --autoname --cmd python my_training_script.py output_filename --my_command_line_arg
```
`--autoname` assumes that the job's output filename comes in third place (after `python` and `my_training_script.py`),
and produces logs with the name: `output_filename.o`, which tends to be much more helpful for working out which log-file
belongs to which job.  This may require you to use `print('...', flush=True)`, to make sure that the printed output isn't buffered.

There is a `--venv` command line argument for specifying the Python virtual environment to activate on the remote node (which tends to be quite difficult if it isn't hard-coded).

To select gpus, use the `--gpumem` option.  It takes a list of `11` (for 1080 and 2080 cards), `24` (for 3090's) and `40` (for 40gb A100s).  You can give a list (e.g. `--gpumem 11 24`).

## Interactive jobs in Blue Pebble
To get an interactive job with one GPU, use:
```
lint -c 1 -g 1 -m 22 -t 12
```
This should only be used for debugging code (not for running it).  And you should be careful to close it after you're done.

## Recommended resource limits
| Card | card memory| system memory per GPU  | CPUs per GPU |
| ------ | ----- | ------------- | ---- |
| 1080/2080 | 11 | 22 | 2 |
| 3090 | 24 | 62 | 2 |
| A100 | 40 | 124 | 16 |


## Logging in to Blue Pebble
I have a hatred of VPNs.  You can login to Blue Pebble without going through the VPN using `local_bin/bp_ssh`. (You'll need to update it with your username though!)

## Guides

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

#### Deprecated: use an SSH key.

Generate a new SSH key:
```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Generate a new SSH key:
```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Copy `~/.ssh/id_rsa.pub` to your GitHub account settings (https://github.com/settings/keys).

Test SSH key:
```
$ ssh -T git@github.com
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

Go to:
```
.git/config
```
Change the `url` line in `[remote "origin"]` from e.g. `url = https://github.com/username/repo_name.git` to `url = ssh://github.com/username/repo_name.git`.

## Updating paths / installing modules
You can browse available modules through `module avail`, and install a module through `module add ...`.  This is mainly useful for very fundamental things such as `gcc`.  For Python, I usually install my own Anaconda in the `$HOME` or `$WORK` directory.

If you want to install a module by default, use `~/.bashrc`, _not_ `~/.bash_profile`.  (It seems that `.bashrc` is run on interactive jobs, but `.bash_profile` isn't).
