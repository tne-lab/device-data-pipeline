function S = closed_loop_stim_config(t, boi, phi)
% This function defines the Closed-loop phase-locked stimulation delivered
% during a recording session.
% By V. Woods - Created on 6/29/2021



S = struct;
S.current_uA = 100;
S.pulse_width_us = 45;
S.waveform = 'biphasic, symmetric, charge-balanced';
S.npulses = 1;

% Time (in minutes) for closed-loop stimulation
S.duration_in_minutes = t;

%If sham pulses are delivered every other Trigger Event, then set to True.
S.sham = 'True'; 

%Lock-out period configured in OEP code (i.e., how long the stim control
% to wait for next Trigger Event
S.stimTimeOut = 1; %in seconds
S.shamTimeOut = 1; %in seconds

%Physiological freq band of interest, set in OEP signal chain
switch boi
    case 'theta'
        S.band = [4 8];
    otherwise
        warning('Are you sure you''re not using the theta band?')
end
        

%Source site for phase calculation
S.source = 'IL';
S.sourceChan = 'Bipolar IL 1-2';

%Phase threshold for stimulus trigger
S.phase_thr = phi; %in degrees

%Target site for stimulus delivery
S.target = 'BLA';
