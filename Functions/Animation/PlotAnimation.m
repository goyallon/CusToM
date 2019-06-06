function [varargout] = PlotAnimation(ModelParameters, AnimateParameters)
% Generation of an animation
%
%   INPUT
%   - ModelParameters: parameters of the musculoskeletal model,
%   automatically generated by the graphic interface 'GenerateParameters' 
%   - AnimateParameters: parameters of the animation, automatically
%   generated by the graphic interface 'GenerateAnimate'
%________________________________________________________
%
% Licence
% Toolbox distributed under 3-Clause BSD License
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

DataXSens = 0;
if isequal(AnimateParameters.Mode, 'GenerateParameters')
    [Human_model, Markers_set, Muscles, EnableModel] = ModelGeneration(ModelParameters);
    [Human_model] = Add6dof(Human_model);
    [Markers_set]=VerifMarkersOnModel(Human_model,Markers_set);
    q6dof = [0 0 0 0 -110*pi/180 0]'; % rotation for visual
    q = zeros(numel(Human_model)-6,1);
else
    load('AnalysisParameters.mat'); %#ok<LOAD>
    num_ext = numel(AnalysisParameters.General.Extension)-1;
    % Filename
    filename = AnimateParameters.filename(1:end-num_ext);
    % Files loading
    load('BiomechanicalModel.mat'); %#ok<LOAD>
    Human_model = BiomechanicalModel.OsteoArticularModel;
    load([filename '/InverseKinematicsResults.mat']); %#ok<LOAD>
    q = InverseKinematicsResults.JointCoordinates;
    load([filename '/ExperimentalData.mat']); %#ok<LOAD>
    if isfield(InverseKinematicsResults,'FreeJointCoordinates')
        q6dof = InverseKinematicsResults.FreeJointCoordinates;
        Markers_set = BiomechanicalModel.Markers;
        Muscles = BiomechanicalModel.Muscles;
        real_markers = ExperimentalData.MarkerPositions;
    else
        DataXSens = 1;
        PelvisPosition = InverseKinematicsResults.PelvisPosition;
        PelvisOrientation = InverseKinematicsResults.PelvisOrientation;
    end
end

% AnimateParameters
if isfield(AnimateParameters, 'seg_anim')
    seg_anim = AnimateParameters.seg_anim;
else
    seg_anim = 0;
end
if isfield(AnimateParameters, 'bone_anim')
    bone_anim = AnimateParameters.bone_anim;
else
    bone_anim = 0;
end
if isfield(AnimateParameters, 'mass_centers_anim')
    mass_centers_anim = AnimateParameters.mass_centers_anim;
else
    mass_centers_anim = 0;
end
if isfield(AnimateParameters, 'Global_mass_center_anim')
    Global_mass_center_anim = AnimateParameters.Global_mass_center_anim;
else
    Global_mass_center_anim = 0;
end
if isfield(AnimateParameters, 'muscles_anim')
    muscles_anim = AnimateParameters.muscles_anim;
else
    muscles_anim = 0;
end
if isfield(AnimateParameters, 'mod_marker_anim')
    mod_marker_anim = AnimateParameters.mod_marker_anim;
else
    mod_marker_anim = 0;
end
if isfield(AnimateParameters, 'exp_marker_anim')
    exp_marker_anim = AnimateParameters.exp_marker_anim;
else
    exp_marker_anim = 0;
end
if isfield(AnimateParameters, 'external_forces_anim')
    external_forces_anim = AnimateParameters.external_forces_anim;
else
    external_forces_anim = 0;
end
if isfield(AnimateParameters, 'external_forces_pred')
    external_forces_p = AnimateParameters.external_forces_pred;
else
    external_forces_p = 0;
end
if isfield(AnimateParameters, 'forceplate')
    forceplate = AnimateParameters.forceplate;
else
    forceplate = 0;
end
if isfield(AnimateParameters, 'BoS')
    BoS = AnimateParameters.BoS;
