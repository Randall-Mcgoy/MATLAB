%% Instruction for using this software
% Place all the raw scan data in a folder and press the run button in the software. Choose the folder in which the raw scan data is palced. 
% The answers are stored in final_mat where 
        % Col 1 is Serial Number of transducer
        % Col 2 is Uniformity time
        % Col 3 is uniformity ratio
% Note: The raw scan data can be only in the following format where XXXX are numbers only. 'TXR XXXX RMXXX R24.txt'

%% To choose the folder containing raw scan data 

function data = SW0018_Uniformity_Calculator(load_img)

folder= uigetdir();

load_img.Visible = 'on';
drawnow;

%if nothing selected, then exit function 
if (strcmp (class(folder),'double'))
    data = zeros(1,3); data(:) = -1;
    return;  
end

info=dir(folder);
j=1;
k=1;
tk=1;
scanr=1.2;
for i=3:length(info)
    if length(info(i).name)==24
        tR24(k,:)=info(i).name;
        k=k+1;
    
    elseif length(info(i).name)==22
        R24(tk,:)=info(i).name;
        tk=tk+1;
        
    end
end
%% To import data from the chosen text file
if tk>1
for i=1:size(R24,1)
    data=importdata(strcat(folder,'\',R24(i,:)));
    mat_data=data.data;
    angle=reshape(mat_data(:,1),81,[]);
    axial_distance=reshape(mat_data(:,2),81,[]);
    vrms=reshape(mat_data(:,3),81,[]);
    UR24(i,1)=str2num(strcat(R24(i,5),R24(i,6),R24(i,7),R24(i,8)));
    [UR24(i,2),UR24(i,3)]=unitime(vrms,scanr);
end
end

if k>1
for i=1:size(tR24,1)
    data=importdata(strcat(folder,'\',tR24(i,:)));
    mat_data=data.data;
    angle=reshape(mat_data(:,1),81,[]);
    axial_distance=reshape(mat_data(:,2),81,[]);
    vrms=reshape(mat_data(:,3),81,[]);
    tUR24(i,1)=str2num(strcat(tR24(i,7),tR24(i,8),tR24(i,9),tR24(i,10)));
    [tUR24(i,2),tUR24(i,3)]=unitime(vrms,scanr);
end
end
if tk>1&&k>1
    final_mat=vertcat(UR24,tUR24);
    
elseif k>1
    final_mat=tUR24;
else
    final_mat=UR24;
end

clearvars -except final_mat

data = final_mat;
%% Function to calculate uniformity time and uniformity ratio
function [Time,ratio] = unitime(vrms,scanr)
clear Time;
clear ratio;
[m,n]=size(vrms); 
az=linspace(0,2*pi,m);              % Azimuthal values for polar plot
dax=0.0001;                         % Axial step size (m)
ti=(vrms.^2)./max(max(vrms.^2));    % Normalized intensity (vrms^2/max[vrms^2])
mti=mean(ti)./max(mean(ti));        % Normalized mean intensity
mti_sav=mti;                        % Save mean intensity before smoothing
b=ones(1,3)/3;                      % Smoothing filter coefficients
mti=filtfilt(b,1,mti);              % Smoothed mean intensity
mti=mti./max(mti);                  % Normalize smoothed mean intensity

min_index=find(mti==min(mti),1,'first');
max_index=find(mti==max(mti),1,'first');
ratio = mti(min_index)/mti(max_index);

% Ratio=num2str(mti(min_index)/mti(max_index))
% int_ratio=strcat(Ratio(1),Ratio(2),Ratio(3),Ratio(4));
% format short
% ratio=str2num(int_ratio);

Step=2*pi*scanr*10/360;             % Azimuthal step size
area=Step*dax;                      % Cross-sectional area (m^2)
Intensity =  1e7;                   % Arbitrary intensity value
Frequency = 9e6;                    % Approximate frequency (Hz)
Media.c = 150000;
Media.dens =  1;
Media.Attenuation1 =  0.13;
Media.att_q =  1.05;
Media.Attenuation=Media.Attenuation1*(Frequency/1e6)^Media.att_q;
Media.Absorption1 =  0.23;
Media.abs_q =  1.05;
Media.Absorption=Media.Absorption1*(Frequency/1e6)^Media.abs_q;
Media.specheat =  3.5e7;
Media.blood_specheat =  3.5e7;
Media.thermcond =  5e4;
Media.blood_perfrate =  13e-3;

AmbientTemp = 36.6;                                 % Ambient temp (degC)
InitialTemp  = AmbientTemp;
Diff = Media.thermcond/Media.dens/Media.specheat;
Perf = Media.blood_perfrate*Media.blood_specheat/Media.dens/Media.specheat;
T = InitialTemp.*ones(size(mti'))-AmbientTemp; 
Q   = Media.Absorption.*(Intensity*mti')/Media.dens/Media.specheat;

tic;
SimulationTime = 3000;              % Max simulation time
dTime = 0.025;                      % Time step [sec]
Dose=T*0; cnt=1; clear SimStat;
T43=43*ones(size(az));

% Main Simulation Time Loop
for Time=0:dTime:SimulationTime 
    mexSingleStepBHTE_1D(T,Diff,Perf,Q,Step,dTime,1);    % Run BHTE calc
    Dose = Dose + 2.^(T+AmbientTemp-43)*dTime;           % Calc T43
    if min(Dose)>7200 % If T43>7200sec, stop sim and display time
        unistr=strcat('Uniformity time = ',num2str(Time),' sec');
        %disp('hi')
        break;
    end   
end


end

end %end SW0018_Uniformity_Calculator

        