close all;
clear;
clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Lab 1: Image rectification


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Applying image transformations

% ToDo: create the function  "apply_H" that gets as input a homography and
% an image and returns the image transformed by the homography.
% The size of the transformed image has to be automatically set so as to 
% contain the whole transformed image.
% At some point you will need to interpolate the image values at some points,
% you may use the Matlab function "interp2" for that.


%% 1.1. Similarities
I=imread('Data/0005_s.png'); % we have to be in the proper folder

% ToDo: generate a matrix H which produces a similarity transformation
theta = 30/180*pi;
R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
s = 0.5;
t = [10,20];
H = [s*R(1,1),  s*R(1,2),  t(1);
     s*R(2,1),  s*R(2,2),  t(2);
     0,  0,  1];

[I2, minX, minY] = apply_H(I, H);
figure; imshow(I); figure; imshow(uint8(I2));


%% 1.2. Affinities

% ToDo: generate a matrix H which produces an affine transformation
A = [0.5, -0.25; 0.25, 0.5];
t = [10,20];
H = [A(1,1),  A(1,2),  t(1);
     A(2,1),  A(2,2),  t(2);
     0,  0,  1];

[I2, minX, minY] = apply_H(I, H);
figure; imshow(I); figure; imshow(uint8(I2));

% ToDo: decompose the affinity in four transformations: two
% rotations, a scale, and a translation
[U,D,V] = svd(A);  % A = (U*V')*(V*D*V') = R1*R2'*D*R2
R1 = U*V';
R2 = V';

Hrot1 = [R1(1,1), R1(1,2), 0;
         R1(2,1), R1(2,2), 0;
         0, 0, 1];
     
Hrot2 = [R2(1,1), R2(1,2), 0;
         R2(2,1), R2(2,2), 0;
         0, 0, 1];
     
Hscale = [D(1,1), D(1,2), 0;
          D(2,1), D(2,2), 0;
          0, 0, 1];
      
Htrans = [1, 0, t(1);
          0, 1, t(2);
          0, 0, 1];

% ToDo: verify that the product of the four previous transformations
% produces the same matrix H as above
H2 = Htrans*Hrot1*Hrot2'*Hscale*Hrot2;
assert(max(abs(H2-H),[],'all') < 1e-10);

