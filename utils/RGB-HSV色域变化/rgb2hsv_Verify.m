r=6;
g=80;
b=177;
K = 32;
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

disp([h,s,v])


