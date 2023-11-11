% 读取图片
input_image = imread('img.jpg'); % 请替换 'your_image.jpg' 为你的图片路径

% RGB到HSV转换
hsv_image = my_rgb2hsv(input_image);

% 对HSV通道进行修改
hsv_image = my_hsv_change(hsv_image,0,0,0);

% HSV到RGB转换
output_image = my_hsv2rgb(hsv_image);
% 显示原图
subplot(1, 2, 1);
imshow(input_image);
title('原图');

% 显示修改后的图像
subplot(1, 2, 2);
imshow(output_image);
title('修改后的图像');

% 设置图像标题和调整显示
sgtitle('图片处理结果');


% RGB到HSV的转换函数
function       hsv_image    = my_rgb2hsv(rgb_image)
[rows, cols, ~] = size(rgb_image);
hsv_image = zeros(rows, cols, 3);
K = 32;

for i = 1:rows
    for j = 1:cols
        % 把图片读取出来的8位无符号数转化为32位无符号数，防止运算过程中溢出
        r = uint32(rgb_image(i, j, 1));
        g = uint32(rgb_image(i, j, 2));
        b = uint32(rgb_image(i, j, 3));

        % 分六种情况，得到最大值，中间值，最小值
        if (r >= g && r >= b && g >= b)
            max_val = r;
            med_val = g;
            min_val = b;
            n =0;
        elseif (r >= g && r >= b && b >= g)
            max_val = r;
            med_val = b;
            min_val = g;
            n=5;
        elseif (g >= r && g >= b && r >= b)
            max_val = g;
            med_val = r;
            min_val = b;
            n =1;
        elseif (g >= r && g >= b && b >= r)
            max_val = g;
            med_val = b;
            min_val = r;
            n =2;
        elseif (b >= r && b >= g && r >= g)
            max_val = b;
            med_val = r;
            min_val = g;
            n=4;
        elseif (b >= g && b >=r && g >= r)
            max_val = b;
            med_val = g;
            min_val = r;
            n=3;
        end

        % 计算H
        alphaK = (med_val-min_val)*K/(max_val-min_val);
        if n == 0
            h = 0+alphaK;
        elseif n == 1
            h = 2*K-alphaK;
        elseif n == 2
            h = 2*K+alphaK;
        elseif n == 3
            h = 4*K -alphaK;
        elseif n == 4
            h = 4*K +alphaK;
        elseif n == 5
            h = 6*K-alphaK;
        end

        % 计算S
        if max_val == 0
            s = 0;
        else
            s = (max_val-min_val )*256.0 / max_val;
        end

        if s>=256
            s = 255;
        end

        % 计算V
        v = max_val;

        hsv_image(i, j, 1) = h;
        hsv_image(i, j, 2) = s;
        hsv_image(i, j, 3) = v;
    end
end
hsv_image = uint8(hsv_image);
end

% HSV到RGB的转换函数
function rgb_image = my_hsv2rgb(hsv_image)
[rows, cols, ~] = size(hsv_image);
rgb_image = zeros(rows, cols, 3);
K=32;
for i = 1:rows
    for j = 1:cols
        h = uint32(hsv_image(i, j, 1));
        s = uint32(hsv_image(i, j, 2));
        v = uint32(hsv_image(i, j, 3));

        %得到最大值
        max = v;
        %得到最大值和最小值的差
        diff = s*v/256;
        %得到最小值
        min = v-diff;

        %根据H的大小，分六种情况，得到中间值并确定RGB的大小顺序
        if(0 <= h && h < K)
            n=0;
            med = h*diff/K+min;
            r=max; g=med; b=min;
        elseif(K <= h && h < 2*K)
            n=1;
            med =(2*K-h)*diff/K+min;
            g=max; r=med; b=min;
        elseif(2*K <= h && h < 3*K)
            n=2;
            med =(h-2*K)*diff/K+min;
            g=max; b=med; r=min;
        elseif(3*K <= h && h < 4*K)
            n=3;
            med =(4*K-h)*diff/K+min;
            b=max; g=med; r=min;
        elseif(4*K <= h && h < 5*K)
            n=4;
            med =(h-4*K)*diff/K+min;
            b=max; r=med; g=min;
        elseif(5*K <= h && h < 6*K)
            n=5;
            med =(6*K-h)*diff/K+min;
            r=max; b=med; g=min;
        end
        %disp([r,g,b]);
        rgb_image(i, j, 1) = r;
        rgb_image(i, j, 2) = g;
        rgb_image(i, j, 3) = b;
    end
end
rgb_image = uint8(rgb_image);
end


% HSV到RGB的转换函数
function res = my_hsv_change(hsv_image,x,y,z)
[rows, cols, ~] = size(hsv_image);
res = zeros(rows, cols, 3);
K=32;
for i = 1:rows
    for j = 1:cols
        h = hsv_image(i, j, 1);
        s = hsv_image(i, j, 2);
        v = hsv_image(i, j, 3);
        if(h+x <0)
            h= h+192+x;
        elseif(x>=192-h)
            h = x+h-192;
        else
            h = h+x;
        end

        if(s+y>=256)
            s = 255;
        elseif(s+y<0)
            s = 0;
        else
            s = s+y;
        end

        if(v+z>=256)
            v =255;
        elseif(s+z<0)
            v = 0;
        else
            v = v+z;
        end

        res(i, j, 1) = h;
        res(i, j, 2) = s;
        res(i, j, 3) = v;

    end
end
res = uint8(res);
end