else
    BoS = 0;
end

% exclude non used markers
if ~DataXSens
    Markers_set=Markers_set(find([Markers_set.exist])); %#ok<FNDSB>
end

% Preliminary computations
if seg_anim && ~DataXSens %anatomical position where other segments are attached
    [Human_model] = anat_position_solid_repere(Human_model,find(~[Human_model.mother]));
end
if bone_anim
    if ~DataXSens
        % scaling factors.
        if isfield(BiomechanicalModel.GeometricalCalibration,'k_calib') && ~isfield(BiomechanicalModel.GeometricalCalibration,'k_markers')
            k_calib = BiomechanicalModel.GeometricalCalibration.k_calib;
            k = (ModelParameters.Size/1.80)*k_calib;
        else
            k = repmat((ModelParameters.Size/1.80),[numel(Human_model),1]);
        end
        bonespath=which('ModelGeneration.m');
        bonespath = fileparts(bonespath);
        for ii=find([Human_model.Visual])
            %TLEM or not.
            if isfield(Human_model,'Geometry') && ~isempty(Human_model(ii).Geometry)
                bonepath=fullfile(bonespath,['Geometries_' Human_model(ii).Geometry]);
            else
                bonepath=fullfile(bonespath,'Geometries');
            end
            try
                load(fullfile(bonepath, Human_model(ii).name)) %#ok<LOAD>
                nb_faces=4000;
                if length(t)>nb_faces
                    bone.faces=t;
                    bone.vertices=p;

                    bone_red=reducepatch(bone,nb_faces);
                    Human_model(ii).V=1.2063*k(ii)*bone_red.vertices;
                    Human_model(ii).F=bone_red.faces;
                else
                    Human_model(ii).V=k(ii)*p;
                    Human_model(ii).F=t;
                end
            catch
                error(['3D Mesh not found of ' Human_model(ii).name]);
            end
        end
    else
        for ii=find([Human_model.Visual])
            load(['Visual/' Human_model(ii).name]); %#ok<LOAD>
            Human_model(ii).V = p;
            Human_model(ii).F=t;
        end
    end
end
if mod_marker_anim || exp_marker_anim || mass_centers_anim
    if mod_marker_anim || exp_marker_anim
        nb_set= mod_marker_anim + exp_marker_anim;
        % Creating a mesh with all the marker to do only one gpatch
        nbmk=numel(Markers_set);
        fmk=1:1:nbmk*nb_set;
        C_mk = zeros(nbmk*nb_set,3); % RGB;
        if mod_marker_anim && ~exp_marker_anim
            C_mk(1:nbmk,:)=repmat([255 102 0]/255,[nbmk 1]);
        elseif ~mod_marker_anim && exp_marker_anim
            C_mk(1:nbmk,:)=repmat([0 153 255]/255,[nbmk 1]);
        elseif mod_marker_anim && exp_marker_anim
            C_mk(1:nbmk,:)=repmat([255 102 0]/255,[nbmk 1]);
            C_mk(nbmk+1:nbmk*nb_set,:)=repmat([0 153 255]/255,[nbmk 1]);
        end
    end
    if mass_centers_anim
        num_s_mass_center=find([Human_model.Visual]);
        nb_ms = length(num_s_mass_center);
        C_ms(1:nb_ms,:)=repmat([34,139,34]/255,[nb_ms 1]);
    end
end
if muscles_anim
    color0 = [0.9 0.9 0.9];
    color1 = [1 0 0];
    if isequal(AnimateParameters.Mode, 'GenerateParameters')
        Aopt = ones(numel(Muscles),1);
    else
        load([filename '/MuscleForcesComputationResults.mat']); %#ok<LOAD>
        Aopt = MuscleForcesComputationResults.MuscleActivations;
    end
end
if external_forces_anim
    load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
    if ~isfield(ExternalForcesComputationResults,'ExternalForcesExperiments')
        error('External Forces from the Experiments have not been computed on this trial')
    end
    external_forces = ExternalForcesComputationResults.ExternalForcesExperiments;
    color_vect_force = [53 210 55]/255;
