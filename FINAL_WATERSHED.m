 
%              *Marker Controlled Watershed Segmentation*



%% Read in the Color Image and Convert it to Grayscale
rgb = imread('apples.jpg');
figure
imshow(rgb)
I = rgb2gray(rgb);  %converting rgb image to grayscale
imshow(I)

 %% Use the Gradient Magnitude as the Segmentation Function
 % Calculating the gradient magnitude.(gradient is a directional change in the intensity or 
...color in an image) 
% The gradient is high at the borders of the objects and low (mostly) inside the objects.

gmag = imgradient(I);
figure
imshow(gmag,[])
title('Gradient Magnitude')

%% Segmenting the image using Watershed Transform


L = watershed(gmag);   % L is a labelled matrix of the image
Lrgb = label2rgb(L);   % converts labelled matrix to rgb image
figure
imshow(Lrgb)
title('Watershed Transform of Gradient Magnitude')

%% Marking the Foreground Objects
%  Using morphological techniques called "opening-by-reconstruction" and 
..."closing-by-reconstruction" to "clean" up the image.
...These operations will create flat maxima inside each object that can be 
...located using imregionalmax.


se = strel('disk',20); %creates a disk-shaped structuring element, where r specifies the radius
Io = imopen(I,se);
figure
imshow(Io)
title('Opening')
%% Computing the opening-by-reconstruction using imerode and imreconstruct. 

%erosion shrinks an image acc to structuring element,in this case,like a
%disk

Ie = imerode(I,se); % returns the eroded image.
Iobr = imreconstruct(Ie,I);
figure
imshow(Iobr)
title('Opening-by-Reconstruction')

%% Following the opening with a closing can remove the dark spots and stem marks. 


Ioc = imclose(Io,se);
figure
imshow(Ioc)
title('Opening-Closing')

%% Now use imdilate followed by imreconstruct. 
...We'll have to complement the image inputs and output of imreconstruct.
Iobrd = imdilate(Iobr,se);  %returns dilated image
Iobrcbr = imreconstruct(imcomplement(Iobrd),imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);
figure
imshow(Iobrcbr)
title('Opening-Closing by Reconstruction')

%%  Calculate the regional maxima of Iobrcbr to obtain good foreground markers.

fgm = imregionalmax(Iobrcbr);
figure
imshow(fgm)
title('Regional Maxima of Opening-Closing by Reconstruction')

%% To help interpret the result, superimpose the foreground marker image on the original image.
I2 = labeloverlay(I,fgm);
figure
imshow(I2)
title('Regional Maxima Superimposed on Original Image')

%% Marking Leftover shadowed objects 
...which means that these objects will not be segmented properly in the end result.
...Also, the foreground markers in some objects go right up to the objects' edge. 
...That means you should clean the edges of the marker blobs and then shrink them a bit. 
...You can do this by a closing followed by an erosion.

se2 = strel(ones(5,5));
fgm2 = imclose(fgm,se2);
fgm3 = imerode(fgm2,se2);

%%  bwareaopen- removes all blobs that have fewer than a certain number of pixels.
...previous procedure tends to leave some stray isolated pixels that must be removed
fgm4 = bwareaopen(fgm3,20); %objects having <20  pixels are removed for accuracy
I3 = labeloverlay(I,fgm4);
figure
imshow(I3)
title('Modified Regional Maxima Superimposed on Original Image')

%% Compute Background Markers
%mark the background. In the cleaned-up image, Iobrcbr, 
%the dark pixels belong to the background,so you could start with a thresholding operation.
bw = imbinarize(Iobrcbr);
figure
imshow(bw)
title('Thresholded Opening-Closing by Reconstruction')

%% We'll "thin" the background.This can be done by computing the watershed transform
%of the distance transform of bw, 
%and then looking for the watershed ridge lines (DL == 0) of the result.
D = bwdist(bw);
DL = watershed(D);

bgm = DL == 0;
figure
imshow(bgm)
title('Watershed Ridge Lines)')

%%  Compute the Watershed Transform of the Segmentation Function.
% imimposemin can be used to modify an image so that it has regional minima 
%only in certain desired locations
gmag2 = imimposemin(gmag, bgm | fgm4);

%% compute the watershed-based segmentation
L = watershed(gmag2);
%figure
%imshow(L);
%% Visualize the Result

labels = imdilate(L==0,ones(3,3)) + 2*bgm + 3*fgm4;
I4 = labeloverlay(I,labels);
figure
imshow(I4)
title('Markers and Object Boundaries Superimposed on Original Image')
