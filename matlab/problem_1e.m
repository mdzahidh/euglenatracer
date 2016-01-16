%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Zahid Hossain (zhossain@stanford.edu), 
% Honesty Kim (honestyk@stanford.edu)
% Riedel-Kruse Lab, Stanford Bioengineering, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load your data
%  replace ./data1 with appropriate path. All the tracks with atleast 10
%  samples will be loaded, feel free to change it.

exp = EuglenaTracks( './data1' ,10);

%% Finding all the tracks that appears within a time period
%  Replace YOUR_START_TIME and YOUR_END_TIME with your desired numbers.
%  This will return a list of tracks (in Matlab Cell format) 
%  instead maybe a single track. Note the use of exp.getFPS() to convert
%  time into frame number. +1 is added because in Matlab indexing starts
%  from 1.
%
%  NOTE: Some tracks may start before your start time, or end later than
%        your end time. i.e. tracks are NOT clipped along selection
%        frame/time boundaries.
startFrame = YOUR_START_TIME_HERE * exp.getFPS() + 1;
endFrame   = YOUR_END_TIME_HERE * exp.getFPS() + 1;
tracks = exp.findTracksBetweenFrames( startFrame , endFrame );

%% Clipping the tracks along selection boundaries.
%  The output is the list of the same tracks except for each track, 
%  only the parts that appeared between startFrame and
%  endFrame are included.
clipped_tracks = exp.clipTracksBetweenFrames( tracks, startFrame, endFrame );

%% Looping through tracks and computing
%  The following is only an example to serve as a hint,
%  so feel free to do whatever you feel fit.
%
%  Here we are looping through all the clipped_tracks and extracting
%  geometry information for each.
%
%  HINT: Selecting tracks, Clipping and then Extracting Geometry is one way to
%        extract data that pertain within a specific time period.

for i=1:length(clipped_tracks)
    %% Loop through each clipped_track
    single_clipped_track = clipped_tracks{i}
    
    % Extract geometry of this single clipped track
    [x,y,width,height,angles,frames] = exp.extractTrackData( single_clipped_track );
    
    % Compute whatever you need to compute here. 
    %
    % Refer to problem_1d.m for an example of how to compute
    % point velocities of a single track.       
end

