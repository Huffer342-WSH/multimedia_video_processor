r =255;
g = 0;
b = 0;
x=0;
y=0;
z=0;
K=32;

r = int32(r);
g = int32(g);
b = int32(b);
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
    out_r=max; out_g=med; out_b=min;
elseif(K <= h && h < 2*K)
    n=1;
    med =(2*K-h)*diff/K+min;
    out_g=max; out_r=med; out_b=min;
elseif(2*K <= h && h < 3*K)
    n=2;
    med =(h-2*K)*diff/K+min;
    out_g=max; out_b=med; out_r=min;
elseif(3*K <= h && h < 4*K)
    n=3;
    med =(4*K-h)*diff/K+min;
    out_b=max; out_g=med; out_r=min;
elseif(4*K <= h && h < 5*K)
    n=4;
    med =(h-4*K)*diff/K+min;
    out_b=max; out_r=med; out_g=min;
elseif(5*K <= h && h < 6*K)
    n=5;
    med =(6*K-h)*diff/K+min;
    out_r=max; out_b=med; out_g=min;
end

disp([r,g,b]);
disp([out_r,out_g,out_b]);