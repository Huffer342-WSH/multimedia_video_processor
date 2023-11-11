# 多媒体视频处理魔盒

## 概述

### 开发平台

- **EDA**: Pango Design Suite 2022.2-SP1-Lite
- **FPGA型号**: PGL50H-6FBG484

### 工程结构

```
├─application //上位机
├─bitstream files	//比特流文件备份
├─doc	//文档
├─project	//pango工程目录
│  ├─compile
│  ├─constraint_check
│  ├─generate_bitstream	//生成的比特流文件
│  ├─ipcore	//IP核
│  ├─place_route
│  ├─report_timing
│  ├─Route Constraint Editor
│  └─synthesize
├─sources		//源文件
│  ├─constraints	//约束
│  ├─designs	//可综合源文件
│  │  ├─adjust_color //调整颜色模块
│  │  ├─ddr	//ddr模块
│  │  ├─hdmi	//HDMI输入输出
│  │  ├─image_filiter	//图像滤波
│  │  ├─others	//其它
│  │  ├─ov5640	//摄像头配置、输入、混合
│  │  ├─reset	//复位
│  │  ├─rotate	//图像旋转、缩放、位移
│  │  ├─udp_osd	//UDP通信、OSD显示
│  │  └─zoom	//图像缩放(二次线性插值)
│  └─simulations	//仿真文件
└─utils	//辅助工具
```

