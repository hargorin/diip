%% Template to plot the data from the CLAHE

clc; clear all; close all;


% Data
fID = fopen('test.txt');
A = fscanf(fID, '%f', 256);
fclose(fID);

h_orig = A;
h_clip = 0;
h_dist = 0;
h_redist = 0;
h_cdf = 0;
h_clahe = 0;

% Plot

% Distribution
figure();
subplot(2,2,1);
plot(h_orig);
title('Original Image');

subplot(2,2,2);
plot(h_clip);
title('Clipping');

subplot(2,2,3);
plot(h_dist);
title('Distribution');

subplot(2,2,4);
plot(h_redist);
title('Redistribution')

% Contrast enhancment
figure();
subplot(2,2,[1 2])
plot(h_cdf);
title('CDF')

subplot(2,2,3);
plot(h_orig);
title('Original Image')

subplot(2,2,4);
plot(h_clahe);
title('CLAHE Image')