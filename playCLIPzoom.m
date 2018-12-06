function playCLIPzoom(butt,PngFolder,filT,soundclip,wavtimeMIN,wavtimeMAX,fs,yHzmn,yHzmx)

%v3.0 12/28/12 - multiple species review now
% v2.2 3/6/12 - changed to work on 2 row pngs
% v2.1 2/23/12 - changed to go across rows and to select in between rows.
% Also filters sound based on selected frequency limits if selected.

% v2.0 12/29/11 Changed so selection can spill into margins to get min/max
% frequency range.

% v1.2  5/9/11
X = 1;





% apply filters where needed.

 if filT == 1;

     N = 800;
     b = fir1(N, [max(yHzmn,1) yHzmx]/(fs/2),'DC-0');
     soundclip1 = fftfilt(b,soundclip);
 else
     soundclip1 = soundclip;
 end
soundsc(soundclip1,fs*X)
cd(PngFolder)
      