commonFiles = {'demo01_basic_load.m';
               'demo02_trackid.m';
               'demo03_multitrack.m';
               'EuglenaTracks.m';
               'textprogressbar.m';
               'problem_1d.m';
               'problem_1e.m'};
           
mexModules = {'euglena';
              'fromjson';
              'tojson';
              'setjsonfield';              
             };

datasets = {'data1';
            'data2';
            'data3'
            };
        
destFolder = '';
if ismac
    destFolder = 'OSX/';
elseif isunix
    destFolder = 'Linux/';
elseif ispc
    destFolder = 'Windows/';
else 
    disp('Unknown platform');
    return
end

mkdir(destFolder);
for i = 1:length(commonFiles)
    copyfile(commonFiles{i},destFolder);
end

for i = 1:length(mexModules)
    copyfile(sprintf('%s.%s',mexModules{i},mexext),destFolder);
end

for i = 1:length(datasets)
    d = datasets{i};
    targetDir = sprintf('%s/%s/',destFolder,d);
    mkdir(targetDir);
    copyfile(sprintf('%s/movie.mp4',d),targetDir);
    copyfile(sprintf('%s/lightdata.json',d),targetDir);
end

if ispc
    copyfile('opencv_ffmpeg310_64.dll',destFolder);
end

