%This algorithm is for measuring plant stand height from LiDAR data used in
%the study 
% Keely Brown, Haley Schuhl, Dhiraj Srivastava, Getu Beyene, Mao Li, Noah Fahlgren, and Katherine Murphy (2025) Quantifying growth and lodging in Tef (Eragrostic tef) with
%Uncrewed Aerial Systems (UAS).
%Please contact Mao Li (mli@danforthcenter.org) for any question.

%Step 1. load LiDAR .las file into Matlab
file=dir('*.las');
idx=1; %change index for other .las files.
lasReader = lasFileReader(file(idx).name);
ptCloud = readPointCloud(lasReader);
V=ptCloud.Location;
a=find(V(:,3)>106.5); %remove noise such as power line
V(a,:)=[];

%Step 2. find and crop the ROI, 
pcshow(V)
view([0 90]) 
%click upper-left & lower-right corner 2 points and export as cursor_info
a=find(V(:,2)<cursor_info(1).Position(2)|V(:,2)>cursor_info(2).Position(2)|V(:,1)<cursor_info(2).Position(1)|V(:,1)>cursor_info(1).Position(1));
V(a,:)=[];
%rotate 
theta=-0.72; % change the angle here
R=[cos(theta) -sin(theta) 0;sin(theta) cos(theta) 0;0 0 1];
V=V*R;

%Step 3. use the data on 07/17 automatic plot detection to find the PlotDim which can be
%mask on the other dates.
Row=min(V(:,1)):(max(V(:,1))-min(V(:,1)))/10:max(V(:,1));
Col=min(V(:,2)):(max(V(:,2))-min(V(:,2)))/4:max(V(:,2));
plant=[];
for i=1:10
    for j=1:4
        a=find(V(:,1)>=Row(i)&V(:,1)<Row(i+1)&V(:,2)>=Col(j)&V(:,2)<Col(j+1));
        w=find(V(a,3)-min(V(a,3))>0.25);
        plant=[plant;a(w)];
    end
end

ptCloud_plant = pointCloud(V(plant,:));
ptCloud_plant = pcdenoise(ptCloud_plant);
minDistance = 0.5;
minPoints = 10;
[labels,numClusters] = pcsegdist(ptCloud_plant,minDistance,'NumClusterPoints',minPoints);
pcshow(ptCloud_plant.Location,labels)
colormap(prism(numClusters))
view([0 90]);

U=ptCloud_plant.Location;
for j=1:numClusters
    a=find(labels==j);
    UU{j}=U(a,:);
    minx=min(UU{j}(:,1));
    maxx=max(UU{j}(:,1));
    miny=min(UU{j}(:,2));
    maxy=max(UU{j}(:,2));
    PlotDim(j,:)=[minx maxx miny maxy];
    b1=find(V(:,1)<maxx+0.5&V(:,1)>minx-0.5&V(:,2)<maxy+0.5&V(:,2)>miny-0.5);
    b2=find(V(:,1)<=maxx&V(:,1)>=minx&V(:,2)<=maxy&V(:,2)>=miny);
    b=setdiff(b1,b2);
    soil(j)=mean(V(b,3));
    UU{j}(:,3)=UU{j}(:,3)-soil(j);
    pcshow(UU{j}); hold on;
end

%use PlotDim to mask on other dates.
%load other V.mat data
for j=1:30
    minx=PlotDim(j,1);
    maxx=PlotDim(j,2);
    miny=PlotDim(j,3);
    maxy=PlotDim(j,4);
    b1=find(V(:,1)<maxx+0.5&V(:,1)>minx-0.5&V(:,2)<maxy+0.5&V(:,2)>miny-0.5);
    w=find(V(b1,3)-min(V(b1,3))>0.2);
    U=V(b1(w),:);
    shiftx(j)=mean(U(:,1))-(minx+maxx)/2;
    shifty(j)=mean(U(:,2))-(miny+maxy)/2;
end
shiftx=mean(shiftx); %=-1.1for 06/21 
shifty=mean(shifty); %=0.2 for 06/21

for j=1:30
    minx=PlotDim(j,1);
    maxx=PlotDim(j,2);
    miny=PlotDim(j,3);
    maxy=PlotDim(j,4);
    minx=minx+shiftx;
    maxx=maxx+shiftx;
    miny=miny+shifty;
    maxy=maxy+shifty;
    b1=find(V(:,1)<maxx+0.5&V(:,1)>minx-0.5&V(:,2)<maxy+0.5&V(:,2)>miny-0.5);
    b2=find(V(:,1)<=maxx&V(:,1)>=minx&V(:,2)<=maxy&V(:,2)>=miny);
    U=V(b2,:);
    b=setdiff(b1,b2);    
    soil=mean(V(b,3));
    thresholdx=minx:(maxx-minx)/3:maxx;
    thresholdy=miny:(maxy-miny)/3:maxy;
    for p1=1:3
        for p2=1:3
            p=find(U(:,1)<=thresholdx(p1+1)&U(:,1)>=thresholdx(p1)&U(:,2)<=thresholdy(p2+1)&U(:,2)>=thresholdy(p2));
            U(p,3)=U(p,3)-soil;
        end
    end
    a=find(U(:,3)>0.05);
    UU{j}=U(a,:);
    pcshow(UU{j}); hold on;
end


%Step 4a. Method 1: mimic the manual measurement using 0.1m x 0.1m paper
clear H
clear Height
group=[0 7 4 1 8 5 2 6 9 3 0 8 7 5 3 2 4 9 6 1 0 4 8 7 5 3 1 6 9 2];
window=0.3;
paper=0.1;
for j=1:30
    if group(j)>0
        U=UU{j};
        minx=min(U(:,1));
        maxx=max(U(:,1));
        miny=min(U(:,2));
        maxy=max(U(:,2));
        [X,Y] = meshgrid(minx+window:0.1:maxx-window,maxy-window:-0.1:miny+window);
        for s1=1:size(X,1)
            for s2=1:size(X,2)
                a=find(abs(U(:,1)-[X(s1,s2)])<paper&abs(U(:,2)-[Y(s1,s2)])<paper);
                if ~isempty(a)
                H{j}(s1,s2)=max(U(a,3));
                end
            end
        end
    end
end

for j=1:9
    a=find(group==j);
    for i=1:3
        tmp=H{a(i)};
    P=prctile(tmp(:),80);
    b=find(tmp>P);
    Height(j,i)=mean(tmp(b));
    end
end

%Step 4b. Method 2. estimate height using 95 percentile subtracting 1 percentile
%use the PlotDim mask on each plot with some margin
margin=0.2;
for j=1:30
    minx=PlotDim(j,1);
    maxx=PlotDim(j,2);
    miny=PlotDim(j,3);
    maxy=PlotDim(j,4);
    minx=minx+shiftx;
    maxx=maxx+shiftx;
    miny=miny+shifty;
    maxy=maxy+shifty;
    b1=find(V(:,1)<maxx+margin&V(:,1)>minx-margin&V(:,2)<maxy+margin&V(:,2)>miny-margin);
    W{j}=V(b1,:);
end
for j=1:9
    a=find(group==j);
    for i=1:3
        tmp=W{a(i)};
        Height(j,i)=prctile(tmp(:,3),95)-prctile(tmp(:,3),1); %
    end
end