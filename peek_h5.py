import sys
import os
import pandas as pd
import h5py

def peek_h5(file_path):
    print(f"--- PEAKING AT: {file_path} ---")

    # check file size
    file_size_mb = os.path.getsize(file_path) / (1024 * 1024)
    print(f"File Size: {file_size_mb:.2f} MB")
    
    # peek at the structure using h5py
    print("\n[1] File Hierarchy (HDF5 Structure):")
    with h5py.File(file_path, 'r') as f:
        def print_attrs(name, obj):
            # check for compression metadata if it is a dataset
            comp_info = ""
            if isinstance(obj, h5py.Dataset) and obj.compression:
                comp_info = f" | Compression: {obj.compression} (Level: {obj.compression_opts})"
            print(f"Key: {name} | Type: {type(obj)}{comp_info}")
        f.visititems(print_attrs)

    # peek at the data using Pandas
    print("\n[2] Tabular Preview (First 5 rows):")
    try:
        # load snippet 
        df = pd.read_hdf(file_path, key='sleap_data', start=0, stop=5)
        
        # display settings to ensure we see the columns
        pd.set_option('display.max_columns', 10)
        pd.set_option('display.width', 1000)
        
        print(df)
        print(f"\nTotal Shape: {pd.read_hdf(file_path, key='sleap_data').shape}")
        
    except Exception as e:
        print(f"Could not load tabular data: {e}")

if __name__ == "__main__":
    
    # path inside the quotes below
    h5 = r"example/video_sleap.h5"
    
    # use command line arg if provided, otherwise use the hardcoded path
    if len(sys.argv) > 1:
        target_file = sys.argv[1]
    else:
        target_file = h5
        
    peek_h5(target_file)