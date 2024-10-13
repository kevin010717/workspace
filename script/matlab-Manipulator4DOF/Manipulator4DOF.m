%https://www.bilibili.com/video/BV1q44y1x7WC?p=2&vd_source=d91bffd2a7a6acff9ff536f2f1332429
%https://petercorke.com/toolboxes/robotics-toolbox/
%% standard DH
L(1)=Link('revolute','d',0.216,'a',0,'alpha',pi/2);

L(2)=Link('revolute','d',0,'a',0.5,'alpha',0,'offset',pi/2);

L(3)=Link('revolute','d',0,'a',sqrt(0.145^2+0.42746^2),'alpha',0,'offset',-atan(427.46/145));

L(4)=Link('revolute','d',0,'a',0,'alpha',pi/2,'offset',atan(427.46/145));

L(5)=Link('revolute','d',0.258,'a',0,'alpha',0);

Five_dof=SerialLink(L,'name','五轴机器人');

Five_dof.base=transl(0,0,0.28);
f = figure('Name', 'standard DH');
Five_dof.teach;

%% Modified DH
L(1)=Link('revolute','d',0,'a',0,'alpha',0,'modified');

L(2)=Link('revolute','d',0,'a',0,'alpha',pi/2,'offset',pi/2,'modified');

L(3)=Link('revolute','d',0,'a',0.5,'alpha',0,'offset',-atan(427.46/145),'modified');

L(4)=Link('revolute','d',0,'a',sqrt(0.145^2+0.42746^2),'alpha',pi/2,'offset',atan(427.46/145),'modified');

L(5)=Link('revolute','d',0.258,'a',0,'alpha',pi/2,'modified');

Five_dof_mod=SerialLink(L,'name','五轴机器人');

Five_dof_mod.base=transl(0,0,0.496);

Five_dof_mod.teach;
%% 
doc SerialLink %查看Serialink官方文档
rtbdemo
%% 
q = [0 0 0 0 0];
Five_dof.plot(q);
%% 
mdl_puma560;
%p560.plot3d(qz);
p560.plot3d(qz,'view',[0 0]);
%% 工作空间范围可视化

L(1)=Link('revolute','d',0.216,'a',0,'alpha',pi/2);

L(2)=Link('revolute','d',0,'a',0.5,'alpha',0,'offset',pi/2);

L(3)=Link('revolute','d',0,'a',sqrt(0.145^2+0.42746^2),'alpha',0,'offset',-atan(427.46/145));

L(4)=Link('revolute','d',0,'a',0,'alpha',pi/2,'offset',atan(427.46/145));

L(5)=Link('revolute','d',0.258,'a',0,'alpha',0);

Five_dof=SerialLink(L,'name','五轴机器人');

Five_dof.base=transl(0,0,0.28);

%Five_dof.teach;

L(1).qlim=[-150,150]/180*pi; %qlim弧度限制   工作空间范围可视化

L(2).qlim=[-100,90]/180*pi;

L(3).qlim=[-90,90]/180*pi;

L(4).qlim=[-100,100]/180*pi;

L(5).qlim=[-180,180]/180*pi;

num=300; %随机次数300次

P=zeros(num,3) ;%零矩阵（num*3行列）

for i=1:num

    %最小关节角度+rand*（最大关节角度减去最小关节角度）

    q1=L(1).qlim(1)+rand*(L(1).qlim(2)-L(1).qlim(1)) ;

    q2=L(2).qlim(1)+rand*(L(2).qlim(2)-L(2).qlim(1));

    q3=L(3).qlim(1)+rand*(L(3).qlim(2)-L(3).qlim(1));

    q4=L(4).qlim(1)+rand*(L(4).qlim(2)-L(4).qlim(1));

    q5=L(5).qlim(1)+rand*(L(5).qlim(2)-L(5).qlim(1));

    q=[q1 q2 q3 q4 q5];

    T=Five_dof.fkine(q);%正向运动学 求得T

    %Five_dof.plot(q);%可显示每次机械臂的实时位置

    %[x,y,z]=transl(T);

    %plot3(x,y,z,'B','markersize',1);

    P(i,:)=transl(T); %transl函数得出三维坐标点

end

plot3(P(:,1),P(:,2),P(:,3),'b.','markersize',1);%三维空间绘制

%axis([-1.5 1.5 -1.5 -0.5 1.5]);

hold on %保留机械臂

grid on

daspect([1 1 1]);

view([45 45]);

Five_dof.plot([0 0 0 0 0]);
%% 

