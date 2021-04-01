close all

[filename, pathname] = uigetfile('*.png', 'Válassza ki a szegmentált képet!');
if ~ischar(filename); return; end
filepath = fullfile(pathname, filename);
img_segment = imread(filepath); % Beolvassuk a szegmentált képet.
figure('Name', 'A szegmentalt kép', 'NumberTitle', 'off'); imshow(img_segment);

thr_segment_cell = 127;
bw_seg_cell = img_segment < thr_segment_cell; % Ahol a kép intenzitása kisebb, mint a threshold érték.
bw_seg_cell_2 = imcomplement(bw_seg_cell); % Invertált kép.
bw_seg_cell_3 = bwmorph(bw_seg_cell_2, 'clean'); % Eltávolítja az elkülönített képpontokat.
bw_seg_cell_4 = bwmorph(bw_seg_cell_3, 'close'); % Először erodálást, majd dilatálást végrz a képen.
bw_segment_cell = bw_seg_cell_4;
% figure; imshow(bw_segment_cell);

[n1,num1] = bwlabel(bw_segment_cell); % Felcimkézzük a sejteket.
for i=1:num1
    if sum(sum(n1==i)) < 500  % Ha az adott objektum méret kisebb, mint 500.
       n1(n1==i) = 0;  % Akkor az i-edik cimkével jelzett elemet kinullázzuk, tehát háttér színe lesz.
    end
    if i==1
       n1(n1==i) = 0;  % Az 1-es cimkével jelzett elemet kinullázzuk, amely ez esetben a háttér.
    end
end
% figure; imshow(n);

%A határvonalak meghatározása:
border = and(bw_segment_cell,not(bwmorph(bw_segment_cell, 'erode'))); % Egy pixel nagyságban erodáljuk
                                            % a képet, majd ezt össze ÉS-eljük 
                                            % az eredeti képpel.
% figure; imshow(border);

dist = bwdist(border); % A távolságot más intenzitással jelzi (távolságtranszformáció).
                       % A távolságtranszformáció függvény értelmében egy
                       % olyan távolságtérképet kapunk, amelyben minden
                       % egyes pixelhez, a hozzá legközelebb található
                       % előtétpontnak a távolsága van elmentve.
dist(bw_segment_cell==0) = 0; % A dist legyen egyenlő 0-val ott, ahol a sejten kívül vagyunk.
                 % Távolság értékeink vannak, amelyek a a határvonaltól
                 % befele számolódnak. --> Lokális maximumok számolhatók
                 % ki, amelyek a sejtközéppontok lesznek.
% figure; imshow(dist, []);

h = fspecial('gaussian', 9, 1.7); % Fspecial paranccs által kialakított 
                                  % gausszűrő, 3x3-as mátrix, 1,7-es intenzitással ??
                                  
dist2 = imfilter(dist, h); % Megfilterezzük a képet a lokális maximumok meghatározására.
% figure; imshow(dist2, []);

kp = imregionalmax(dist2); % Maxpontokat/középpontokat megkeresi.
                           % Egy bináris képpel tér vissza, ahol azonosítja
                           % egy szürkesálás kép lokális maximumát.
% figure; imshow(kp);

dist3 = bwdist(kp); % A középpontokból indítunk egy távolságtranszformációt.
% figure; imshow(dist3, []);

dist3(bw_segment_cell==0) = -inf;
% figure; imshow(dist3, []);

L = watershed(dist3, 8); % Feltöltés
% figure; imshow(L);

[n6, num2] = bwlabel(L); % Újra labelezzük a sejteket.

[filename, pathname] = uigetfile('*.png', 'Válassza ki a zöldcsatornás képet!');
if ~ischar(filename); return; end
filepath = fullfile(pathname, filename);
img_green = imread(filepath); % Beolvassuk a zöldcsatornás képet.
% figure; imshow(img_green);

img_gray = rgb2gray(img_green);
red = img_gray;
for i = 1:num2
    if sum(sum(and(n6==i,kp))) == 0 % Ha nincs közös pontja.
        n6(n6==i) = 0;
    end
    red(and(bwmorph(n6==i,'dilate'), not(n6==i))) = 255; % A külső régiók határa.
end
bw_seg_cell_2 = n6 > 0;

[n3,num3] = bwlabel(bw_seg_cell_2);
for i=1:num3
    if sum(sum(n3==i)) < 500  % Ha az adott objektum méret kisebb, mint 500.
        n3(n3==i) = 0;  % Akkor az i-edik cimkével jelzett elemet kinullázzuk, tehát háttér színe lesz.
    end
end

