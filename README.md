# device-data-pipeline
## Last updated 21Jul2022 by J. Whear
## Updated 20Dec2022 by Jazlin Taylor

## simple_CL.py
Controls Open Ephys recording and stimulation. Outputs MATLAB struct and records experiment video for offline analysis.

### Dependencies
dev-record Anaconda Environment: https://drive.google.com/file/d/1jDtlvcnChtuyR-nHQDAhDg8elKqCbgwa/view?usp=sharing

dev_cam.py

## dev_cam.py
Handles experiment recordings using OpenCV

## create_ds_data()
To be run on rig machine and corresponding outputs be transferred to another computer for analysis. File asks for log_file.mat created by Python. 

## create_ds_acceleration()
Very similar to create_ds_data - Takes accelerometry data from Intan board and prepares it for further analysis.

## clean_timeseries()
File once again asks for log_file.mat from Python. Appends clean data to same .mat files.

## create_TFR_coh_from_log()
File once again asks for log_file.mat from Python. creates a TFR.mat and coh.mat file.

## create_daily_plots()
File once again asks for log_file.mat from Python. creates plots of coh vs freq for pre stim, post stim, and difference between the two. Also plots theta distribution and Z-score theta coherence.

## mtmcoh.m
Takes in cleaned time series data created from create_ds_data() and clean_timeseries() to calculate multitaper coherence values and plots the spectrogram. Uses functions from FieldTrip