end
if external_forces_p
    color_vect_force_p = 1-([53 210 55]/255);
    load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
    if ~isfield(ExternalForcesComputationResults,'ExternalForcesPrediction')
        error('ExternalForcesPrediction have not been computed on this trial')
    end
    external_forces_pred = ExternalForcesComputationResults.ExternalForcesPrediction;
end
if external_forces_anim || external_forces_p  %vector normalization
    lmax_vector_visual = 1; % longueur max du vecteur (en m)
    coef_f_visual=(ModelParameters.Mass*9.81)/lmax_vector_visual;
end
if forceplate
    h = btkReadAcquisition([filename '.c3d']);
    ForceplatesData = btkGetForcePlatforms(h);
end

% Figure
if isequal(AnimateParameters.Mode, 'Figure') ...
        || isequal(AnimateParameters.Mode, 'Picture')
    fig=figure('outerposition',[483,60,456*1.5,466*1.5]);
elseif isequal(AnimateParameters.Mode, 'cFigure')
    fig=cFigure; % from GIBBON
    view(3); axis equal; axis tight; axis vis3d; grid on; box on;
    camlight headlight; axis off; axis manual;
    ax=gca;
    ax.Clipping = 'off';
    drawnow;
elseif isequal(AnimateParameters.Mode, 'GenerateAnimate') || isequal(AnimateParameters.Mode, 'GenerateParameters')
    ax = AnimateParameters.ax;
    camlight(ax, 'headlight');
%     material(ax, 'metal');
end

% Frames to display
if isequal(AnimateParameters.Mode, 'Picture') ...
        || isequal(AnimateParameters.Mode, 'GenerateAnimate') ...
        || isequal(AnimateParameters.Mode, 'GenerateParameters')
    f_affich = AnimateParameters.PictureFrame;
else
    f_affich = 1:5:size(q,2);
end

%Initialization animStruct
animStruct=struct();
if ~isequal(AnimateParameters.Mode, 'GenerateParameters')
    animStruct.Time=ExperimentalData.Time;
end

animStruct.Handles=cell(1,size(q,2));
animStruct.Props=cell(1,size(q,2));
animStruct.Set=cell(1,size(q,2));

