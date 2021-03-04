close all

img = imread("cells.png");
% imshow(img);

% imhist(img)

thr = 113;
bw = img<thr;

figure; imshow(bw)
[n,num]=bwlabel(bw);
sv = zeros(num,1);
for i=1:num
    if sum(sum(n==i)) < 50
        n(n==i) = 0;
    end
end

bw = n>0;

border = and(bw,not(bwmorph(bw,'erode')));

dist = bwdist(border);
dist(bw==0)=0;

h=fspecial('gaussian',9,1.7);
dist2 = imfilter(dist,h);

kp = imregionalmax(dist2);

dist3 = bwdist(kp);
dist3(bw==0) = -Inf;

L=watershed(dist3,8);

[n2,num2]=bwlabel(L);
red = img;
for i = 1:num2
    if sum(sum(and(n2==i,kp)))==0
        n2(n2==i)=0;
    end
    red(and(bwmorph(n2==i,'dilate'),not(n2==i)))=255;
end

res=cat(3,red,img,img);

imshow(res);
% figure; imshow(bw)
% % figure; imshow(bwdist(border),[])
% % figure; imshow(dist2,[])
% % figure; imshow(kp);
% figure; imshow(dist3,[]);
% figure;imshow(n2>0)