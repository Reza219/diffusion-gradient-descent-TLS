clear
addpath('Function')
load('data')      %load npi: input noise variance at each node
                  %     npo: output noise variance at each node
                  %     xp : input signal variance at each node

%constants
L=2;              %system order
dl=300;           %no of iterations
N=20;             %number of nodes
lpn=3;            %average link per node
beta=npo./npi;    %beta
mu1=.05;          %step size
nr=10;            %number of trials

%network connectivity matrix
G=creategraph_f(4,N,lpn);

%combination weights
A1=eye(N);
A2=unicoef_f(G,N);
C1=eye(N);
C2=metrocoef_f(G,N);

%target system
h=randn(L,1);
h=h/norm(h);

%initialization
Nc=4;             %number of curves
V=zeros(dl,Nc);
v=zeros(dl,Nc);
S=zeros(N,Nc);
s=zeros(N,Nc);

for ii=1:nr
    ii
    %noiseless input signal
    x=randn(L,N,dl);
    for k=1:N
        x(:,k,:)=sqrt(xp(k))*x(:,k,:);
    end
    
    %filter output
    y=zeros(N,dl);
    for k=1:N
        y(k,:)=h'*squeeze(x(:,k,:));
    end
    
    %output noise
    no=randn(N,dl);
    for k=1:N
        no(k,:)=sqrt(npo(k))*no(k,:);
    end
    
    %noisy output signal
    y=y+no;
    
    %input noise
    ni=randn(L,N,dl);
    for k=1:N
        ni(:,k,:)=sqrt(npi(k))*ni(:,k,:);
    end
    
    %noisy input signal
    x=x+ni;
    
    %gradient-descent TLS without cooperation
    vi    =DGDTLS_ATC_f(dl,L,x,y,h,mu1,A1,C1,G,N,beta);
    v(:,1)=mean(vi,2);
    s(:,1)=mean(vi(150:dl,:),1);
    
    %diffusion gradient-descent TLS - combine then adapt 
    vi    =DGDTLS_CTA_f(dl,L,x,y,h,mu1,A2,C2,G,N,beta);
    v(:,2)=mean(vi,2);
    s(:,2)=mean(vi(150:dl,:),1);
    
    %diffusion gradient-descent TLS - adapt then combine
    vi    =DGDTLS_ATC_f(dl,L,x,y,h,mu1,A2,C2,G,N,beta);
    v(:,3)=mean(vi,2);
    s(:,3)=mean(vi(150:dl,:),1);
    
    %centeralized gradient-descent TLS
    v(:,4)=CGDTLS_f(dl,L,x,y,h,mu1/N,N,beta);
    s(:,4)=mean(v(150:dl,4),1);
    
    V=V+v;
    S=S+s;
end

V=V/nr;
S=S/nr;

figure
plot(10*log10(V(:,1)),'k','linewidth',3)
hold on
plot(10*log10(V(:,2)),'r','linewidth',3)
plot(10*log10(V(:,3)),'g','linewidth',3)
plot(10*log10(V(:,4)),'b','linewidth',3)
xlabel('no. of iteration')
ylabel('misalignment (dB)')
legend('no coop','CTA','ATC','Centeralized')

figure
plot(10*log10(S(:,1)),'k','linewidth',3)
hold on
plot(10*log10(S(:,2)),'r','linewidth',3)
plot(10*log10(S(:,3)),'g','linewidth',3)
plot(10*log10(S(:,4)),'b','linewidth',3)
xlabel('no. of node')
ylabel('misalignment (dB)')
legend('no coop','CTA','ATC','Centeralized')