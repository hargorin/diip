%% Wallis Filter

clc; clear all; close all;

WIN_SIZE = 41;
LENGTH = WIN_SIZE * WIN_SIZE;


% weisses Bild
pixel = linspace(0, 0, LENGTH);
sprintf('Mean (white): %.2f', mean(pixel))
sprintf('Var (white): %.2f', var(pixel))

% schwarzes Bild
pixel = linspace(255, 255, LENGTH);
sprintf('Mean (black): %.2f', mean(pixel))
sprintf('Var (black): %.2f', var(pixel))
sprintf('sum_Pixel (black): %.2f', sum(pixel))

% 50:50
pixel = [linspace(0, 0, (LENGTH - 1)/2), linspace(255, 255, (LENGTH - 1)/2+1)];
sprintf('Mean (50:50): %.2f', mean(pixel))
sprintf('Var (50:50): %.2f', var(pixel))

pixel = [linspace(0, 0, (LENGTH - 1)/2+1), linspace(255, 255, (LENGTH - 1)/2)];
sprintf('Mean (50:50): %.2f', mean(pixel))
sprintf('Var (50:50): %.2f', var(pixel))

% linear
pixel = floor(linspace(0, 255, LENGTH));
sprintf('Mean (lin): %.2f', mean(pixel))
sprintf('Var (lin): %.2f', var(pixel))








% Input Variables
% pixel = 0;
% n_Mean = 156;
% n_Var = 2400;
% g_Mean = 127;
% g_Var = 3600;
% b = 0.8;
% c = 0.75;
% 
% w_gMean = b * g_Mean;
% w_gVar = (1-c) * g_Var;
% 
% tmp_Num = (pixel - n_Mean) * g_Var;
% fp_Num = tmp_Num * c;
% fp_nVar = c * n_Var;
% fp_nMean = (1-b) * n_Mean;
% fp_Var = fp_nVar + w_gVar;
% fp_Div = fp_Num / fp_Var;
% w_Pixel = fp_Div + w_gMean + fp_nMean



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


