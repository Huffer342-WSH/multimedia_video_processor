h = 160;
s = 100;
v = 100;
K=32;
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
disp([r,g,b]);