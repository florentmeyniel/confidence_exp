function imTex = loc_MakePatchTexture(gabor_dim_pix, freq, window)

% COMPUTE THE CHECKERBOARD
% compute the period
nrep = floor(gabor_dim_pix/(2*freq));

% binarize matrix according to period
xval = repmat(1:gabor_dim_pix, [gabor_dim_pix, 1]);
yval = repmat((1:gabor_dim_pix)', [1 gabor_dim_pix]);
xval_step = floor(xval ./ nrep);
yval_step = floor(yval ./ nrep);
for k = 1:max(xval_step(:));
    xval_step(xval_step(:) == k) = mod(k, 2);
    yval_step(yval_step(:) == k) = mod(k, 2);
end
xval_step(xval_step(:) == 0) = -1;
yval_step(yval_step(:) == 0) = -1;

% make the checkerboard
checkerboard = xval_step .* yval_step;

% COMPUTE ALPHA SHADING
% distance from center
center = round(gabor_dim_pix/2);
dist2center = sqrt((xval-center).^2 + (yval-center).^2);

% OPTION 1
Alpha_level = exp(-dist2center/(gabor_dim_pix/6));

% OPTION 2
% ring_w = round(gabor_dim_pix/2*0.5); % width of the outer ring
% ring_inner_rad = round(gabor_dim_pix/2 - ring_w); % radius of the inner circle
% % Alpha_level = (dist2center - ring_inner_rad) / ring_w;
% % Alpha_level(dist2center < ring_inner_rad) = 0;


Alpha_level(dist2center > gabor_dim_pix/2) = 0;

% Combine checkerboard and alpha
PatchTex = zeros(gabor_dim_pix, gabor_dim_pix, 4);
for k = 1:3
    PatchTex(:,:,k) = checkerboard;
end
PatchTex(:,:,4) = Alpha_level;

% Make texture
imTex = Screen('MakeTexture', window, PatchTex);



