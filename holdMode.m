function [resltMTX, butt, handleMTX, n,m] = holdMode(butt,resltMTX,handleMTX,n,m);

% allows choices to be continued to next png.

 if get(butt.hold,'Value') == 1;
%      'it is on'
     set(butt.hold,'BackgroundColor',[0 0 1]);
 elseif get(butt.hold,'Value') == 0
%      'it is off'
      set(butt.hold,'BackgroundColor',[0.941176 0.941176 0.941176]);
 end
     
     