% ToDo: verify that the proper sequence of the four previous
% transformations over the image I produces the same image I2 as before
[I3, minX, minY] = apply_H(I, Hrot2);
[I3, minX, minY] = apply_H(I3, Hscale);
[I3, minX, minY] = apply_H(I3, Hrot2');
[I3, minX, minY] = apply_H(I3, Hrot1);
[I3, minX, minY] = apply_H(I3, Htrans);
figure; imshow(uint8(I3));  % the result is blurrier due to successive interpolations


%% 1.3 Projective transformations (homographies)

% ToDo: generate a matrix H which produces a projective transformation
A = [0.5, -0.25; 0.25, 0.5];
t = [10,20];
v = [0,0.0005];
H = [A(1,1),  A(1,2),  t(1);
     A(2,1),  A(2,2),  t(2);
     v(1),  v(2),  1];

[I2, minX, minY] = apply_H(I, H);
figure; imshow(I); figure; imshow(uint8(I2));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Affine Rectification
% choose the image points
I = imread('Data/0000_s.png');
A = load('Data/0000_s_info_lines.txt');

% indices of lines
i = 424;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
i = 240;
p3 = [A(i,1) A(i,2) 1]';
p4 = [A(i,3) A(i,4) 1]';
i = 712;
p5 = [A(i,1) A(i,2) 1]';
p6 = [A(i,3) A(i,4) 1]';
i = 565;
p7 = [A(i,1) A(i,2) 1]';
p8 = [A(i,3) A(i,4) 1]';

% ToDo: compute the lines l1, l2, l3, l4, that pass through the different pairs of points
l1 = cross(p1,p2);
l2 = cross(p3,p4);
l3 = cross(p5,p6);
l4 = cross(p7,p8);
l5 = cross(p1,p4);
l6 = cross(p2,p3);

% show the chosen lines in the image
figure;imshow(I);
hold on;
t=1:0.1:1000;
plot(t, -(l1(1)*t + l1(3)) / l1(2), 'y');
plot(t, -(l2(1)*t + l2(3)) / l2(2), 'y');
plot(t, -(l3(1)*t + l3(3)) / l3(2), 'y');
plot(t, -(l4(1)*t + l4(3)) / l4(2), 'y');
hold off;

% ToDo: compute the homography that affinely rectifies the image
v1 = cross(l1,l2);
v2 = cross(l3,l4);
linf = cross(v1,v2);
linf = linf / linf(3);  % why does this need to be normalized?
 
Hpa = [1, 0, 0; 0, 1, 0; linf'];
 
[I2, minX, minY] = apply_H(I, Hpa);
figure; imshow(uint8(I2));

% ToDo: compute the transformed lines lr1, lr2, lr3, lr4
lr1 = Hpa'\l1;
lr2 = Hpa'\l2;
lr3 = Hpa'\l3;
lr4 = Hpa'\l4;
lr5 = Hpa'\l5;
lr6 = Hpa'\l6;

% show the transformed lines in the transformed image
figure;imshow(uint8(I2));
hold on;
t=1:0.1:1000;
plot(t, -(lr1(1)*t + lr1(3)) / lr1(2), 'y');
plot(t, -(lr2(1)*t + lr2(3)) / lr2(2), 'y');
plot(t, -(lr3(1)*t + lr3(3)) / lr3(2), 'g');
plot(t, -(lr4(1)*t + lr4(3)) / lr4(2), 'g');
plot(t, -(lr5(1)*t + lr5(3)) / lr5(2), 'c');
plot(t, -(lr6(1)*t + lr6(3)) / lr6(2), 'c');
hold off;

% ToDo: to evaluate the results, compute the angle between the different pair 
% of lines before and after the image transformation
angle_l1_l2 = angle_between_lines(l1,l2)/pi*180;
angle_lr1_lr2 = angle_between_lines(lr1,lr2)/pi*180;

angle_l3_l4 = angle_between_lines(l3,l4)/pi*180;
angle_lr3_lr4 = angle_between_lines(lr3,lr4)/pi*180;

angle_l1_l3 = angle_between_lines(l1,l3)/pi*180;
angle_l2_l4 = angle_between_lines(l2,l4)/pi*180;

fprintf('Angle between (l1, l2): %.2f -> %.2f\n', angle_l1_l2, angle_lr1_lr2);
fprintf('Angle between (l3, l4): %.2f -> %.2f\n', angle_l3_l4, angle_lr3_lr4);

assert(angle_lr1_lr2 == 0);
assert(angle_lr3_lr4 == 0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Metric Rectification

%% 3.1 Metric rectification after the affine rectification (stratified solution)

% ToDo: Metric rectification (after the affine rectification) using two non-parallel orthogonal line pairs
%       As evaluation method you can display the images (before and after
%       the metric rectification) with the chosen lines printed on it.
%       Compute also the angles between the pair of lines before and after
%       rectification.

lr1 = [lr1(1) / lr1(3), lr1(2)/lr1(3), 1];
lr2 = [lr2(1) / lr2(3), lr2(2)/lr2(3), 1];
lr3 = [lr3(1) / lr3(3), lr3(2)/lr3(3), 1];
lr4 = [lr4(1) / lr4(3), lr4(2)/lr4(3), 1];
lr5 = [lr5(1) / lr5(3), lr5(2)/lr5(3), 1];
lr6 = [lr6(1) / lr6(3), lr6(2)/lr6(3), 1];

lm1 = [lr5(1)*lr6(1), lr5(1)*lr6(2) + lr5(2)*lr6(1), lr5(2)*lr6(2)];
lm2 = [lr2(1)*lr4(1), lr2(1)*lr4(2) + lr2(2)*lr4(1), lr2(2)*lr4(2)];

% compute angle between pairs of lines before rectification
theta_init_l1_l2 = angle_between_lines(lr1,lr2)/pi*180;
theta_init_l3_l4 = angle_between_lines(lr3,lr4)/pi*180;
theta_init_l1_l3 = angle_between_lines(lr1,lr3)/pi*180;
theta_init_l2_l4 = angle_between_lines(lr2,lr4)/pi*180;

A = [lm1(1:2); lm2(1:2)];
b = -[lm1(3); lm2(3)];
sol = linsolve(A, b);

S = [sol(1) sol(2); sol(2) 1];
R = chol(inv(S));

Ha = [R [0;0]; 0 0 1];
H3 = Ha*Hpa;
[I3, minX, minY] = apply_H(I, H3);

% compute the lines from the transformed points
lr1 = H3'\l1;
lr2 = H3'\l2;
lr3 = H3'\l3;
lr4 = H3'\l4;
lr5 = H3'\l5;
lr6 = H3'\l6;

lr1 = [lr1(1) / lr1(3), lr1(2)/lr1(3), 1];
lr2 = [lr2(1) / lr2(3), lr2(2)/lr2(3), 1];
lr3 = [lr3(1) / lr3(3), lr3(2)/lr3(3), 1];
lr4 = [lr4(1) / lr4(3), lr4(2)/lr4(3), 1];
lr5 = [lr5(1) / lr5(3), lr5(2)/lr5(3), 1];
lr6 = [lr6(1) / lr6(3), lr6(2)/lr6(3), 1];

figure; imshow(uint8(I3));
hold on;
t=1:0.1:1000;
plot(t, -(lr1(1)*t + lr1(3)) / lr1(2), 'y');
plot(t, -(lr2(1)*t + lr2(3)) / lr2(2), 'y');
plot(t, -(lr3(1)*t + lr3(3)) / lr3(2), 'g');
plot(t, -(lr4(1)*t + lr4(3)) / lr4(2), 'g');
plot(t, -(lr5(1)*t + lr5(3)) / lr5(2), 'c');
plot(t, -(lr6(1)*t + lr6(3)) / lr6(2), 'c');
hold off;

% compute angle between pairs of lines after rectification
theta_fin_l1_l2 = angle_between_lines(lr1,lr2)/pi*180;
theta_fin_l3_l4 = angle_between_lines(lr3,lr4)/pi*180;
theta_fin_l1_l3 = angle_between_lines(lr1,lr3)/pi*180;
theta_fin_l2_l4 = angle_between_lines(lr2,lr4)/pi*180;


disp('Angles after metric rectification:')

disp(['Angle between l1 and l2 before transformation (parallel): ', num2str(theta_init_l1_l2),' - after transformation: ', num2str(theta_fin_l1_l2)])
disp(['Angle between l3 and l4 before transformation (parallel): ', num2str(theta_init_l3_l4),' - after transformation: ', num2str(theta_fin_l3_l4)])
disp(['Angle between l1 and l3 before transformation (orthogonal): ', num2str(theta_init_l1_l3),' - after transformation: ', num2str(theta_fin_l1_l3)])
disp(['Angle between l2 and l4 before transformation (orthogonal): ', num2str(theta_init_l2_l4),' - after transformation: ', num2str(theta_fin_l2_l4)])

disp(['Angle between l1 and l2 before rectification (parallel): ', num2str(angle_l1_l2),' - after rectification: ', num2str(theta_fin_l1_l2)])
disp(['Angle between l3 and l4 before rectification (parallel): ', num2str(angle_l3_l4),' - after rectification: ', num2str(theta_fin_l3_l4)])
disp(['Angle between l1 and l3 before rectification (orthogonal): ', num2str(angle_l1_l3),' - after rectification: ', num2str(theta_fin_l1_l3)])
disp(['Angle between l2 and l4 before rectification (orthogonal): ', num2str(angle_l2_l4),' - after rectification: ', num2str(theta_fin_l2_l4)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Affine and Metric Rectification of the left facade of image 0001

close all
clear all
clc
% ToDo: Write the code that rectifies the left facade of image 0001 with
%       the stratified method (affine + metric). 
%       Crop the initial image so that only the left facade is visible.
%       Show the (properly) transformed lines that are used in every step.


% choose the image points
I=imread('Data/0001_s.png');
A = load('Data/0001_s_info_lines.txt');

I = I(:, 1:450, :);

% indices of lines
i = 614;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
i = 159;
p3 = [A(i,1) A(i,2) 1]';
p4 = [A(i,3) A(i,4) 1]';
i = 645;
p5 = [A(i,1) A(i,2) 1]';
p6 = [A(i,3) A(i,4) 1]';
i = 541;
p7 = [A(i,1) A(i,2) 1]';
p8 = [A(i,3) A(i,4) 1]';

% compute the lines l1, l2, l3, l4, that pass through the different pairs of points

l1 = cross(p1,p2);
l2 = cross(p3,p4);
l3 = cross(p5,p6);
l4 = cross(p7,p8);

% Crossed lines
p9 = cross(l1, l3);
p10 = cross(l1, l4);
p11 = cross(l2, l3);
p12 = cross(l2, l4);
l5 = cross(p9, p12);
l6 = cross(p10, p11);

% show the chosen lines in the image
figure;imshow(I);
hold on;
t=1:0.1:1000;
plot(t, -(l1(1)*t + l1(3)) / l1(2), 'y');
plot(t, -(l2(1)*t + l2(3)) / l2(2), 'y');
plot(t, -(l3(1)*t + l3(3)) / l3(2), 'y');
plot(t, -(l4(1)*t + l4(3)) / l4(2), 'y');
plot(t, -(l5(1)*t + l5(3)) / l5(2), 'y');
plot(t, -(l6(1)*t + l6(3)) / l6(2), 'y');

% ToDo: compute the homography that affinely rectifies the image

v1 = cross(l1,l2);
v2 = cross(l3,l4);
 
linf = cross(v1, v2);
linf = linf/linf(3);

Hpa = [1 0 0; 0 1 0; linf'];
 
[I2, minX, minY] = apply_H(I, Hpa);
figure; imshow(uint8(I2));

% ToDo: compute the transformed lines lr1, lr2, lr3, lr4
lr1 = Hpa'\l1;
lr2 = Hpa'\l2;
lr3 = Hpa'\l3;
lr4 = Hpa'\l4;
lr5 = Hpa'\l5;
lr6 = Hpa'\l6;

% show the transformed lines in the transformed image
figure;imshow(uint8(I2));
hold on;
t=1:0.1:1000;
plot(t, -(lr1(1)*t + lr1(3)) / lr1(2), 'y');
plot(t, -(lr2(1)*t + lr2(3)) / lr2(2), 'y');
plot(t, -(lr3(1)*t + lr3(3)) / lr3(2), 'g');
plot(t, -(lr4(1)*t + lr4(3)) / lr4(2), 'g');
plot(t, -(lr5(1)*t + lr5(3)) / lr5(2), 'c');
plot(t, -(lr6(1)*t + lr6(3)) / lr6(2), 'c');

% ToDo: to evaluate the results, compute the angle between the different pair 
% of lines before and after the image transformation
theta_l1_l2 = angle_between_lines(l1,l2)/pi*180;
theta_lr1_lr2 = angle_between_lines(lr1,lr2)/pi*180;

theta_l3_l4 = angle_between_lines(l3,l4)/pi*180;
theta_lr3_lr4 = angle_between_lines(lr3,lr4)/pi*180;

theta_l1_l3 = angle_between_lines(l1,l3)/pi*180;
theta_l2_l4 = angle_between_lines(l2,l4)/pi*180;
% 
disp(['Angle between l1 and l2 before transformation: ', num2str(theta_l1_l2),' - after transformation: ', num2str(theta_lr1_lr2)])
disp(['Angle between l3 and l4 before transformation: ', num2str(theta_l3_l4),' - after transformation: ', num2str(theta_lr3_lr4)])


%Metric rectification
lrr1 = [lr1(1) / lr1(3), lr1(2)/lr1(3), 1];
lrr2 = [lr2(1) / lr2(3), lr2(2)/lr2(3), 1];
lrr3 = [lr3(1) / lr3(3), lr3(2)/lr3(3), 1];
lrr4 = [lr4(1) / lr4(3), lr4(2)/lr4(3), 1];
lrr5 = [lr5(1) / lr5(3), lr5(2)/lr5(3), 1];
lrr6 = [lr6(1) / lr6(3), lr6(2)/lr6(3), 1];

lm1 = [lrr5(1)*lrr6(1), lrr5(1)*lrr6(2) + lrr5(2)*lrr6(1), lrr5(2)*lrr6(2)];
lm2 = [lrr1(1)*lrr3(1), lrr1(1)*lrr3(2) + lrr1(2)*lrr3(1), lrr1(2)*lrr3(2)];
% lm2 = [lr2(1)*lr4(1), lr2(1)*lr4(2) + lr2(2)*lr4(1), lr2(2)*lr4(2)];

% compute angle between pairs of lines before rectification
theta_init_l1_l2 = angle_between_lines(lr1,lr2)/pi*180;
theta_init_l3_l4 = angle_between_lines(lr3,lr4)/pi*180;
theta_init_l1_l3 = angle_between_lines(lr1,lr3)/pi*180;
theta_init_l2_l4 = angle_between_lines(lr2,lr4)/pi*180;

A = [lm1(1:2); lm2(1:2)];
b = -[lm1(3); lm2(3)];
sol = linsolve(A, b);

S = [sol(1) sol(2); sol(2) 1];
R = chol(S, 'lower');

Ha = [R [0;0]; 0 0 1];
H3 = inv(Ha);
[I3, minX, minY] = apply_H(I2, H3);

% compute the lines from the transformed points
lr1 = H3'\lr1;
lr2 = H3'\lr2;
lr3 = H3'\lr3;
lr4 = H3'\lr4;
lr5 = H3'\lr5;
lr6 = H3'\lr6;

lr1 = [lr1(1) / lr1(3), lr1(2)/lr1(3), 1];
lr2 = [lr2(1) / lr2(3), lr2(2)/lr2(3), 1];
lr3 = [lr3(1) / lr3(3), lr3(2)/lr3(3), 1];
lr4 = [lr4(1) / lr4(3), lr4(2)/lr4(3), 1];
lr5 = [lr5(1) / lr5(3), lr5(2)/lr5(3), 1];
lr6 = [lr6(1) / lr6(3), lr6(2)/lr6(3), 1];

figure;imshow(uint8(I3));
hold on;
t=1:0.1:1000;
plot(t, -(lr1(1)*t + lr1(3)+(minY-1)*lr1(2)) / lr1(2), 'y');
plot(t, -(lr2(1)*t + lr2(3)+(minY-1)*lr2(2)) / lr2(2), 'y');
plot(t, -(lr3(1)*t + lr3(3)+(minY-1)*lr3(2)) / lr3(2), 'g');
plot(t, -(lr4(1)*t + lr4(3)+(minY-1)*lr4(2)) / lr4(2), 'g');
plot(t, -(lr5(1)*t + lr5(3)+(minY-1)*lr5(2)) / lr5(2), 'c');
plot(t, -(lr6(1)*t + lr6(3)+(minY-1)*lr6(2)) / lr6(2), 'c');

% compute angle between pairs of lines after rectification
theta_fin_l1_l2 = angle_between_lines(lr1,lr2)/pi*180;
theta_fin_l3_l4 = angle_between_lines(lr3,lr4)/pi*180;
theta_fin_l1_l3 = angle_between_lines(lr1,lr3)/pi*180;
theta_fin_l2_l4 = angle_between_lines(lr2,lr4)/pi*180;

disp('Angles after metric rectification:')

disp(['Angle between l1 and l2 before transformation (parallel): ', num2str(theta_init_l1_l2),' - after transformation: ', num2str(theta_fin_l1_l2)])
disp(['Angle between l3 and l4 before transformation (parallel): ', num2str(theta_init_l3_l4),' - after transformation: ', num2str(theta_fin_l3_l4)])
disp(['Angle between l1 and l3 before transformation (orthogonal): ', num2str(theta_init_l1_l3),' - after transformation: ', num2str(theta_fin_l1_l3)])
disp(['Angle between l2 and l4 before transformation (orthogonal): ', num2str(theta_init_l2_l4),' - after transformation: ', num2str(theta_fin_l2_l4)])

disp(['Angle between l1 and l2 before rectification (parallel): ', num2str(theta_l1_l2),' - after rectification: ', num2str(theta_fin_l1_l2)])
disp(['Angle between l3 and l4 before rectification (parallel): ', num2str(theta_l3_l4),' - after rectification: ', num2str(theta_fin_l3_l4)])
disp(['Angle between l1 and l3 before rectification (orthogonal): ', num2str(theta_l1_l3),' - after rectification: ', num2str(theta_fin_l1_l3)])
disp(['Angle between l2 and l4 before rectification (orthogonal): ', num2str(theta_l2_l4),' - after rectification: ', num2str(theta_fin_l2_l4)])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. OPTIONAL: Metric Rectification in a single step
% Use 5 pairs of orthogonal lines (pages 55-57, Hartley-Zisserman book)

close all
clear all
clc

% choose the image points
I=imread('Data/0001_s.png');
A = load('Data/0001_s_info_lines.txt');

I = I(:, 1:450, :);

% 5 pairs of orthogonal lines
i = 614;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair1a = cross(p1,p2);
i = 541;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair1b = cross(p1,p2);

i = 159;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair2a = cross(p1,p2);
i = 645;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair2b = cross(p1,p2);

i = 188;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair3a = cross(p1,p2);
i = 337;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair3b = cross(p1,p2);

i = 301;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair4a = cross(p1,p2);
i = 298;
p1 = [A(i,1) A(i,2) 1]';
p2 = [A(i,3) A(i,4) 1]';
pair4b = cross(p1,p2);

p1 = cross(pair1a, pair2b);
p2 = cross(pair1a, pair1b);
p3 = cross(pair2a, pair2b);
p4 = cross(pair1b, pair2a);
pair5a = cross(p1, p4);
pair5b = cross(p2, p3);

% show the chosen lines in the image
figure;imshow(I);
hold on;
t=1:0.1:1000;
plot(t, -(pair1a(1)*t + pair1a(3)) / pair1a(2), 'y');
plot(t, -(pair1b(1)*t + pair1b(3)) / pair1b(2), 'y');
plot(t, -(pair2a(1)*t + pair2a(3)) / pair2a(2), 'g');
plot(t, -(pair2b(1)*t + pair2b(3)) / pair2b(2), 'g');
plot(t, -(pair3a(1)*t + pair3a(3)) / pair3a(2), 'c');
plot(t, -(pair3b(1)*t + pair3b(3)) / pair3b(2), 'c');
plot(t, -(pair4a(1)*t + pair4a(3)) / pair4a(2), 'b');
plot(t, -(pair4b(1)*t + pair4b(3)) / pair4b(2), 'b');
plot(t, -(pair5a(1)*t + pair5a(3)) / pair5a(2), 'r');
plot(t, -(pair5b(1)*t + pair5b(3)) / pair5b(2), 'r');

% compute angle between pairs of lines before rectification
theta_init_orthpair1 = angle_between_lines(pair1a,pair1b)/pi*180;
theta_init_orthpair2 = angle_between_lines(pair2a,pair2b)/pi*180;
theta_init_orthpair3 = angle_between_lines(pair3a,pair3b)/pi*180;
theta_init_orthpair4 = angle_between_lines(pair4a,pair4b)/pi*180;
theta_init_orthpair5 = angle_between_lines(pair5a,pair5b)/pi*180;

% compute homography
pair1a = [pair1a(1) / pair1a(3), pair1a(2)/pair1a(3), 1]; % Es necessari normalitzar, sino al
pair1b = [pair1b(1) / pair1b(3), pair1b(2)/pair1b(3), 1]; % solucionar el C = linsolve(A, b)
pair2a = [pair2a(1) / pair2a(3), pair2a(2)/pair2a(3), 1]; % no s'arriba a un resultat correcte 
pair2b = [pair2b(1) / pair2b(3), pair2b(2)/pair2b(3), 1]; % per algun motiu del matlab.
pair3a = [pair3a(1) / pair3a(3), pair3a(2)/pair3a(3), 1];
pair3b = [pair3b(1) / pair3b(3), pair3b(2)/pair3b(3), 1];
pair4a = [pair4a(1) / pair4a(3), pair4a(2)/pair4a(3), 1];
pair4b = [pair4b(1) / pair4b(3), pair4b(2)/pair4b(3), 1];
pair5a = [pair5a(1) / pair5a(3), pair5a(2)/pair5a(3), 1];
pair5b = [pair5b(1) / pair5b(3), pair5b(2)/pair5b(3), 1];

c1 = [pair1a(1)*pair1b(1), (pair1a(1)*pair1b(2)+pair1a(2)*pair1b(1))/2, pair1a(2)*pair1b(2), (pair1a(1)*pair1b(3)+pair1a(3)*pair1b(1))/2, (pair1a(2)*pair1b(3)+pair1a(3)*pair1b(2))/2, pair1a(3)*pair1b(3)];
c2 = [pair2a(1)*pair2b(1), (pair2a(1)*pair2b(2)+pair2a(2)*pair2b(1))/2, pair2a(2)*pair2b(2), (pair2a(1)*pair2b(3)+pair2a(3)*pair2b(1))/2, (pair1a(2)*pair2b(3)+pair2a(3)*pair2b(2))/2, pair2a(3)*pair2b(3)];
c3 = [pair3a(1)*pair3b(1), (pair3a(1)*pair3b(2)+pair3a(2)*pair3b(1))/2, pair3a(2)*pair3b(2), (pair3a(1)*pair3b(3)+pair3a(3)*pair3b(1))/2, (pair1a(2)*pair3b(3)+pair3a(3)*pair3b(2))/2, pair3a(3)*pair3b(3)];
c4 = [pair4a(1)*pair4b(1), (pair4a(1)*pair4b(2)+pair4a(2)*pair4b(1))/2, pair4a(2)*pair4b(2), (pair4a(1)*pair4b(3)+pair4a(3)*pair4b(1))/2, (pair1a(2)*pair4b(3)+pair4a(3)*pair4b(2))/2, pair4a(3)*pair4b(3)];
c5 = [pair5a(1)*pair5b(1), (pair5a(1)*pair5b(2)+pair5a(2)*pair5b(1))/2, pair5a(2)*pair5b(2), (pair5a(1)*pair5b(3)+pair5a(3)*pair5b(1))/2, (pair1a(2)*pair5b(3)+pair5a(3)*pair5b(2))/2, pair5a(3)*pair5b(3)];

A = [c1(1:5); c2(1:5); c3(1:5); c4(1:5); c5(1:5)];
b = -[c1(6); c2(6); c3(6); c4(6); c5(6)];
C = linsolve(A, b);

M = [C(1),  C(2)/2,  C(4)/2;
     C(2)/2,  C(3),  C(5)/2;
     C(4)/2, C(5)/2, 1];

% TODO: find K and v

[I2, minX, minY] = apply_H(I, H);
figure;imshow(I2);

