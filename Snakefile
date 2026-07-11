### snakefile for running the rpadi video sleap inference pipeline


# import deps
# also utilizing sleap versions 1.6.2 via uv/powershell
import os

# import the config file
configfile: "config.yaml"
shell.executable("powershell.exe")

# extract paths from config
VIDEO_DIR = config["video_dir"]
OUTPUT_DIR = config["output_dir"]
MODEL_DIR = config["model_dir"]

# we can scan for all videos while also mapping the structure of the input directory
# this will capture the condition, treatment, and replicate info already in the directory structure
CONDITIONS, REPLICATES, VIDEO_IDS = glob_wildcards(f"{VIDEO_DIR}/{{condition}}/{{replicate}}/Camera0/{{video_id}}.mp4")

# debug wildcards
# print(f"\n--- DEBUG INFO ---")
# print(f"searching exactly in: {VIDEO_DIR}")
# print(f"number of videos found: {len(VIDEO_IDS)}")
# print(f"------------------\n")


# set the rule all to specify the final output files we want to generate
rule all:
    input:
        # we can use zip to make sure snakemake can pair the exact wildcards that were found together on disk
        expand(
            f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.h5",
            zip,
            condition=CONDITIONS,
            replicate=REPLICATES,
            video_id=VIDEO_IDS
        )


# we can set a rule that does the first sleap inference step and outputs the results to a directory
rule predict_chunk:
    input:
        video=f"{VIDEO_DIR}/{{condition}}/{{replicate}}/Camera0/{{video_id}}.mp4",
    output:
        # save initial sleap prediction file
        slp = f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.slp"
    log:
        # log text file for catching output (FPS) or errors
        txt=f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_predict.log"
    #benchmark:
    #    f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_predict.benchmark.txt"
    params:
        model=MODEL_DIR
    shell:
        """
        # for testing purposes, add --n-frames 5000 to limit to a smaller num of frames
        sleap-nn predict {params.model} {input.video} -o {output.slp} --runtime tensorrt --batch-size 32 > {log.txt} 2>&1
        """

# after we have our predictions, we can convert to h5 format to save space and make it easier to work with downstream
# h5 files with no tracking overwrite individuals, CSV unnafected.
# rule convert_to_h5:
#     input:
#         slp=f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.slp"
#     output:
#         # The final flattened analysis array
#         h5=f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.h5",
#         csv=f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.csv"
#     shell:
#         """
#         # convert the SLEAP format into a smaller hdf5 format
#         sleap export {input.slp} -o {output.h5} --h5-dim-order standard
#         # small csv export for quick debugging
#         sleap export {input.slp} -o {output.csv}
#         """

# instead of converting to h5 and having to track. we can just treat the csv as temp and convert to h5
# here we use pandas. maybe there are faster functions in different libs? files should fit in memory though so this should be sufficient
rule convert_to_pandas_h5:
    input:
        slp=f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.slp"
    output:
        h5=f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.h5",
        # add temp around csv after testing, we can also add a rule to clean up the intermediate files if we want to save space
        csv=temp(f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_sleap.csv")
    #benchmark:
    #    f"{OUTPUT_DIR}/{{condition}}/{{replicate}}/{{video_id}}_convert.benchmark.txt"
    shell:
        """
        # first export to csv
        sleap export {input.slp} -o {output.csv}
        
        # convert to h5 with pandas, adjust paramters as needed for compression and speed
        uv run --with pandas --with tables python -c "import pandas as pd; df = pd.read_csv('{output.csv}'); df.to_hdf('{output.h5}', key='sleap_data', mode='w', complevel=9)"
        """

# we can also add rules to clean up the intermediate files if we want to save space