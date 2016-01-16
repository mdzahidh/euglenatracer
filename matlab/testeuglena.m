
%%% uncomment the following to see debug images,
%%% Caution: it may flood your current directory with many images!
% json = euglena('movie.mp4',10,'debug');


display('Tracing euglenas from movie');
json = euglena('movie.mp4',10,'threshold',5);
data = fromjson(json);
disp (sprintf('There are %2d tracks',length(data)))

%% accumulated some info in a table, its much easier to manipulate from here
table = int32(zeros(length(data), 4 ));
for i = 1:length(data)   
    table(i,:) = [data{i}.trackID, data{i}.startFrame, data{i}.lastFrame, data{i}.numSamples];
end

%% sorting tracks by start time
table = sortrows(table, 2);
disp ( sprintf('The largest track has a length of %d', max(table(:,4)) ) );
disp ( sprintf('The smallest track has a length of %d', min(table(:,4)) ) );