%% Animation frame by frame
cpt = 0; % counter of number of frames to in video
for f=f_affich
    cpt = cpt + 1;

    if isequal(AnimateParameters.Mode, 'Figure') || isequal(AnimateParameters.Mode, 'Picture')
        clf  % just for figure
        ax = gca;
        axis equal
        set(ax,'visible','off')
        camlight(ax, 'headlight');
        xlim(AnimateParameters.xlim);
        ylim(AnimateParameters.ylim);
        zlim(AnimateParameters.zlim);
        view(AnimateParameters.view);
    end
    
    %Initialization animStruct
    animStruct.Handles{f}=[];
    animStruct.Props{f}={};
    animStruct.Set{f}={};
    if ~isequal(AnimateParameters.Mode, 'GenerateAnimate') && ~isequal(AnimateParameters.Mode, 'GenerateParameters')
        hold on
    end
    
    %% forward kinematics
    if DataXSens
        qf = q(:,f);
        Human_model(1).p = PelvisPosition{f};
        Human_model(1).R = PelvisOrientation{f};
        [Human_model_bis] = ForwardKinematicsAnimation8XSens(Human_model,qf,1);
    else
        qf(1,:)=q6dof(6,f);
        qf(2:size(q,1),:)=q(2:end,f);
        qf((size(q,1)+2):(size(q,1)+6),:)=q6dof(1:5,f);
        [Human_model_bis,Muscles_test, Markers_set_test]=...
            ForwardKinematicsAnimation8(Human_model,Markers_set,Muscles,qf,find(~[Human_model.mother]),...
            seg_anim,muscles_anim,mod_marker_anim);
    end
   
    %% Segments
    if seg_anim
        V_seg=[];
        F_seg=[];
        for j=find([Human_model_bis.Visual])
            pts = Human_model_bis(j).pos_pts_anim';
            if size(pts,1)>1
                F_seg =[F_seg; nchoosek(1:size(pts,1),2)+length(V_seg)]; %#ok<AGROW> %need to be done before V_seg !
            else
                F_seg =[F_seg; length(V_seg) length(V_seg)+1]; %#ok<AGROW> %need to be done before V_seg !
            end
            V_seg = [V_seg; pts];  %#ok<AGROW>
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
            h_seg = gpatch(ax,F_seg,V_seg,[],0.4*[1 1 1],1,4);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} h_seg];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'}; %#ok<*CCAT>
        animStruct.Set{f} = {animStruct.Set{f}{:},V_seg};
    end

    %% Bones
    if bone_anim % To do % to concatenate bones;
        X=[];
        Fbones=[];
        jj=find([Human_model_bis.Visual]);
        for j=1:length(jj)
            jjj=jj(j);
            cur_nb_V=length(Human_model_bis(jjj).V);
            cur_nb_F=length(Human_model_bis(jjj).F);
            tot_nb_F=length(Fbones);
            tot_nb_V=length(X);
            Fbones((1:cur_nb_F)+tot_nb_F,:)=Human_model_bis(jjj).F+tot_nb_V; %#ok<AGROW>
            onearray = ones([1,cur_nb_V]);
            if isempty(Human_model_bis(jjj).V)
                temp=[];
            else
                temp=(Human_model_bis(jjj).Tc_R0_Ri*...
                    [Human_model_bis(jjj).V';onearray ])';
            end
            X = [ X ;...
                temp]; %#ok<AGROW>
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
            hc = gpatch(ax,Fbones,X(:,1:3),[227 218 201]/255*0.9,'none');
        end
        animStruct.Handles{f}=[animStruct.Handles{f} hc];
        animStruct.Props{f}={ animStruct.Props{f}{:}, 'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},X(:,1:3)};
    end
    
    %% Markers
    % Mod�le
    if mod_marker_anim || exp_marker_anim
        Vsmk=[];
        if mod_marker_anim %% Markers on the model
            for i_m = 1:numel(Markers_set_test)
                cur_Vs=Markers_set_test(i_m).pos_anim';
                Vsmk=[Vsmk;cur_Vs]; %#ok<AGROW>
            end
        end
        % XP
        if exp_marker_anim %% Experimental markers
            for i_m = 1:numel(Markers_set_test)
                cur_Vs=real_markers(i_m).position(f,:);
                Vsmk=[Vsmk;cur_Vs]; %#ok<AGROW>
            end
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
            m = patch(ax,'Faces',fmk,'Vertices',Vsmk,'FaceColor','none','FaceVertexCData',C_mk,'EdgeColor','none');
            m.Marker='o';
            m.MarkerFaceColor='flat';
            m.MarkerEdgeColor='k';
            m.MarkerSize=6;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} m];
        animStruct.Props{f}={ animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},Vsmk};
    end
    
    %% Mass Centers
    if mass_centers_anim
        Vsms=[];
        for j=num_s_mass_center
            X = (Human_model_bis(j).Tc_R0_Ri(1:3,4))';
            Vsms=[Vsms;X]; %#ok<AGROW>
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
            hmass = patch(ax,'Faces',1:nb_ms,'Vertices',Vsms,'FaceColor','none','FaceVertexCData',C_ms,'EdgeColor','none');
            hmass.Marker='o';
            hmass.MarkerFaceColor='flat';
            hmass.MarkerEdgeColor='k';
            hmass.MarkerSize=6;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} hmass];
        animStruct.Props{f}={animStruct.Props{f}{:}, 'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},Vsms};
    end
    
    %% Global Mass Centers
    if Global_mass_center_anim
        CoM = CalcCoM(Human_model_bis);
        X = CoM';
        if f==f_affich(1) ||isequal(AnimateParameters.Mode, 'Figure')
            hGmass=patch(ax,'Faces',1,'Vertices',X,'FaceColor','none','FaceVertexCData',[34,139,34]/255,'EdgeColor','none');
            hGmass.Marker='o';
            hGmass.MarkerFaceColor='flat';
            hGmass.MarkerEdgeColor='k';
            hGmass.MarkerSize=10;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} hGmass];
        animStruct.Props{f}={animStruct.Props{f}{:}, 'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},X};
    end
    
    %% Muscles
    if muscles_anim && numel(Muscles)
        Fmu=[];
        CEmu=[];
        Vmu=[];
        color_mus = color0 + Aopt(:,f)*(color1 - color0);
        ind_mu=find([Muscles_test.exist]==1);
        for i_mu = 1:numel(ind_mu)
            mu=ind_mu(i_mu);
            pts_mu = Muscles_test(mu).pos_pts';
            nbpts_mu = size(pts_mu,1);
            cur_Fmu = repmat([1 2],[nbpts_mu-1 1])+(0:nbpts_mu-2)'+size(Vmu,1);
            Fmu =[Fmu; cur_Fmu]; %#ok<AGROW>
            Vmu=[Vmu ;pts_mu]; %#ok<AGROW>
            CEmu=[CEmu; repmat(color_mus(mu,:),[nbpts_mu 1])]; %#ok<AGROW>
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
            hmu=gpatch(ax,Fmu,Vmu,[],CEmu,1,2);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} hmu hmu];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices','FaceVertexCData'};
        animStruct.Set{f} = {animStruct.Set{f}{:},Vmu,CEmu};
    end
    
    %% Vectors of external forces issued from experimental data
    if external_forces_anim
        extern_forces_f = external_forces(f).Visual;
        F_ef=[];V_ef=[];
        for i_for=1:size(extern_forces_f,2)
