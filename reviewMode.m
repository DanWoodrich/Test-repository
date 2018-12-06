function [currentContrast, PNGrslts_MetaData,resltMTX,whoMTX,butt, ...
    n,m,reviewCntr,strtRevCntr] = reviewMode(butt, resltMTX,whoMTX,handleMTX,fileMTX, ...
    PNGrslts_MetaData,CheckNum,PngFolder, currentContrast, Sounds, ...
    WhoRan,ResultsFolder,Recorder,n,m,f1,f2,WaveFolder,pngCounter);
% v 5.1 3/17/15 - added some lines to sort the chosen pngs by day/png -
% leaving out the species, so the review happens sequentially (and not one
% species after another).
% v 5.0  1/21/15 - added 'stable' to the unique lines to keep them from
% sorting.
%v4.0 04/04/13 - keyboard shortcuts for lighten/darken/done
%v3.0 12/28/12 - multiple species review now
% v2.2  06/01/12   - added option to review back through all pngs - not
% just the ones you analyzed (i.e. gets all skipped ones too).
% v2.1 03/27/12 - added changing answer function - saves to Changes file in
% pngResults folder
% v2.0  12/27/11 - darken/lighten stays until changed.

% v1.2  6/10/11
%n is png; m is day

if get(butt.review,'Value') == 1;  %ON
    set(butt.review,'BackgroundColor',[1 0 0]);
    prompt = {'Date (yymmdd)', 'Time (hhmmss)'};
    parspp = input('Do you want to specify a particular specie(s)?(y/n)','s');
    if parspp == 'y';
        for p = 1:size(char(Sounds(CheckNum).Spp),1);
            fprintf(1,[num2str(p) ':' char(Sounds(CheckNum).Spp{p}) '\n']);
        end
        fprintf(1,' \n');
        whichSpp = input('Which species do you want to review? (#)');
        fprintf(1,'What do you want to look through?\n');
        choices = input(' [1 = yeses, 2 = maybes, 3 = yeses & maybes, 4 = all checked, 5 = not checked, 6 = yes/maybe/unchecked, 7 = no skipping, 8 = just nos]');
    else
        fprintf(1,'What do you want to look through?\n');
        choices = input(' [1 = yeses, 2 = maybes, 3 = yeses & maybes, 4 = all checked, 5 = not checked, 6 = yes/maybe/unchecked, 7 = no skipping, 8 = just nos]');
        whichSpp = 1:size(char(Sounds(CheckNum).Spp),1);  % all species
    end
    
    currfile = fileMTX{m}(n,:);
    dashes = strfind(currfile,'-');
    
    currdate = currfile(dashes(2)+1:dashes(3)-1);
    currtime = currfile(dashes(3)+1:dashes(4)-1);
    
    def = {currdate, currtime};
    spoint = newid(prompt,'Start Point',1,def);
    
    for bn = [1 2 5 6];
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','off');
    end
    set(butt.hold,'Visible','off');
    
    % get list of files to review first.
    if choices == 1;
        [Rindx] = findn(resltMTX(:,:,whichSpp) == 1); % these are Rows, Columns, and sheets for yeses
    elseif choices == 2;
        [Rindx] = findn(resltMTX(:,:,whichSpp) == 2); % these are Rows, Columns, and sheets for maybes
    elseif choices == 3;
        [Rindx] = findn(resltMTX(:,:,whichSpp) ==1 | resltMTX(:,:,whichSpp) == 2);% Rows, Columns, and sheets for y and m
    elseif choices == 4 % these are Rows and Columns for all reviewed
        [Rindx] = findn(resltMTX(:,:,whichSpp) <99);% because 99s aren't reviewed yet.
    elseif choices == 5; % finds all that have not been reviewed
        [Rindx] = findn(resltMTX(:,:,whichSpp) == 99);
    elseif choices == 6; % finds all yeses/maybes/ and 99's - ignores the no's.
        [Rindx] = findn(resltMTX(:,:,whichSpp) ==1 | resltMTX(:,:,whichSpp) == 2 |resltMTX(:,:,whichSpp) == 99);
    elseif choices == 7; % finds all pngs totally (nothing skipped)
        [Rindx] = findn(resltMTX(:,:,1) <=99); % can limit to first spp since will just save time.
    elseif choices == 8; % finds all pngs totally (nothing skipped)
        [Rindx] = findn(resltMTX(:,:,1) ==0); % can limit to first spp since will just save time.
    end
    
    % [png day spp] is what [Rn Rm Ro] are.
    % Because more than one spp can have a yes, need to just find the
    % unique pngs for whatever choice you've selected.
    
    % you can get rid of the species here - since you want to look at them
    % in sequential order, not all yeses for one species, then all yeses
    % for the next.
    RRindx = Rindx(:, 1:2);
    R = sortrows(RRindx,[2,1]);
    
    
    % so get unique png/day pairs here:
    URpngdays = unique(R,'rows','stable');
    
    Rm = URpngdays(:,2);
    Rn = URpngdays(:,1);
    
    
    % but then you need to make sure to ignore any of the 99's not associated
    % with a fileMTX file.. (i.e. that the 99 was a placeholder)
    
    for pp = 1:size(fileMTX,2);
        szfiles(pp) = size(fileMTX{pp},1);
    end
    
    uRm = unique(Rm,'stable');
    elim = [];
    for inz = 1:size(uRm,1);
        fuRm = find(Rm == uRm(inz));
        allRn = Rn(fuRm);
        fallRn = find(allRn > szfiles(uRm(inz)));
        if isempty(fallRn);
            % great, all are okay
        else
            % need to eliminate these ones from the list
            elim = [elim; Rm(fuRm(fallRn)) allRn(fallRn)];
        end
    end
    if isempty(elim) == 0;
        newRs = setdiff([Rm Rn], elim,'rows');
        Rm = newRs(:,1);
        Rn = newRs(:,2);
    else
        % no changes to Rm or Rn
    end
    dirx = 1;
    % then get the dates/times associated with these unique pairs
    for u = 1:size(Rm,1);
        FilesDateNum(u,:) = ...
            datenum(fileMTX{Rm(u)}(Rn(u), ...
            dashes(2)+1:dashes(4)-1),'yymmdd-HHMMSS');
    end
    
    set(butt.review,'UserData',[choices choices choices; m n dirx; ...
        [Rm Rn FilesDateNum]]);
    
    %currfile is the file you were on when you hit 'review mode'
    %spoint is the date/time you entered in the popup window
    
    findDay = datenum([char(spoint(1,:)) char(spoint(2,:))], ...
        'yymmddHHMMSS');
    
    % then find the closest prior segment
    % that has been reviewed
    
    reviewCntr = max(find(FilesDateNum <= findDay));% this is the closest time <= the one you
    %entered in the popup window
    if isempty(reviewCntr)
        reviewCntr = 1; % then start from the very first date/time
    end
    
    
    n = Rn(reviewCntr);
    m = Rm(reviewCntr);
    [n,m,currentContrast] = pngPLOT(fileMTX,PngFolder,n,...
        m,currentContrast);
    for o = 1:size(handleMTX,1);
        if  resltMTX(n,m,o) == 99;
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));  % No is selection
        else
            if resltMTX(n,m,o) ~=0;
                set(eval(['butt.objgrp' num2str(o)]), ...
                    'SelectedObject',handleMTX(o, ...
                    resltMTX(n,m,o)));
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));
            end
        end
    end
    
    for bn = 5:6;
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','on');
    end
    set(butt.change,'visible','on');
    strtRevCntr = reviewCntr;
    dispRevCntr = 0;   % start from 0 here - you haven't reviewed one until you've gone forward one.
    
    butt.obj20 = uicontrol('Parent',f1,'Style','Text', ...
        'String', num2str(dispRevCntr),'backgroundcolor',[1 1 1], ...  % dispRevCntr here is 1 because it starts with first one.
        'Units','normalized','Position',[.05 .92 .05 .025]);
    set(f2,'WindowKeyPressFcn',{@keytry2,butt,PngFolder,WaveFolder,fileMTX,n,m,currentContrast,...
        PNGrslts_MetaData,pngCounter,f1,resltMTX,whoMTX,CheckNum,ResultsFolder,Recorder,handleMTX,WhoRan,f2,Sounds,reviewCntr,strtRevCntr});
    set(f1,'WindowKeyPressFcn',{@keytry2,butt,PngFolder,WaveFolder,fileMTX,n,m,currentContrast,...
        PNGrslts_MetaData,pngCounter,f1,resltMTX,whoMTX,CheckNum,ResultsFolder,Recorder,handleMTX,WhoRan,f2,Sounds,reviewCntr,strtRevCntr});
  
