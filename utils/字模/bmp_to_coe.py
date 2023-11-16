#%%
from PIL import Image
import numpy as np
import matplotlib.pyplot as plt

#%%
# 读取BMP文件
image = Image.open('ASCII.BMP')
# 显示图像


# 将图像转换为NumPy数组
img_array = np.array(image,dtype=np.uint8)
plt.imshow(img_array, cmap='gray')
plt.axis('off')  # 可选择不显示坐标轴
plt.show()

char_array = np.zeros(shape=(94,18,9),dtype=np.uint8)
for i in range(94):
    char_array[i]=img_array[:,i*9:i*9+9]

#%%
# 以写入模式打开文本文件
with open('example.txt', 'w') as f:
    # 写入内容
    f.write("memory_initialization_radix = 2;\n")
    for i in char_array:
        for j in i:
            for k in j:
                f.write(str(k))
            f.write(';\n')
                

#%%
