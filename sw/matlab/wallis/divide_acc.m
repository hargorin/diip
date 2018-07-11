%% Calculate the accurance of the Mean and Variance division
clc; clear all; close all;

BITS = 14;
WIN_LENGTH = 21;
WIN_SIZE = WIN_LENGTH * WIN_LENGTH;

sum_pixel = linspace(0, (WIN_SIZE * 255), (WIN_SIZE * 255 + 1));

% Exact Calculation
for i = 1:numel(sum_pixel)
    e_mean(i) = round(sum_pixel(i) / WIN_SIZE);
end

% Inexact Calculation
const = floor(2^BITS / WIN_SIZE);

for i = 1:numel(sum_pixel)
    ie_mean(i) = sum_pixel(i) * const;
    ie_mean(i) = floor(ie_mean(i) / 2^BITS);
end

% Inexact Round Calculation
const = floor(2^BITS / WIN_SIZE);

for i = 1:numel(sum_pixel)
    ier_mean(i) = sum_pixel(i) * const + (2^(BITS-1));
    ier_mean(i) = floor(ier_mean(i) / 2^BITS);
end

% Comparision
disp('RMSE')
RMSE = sqrt(mean((e_mean - ie_mean).^2))

disp('RMSE - Round')
RMSE = sqrt(mean((e_mean - ier_mean).^2))