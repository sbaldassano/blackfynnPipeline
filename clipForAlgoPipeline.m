% use this to assemble and save the clips to train classifier
% it takes in .mat files for each seizure and interictal segment

function clipForAlgoPipeline(fs, ptName)

leads = 1:4;  
% make a directory for this subject's data    
if ~exit(ptName,'dir')
    mkdir(ptName)
end
% set up channels names in correct format
for i = 1:numel(leads)
    field = ['X_Ch' num2str(i) '_'];
    channels.(field) = ['Ch' num2str(i)];
end

% load and clip seizures
szClipNum = 0;
i=1;
while 1
    try
        load(['sz' num2str(i) '.mat'])
    catch
        fprintf('All %g seizures loaded\n', i-1);
        break
    end
    curData = clip;
        
    numClips = floor(size(curData,1)/fs);
    ictal=1;
    netClips = clipData(curData',fs,channels,ptName,numClips,szClipNum,ictal);               
    szClipNum = szClipNum + netClips;
    i = i+1;      
end
    
% load and clip interictals    
interictalClipNum = 0;
i=1;
while 1
    try
        load(['nonsz' num2str(i) '.mat'])
    catch    
        fprintf('All %g interictal segments loaded\n', i-1);
        break
    end

    curData = clip;  
            
    numClips = floor(size(curData,1)/fs);       
    ictal=0;
    netClips = clipData(curData',fs,channels,ptName,numClips,interictalClipNum,ictal);   
    interictalClipNum = interictalClipNum + netClips; 
    i = i+1;
end
end

% this function does the actual clipping. It gets rid of one-second clips that have missing data or dead leads. Saves the one-second clips
% in the format expected by the algorithm for training
function netClips = clipData(curData,fs,channels,ptName,numClips,tempClipNum,ictal)
    % will clip the data into one second chunks and then save each of them
    % in the appropriate format
    freq = fs; 
    pos = 0;
    skippedForNans = 0;
    for c = 1:numClips
        data = curData(:,pos+1:pos+fs);
        pos = pos+fs;
        if any(any(isnan(data)))
            skippedForNans = skippedForNans + 1;
            continue
        end
        if any(all(data'==0))
            skippedForNans = skippedForNans + 1;
            continue
        end
        data = data - repmat(mean(data,2),1,size(data,2)); %mean normalize each channel signal within the clip. could try without this.
        latency = c-1;
        if ictal
            save([ptName '/' ptName '_ictal_segment_' num2str(c-skippedForNans+tempClipNum) '.mat'], 'data','channels','freq','latency');
        else
            save([ptName '/' ptName '_interictal_segment_' num2str(c-skippedForNans+tempClipNum) '.mat'], 'data','channels','freq');
        end

    end
    netClips = numClips - skippedForNans;
end
        
    
