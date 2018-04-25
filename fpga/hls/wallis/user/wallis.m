%% Wallis Filter

clc; clear all; close all;

% Input Variables
pixel = 0;
n_Mean = 156;
n_Var = 2400;
g_Mean = 127;
g_Var = 3600;
b = 0.8;
c = 0.75;

w_gMean = b * g_Mean;
w_gVar = (1-c) * g_Var;

tmp_Num = (pixel - n_Mean) * g_Var;
fp_Num = tmp_Num * c;
fp_nVar = c * n_Var;
fp_nMean = (1-b) * n_Mean;
fp_Var = fp_nVar + w_gVar;
fp_Div = fp_Num / fp_Var;
w_Pixel = fp_Div + w_gMean + fp_nMean



% pixel = int64(0);
% n_Mean = int64(156);
% n_Var = int64(2400);
% g_Mean = int64(127);
% g_Var = int64(3600);
% b = int64(0.8);
% c = int64(0.75);
% 
% w_gMean = b * g_Mean;
% w_gVar = (1-c) * g_Var;
% 
% tmp_Num = (pixel - n_Mean) * g_Var;
% fp_Num = tmp_Num * c;
% fp_nVar = c * n_Var;
% fp_nMean = (1-b) * n_Mean;
% fp_Var = fp_nVar + w_gVar;
% fp_Div = idivide(fp_Num, fp_Var);
% w_Pixel = (fp_Div + w_gMean + fp_nMean)


