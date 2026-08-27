%% Project 259 - CIRS040GSE reference validation

clear;
clc;
close all;

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

inputFile = fullfile(projectRoot, ...
    "data", "processed", ...
    "cirs040_reference_reconstruction.mat");

imageFile = fullfile(projectRoot, ...
    "data", "processed", ...
    "cirs040_reference_reconstruction.png");

load(inputFile, "bMode", "imageRF", "x", "z", "USHEADER");

fprintf("Project 259 - CIRS040GSE reference validation\n");
fprintf("---------------------------------------------\n");

%% Check the reconstructed data

fprintf("B-mode size: %s\n", mat2str(size(bMode)));
fprintf("RF image size: %s\n", mat2str(size(imageRF)));
fprintf("B-mode range: %.2f to %.2f dB\n", ...
    min(bMode(:)), max(bMode(:)));

fprintf("Lateral range: %.2f to %.2f mm\n", ...
    min(x) * 1e3, max(x) * 1e3);

fprintf("Depth range: %.2f to %.2f mm\n", ...
    min(z) * 1e3, max(z) * 1e3);

%% Check for invalid values

numNaN = sum(isnan(bMode(:)));
numInf = sum(isinf(bMode(:)));

fprintf("\nNaN values: %d\n", numNaN);
fprintf("Inf values: %d\n", numInf);

%% Calculate basic image statistics

meanDB = mean(bMode(:));
stdDB = std(bMode(:));

fprintf("\nMean B-mode level: %.2f dB\n", meanDB);
fprintf("B-mode standard deviation: %.2f dB\n", stdDB);

%% Confirm the saved image exists

if isfile(imageFile)
    imageInfo = dir(imageFile);

    fprintf("\nSaved image: PASS\n");
    fprintf("Image file size: %.1f kB\n", imageInfo.bytes / 1024);
else
    fprintf("\nSaved image: FAIL\n");
end

%% Final validation result

if numNaN == 0 && numInf == 0 && isfile(imageFile)
    fprintf("\nReference validation: PASS\n");
else
    fprintf("\nReference validation: CHECK OUTPUT\n");
end