% t = linspace(0,2,51);
% [p,dp,ddp] = tpoly(0,3,t);
% [p,dp,ddp] = tpoly(0,3,t,0.02,0.01);
% 
% 
% [p,dp,ddp] = lspb(0,3,t);
% [p,dp,ddp] = lspb(0,3,t,0.1);
% 
% [p,dp,ddp] = mtraj(@tpoly,[0,0],[3,4],t);
%%
T1 = transl(0.7,-0.5,1) ;
T2 = transl(0.7,0.5,0.5) ;

q1 = Five_dof.ikunc(T1);
q2 = Five_dof.ikunc(T2);

Five_dof.plot(q1);
pause
Five_dof.plot(q2);
pause

T1 = transl(0.7,-0.5,1) * trotx(180);
T2 = transl(0.7,0.5,0.5) * trotx(180);

q1 = Five_dof.ikunc(T1);
q2 = Five_dof.ikunc(T2);

Five_dof.plot(q1);
pause
Five_dof.plot(q2);
%%
P1 = [0.7,-0.5,0];
P2 = [0.7,0.5,0.5];

t = linspace(0,2,51);
Traj = mtraj(@tpoly,P1,P2,t);

n = size(Traj,1);
T = zeros(4,4,n);

for i = 1:n
    T(:,:,i) = transl(Traj(i,:)) * trotx(180);
end

Qtraj = Five_dof.ikunc(T);

Five_dof.plot(Qtraj);
% Five_dof.plot(Qtraj,'trail','b');%绘制轨迹
% Five_dof.plot(Qtraj,'movie','trail.gif');%生成gif
%% 
hold on
plot(t,Traj(:,1),'.-','linewidth',1);
plot(t,Traj(:,2),'.-','linewidth',1);
plot(t,Traj(:,3),'.-','linewidth',1);

grid on
legend('x','y','z');
xlabel('time');
ylabel('position');

%% 

T_liner = trinterp(T1,T2,51);
P_liner = transl(T_liner);
t1 = linspace(0,2,51);

subplot(1,2,1);
hold on
plot(t1,P_liner(:, 1),'.-','linewidth',1);
plot(t1,P_liner(:, 2),'.-','linewidth',1);
plot(t1,P_liner(:, 3),'.-','linewidth',1);

grid on
legend('x','y','z');
xlabel('time');
ylabel('position');

T_tpoly = trinterp(T1, T2, tpoly(0, 2, 50) / 2);
P_tpoly = transl(T_tpoly);
t2 = linspace(0,2,50);clc

subplot(1,2,2);
hold on
plot(t2,P_tpoly(:,1),'.-','linewidth',1);
plot(t2,P_tpoly(:,2),'.-','linewidth',1);
plot(t2,P_tpoly(:,3),'.-','linewidth',1);

grid on
legend('x','y','z');
xlabel('time');
ylabel('position');
%% 
T = ctraj(T1,T2,51);
t1 = linspace(0,2,51);
P1 = transl(T);

hold on
plot(t1,P1(:, 1),'.-','linewidth',1);
plot(t1,P1(:, 2),'.-','linewidth',1);
plot(t1,P1(:, 3),'.-','linewidth',1);

T = ctraj(T1,T2,tpoly(0,2,50)/2);
t2 = linspace(0,2,50);
P2 = transl(T);

hold on
plot(t2,P2(:,1),'.-','LineWidth',1);
plot(t2,P2(:,2),'.-','LineWidth',1);
plot(t2,P2(:,3),'.-','LineWidth',1);

grid on
legend('x1','y1','z1','x2','y2','z2');
xlabel('time');
ylabel('position')
%% 
T1 = transl(0.7,-0.5,0)*troty(150);
T2 = transl(0.7,0.5,0.5)*troty(200);

q1 = Five_dof.ikunc(T1);
q2 = Five_dof.ikunc(T2);

Five_dof.plot(q1);
pause
Five_dof.plot(q2);
%% 
rpy1 = [0,150,0];
rpy2 = [200,0,0];

t = linspace(0,2,51);
rpy_traj = mtraj(@tpoly,rpy1,rpy2,t);
T_traj_rot = rpy2tr(rpy_traj);

P1 = transl(T1);
P2 = transl(T2);
P_traj = mtraj(@tpoly,P1',P2',t);
T_traj_transl = transl(P_traj);

n = length(t);
T_traj = zeros(4,4,n);
for i = 1:n
    T_traj(:,:,i) = T_traj_transl(:,:,i)*T_traj_rot(:,:,i);
end

q_traj = Five_dof.ikunc(T_traj);
Five_dof.plot(q_traj,'trail','r');
%% 
t = linspace(0,2,51);
T_traj = trinterp(T1,T2,t/2);
q = Five_dof.ikunc(T_traj);

Five_dof.plot(q,'trail','r');

%% 

t = linspace(0,2,51);
T_traj = ctraj(T1,T2,t/2);
q = Five_dof.ikunc(T_traj);

