%myINFO.m

% This code let's you enter all your path/folder information once so you
% don't have to update it each time I make a new soundchecker version.

% 2/16/12 CLB
%v3.0 12/28/12 - multiple species review now
p = pathdef;
f = strfind(p,';');
defaultpath = p(1:f(1)-1);



    cd(defaultpath)
    


whereAnalysis = [uigetdir('C:\','Where is the ANALYSIS folder?')];
wherePngs = [uigetdir('C:\','Where are your PNG folders?')];
whereWavs = [uigetdir('C:\','Where are your WAVE folders?')];
whereExamples = [uigetdir('C:\','Where is your example folder?')];
save([cd '\MyFolderSettings'],'where*');





