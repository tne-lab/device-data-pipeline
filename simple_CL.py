# Last updated 22Jul2022 by JHW
# NOTE: Video/Ephys are approximately concurrent. Start and stop times are prone to slight mismatch.

print('Importing Required Libraries')
import json
import threading
import time
import os

#import tkinter
from tkinter import *
from queue import Queue

from scipy.io import savemat
import pyximport; pyximport.install()

import daqAPI
import dev_cam as cam
import stimmer
import zmqClasses


print('Libraries Successfully Imported!')
######################### THINGS TO CHANGE ###########################
CLTimerLocked = 10 # Seconds 1800 (How long to run closed loop)
#CLTimerPre = 600 # seconds for section to let TORTE lock to 180 degrees, added 12/17/2021
CLTimerPre = 6 # seconds for section to let TORTE lock to 180 degrees, added 12/17/2021
stimAddressX = 'Dev1/ao0' # stim
stimAddressY = 'Dev1/ao1' # Sham
CLCHANNEL = 1             # CL event channel (out from last crossing detector)
# Change back to 500 for stimjim
CLMicroAmps = 500         # How many microamps (100ua/V) - 90micro sec biphasic pulse
CLLag = 0                 # Wait? (almost zero for phase based CL, only used in plasticity)
CLTimeout = 1             # Timeout between stim
CLTimeoutVar = 0.2        # Timeout var
OE_Address = "localhost"  # localhost or ip address of other computer
rat = 'dev2211'
day = 'day4'
drive = "D:" # drive where the data is written - This should be the same on all device project computers
drive_folder = 'EPHYSDATA'
record_dir = os.path.join(drive, drive_folder, rat, day) # os.path is the clean way of formatting paths between unix/windows platforms
watchChannel = '1-2' # what channel did you watch for phase '1-2' would mean channel 1 was watched and was bipoled with channel 2
freqRange = [4, 8] # what freq range (just for logging purposes, doesn't change anything in OE itself)

### Recording Conditions ###
light_type = 'Ambient' # Were lights on in the chamber? If not LED or puck light, maybe 'OFF'?
light_color = 'N/A'
door_open = False # Was the door of the chamber open or closed? Boolean value is my first thought for this
erps = False # Was erp section included in the recording protocol?
rec_by = 'PB, JN' # Who did the recording?
rec_comp = "Rig 1"
rec_notes = 'Stim return wire is attatched to a bone screw' # Blank by default

### ERP Parameters ###
nERP = 5 # How many ERPS [50]
ERPTOmin = 3 # ERP timeout min and max
ERPTOmax = 5
nERPLoc = 2 # How many locations to do ERP in

### Raw Parameters ###
rawTime = 1 # In minutes [5]

### Additional Parameters ###
recordingList = []
snd = zmqClasses.SNDEvent(OE_Address,5556, recordingDir = record_dir)
print('IF HANGS ADD NETWORK EVENTS TO OPEN EPHYS!!!')
snd.send(snd.STOP_REC)
stimX = daqAPI.AnalogOut( stimAddressX)
stimY = daqAPI.AnalogOut( stimAddressY)
stimQ = Queue()
stimBackQ = Queue()

### RAW_PRE ###
print('starting raw pre')
snd.send(snd.STOP_REC)
snd.changeVars(prependText = 'RAW_PRE')
t1 = threading.Thread(target=cam.run_rec, args=[os.path.join(record_dir,'RAW_PRE'+rat+day+".avi"), rat, day, 'RAW_PRE', 0])
t2 = threading.Thread(target=snd.send, args = snd.START_REC)
t1.start()
t2.start()
time.sleep(rawTime*60) # Sleep time
cam.stop_threads = True
t1.join()
t2.join()
snd.send(snd.STOP_REC)
recordingList.append('RAW_PRE')
cam.stop_threads = False # Reset for subsequent recording

