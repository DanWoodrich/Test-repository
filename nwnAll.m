
function [butt] = nwnAll(handleMTX,butt)
%nwnAll.m
%v3.0 12/28/12 - multiple species review now
% when this button is pushed it automatically selects NWN for all species
% on the list.

for o = 1:size(handleMTX,1);
set(eval(['butt.objgrp' num2str(o)]), ...
    'SelectedObject',eval(['butt.objNwn' num2str(o)]));  % No is selection
set(eval(['butt.objNo' num2str(o)]), ...
    'BackgroundColor',[0.941176 0.941176 0.941176]);
end