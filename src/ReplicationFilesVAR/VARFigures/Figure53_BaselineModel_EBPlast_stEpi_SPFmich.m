clear all
cd ..
addpath([cd '/GLPreplicationWeb']);
addpath([cd '/GLPreplicationWeb/subroutines']);
figpath = [pwd(), '/../../figures/'];

% load the data and assign variable names
LoadDataAssignVariableNames

% variables included in the VARs
y=[unem nunem corepceinfl gdpinfl 100*(rgdp-log(pop)) 100*(h-log(pop)) aheinfl ls epi1 EBP];
ymich=[unem nunem corepceinfl gdpinfl 100*(rgdp-log(pop)) 100*(h-log(pop)) aheinfl ls epimich EBP];

series=["unemployment","natural unemployment","core inflation","inflation","GDP","hours","wage inflation (PNSE)","labor share","inflation expectations","excess bond premium","wage inflation (total economy)"]
YLABEL=["percentage points","percentage points","percentage points","percentage points","percent","percent","percentage points","percent","percentage points","percentage points","percentage points"];

% dimensions and settings
[junk maxind]=max(1-isnan(y));
[junk,n]=size(y);
lags=4;             % # lags
H=20;               % maximum horizon for impulse responses
M=20000;            % # MCMC draws (discard the first M/2)
nshock=10;           % position of the shock (in Cholesky identification)

% sample for VAR with SPF
startdate1=1990-lags/4; T01=find(Time==startdate1);
enddate1=2019.5; T11=find(Time==enddate1);

% sample for VAR with Michigan
startdate2=1990-lags/4; T02=find(Time==startdate2);
enddate2=2019.5; T12=find(Time==enddate2);

% GLP estimation, SPF
resGLP1 = bvarGLP([y(T01:T11,:)],lags,'mcmc',1,'MCMCconst',10,'MNpsi',0,'noc',0,'sur',0,'Ndraws',M);

% impulse responses, SPF
ndraws = size(resGLP1.mcmc.beta,3);
Dirf1 = zeros(H+1,size(y,2),ndraws);
Share1=zeros(ndraws,n);
VBC1=zeros(ndraws,n);
for jg = 1:ndraws
    Dirf1(:,:,jg) =  bvarIrfs(resGLP1.mcmc.beta(:,:,jg),resGLP1.mcmc.sigma(:,:,jg),nshock,H+1);
end
Dirf1=Dirf1/median(Dirf1(1,nshock,:));      % normalization of the size of the initial impulse
sIRF1 = sort(Dirf1,3);

% GLP estimation, Michigan
resGLP2 = bvarGLP([ymich(T02:T12,:)],lags,'mcmc',1,'MCMCconst',5,'MNpsi',0,'noc',0,'sur',0,'Ndraws',M);

% impulse responses, Michigan
Dirf2 = zeros(H+1,size(y,2),ndraws);
Share2=zeros(ndraws,n);
VBC2=zeros(ndraws,n);
for jg = 1:ndraws
    Dirf2(:,:,jg) =  bvarIrfs(resGLP2.mcmc.beta(:,:,jg),resGLP2.mcmc.sigma(:,:,jg),nshock,H+1);
end
Dirf2=Dirf2/median(Dirf2(1,nshock,:));      % normalization of the size of the initial impulse
sIRF2 = sort(Dirf2,3);

% computation of alpha and kappa for each draw of the impulse resposes (SPF and Michigan)
AK1=zeros(ndraws,2);
AK2=zeros(ndraws,2);
stdAK1=zeros(ndraws,2);
stdAK2=zeros(ndraws,2);
for ii=1:ndraws
    r1=ols1(squeeze(Dirf1(2:end,4,ii))-squeeze(Dirf1(1:end-1,4,ii)),[squeeze(Dirf1(2:end,9,ii))-squeeze(Dirf1(1:end-1,4,ii)) squeeze(Dirf1(2:end,1,ii))]);
    AK1(ii,:)=r1.bhatols';
    r2=ols1(squeeze(Dirf2(2:end,4,ii))-squeeze(Dirf2(1:end-1,4,ii)),[squeeze(Dirf2(2:end,9,ii))-squeeze(Dirf2(1:end-1,4,ii)) squeeze(Dirf2(2:end,1,ii))]);
    AK2(ii,:)=r2.bhatols';
end

% plot the histograms of alpha and kappa
p = figure('Position', [0, 0, 700, 300]);
subplot(1,2,1); histogram(AK2(:,1),30,'Normalization','pdf','FaceColor',[.2157, .4941, .7216]); hold on
    histogram(AK1(:,1),30,'Normalization','pdf','FaceColor',[.8941, .1020, .1098])
    xlabel('\alpha')
    legend('Michigan Survey','SPF')
subplot(1,2,2); histogram(AK2(:,2),30,'Normalization','pdf','FaceColor',[.2157, .4941, .7216]); hold on
    histogram(AK1(:,2),30,'Normalization','pdf','FaceColor',[.8941, .1020, .1098])
    xlabel('\kappa')
saveas(p, [figpath, 'Figure6'], 'eps');
saveas(p, [figpath, 'Figure6'], 'svg');
