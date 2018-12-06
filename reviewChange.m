function [resltMTX,whoMTX,butt,currentContrast,PNGrslts_MetaData,reviewCntr,n,m,f1,f2] = ...
    reviewChange(resltMTX, fileMTX, whoMTX, CheckNum, ...
    ResultsFolder,PngFolder, butt,Recorder, Sounds,...
    PNGrslts_MetaData,currentContrast,handleMTX, WhoRan,reviewCntr,strtRevCntr,f1,f2); %n is png; m is day; o is spp

%v4.0 04/04/13 - keyboard shortcuts for lighten/darken/done
%v3.0 12/28/12 - multiple species review now
% new version 12/27/2012 - makes permanent change to results/who MTX's.

Getvars = get(f2,'WindowKeyPressFcn');
reviewCntr = Getvars{21};  % this will take the counter from either the key or the button.
resltMTX = Getvars{12};
whoMTX = Getvars{13};
butt = Getvars{2};
currentContrast = Getvars{8};

if exist([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName])
    load([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
        'resltMTX','whoMTX','PNGrslts_MetaData');
end


nm = get(butt.review,'UserData');
dirx = nm(2,3);  % set to 1 as soon as you open reviewmode - can change with reviewscroll
choices = nm(1,1);
Rn = nm(3:end,2);
Rm = nm(3:end,1);
Rfiles = nm(3:end,3);
n = Rn(reviewCntr);
m = Rm(reviewCntr);
% reviewCntr is imported in from reviewMode and reviewScroll - it won't
% change until you accept a change or scroll to next.  This is the change
% code here.

for o = 1:size(handleMTX,1);
    
    selected = get(eval(['butt.objgrp' num2str(o)]),'SelectedObject');
    answer = find(handleMTX(o,:) == selected);
    if answer ~=3;
        resltMTX(n,m,o) = answer;
    elseif answer == 3;
        resltMTX(n,m,o) = 0;
    end
    
end

whoMTX{m}(n,:) = WhoRan;


% save results matrix so answer is not lost if system crashes ************
save([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
    '*MTX','PNGrslts_MetaData');

% set(butt.obj20,'Value',reviewCntr-strtRevCntr);
Getvars{21} = reviewCntr;
Getvars{12} =  resltMTX;
Getvars{13} = whoMTX;
Getvars{2} = butt;
Getvars{8} = currentContrast;
  set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
 set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button


[butt,resltMTX, currentContrast, PNGrslts_MetaData,reviewCntr,n,m,f1,f2,whoMTX] = ...
    reviewSCROLL(fileMTX,PngFolder, resltMTX,handleMTX,PNGrslts_MetaData,CheckNum, ...
    butt,dirx,currentContrast,Sounds,reviewCntr,strtRevCntr,f1,f2,whoMTX,ResultsFolder);