# CL - 10 minute locking section
snd.changeVars(prependText = 'CLOSED_LOOP_Pre')
snd.send(snd.START_REC)
stimmer.waitForEvent(stimX,  stimY,  stimQ,  stimBackQ,  CLCHANNEL,  CLMicroAmps,  CLLag, CLTimerPre,  CLTimeout,  CLTimeoutVar,  OE_Address)
snd.send(snd.STOP_REC)
recordingList.append('CLOSED_LOOP_Pre')

# CL - 30 Minute Section - Added 12/17/21 - For when we have locked onto 180 degrees
print('starting 30 minute closed loop section')
snd.changeVars(prependText = 'CLOSED_LOOP')
snd.send(snd.START_REC)

t1 = threading.Thread(target=cam.run_rec, args=[os.path.join(record_dir,'CLOSED_LOOP'+rat+day+".avi"), rat, day, 'CLOSED_LOOP', 0])
t2 = threading.Thread(target=stimmer.waitForEvent, args=[stimX,  stimY,  stimQ,  stimBackQ,  CLCHANNEL,  CLMicroAmps,  CLLag, CLTimerLocked,  CLTimeout,  CLTimeoutVar,  OE_Address])
t1.start()
t2.start()
time.sleep(CLTimerLocked) # Stimmer has seperate arg for time, this is for recording only
cam.stop_threads = True
t1.join()
t2.join()
snd.send(snd.STOP_REC)
recordingList.append('CLOSED_LOOP')
cam.stop_threads = False # Reset for subsequent recording

# Raw post
print('starting raw post')
snd.send(snd.STOP_REC)
snd.changeVars(prependText = 'RAW_POST')
t1 = threading.Thread(target=cam.run_rec, args=[os.path.join(record_dir,'RAW_POST'+rat+day+".avi"), rat, day, 'RAW_POST', 0])
t2 = threading.Thread(target=snd.send, args = snd.START_REC)
t1.start()
t2.start()
recordingList.append('RAW_POST')
time.sleep(rawTime*60)
cam.stop_threads = True
t1.join()
t2.join()
snd.send(snd.STOP_ACQ)
cam.stop_threads = False

# End tasks with daq so we can use them again
stimX.end()
stimY.end()

matdic = {}
# save data folders
matdic['paths'] = recordingList
# save data vars from above
matdic['CLTimerLocked'] = CLTimerLocked # recording in seconds of CL - This is a new add 12/17/21 to add a second stim section - JHW
matdic['CLTimerPre'] = CLTimerPre # Added 12/17/21 - JHW. See above comment
matdic['stimAddressX'] =stimAddressX # stim
matdic['stimAddressY'] =stimAddressY         # Sham
matdic['CLCHANNEL'] =CLCHANNEL            # CL event channel (out from last crossing detector)
matdic['CLMicroAmps'] =CLMicroAmps         # How many microamps
matdic['CLLag'] =CLLag              # seconds to sleep between event recieved and sending out stim. Also can use a list ie [0, 5] to wait randomly between 0 and 5 seconds after event
matdic['CLTimeout'] =CLTimeout              # Timeout between stim
matdic['CLTimeoutVar'] =CLTimeoutVar         # Timeout var
matdic['OE_Address'] =OE_Address   # localhost or ip address of other computer
matdic['record_dir'] =record_dir         # Where do you want data to be recorded
matdic['watchChannel'] =watchChannel  # what channel did you watch for phase '1-2' would mean channel 1 was watched and was bipoled with channel 2
matdic['freqRange'] =freqRange # what freq range

## ERPS
matdic['nERP'] =nERP  # How many ERPS
matdic['ERPTOmin'] =ERPTOmin  # ERP timeout min and max
matdic['ERPTOmax'] =ERPTOmax 
matdic['nERPLoc'] =nERPLoc # How many locations to do ERP in

## Raw 
matdic['rawTime'] =rawTime # In minutes

# Recording Conditions
matdic['light_type'] = light_type
matdic['light_color'] = light_color
matdic['door_open'] = door_open
matdic['erps'] = erps
matdic['rec_by'] = rec_by
matdic['rec_notes'] = rec_notes
matdic['rec_comp'] = rec_comp
matdic['rat'] = rat
matdic['day'] = day

savemat(record_dir + '\\log_file.mat', matdic)
