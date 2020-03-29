%% Benders Decomposition ʾ������

clear variables
close all
warning off
clc

%% ����ϵ������

% 1. ����ı�׼��ʽ
% min   cx + dy
% s.t.  Ax + By >= f
%       x >= 0
%       x is continious
%       y is binary

c = [ 1, 1, 1, 1, 1];
d = [ 7, 7, 7, 7, 7];
A = [-1, 0, 0,-1,-1;
      1, 0, 0, 1, 1;
      0,-1, 0, 0,-1;
      0, 1, 0, 0, 1;
      0, 0,-1,-1, 0;
      0, 0, 1, 1, 0;
     -1, 0, 0, 0, 0;
      0,-1, 0, 0, 0;
      0, 0,-1, 0, 0;
      0, 0, 0,-1, 0;
      0, 0, 0, 0,-1];  % ϵ������A
B = [ 0, 0, 0, 0, 0;
      0, 0, 0, 0, 0;
      0, 0, 0, 0, 0;
      0, 0, 0, 0, 0;
      0, 0, 0, 0, 0;
      0, 0, 0, 0, 0;
      8, 0, 0, 0, 0;
      0, 3, 0, 0, 0;
      0, 0, 5, 0, 0;
      0, 0, 0, 5, 0;
      0, 0, 0, 0, 3];  % ϵ������A
f = [-8; 8;-3; 3;-5; 5; 0; 0; 0; 0; 0];  % ϵ������f

% 2. ���ڲ��������⣬�蹹����Feasibility Relaxation�����׼��ʽΪ
% min   ez
% s.t.  Ax + By + Cz >= f
%       x >= 0
%       z >= 0
%       x is continious
%       y is binary

e = ones(1, size(A,1)) * 5;  % ϵ������e
C = eye(size(A,1));  % ϵ������C


%% ���� yalmip + cplex ֱ�ӽ�ģ���

% 1. ��������
x = sdpvar(5,1);  % ����x
y = binvar(5,1);  % ����y

% 2. ģ�͹���
obj = c*x + d*y;  % Ŀ�꺯��
constr = [];  % Լ������
constr = [constr, A*x + B*y >= f];
constr = [constr, x >= 0];

% 3. ģ�����
opts = sdpsettings('solver','cplex','verbose',2);  % yalmip��������
diag = optimize(constr,obj,opts);  % ģ�����
if diag.problem == 0  % �п��н�
    res_cplex = value(obj);  % ��¼���н�
    sol_cplex = [value(x),value(y)];
else
    disp('The original problem is infeasible!')
    pause();
end

%% ����Benders Decomposition���

% 1. �㷨��ʼ��
lb = [];  % �½�
ub = [];  % �Ͻ�
sub_coef = [];  % ��¼��żϵ��
sub_sol  = [];  % ��¼�������������⴫�ݵĽ�
sub_obj  = [];  % ��¼�������Ŀ�꺯��

% 2. ������
while true
    % 1) ��������
    x = sdpvar(5,1);
    y = binvar(5,1);
    z = sdpvar(size(A,1),1);  % �������ɳ���������
    t = sdpvar(1,1);  % ��������������
    
    % 2) ���������
    obj = d*y + t;
    constr = [];
    constr = [constr, t >= 0];
    if ~isempty(sub_coef)  % ���Benders Cut
        for i = 1:size(sub_coef,2)
            constr = [constr, t >= sub_obj(i) - sub_coef(:,i)' * (y - sub_sol(:,i))];
        end
    end
    opts = sdpsettings('solver','cplex','verbose',2);
    optimize(constr,obj,opts);
    y_star = value(y);  % ��¼��ǰy��ֵ
    lb = [lb, value(obj)];  % �����½�
    
    % 3) ���������
    obj = c*x;
    constr = [];
    constr = [constr, A*x + B*y >= f];
    constr = [constr, x >= 0];
    constr = [constr, y == y_star];  % ����������Ӧ����������
    opts = sdpsettings('solver','cplex','verbose',2,'relax',1);  % ������0-1�����ɳ�
    diag = optimize(constr,obj,opts);
    if diag.problem == 1  % �޿��н⣬����Infeasibility Relaxation
        obj = c*x + e*z;
        constr = [];
        constr = [constr, A*x + B*y + C*z >= f];
        constr = [constr, x >= 0];
        constr = [constr, z >= 0];
        constr = [constr, y == y_star];  % ����������Ӧ����������
        opts = sdpsettings('solver','cplex','verbose',2,'relax',1);  % ������0-1�����ɳ�
        optimize(constr,obj,opts);
    end
    sub_coef = [sub_coef, dual(constr(end))];  % ���¶�żϵ��
    sub_sol  = [sub_sol , y_star];  % �����������������⴫�ݵĽ�
    sub_obj  = [sub_obj , value(obj)];  % �����������Ŀ�꺯��
    ub = [ub, d * y_star + value(obj)];  % �����Ͻ�
    
    % 4) �����ж�
    gap = (ub(end) - lb(end)) / ub(end);
    if gap <= 1e-5
        res_benders = ub(end);
        sol_benders = [value(x),value(y)];
        break;
    end
end

%% ������

disp('');
disp('cplex�õ����������Ž�Ϊ��');
sol_cplex
disp(['���Ž⣺', num2str(res_cplex)]);
disp('');
disp('Benders Decomposition�õ����������Ž�Ϊ��');
sol_benders
disp(['���Ž⣺', num2str(res_benders)]);




