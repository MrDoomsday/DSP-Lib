close all
clear all
clc


%% init values
iteration = 16;
x0 = 1000;
y0 = 1000;
angle = pi/4;


%% variables
x = zeros(iteration,1);
y = zeros(iteration,1);
z = zeros(iteration,1);

x(1) = x0;
y(1) = y0;
z(1) = angle;

%% calc
for i = 1:iteration-1
    disp(num2str(atan(1/2^(i-1))));
    if(z(i) < 0)
        x(i+1,1) = x(i,1) + y(i,1)/2^(i-1);
        y(i+1,1) = y(i,1) - x(i,1)/2^(i-1);
        z(i+1,1) = z(i,1) + atan(1/2^(i-1));
    else
        x(i+1,1) = x(i,1) - y(i,1)/2^(i-1);
        y(i+1,1) = y(i,1) + x(i,1)/2^(i-1);
        z(i+1,1) = z(i,1) - atan(1/2^(i-1));
    end
end

% coefficient deformation
x1 = 0.6073*x(iteration,1);
y1 = 0.6073*y(iteration,1);


disp("x1 = " + num2str(x1) + ", y1 = " + num2str(y1));