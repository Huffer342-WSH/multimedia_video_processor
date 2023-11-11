#%%
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import matplotlib.pyplot as plt

x_off = 3
y_off = 2
width = 9
height = 18
# 定义字符集及其对应的像素矩阵
characters = np.zeros(shape=(height*94,width),dtype=np.uint8)
j=0
for i in range(ord('!'), ord('~') + 1):
    char_image = Image.new('1', (32, 32), color=1)
    draw = ImageDraw.Draw(char_image)
    font = ImageFont.truetype('CascadiaMono.ttf',17)
    draw.text((2, -1), chr(i), font=font)
    characters[j*height:j*height+height,:]=np.reshape(char_image.getdata(),newshape=(32, 32))[y_off:y_off+height,x_off:x_off+width]
    j=j+1

plt.imshow(characters, cmap='gray')

plt.axis('off')  # 可选择不显示坐标轴
plt.show()

#%%
# 将像素矩阵写入COE文件
with open('ascii.coe', 'w') as f:
    f.write(';每个字符18*9(考虑到紫光RAM是9bit位宽),位宽9bit,深度1692,包含从ACSII 33~126 的所有字符(! --> ~)\n')
    f.write('memory_initialization_radix=2;\n')
    f.write('memory_initialization_vector=\n')
    for image_data in characters:
        binary_str = ''.join(str(pixel) for pixel in image_data)
        f.write(binary_str + ',\n')
    f.write(';')

with open('ascii.dat', 'w') as f:
    f.write('////每个字符18*9(考虑到紫光RAM是9bit位宽),位宽9bit,深度1692,包含从ACSII 33~126 的所有字符(! --> ~)\n')
    i = 0
    for image_data in characters:
        binary_str = ''.join(str(pixel) for pixel in image_data)
        f.write(binary_str+ '\n')
        i=i+1
    for j in range(i,2048):
        f.write("111111111\n")
