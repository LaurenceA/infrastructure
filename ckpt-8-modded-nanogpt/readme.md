# What is this?

The script `train_gpt2.py` is _almost_ checkpoint 8 of modded-nanogpt, but we
also store most model weights in bfloat16. The motivation for having a version
of modded-nanogpt at checkpoint 8 is that it is the last simple checkpoint.
Subsequent checkpoints contain weird architectural tricks.

The recipe for obtaining this script was simple:

1. Begin with commit 11e39fb of https://github.com/KellerJordan/modded-nanogpt
2. Include bfloat16 changes from 6671ed1
3. Add SMALL_GPU flag for experimenting on smaller gpus.


# Instruction for running

1. Install packages: torch==2.5, numpy, huggingface_hub. For me, the following
works:

```
mamba create -n sf312 python=3.12
mamba install -c pytorch -c nvidia cuda-python cuda pytorch pytorch-cuda=12.4 # check the cuda version here matches the one on BP nodes
pip install numpy # also install tiktoken if you want to tokenize new data
pip install huggingface_hub # some authetication is probably required to get this package working...
```

At the time of writing, if you try to use torch==2.6 you will get an error
related to strides. torch==2.5 is important!

2. Download (tokenized) data with `python ./data/cached_fineweb10B.py`.

3. Begin training!:

```
# one gpu:
torchrun --standalone --nproc_per_node=1 train_gpt2.py

## multiple gpus (e.g. 4):
# torchrun --standalone --nproc_per_node=4 train_gpt2.py
```

The script will train for ~4578 steps.

4. After ~3 hours on a single A100, you should see ~3.28 validation loss. The
wall time should scale linearly with number of GPUs, so for 8 A100s expect
~20mins.

# Example job submission

Say you want to use 2 GPUs for 4 hours, submit a job with `lbatch` by running:

```
lbatch -c 1 -g 2 -t 4 -m 64 -a cosc020762 --queue cnu --cmd "torchrun --standalone --nproc_per_node=2 train_gpt2.py"
```

To use A100s: add `--gputype A100` and/or `--exclude_40G_A100`.

# Note on GPUs

The code was originally designed for H100s but runs fine on A100s, albeit
roughly 2x slower. The code will run on GPUs with less memory by decreasing
memory requirements, e.g. by decreasing `device_batch_size` in `train_gpt2.py`,
or altering the model configuration. When testing, I found some attention
implementations don't work with RTX 2080; a `SMALL_GPU` flag is included as a
work around to this.