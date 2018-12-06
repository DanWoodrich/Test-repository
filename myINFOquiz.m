%myINFOquiz.m

% This code let's you enter all your path/folder information once so you
% don't have to update it each time I make a new soundchecker version.

% 2/16/12 CLB
%v3.0 12/28/12 - multiple species review now
p = pathdef;
f = strfind(p,';');
defaultpath = p(1:f(1)-1);



    cd(defaultpath)
    


whereAnalysis = [uigetdir('Z:\','Where is the Quiz ANALYSIS folder?')];
wherePngs = [uigetdir('Z:\','Where are the Quiz PNG folders?')];
whereWavs = [uigetdir('Z:\','Where are the Quiz WAVE folders?')];
whereExamples = [uigetdir('Z:\','Where is the Quiz EXAMPLES folder?')];
save([cd '\MyQuizFolderSettings'],'where*');





