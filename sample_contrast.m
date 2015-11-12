function [samples] = sample_contrast(contrast, sigma, reference_contrast,side)
samples = -1;
while mean(samples) < 0
    samples = randn(1,10)*sigma + contrast ;
end
samples = reference_contrast + samples*side;
end
