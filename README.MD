# *Rhopalosiphum padi* Sleap Inference Pipeline

## Overview
This repository contains the scripts used to inference over the *R. padi* video data using the sleap program.


## Tools and Dependencies
Currently, we are utilizing sleap and snakemake as installed via the uv package manager. 

```powershell
PS C:\Users\nalamlab\RpadiSleapInferencePipeline> uv tool list
sleap v1.6.2
- sleap
- sleap-convert
- sleap-diagnostic
- sleap-inspect
- sleap-label
- sleap-nn-export
- sleap-nn-predict
- sleap-nn-track
- sleap-nn-train
- sleap-render
- sleap-track
- sleap-train
sleap-nn v0.1.3
- sleap-nn
snakemake v9.23.1
- snakemake
```
Note: the snakemake docs suggest installing with pixi/pip on linux and using WSL when utilizing a workflow on a windows machine. I have had success in installing snakemake as a command line tool with uv with no issue so far.

We installed snakemake with:

```powershell
 uv tool install snakemake
```

Sleap v1.6.2 and the associated NN and IO packages were also installed with uv following the documentation: https://docs.sleap.ai/v1.6.2/installation/. 

## Overall Workflow

We have a series of videos of *R. padi* across 96 h. For each video, we have 96 series of 1 h video chunks. Each replicate contains these 96 h videos.

We have these backed up in a few places. But this is what the dataset looks like. Note we have reps across both LD and DD conditions on artificial diet (we additionally have a wheat dataset in progress).

```powershell
PS C:\Users\nalamlab\campyav1\campy\experimental_videos\reps> ls


    Directory: C:\Users\nalamlab\campyav1\campy\experimental_videos\reps


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         2/25/2026   1:31 PM                DD-Diet
d-----         2/10/2026  12:39 PM                LD-Diet
d-----          7/2/2026   1:20 PM                LD-wheat
```

We can also see how the LD and LL diet datasets look in terms of their directory structure.

```powershell
PS C:\Users\nalamlab\campyav1\campy\experimental_videos\reps> tree /A
Folder PATH listing for volume OSDisk
Volume serial number is 020D-0849
C:.
+---DD-Diet
|   +---agesync_10-23-25-rep2-DD
|   |   \---Camera0
|   +---agesync_10-3-25-rep1-DD
|   |   \---Camera0
|   +---agesync_11-17-25-rep3-DD
|   |   \---Camera0
|   +---agesync_11-28-25-rep4-DD
|   |   \---Camera0
|   +---agesync_12-16-25-rep5-DD
|   |   \---Camera0
|   +---agesync_12-26-25-rep6-DD
|   |   \---Camera0
|   +---agesync_2-11-26-rep7-DD
|   |   \---Camera0
|   +---agesync_2-18-26-rep8-DD
|   |   \---Camera0
|   \---PC_WENT_TO_SLEEP_CORRUPTED_agesync_10-13-25-rep2-DD
|       \---Camera0
+---LD-Diet
|   +---agesync_1-2-26-rep7
|   |   \---Camera0
|   +---agesync_1-23-26-rep8
|   |   \---Camera0
|   +---agesync_7-29-25-rep1
|   |   \---Camera0
|   +---agesync_8-19-25-rep3
|   |   \---Camera0
|   +---agesync_8-25-25-rep4
|   |   \---Camera0
|   +---agesync_8-8-25-rep2
|   |   \---Camera0
|   +---agesync_9-11-25-rep5
|   |   \---Camera0
|   \---agesync_9-18-25-rep6
|       \---Camera0
\---LD-wheat
    +---agesync_4-25-26-rep1-LD
    |   +---Camera0
    |   \---env_cond
    +---agesync_5-9-26-rep2-LD
    |   +---Camera0
    |   \---env_cond
    +---agesync_6-19-26-rep3-LD
    |   \---Camera0
    \---agesync_6-26-26-rep4-LD
        \---Camera0
```
Great, we can see that each rep has a subfolder with `camera0` denoting that these videos contain only one camera.

In that subdirectory we can see all of the videos and additional metadata that the `campy` python program includes. The `video.mp4` files are the only thing of interest to us right now.

```powershell
PS C:\Users\nalamlab\campyav1\campy\experimental_videos\reps\LD-Diet\agesync_1-2-26-rep7\Camera0> tree /F
Folder PATH listing for volume OSDisk
Volume serial number is 020D-0849
C:.
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_125141_0-215999.mp4
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_125141_metadata.csv
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_135141_216000-431999.mp4
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_135141_216000-431999_timestamps.csv
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_145142_432000-647999.mp4
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_145142_432000-647999_timestamps.csv
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_155142_648000-863999.mp4
    LD-diet_agesync_1-2-26-rep7_Camera0_20260109_155142_648000-863999_timestamps.csv
```

Great we can see all of our videos in that specific directory. Essentially this is the input unit of our pipeline. We want to read a video, run inference on that video, and save the results to an output directory. Additionally, in between inference and saving the results, we may want to convert our results into a smaller sized file, such as an h5 file, to save storage space. These h5 files will be a great unit to import into R or python for our downstream analysis.


## Running the Workflow. 
To run the workflow, make sure that you are in the correct directory where the snakefile lives. 

For us this is in the user directory (the default dir after opening a PS instance):
```powershell
PS C:\Users\nalamlab> cd .\RpadiSleapInferencePipeline\
```

Be sure to tell snakemake where your input videos, output directory, and sleap models are in the `config.yaml` before running the pipeline!

Once in the directory with the correct config, the workflow can be ran by the command.
```powershell
snakemake --cores 4
```
We have optimized our models to be able to fit 4 inference jobs on our machine at once. Maybe we can do 5 at once but lets not get greedy, 4 is already using ~80% of our GPU. Thus we keep the number of cores at 4. 