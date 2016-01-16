%% EuglenaTrack( datapath, threshold,)
%  where 
%       datapath = path where movie.mp4 and lightdata.json are stored.
%       threshold = Extracted traces have length > threshold. 
%                   e.g. threshold  = 0 extracts every trace.
%
%       Other examples
%       exp = EuglenaTracks('./demo5/',15);
%
%  NOTE: This function also extracts raw images with all the tracks,
%  regardless of the threshold value, in the folder "debug"
%
%  The number written next to each Euglena is their "trackID". We will see
%  shortly how to use these trackIDs.

clc;clear;
exp = EuglenaTracks('./data1/',10);

%% Printing some basic info about the experiment
disp( sprintf('Total number of tracks extracted   : %d'  , exp.getNumTracks()) );
disp( sprintf('Total number of frames in the video: %d'  , exp.getNumFrames()) );
disp( sprintf('Total time of the experiment       : %f s', exp.getTotalTime()) );
disp( sprintf('Frames per second                  : %f s', exp.getFPS()) );
disp( sprintf('Length scale, um per pixel         : %f s', exp.getUMPP()) );

%% Making a full movie
%  NOTE, any movie making takes a long time !
disp('Making movie from all the frames,including all the tracks');
disp('** This may take long; be patient **');


% exp.movieFromFrames(startFrame, endFrame);
M = exp.movieFromFrames(1,exp.getNumFrames());
implay(M);
disp('Close the movie player and press any key to continue');
pause()

%% Finally, any movie produced by the EuglenaTracks module can be saved as
%  an MP4 video by the following:
exp.movieSave('demo01_basic_load',M);