%             if norm(extern_forces_f(4:6,i_for)) > 20
%                 % Arrows
%                 X_array=[extern_forces_f(1,i_for),...
%                     extern_forces_f(4,i_for)/coef_f_visual];
%                 Y_array=[extern_forces_f(2,i_for),...
%                     extern_forces_f(5,i_for)/coef_f_visual];
%                 Z_array=[extern_forces_f(3,i_for),...
%                     extern_forces_f(6,i_for)/coef_f_visual];
%                 [F,V]=quiver3Dpatch(X_array(1),Y_array(1),Z_array(1),...
%                     X_array(2),Y_array(2),Z_array(2),[],[]);
%                 F_ef=[F_ef;F+size(V_ef,1)]; V_ef=[V_ef;V];  %#ok<AGROW>
                % Lines
                X_array=[extern_forces_f(1,i_for),...
                    extern_forces_f(1,i_for) + extern_forces_f(4,i_for)/coef_f_visual];
                Y_array=[extern_forces_f(2,i_for),...
                    extern_forces_f(2,i_for) + extern_forces_f(5,i_for)/coef_f_visual];
                Z_array=[extern_forces_f(3,i_for),...
                    extern_forces_f(3,i_for) + extern_forces_f(6,i_for)/coef_f_visual];
                F_ef = [F_ef; [1 2]+size(V_ef,1)]; %#ok<AGROW>
                V_ef = [V_ef; [X_array' Y_array' Z_array']]; %#ok<AGROW>
%             end
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
%             % Arrows
%             Ext=gpatch(ax,F_ef,V_ef,color_vect_force,color_vect_force,0.5);
            % Lines
            Ext = gpatch(ax,F_ef,V_ef,[],color_vect_force,1,4);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} Ext];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f} = {animStruct.Set{f}{:},V_ef};
    end
    
    %% Vectors of external forces issued from prediction
    if external_forces_p
        extern_forces_f = external_forces_pred(f).Visual;
        F_efp=[];V_efp=[];
        for i_for=1:size(extern_forces_f,2)
