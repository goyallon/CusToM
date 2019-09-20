function [Markers]=Marker_set6(varargin)
% Definition of the markers set used in the IRSST
%
%   INPUT
%   - nb_markers_hand: number of markers used on each hand
%   OUTPUT
%   - Markers: set of markers (see the Documentation for the structure) 

s=cell(0);

% Trunk
s=[s;{'STRN' 'STRN' {'Off';'On';'Off'}; ...
    'Manubrium' 'CLAV' {'Off';'On';'Off'};...
%     'T12_C' 'T12' {'Off';'On';'Off'};...
    'L5' 'Pelvis_L5JointNode' {'Off';'Off';'Off'};...
    'C7' 'C7' {'Off';'On';'Off'};...
%     'EAV_D' 'REAV' {'On';'Off';'On'};...
%     'EAV_G' 'LEAV' {'On';'Off';'On'};...
    'EAR_D' 'REAR' {'Off';'Off';'On'};...
    'EAR_G' 'LEAR' {'Off';'Off';'On'};...
    'EIASD' 'RFWT' {'Off';'Off';'On'};...
    'EIASG' 'LFWT' {'Off';'Off';'On'};...
    'EIPSD' 'RBWT' {'Off';'Off';'On'};...
    'EIPSG' 'LBWT' {'Off';'Off';'On'};...
    'NEZ' 'NEZ' {'Off';'Off';'Off'};...
%     'NUQUE' 'NUQUE' {'On';'On';'Off'};...
    'VERTEX' 'VERTEX' {'Off';'On';'On'};...
    'T8' 'T8' {'Off';'On';'Off'};...
}];

Side={'R';'L'};
Side2={'D';'G'};
% Leg
for i=1:2
    Signe=Side{i};
    Signe2=Side2{i};
    s=[s;{...
        [Signe 'KNE'] [Signe 'KNE'] {'Off';'Off';'Off'};...
        [Signe 'ANE'] [Signe 'ANE'] {'Off';'On';'Off'};...
        [Signe 'ANI'] [Signe 'ANI'] {'Off';'Off';'Off'};...
        [Signe 'KNI'] [Signe 'KNI'] {'Off';'On';'On'};...
%         ['TAL' Signe2 'A'] [Signe 'HEE'] {'Off';'On';'Off'};...
%         ['PIEX' Signe2] [Signe 'TAR'] {'Off';'On';'On'};...
        ['BP__' Signe2] [Signe 'TOE'] {'Off';'On';'Off'};...
%         ['PIIN' Signe2] [Signe 'TARI'] {'Off';'On';'On'};...
        }]; %#ok<AGROW>
end


% Arm
for i=1:2
    Signe=Side{i};
    Signe2=Side2{i};
    s=[s;{...
        ['EPI_' Signe2] [Signe 'HUM'] {'Off';'Off';'Off'};...
        ['EPE_' Signe2] [Signe 'RAD'] {'On';'On';'Off'};...
        ['PEX_' Signe2] [Signe 'WRA'] {'Off';'Off';'Off'};...
        ['PIN_' Signe2] [Signe 'WRB'] {'Off';'On';'Off'};...
        ['MC2' Signe2] [Signe 'CAR2'] {'Off';'Off';'Off'};...
        ['MC5' Signe2] [Signe 'OHAND'] {'Off';'Off';'Off'}}]; %#ok<AGROW>       
end

Markers=struct('name',{s{:,1}}','anat_position',{s{:,2}}','calib_dir',{s{:,3}}'); %#ok<CCAT1>

end