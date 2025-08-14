# Work on a Jupyter notebook on Blue Pebble

The simplest option to run the Jupyter server on the login node.
However, sometimes this is not desirable. Perhaps you want more resources than a login node provides or you don't want to have to manage keeping the process running if you don't maintain a network connection.

Another option is to run the Jupyter server on a compute node by queuing it as a job through Slurm.
There are two ways to achieve this: as a batch job on a compute node or as an interactive job on a compute node.
SSH tunnels are used to connect the port used by Jupyter on the compute node back to the login nodes.

Whether you run on login node or compute node you will need to open an SSH tunnel from your local machine to a login node.

## Assumptions

This guide makes the following assumptions:

* You have Jupyter installed on Blue Pebble. It also assumes that if you have environments managed by tools like `conda` or `venv` you are able to adjust the commands to activate the environments (e.g. `--venv` argument for `lbatch`).
* You have a port to use since someone else might have taken the default 8888. For the commands below `<<<PORT>>>` should be replaced with your chosen port. You can use the following to choose a random one before you start: `shuf -i 6000-9999 -n 1`.
* The commands below are all proceeded by the machine on which to run them - either your local machine, a Blue Pebble login node or a Blue Pebble compute node.
* You want a notebook server. If you want something else like Jupyter Lab then update the commands, e.g replace `jupyter notebook` with `jupyter lab`.
* If you don't want to have to dig the security token out of the server logs each time then you can set a password for authentication with Jupyter instead.

```
bp-login $ jupyter notebook password
```

## Warning

Don't forget to cancel any batch or interactive jobs and stop any processes on the login nodes once you're done. The example commands below limit the jobs to 8 hours in case you forget.

## Option 1: Batch job

```
bp-login $ port=<<<PORT>>>
bp-login $ cd my/directory/of/notebooks
bp-login $ lbatch --hours 8 -a PROJECT_CODE --port ${port} --cmd "jupyter notebook --no-browser --port ${port}"
```

Once the job starts running on the cluster, a file called `slurm-JOBID.out` will include the output for the jupyter command including the server logs so check it to determine when the Jupyter server is up and running.

Don't forget to cancel the job once you've finished.

If you want to connect a jupyter notebook in VSCode to a remote jupyter server, you need to set up the jupyter server with some extra settings:

```
bp-login $ lbatch --hours 8 -a PROJECT_CODE --port ${port} --cmd "jupyter notebook --no-browser --port ${port} --NotebookApp.allow_origin='*' --NotebookApp.ip='0.0.0.0'"
```

Then from a remote session in VSCode (i.e. connected to one of the login nodes), follow the instructions [here](https://code.visualstudio.com/docs/datascience/jupyter-kernel-management#_existing-jupyter-server) making sure to use the url from `slurm-JOBID.out` that contains the compute node address (e.g. `http://bp1-compute001:8893/?token=TOKENSTRING`) 

## Option 2: Interactive job

This way is more typing and you will want to use something like screen or tmux to keep the jupyter process running in case you lose network connection. The advantage of being interactive is the live feedback from the commands so you'll know immediately when you have a compute node and when Jupyter is running.

```
bp-login $ cd my/directory/of/notebooks
bp-login $ lint
```

This will eventually leave you with a shell on a compute node at which point you can open SSH tunnels back from the login nodes and start Jupyter:

```
bp-compute $ port=<<<PORT>>>
bp-compute $ for i in 1 2 3 4 5; do /usr/bin/ssh -N -f -R ${port}:localhost:${port} bp1-login0${i}.data.bp.acrc.priv; done
bp-compute $ jupyter notebook --no-browser --port ${port}
```

Don't forget to kill the interactive job once you've finished.

## Option 3: Login node

```
bp-login $ port=<<<PORT>>>
bp-login $ cd my/directory/of/notebooks
bp-login $ jupyter notebook --port ${port} --no-browser
```

## Opening a notebook in a browser

Whichever approach you choose you will need to open an SSH tunnel from your local machine to a login node.
NB your port will need to match the one used to by the Jupyter server.

```
local $ port=<<<PORT>>>
local $ ssh -N -f -L localhost:${port}:localhost:${port} -J seis blue-pebble
```

At this point you can point your local browser to `http://localhost:<<<PORT>>>`.

## One line helper

The script [local_bin/bp_jupyter](../local_bin/bp_jupyter) will:
1. Pick a random port
2. Submit a job to run Jupyter notebook on a compute node with needed SSH tunnels on the cluster
3. Open an ssh tunnel to the login node

e.g.
```
local $ local_bin/bp_jupyter --hours 8
```
The options you pass will be given to lscript and lcmd so you can use them to set your job resource needs.

The downside is that it will run the Jupyter server in your home directory and you will still need to cancel the job when your are finished.

The script also assume you have create an alias in your local SSH config which points bp at Blue Pebble login node with the correct username.

## SSH forwarding
Once you've got a Jupyter server running on a BluePebble compute node, it can be convenient to set up SSH forwarding to that server.
This allows you to have the Jupyter notebook file locally on your laptop but execute it remotely on the GPU, which I find really convenient.

Assuming the server is running at bp1-gpu039 on port :8888, and that your local machine has the BluePebble login node saved as `bp` in your SSH config, you can set up SSH forwarding with
```
ssh -L 8888:localhost:8888 -o ProxyJump=bp bp1-gpu039
```
Then simply open a Jupyter notebook on your local machine, click the kernel selector in the top right corner, then "Select another kernel", "Existing Jupyter server" and type in `http:127.0.0.1:8000`