[n4, num4] = bwlabel(n3); % A megmaradt részeket felcimkézzük, amelyek a tényleges sejtek lesznek.
bw_cell = n4;
% figure; imshow(bw_cell);

res = cat(3, red, img_gray, img_gray); % Egyforma méretű tömböket összekapcsol.
% figure; imshow(res);

% A sejtek címkéinek megjelenítése:
s = regionprops(bw_cell, 'Centroid');
figure('Name', 'A zöldcsatornás kép', 'NumberTitle', 'off'); imshow(img_green);
hold on
for i = 1:numel(s)
    c = s(i).Centroid;
    textColor = 'red'; % A számok színe.
    text(c(1), c(2), sprintf('%d', i), ...
        'Color', textColor, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle');
end
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sejtmag intenzitás
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

thr_segment_nucleon = 255;
bw_seg_nuc = img_segment < thr_segment_nucleon; % Ahol a kép intenzitása kisebb, mint a threshold érték.
bw_seg_nuc_inv = imcomplement(bw_seg_nuc); % Invertált kép
bw_seg_nuc_inv_2 = bwmorph(bw_seg_nuc_inv, 'bridge'); % A nem csatlakoztatott képpontokat átállítja.
bw_seg_nuc_inv_3 = bwmorph(bw_seg_nuc_inv_2, 'open'); % Először erodálást, majd dilatálást végrz a képen.
bw_seg_nuc_inv_4 = bwmorph(bw_seg_nuc_inv_3, 'bridge'); % A nem csatlakoztatott képpontokat átállítja.
bw_seg_nuc_inv_5 = bwmorph(bw_seg_nuc_inv_4, 'clean'); % Eltávolítja az elkülönített képpontokat.
bw_seg_nuc_inv_6 = bwmorph(bw_seg_nuc_inv_5, 'close'); % Először dilatálást, majd erodálást végez a képen.
bw_seg_nuc_2 = imcomplement(bw_seg_nuc_inv_6); % Invertált kép
% figure; imshow(bw_seg_nuc_inv_6);

bw_seg_nuc_3 = and(bw_seg_nuc_2, (bwmorph(bw_cell, 'erode', 3)));
% figure; imshow(bw_seg_nuc_3);

% A sejtmagok felcímkézése:
dims = size(bw_cell);
bw_nucleon = zeros(dims, 'double');
for k = 1:num4
    for j=1:dims(2)
        for i=1:dims(1)
           if (and(bw_seg_nuc_3(i,j), bw_segment_cell(i,j)))
                bw_nucleon(i,j) = bw_cell(i,j);
           end
        end
    end
end
% figure; imshow(bw_nucleon);

% A szürkeskálás képre ráteesük az invertált bináris maszkot, 
% majd meghatározzuk a felcímkézett sejtmagok átlagintenzitásértékét.
props_nucleon = regionprops(bw_nucleon, img_gray, 'MeanIntensity');
allIntensities_nucleon = [props_nucleon.MeanIntensity];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sejtplazma intenzitás
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bw_pls = bw_seg_nuc_inv_6;
% figure; imshow(bw_pls);

% A sejtplazmák felcímkézése:
dims = size(bw_cell);
bw_plasma = zeros(dims, 'double');
for k = 1:num4
    for j=1:dims(2)
        for i=1:dims(1)
           if (and(bw_pls(i,j), bw_segment_cell(i,j)))
                bw_plasma(i,j) = bw_cell(i,j);
           end
        end
    end
end
% figure; imshow(bw_plasma);

% A szürkeskálás képre ráteesük az invertált bináris maszkot, 
% majd meghatározzuk a felcímkézett sejtplazmák átlagintenzitásértékét.
props_plasma = regionprops(bw_plasma, img_gray, 'MeanIntensity');
allIntensities_plasma = [props_plasma.MeanIntensity];

% Az intenzitás arány értékek meghatározása:
dims = size(allIntensities_nucleon);
allIntensities_cell = zeros(dims, 'double');
for k = 1: num4
    allIntensities_cell(k) = allIntensities_nucleon(k) / allIntensities_plasma(k);
end

% Az intenzitás értékek megjelenítése:
t_data_cell = array2table(allIntensities_cell'); % Struct táblázattá konvertálása.
% A táblázat megjelenítése egy figure-ben:
fig_cell = uifigure('Name', 'Fluoreszcencia intenzitás értékek', 'Position',[200 200 350 350]);
uit_cell = uitable(fig_cell);
uit_cell.Position = [20 20 310 310];
uit_cell.Data = t_data_cell;
uit_cell.RowName = 'numbered';
uit_cell.ColumnName = 'sejtmag / citoplazma';