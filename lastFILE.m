function [resltMTX,butt,n,m,currentContrast,PNGrslts_MetaData,pngCounter,f1] = ...
    lastFILE(fileMTX,ResultsFolder, ...
    PngFolder,CheckNum, resltMTX,butt,n,m,currentContrast, ...
    PNGrslts_MetaData, handleMTX, whoMTX,pngCounter,f1,f2,WaveFolder, ...
    Recorder,WhoRan);
%v4.0 04/04/13 - keyboard shortcuts for lighten/darken/done
%v3.0 12/28/12 - multiple species review now
% v2.1 4/4/12   - fixed to save  if stopping right after backing
% up.
% v2.0  12/27/11 - darken/lighten stays until changed.

%v1.2  5/9/11
% Move to previous file

if exist([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName])
load([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
    'resltMTX','whoMTX','PNGrslts_MetaData');
end

n = n-1;
if n == 0; % then you are at start of that day.
    m = m-1; % go to previous day
    if m >0;
        n = size(fileMTX{m},1); % go to last file of previous day
        if m ==1 & n == 1;
            set(butt.obj1,'visible','off');
        end
    else
        % then you are back to the beginning - turn off back button.
        set(butt.obj1,'visible','off');
        m =1;
        n = 1;
    end
end


% not going to reset everything to 'No'.  Because you are maybe wanting to
% change the answer for just one species.  The startday/startpng will keep
% you on track, even if you close out Soundchecker before you've changed
% all you have backpedaled over.  It won't say you are done until
% startday/startpng is at the end.

%show the results here:
 % first set to defaults:
    for o = 1:size(handleMTX,1);
        %find what original selection is and set buttons

        if  resltMTX(n,m,o) == 99;
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));  % No is selection         
        elseif resltMTX(n,m,o) == 81; % autodetection - yes
            set(eval(['butt.objgrp' num2str(o)]),...
                'SelectedObject',handleMTX(o,1));  % Yes is selection
             set(eval(['butt.objNo' num2str(o)]),'BackgroundColor',[ 1.0000 0.4102 0.7031]);
        elseif resltMTX(n,m,o) == 80; % autodetection - no
            set(eval(['butt.objgrp' num2str(o)]),...
                'SelectedObject',handleMTX(o,3));  % No is selection
             set(eval(['butt.objNo' num2str(o)]),'BackgroundColor',[ 1.0000 0.4102 0.7031]);
        else
            if resltMTX(n,m,o) ~=0;
                set(eval(['butt.objgrp' num2str(o)]), ...
                    'SelectedObject',handleMTX(o,resltMTX(n,m,o)));
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));

            end
        end
       
    end



% display previous file
PngFileDashes = strfind(fileMTX{1}(1,:),'-');  %just look at 1st file of 1st folder.
for ff = 1:size(fileMTX,2);
    PngDays(ff,:) = char(fileMTX{ff}(1,PngFileDashes(2)+1:PngFileDashes(2)+6));
end

[n,m,currentContrast] = pngPLOT(fileMTX,PngFolder,n,m,currentContrast);

% 
PNGrslts_MetaData(CheckNum).startday = m;
PNGrslts_MetaData(CheckNum).startpng = n;

% save results matrix so answer is not lost if system crashes ************
save([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
    '*MTX','PNGrslts_MetaData');
pngCounter = pngCounter-1;
butt.obj0 = uicontrol('Parent',f1,'Style','Text', ...
    'String', num2str(pngCounter),'backgroundcolor',[1 1 1], ...
    'Units','normalized','Position',[.92 .92 .05 .025]);
Getvars = get(f1,'WindowKeyPressFcn');
whoMTX = Getvars{13};
%     currentContrast = Getvars{8};
Getvars{10} = pngCounter;
Getvars{6} = n;
Getvars{7} = m;

Getvars{2} = butt;
set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button

end