elseif get(butt.review,'Value') == 0;  %OFF
    
    set(butt.review,'BackgroundColor',[0.941176 0.941176 0.941176]);
    % and now go back to currfile:
    for bn = [1 2];
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','on');
    end
    for bn = 5:6;
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','off');
    end
    set(butt.change,'visible','off');
    
    nm = get(butt.review,'UserData');
    n = nm(2,2);   % these set the n and m back to the place you left off
    m = nm(2,1);    % before the review started.
    
    [n,m] = pngPLOT(fileMTX,PngFolder,n,m,currentContrast);
    for o = 1:size(handleMTX,1);
        %find what original selection is and set buttons
        if  resltMTX(n,m,o) == 99;
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));  % No is selection
        else
            if resltMTX(n,m,o) ~=0;
                set(eval(['butt.objgrp' num2str(o)]), ...
                    'SelectedObject',handleMTX(o,resltMTX(n,m,o)));
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));
            end
        end
    end
    Getvars = get(f2,'WindowKeyPressFcn');
    resltMTX = Getvars{12};
    whoMTX = Getvars{13};
    currentContrast = Getvars{8};
    butt = Getvars{2};
    set(butt.review,'Value',0);
     set(butt.hold,'Visible','on');
    set(butt.obj20,'String','0');
    reviewCntr = 0;
    strtRevCntr = 0;
      Getvars{21} = reviewCntr;
    Getvars{2} = butt;
    Getvars{8} = currentContrast;
    Getvars{6} = n;
    Getvars{7} = m;
    set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
    set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
  
end
