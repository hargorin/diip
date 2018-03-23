%% Template to plot the data from the CLAHE

clc; clear all; close all;


% Read Data
ARR_LENGTH = 256;
fID = fopen('clahe_data.txt');

h_orig = fscanf(fID, '%d', ARR_LENGTH);
h_clip = fscanf(fID, '%d', ARR_LENGTH);
h_dist = fscanf(fID, '%d', ARR_LENGTH);
h_redist = fscanf(fID, '%d', ARR_LENGTH);
cdf = fscanf(fID, '%f', ARR_LENGTH);
h_clahe = fscanf(fID, '%d', ARR_LENGTH);

fclose(fID);


% Plot

% Distribution
figure();
subplot(2,2,1);
plot(h_orig); xlim([0 255]);
title('Original Image');

subplot(2,2,2);
plot(h_clip); xlim([0 255]);
title('Clipping');

subplot(2,2,3);
plot(h_dist); xlim([0 255]);
title('Distribution');

subplot(2,2,4);
plot(h_redist); xlim([0 255]);
title('Redistribution')

% Contrast enhancment
figure();
subplot(2,2,[1 2])
plot(cdf); xlim([0 255]);
title('CDF')

subplot(2,2,3);
stem(h_orig, 'Marker', '.'); xlim([0 255]);
title('Original Image')

subplot(2,2,4);
stem(h_clahe, 'Marker', '.'); xlim([0 255]);
title('CLAHE Image')