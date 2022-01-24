# device-data-pipeline
## Last updated 24Jan2022 by J. Whear

## create_ds_data()
To be run on rig machine and corresponding outputs be transferred to another computer for analysis. File asks for log_file.mat created by Python. Jan2022 version alos takes in accelerometry data from Intan board.

## clean_timeseries()
File once again asks for log_file.mat from Python. Appends clean data to same .mat files.

## create_TFR_coh_from_log()
File once again asks for log_file.mat from Python. creates a TFR.mat and coh.mat file.

## create_daily_plots()
File once again asks for log_file.mat from Python. creates plots of coh vs freq for pre stim, post stim, and difference between the two. Also plots theta distribution and Z-score theta coherence.
