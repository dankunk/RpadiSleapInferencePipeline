# When exporting with sleap to h5, the tracks dataset is only showing one individual.
# This is due to a bug with sleap (https://github.com/talmolab/sleap/issues/1853)
# CSV seems to be patched but the h5 export is not. 
# This script compares the CSV and H5 outputs to see if they match, and how many instances are in each.

# The best thing to do is to likely add tracks during inference. 
# This will allow us to get the correct number of instances in the h5 file.
# It will also allow us to not have to correct for identity based on ROI as we did previously.

import sys
import pandas as pd
from pandas.testing import assert_frame_equal

def validate(csv_path, h5_path):
    print(f"--- Loading Data ---")
    df_csv = pd.read_csv(csv_path, low_memory=False)
    df_h5 = pd.read_hdf(h5_path, key='sleap_data')
    
    # sort to ensure order matches
    df_csv = df_csv.sort_values('frame_idx').reset_index(drop=True)
    df_h5 = df_h5.sort_values('frame_idx').reset_index(drop=True)

    print(f"CSV Shape: {df_csv.shape}")
    print(f"H5 Shape:  {df_h5.shape}")
    
    print(f"\n--- Previewing CSV Data (First 2 rows) ---")
    print(df_csv.head(2))
    
    print(f"\n--- Previewing H5 Data (First 2 rows) ---")
    print(df_h5.head(2))

    print(f"\n--- Running Assertion ---")
    try:
        assert_frame_equal(df_csv, df_h5, check_dtype=False, atol=1e-5)
        print(":) SUCCESS: Data frames match!")
    except AssertionError as e:
        print(":( FAILED: Data frames do not match.")
        print(e)

if __name__ == "__main__":
    # update these paths to the specific file you want to check
    csv_file = r"D:\snakemake_test_output\LD_Diet\agesync_7-29-25-rep1\LD-diet_agesync_7-29-25-rep1_Camera0_20250806_142325_10800000-11015999_sleap.csv"
    h5_file = r"D:\snakemake_test_output\LD_Diet\agesync_7-29-25-rep1\LD-diet_agesync_7-29-25-rep1_Camera0_20250806_142325_10800000-11015999_sleap.h5"
    validate(csv_file, h5_file)