%             if norm(extern_forces_f(4:6,i_for)) > 20
%                 % Arrows
%                 X_array=[extern_forces_f(1,i_for),...
%                     extern_forces_f(4,i_for)/coef_f_visual];
%                 Y_array=[extern_forces_f(2,i_for),...
%                     extern_forces_f(5,i_for)/coef_f_visual];
%                 Z_array=[extern_forces_f(3,i_for),...
%                     extern_forces_f(6,i_for)/coef_f_visual];
%                 [F,V]=quiver3Dpatch(X_array(1),Y_array(1),Z_array(1),...
%                     X_array(2),Y_array(2),Z_array(2),[],[]);
%                 F_efp=[F_efp;F+size(V_efp,1)]; V_efp=[V_efp;V]; %#ok<AGROW>
                % Lines
                X_array=[extern_forces_f(1,i_for),...
                    extern_forces_f(1,i_for) + extern_forces_f(4,i_for)/coef_f_visual];
                Y_array=[extern_forces_f(2,i_for),...
                    extern_forces_f(2,i_for) + extern_forces_f(5,i_for)/coef_f_visual];
                Z_array=[extern_forces_f(3,i_for),...
                    extern_forces_f(3,i_for) + extern_forces_f(6,i_for)/coef_f_visual];
                F_efp = [F_efp; [1 2]+size(V_efp,1)]; %#ok<AGROW>
                V_efp = [V_efp; [X_array' Y_array' Z_array']]; %#ok<AGROW>
%             end
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
%             % Arrows
%             Extp=gpatch(ax,F_efp,V_efp,color_vect_force_p,color_vect_force_p,0.5);
            % Lines
            Extp = gpatch(ax,F_efp,V_efp,[],color_vect_force_p,1,4);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} Extp];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f} = {animStruct.Set{f}{:},V_efp};
    end
    
    %% Display force plates position
    if forceplate
        x_fp = []; y_fp = []; z_fp = [];
        for i=1:numel(ForceplatesData)
            if ~isequal(AnalysisParameters.ExternalForces.Options{i}, 'NoContact')
                x_fp = [x_fp ForceplatesData(i).corners(1,:)'/1000]; %#ok<AGROW> % mm -> m
                y_fp = [y_fp ForceplatesData(i).corners(2,:)'/1000]; %#ok<AGROW> % mm -> m
                z_fp = [z_fp ForceplatesData(i).corners(3,:)'/1000]; %#ok<AGROW> % mm -> m
            end
        end
        patch(ax,x_fp,y_fp,z_fp,[.9 .9 .9]);
    end
    
    %% Base of support
    if BoS
        if numel(InverseKinematicsResults.BoS{1,f})
            x_bos = InverseKinematicsResults.BoS{1,f}(1,:);
            y_bos = InverseKinematicsResults.BoS{1,f}(2,:);
            z_bos = InverseKinematicsResults.BoS{1,f}(3,:);
            patch(ax,x_bos,y_bos,z_bos,[1 .4 0]);
        end
    end

    %% Save figure
    if isequal(AnimateParameters.Mode, 'Figure')
        % drawing an saving
        drawnow
        M(cpt) = getframe(fig); %#ok<AGROW>
    end
    
    if isequal(AnimateParameters.Mode, 'Picture')
        saveas(fig,[filename '_' num2str(f)],'png');
        close(fig);
    end
    
end

if isequal(AnimateParameters.Mode, 'Figure')
    close all
    v=VideoWriter([filename '.avi']);
    v.FrameRate=1/(5*ExperimentalData.Time(2));
    open(v)
    writeVideo(v,M);
    close(v)
elseif isequal(AnimateParameters.Mode, 'cFigure')
    anim8(fig,animStruct);
end

% varargout
if isequal(AnimateParameters.Mode, 'GenerateParameters')
    varargout{1} = Human_model;
    varargout{2} = Markers_set;
    varargout{3} = EnableModel;
end

end
