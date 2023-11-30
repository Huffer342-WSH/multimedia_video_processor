import sys

from functools import partial
from PySide6.QtWidgets import QApplication, QWidget, QLabel, QSlider, QLineEdit, QVBoxLayout, QHBoxLayout, QTextEdit, QPushButton
from PySide6.QtGui import QIcon, QFont
from PySide6.QtCore import Qt
from qt_material import apply_stylesheet
import socket
import struct
import splash


class MyWidget(QWidget):
    def __init__(self):

        super().__init__()

        self.initUI()
        self.initUDP()
        
    def initUDP(self):
        self.osd_address = ('192.168.10.10', 1234)
        self.config_address = ('192.168.10.10', 1000)
        # self.osd_address = ('127.0.0.1', 1234)
        # self.config_address = ('127.0.0.1', 1000)
        self.osd_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.config_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    
    def setOSD(self,text):
        # self.osd_socket.send(text)
        self.osd_socket.sendto(text,self.osd_address)
    def setConfig(self,index):
        # print( self.filters_info[index].get("name"),self.values[index])
        data = bytearray(4)
        data[0] = self.filters_info[index]["mem_addr"]
        data[1] = self.filters_info[index]["mem_width"]
        t = struct.pack('<h', self.values[index])
        data[2] = t[0]
        data[3] = t[1]
        self.config_socket.sendto(data,self.config_address)
        


    def initUI(self):
        # 创建14组滑块、标签和输入框
        self.sliders = []
        self.name_labels = []
        self.value_labels = []
        self.line_edits = []
        self.values = [0] * 14  # 存储文本输入框的值

        main_layout = QHBoxLayout()

        # 将 filters_info 设置为类的属性
        self.filters_info = [
            {"name": "滤波器1    ", "default_value": 0, "min_value": 0, "max_value": 4,"mem_addr":0,"mem_width":1},
            {"name": "滤波器2    ", "default_value": 0, "min_value": 0, "max_value": 4,"mem_addr":1,"mem_width":1},
            {"name": "放大系数   ", "default_value": 128, "min_value":1, "max_value": 1023,"mem_addr":2,"mem_width":2},
            {"name": "旋转       ", "default_value": 0, "min_value": 0, "max_value": 255,"mem_addr":4,"mem_width":1},
            {"name": "OSD起始X       ", "default_value": 10, "min_value": 1, "max_value": 1920,"mem_addr":5,"mem_width":2},
            {"name": "OSD起始Y       ", "default_value": 10, "min_value": 2, "max_value": 1000,"mem_addr":7,"mem_width":2},
            {"name": "OSD字符间距", "default_value": 10, "min_value": 9, "max_value": 30,"mem_addr":9,"mem_width":2},
            {"name": "OSD行距    ", "default_value": 20, "min_value": 18, "max_value": 40,"mem_addr":11,"mem_width":2},
            {"name": "缩放系数2  ", "default_value": 128, "min_value": 1, "max_value": 1023,"mem_addr":13,"mem_width":2},
            {"name": "图像位移X  ", "default_value": 0, "min_value": -1920, "max_value": 1920,"mem_addr":15,"mem_width":2},
            {"name": "图像位移Y  ", "default_value": 0, "min_value": -1080, "max_value": 1080,"mem_addr":17,"mem_width":2},
            {"name": "色相H  ", "default_value": 0, "min_value": 0, "max_value": 191,"mem_addr":19,"mem_width":2},
            {"name": "饱和度S  ", "default_value": 0, "min_value": -255, "max_value": 255,"mem_addr":21,"mem_width":2},
            {"name": "亮度V  ", "default_value": 0, "min_value": -255, "max_value": 255,"mem_addr":23,"mem_width":2},
            # 添加其他参数的信息
        ]
        label_name_layout = QVBoxLayout()
        label_value_layout = QVBoxLayout()
        slider_layout = QVBoxLayout()
        line_edit_layout = QVBoxLayout()
        restore_button_layout = QVBoxLayout()
        
        
        main_layout.addLayout(label_name_layout)
        main_layout.addLayout(label_value_layout)
        main_layout.addLayout(slider_layout)
        main_layout.addLayout(line_edit_layout)
        main_layout.addLayout(restore_button_layout)
        for i, filter_info in enumerate(self.filters_info):
            # 创建滑块和标签
            slider = QSlider(Qt.Horizontal)
            label_name = QLabel(f'{filter_info["name"]}')
            label_value = QLabel(f'Value: {filter_info["default_value"]}')
            label_value.setMinimumWidth(90)

            # 设置滑块的范围和默认值
            slider.setMinimum(filter_info["min_value"])
            slider.setMaximum(filter_info["max_value"])
            slider.setValue(filter_info["default_value"])
            slider.setMinimumWidth(200)

            # 创建文本输入框
            line_edit = QLineEdit()
            line_edit.setText(str(filter_info["default_value"]))
            
              # 创建按钮
            restore_button = QPushButton('Restore Default')
            restore_button.clicked.connect(partial(self.restore_default_value, i))



            
            slider.setMinimumHeight(40)


            # 设置布局
            label_name_layout.addWidget(label_name)
            label_value_layout.addWidget(label_value)
            slider_layout.addWidget(slider)
            line_edit_layout.addWidget(line_edit)
            restore_button_layout.addWidget(restore_button)

            # 添加到主布局
            self.sliders.append(slider)
            self.name_labels.append(label_name)
            self.value_labels.append(label_value)
            self.line_edits.append(line_edit)
            
            

            # 连接信号和槽
            slider.valueChanged.connect(lambda value, i=i: self.slider_value_changed(value, i))
            line_edit.textChanged.connect(lambda text, i=i: self.line_edit_text_changed(text, i))

        # 添加文本输入框和按钮
        text_edit = QTextEdit()
        text_edit.setMinimumWidth(500)
        print_button = QPushButton('设置OSD文本')
        print_button.clicked.connect(lambda: self.print_text_to_terminal(text_edit.toPlainText()))

        main_layout.addWidget(text_edit)
        main_layout.addWidget(print_button)

        self.setLayout(main_layout)
        QApplication.setFont(QFont("Arial", 12))
        self.setWindowTitle('多媒体视频处理魔盒上位机')
        self.setWindowIcon(QIcon('D:\Project\Python_Project\多媒体视频处理魔盒上位机\icon.png'))
        self.setGeometry(300, 300, 800, 600)

    def slider_value_changed(self, value, index):
        # 滑块值变化时更新标签和文本输入框
        self.value_labels[index].setText(f'Value: {value}')
        self.line_edits[index].setText(str(value))
        self.values[index] = value  # 更新对应变量的值
        self.setConfig(index)

    def line_edit_text_changed(self, text, index):
        # 文本输入框值变化时更新标签和滑块
        try:
            value = int(text)
            self.value_labels[index].setText(f'Value: {value}')
            self.sliders[index].setValue(value)
            self.values[index] = value  # 更新对应变量的值
            # self.setConfig(index)
        except ValueError:
            # 如果输入非整数，可以在这里处理错误
            pass

    def print_text_to_terminal(self, text):
        # 打印文本框中的内容（ASCII编码）
        # print("Text from Text Edit:")
        # for char in text:
            # print(f"Character: {char}, ASCII Code: {ord(char)}")
        self.setOSD(text.encode())
        
    def restore_default_value(self, index):
        # 恢复默认值
        print("restore_default_value ",index)
        default_value = self.filters_info[index]["default_value"]
        self.sliders[index].setValue(default_value)
        self.line_edits[index].setText(str(default_value))
        self.value_labels[index].setText(f'Value: {default_value}')
        self.values[index] = default_value
        self.setConfig(index)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    apply_stylesheet(app, theme='light_blue.xml', invert_secondary=True)

    ex = MyWidget()
    ex.show()
    sys.exit(app.exec_())