Five_dof.plot(q,'trail','r');
%% 
t = linspace(0,2,51);
[q,dq,ddq] = jtraj(q1,q2,t);
Five_dof.plot(q,'trail','r')
%% 
subplot(1,3,1)
plot(t,q)
grid on
xlabel('time')
ylabel('q')
legend('joint1','joint2','joint3','joint4','joint5')

subplot(1,3,2)
plot(t,dq)
grid on
xlabel('time')
ylabel('dq')
legend('joint1','joint2','joint3','joint4','joint5')

subplot(1,3,3)
plot(t,ddq)
grid on
xlabel('time')
ylabel('ddq')
legend('joint1','joint2','joint3','joint4','joint5')

%% 3d mod
clear;
clc;

L(1)=Link('revolute','d',0.216,'a',0,'alpha',pi/2);
L(2)=Link('revolute','d',0,'a',0.5,'alpha',0,'offset',pi/2);
L(3)=Link('revolute','d',0,'a',sqrt(0.145^2+0.42746^2),'alpha',0,'offset',-atan(427.46/145));
L(4)=Link('revolute','d',0,'a',0,'alpha',pi/2,'offset',atan(427.46/145));
L(5)=Link('revolute','d',0.258,'a',0,'alpha',0);

Five_dof=SerialLink(L,'name','5-dof');
Five_dof.base=transl(0,0,0.28);

q0=[0 0 0 0 0];
v=[35 20];
w=[-1 1 -1 1 0 2];
h = figure('Name', '3d mod');

Five_dof.plot3d(q0,'tilesize',0.1,'workspace',w,'path','C:\matlabcode\Manipulator4DOF','nowrist','view',v)

light('Position',[1 1 1],'color','w');
%% pick
Position = [0.5 0.5 0.5];
r = 0.04;
plot_sphere(Position,r,'r');

T1 = transl(Position)*rpy2tr(180,0,0);

q1 = Five_dof.ikunc(T1);

q = jtraj(q0,q1,60);

Five_dof.plot3d(q,'view',v,'fps',60,'nowrist');
%% place 
position2 = [0.5,-0.5,1];

T2 = transl(position2)*rpy2tr(90,90,0);

q2 = Five_dof.ikunc(T2);

t = 30;
q = jtraj(q1,q2,t);

for i = 1:30
    qi = q(i,:);
    Ti = Five_dof.fkine(qi);
    Pi = transl(Ti);
    plot_sphere(Pi,r,'r');
    Five_dof.plot3d(qi,'view',v,'nowrist');
    cla;
end
%% back
plot_sphere(Pi,r,'r');

q = jtraj(q2,q0,60);

Five_dof.plot3d(q,'view',v,'nowrist','fps',60);

cla;
%% trace

q = [jtraj(q0,q1,60);
    jtraj(q1,q2,60);
    jtraj(q2,q0,60)];

Five_dof.plot3d(q,'view',v,'nowrist','fps',60,'trail',{'r','LineWidth',1});
%% jacob
L(1)=Link('revolute','d',0.216,'a',0,'alpha',pi/2);
L(2)=Link('revolute','d',0,'a',0.5,'alpha',0,'offset',pi/2);
L(3)=Link('revolute','d',0,'a',sqrt(0.145^2+0.42746^2),'alpha',0,'offset',-atan(427.46/145));
L(4)=Link('revolute','d',0,'a',0,'alpha',pi/2,'offset',atan(427.46/145));
L(5)=Link('revolute','d',0.258,'a',0,'alpha',0);
Five_dof=SerialLink(L,'name','五轴机器人');
Five_dof.base=transl(0,0,0.28);

L(1).qlim=[-150,150]/180*pi; %qlim弧度限制   工作空间范围可视化
L(2).qlim=[-100,90]/180*pi;
L(3).qlim=[-90,90]/180*pi;
L(4).qlim=[-100,100]/180*pi;
L(5).qlim=[-180,180]/180*pi;

q0 = [0 0 0 0 0];
J0 = Five_dof.jacob0(q0);
Je = Five_dof.jacobe(q0);

T = Five_dof.fkine(q0);
r = t2r(T);
R = [r zeros(3);
    zeros(3) r];

J1 = R*J0;
J2 = inv(R)*Je;
J3 = R\Je;

q1 = [pi/2 0 0 0 0];
t = 0:0.05:2;
[Q,dQ,ddQ] = jtraj(q0,q1,t);
Five_dof.plot(Q);

v = zeros(6,length(t));
for i = 1:length(t)
    q = Q(i,:)';
    dq = dQ(i,:)';
    J0 = Five_dof.jacob0(q);
    v(:,i) = J0*dq;
end

plot(t,v(1:3,:)');
legend('vx','vy','vx');

figure;
plot(t,v(4:6,:)');
legend('θx','θy','θz');