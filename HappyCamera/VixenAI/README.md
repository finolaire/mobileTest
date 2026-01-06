# 📸 Vixen AI - 智能相机应用

一款以相机功能为核心的 iOS 应用，提供流畅的拍照体验和照片管理功能。

## ✨ 主要功能

### 1. 首页
- 🎨 精美的渐变背景设计
- 💫 大尺寸拍照按钮，带脉动动画效果
- ✨ 流畅的点击交互动画
- 🎯 突出相机核心功能

### 2. 拍照功能
- 📷 实时相机预览
- 🔄 前后摄像头切换
- 📸 高质量照片拍摄
- 🔁 重拍功能
- ✅ 确认保存功能
- 🎭 支持竖屏拍摄

### 3. 照片保存
- 💾 自动保存到系统相册
- 🔐 智能权限管理
- ⚡️ 保存进度显示
- ✅ 保存成功提示
- ❌ 错误处理和提示
- 🚀 支持批量保存

### 4. 权限管理
- 📹 相机权限请求和检测
- 📱 相册权限请求和检测
- ⚙️ 一键跳转系统设置
- 💬 友好的权限提示文案

## 🏗️ 项目架构

采用 MVVM 架构，遵循 Vixen 命名规范：

```
VixenAI/
├── VixenSchemas/           # 数据模型层
│   ├── VixenUserSchema.swift
│   └── VixenImageSchema.swift
│
├── VixenCanvases/          # 视图层
│   ├── VixenBaseModule.swift
│   ├── VixenHomeCanvas.swift
│   └── VixenCaptureCanvas.swift
│
├── VixenPresenters/        # 视图模型层
│   └── VixenHomePresenter.swift
│
├── VixenOperators/         # 服务/管理层
│   ├── VixenCameraOperator.swift
│   ├── VixenPhotoOperator.swift
│   └── VixenStorageOperator.swift
│
├── VixenGateway/           # 网络层
│   ├── VixenAPI.swift
│   └── VixenGatewayManager.swift
│
├── VixenAccessories/       # 工具/扩展
│   ├── VixenViewAccessory.swift
│   ├── VixenImageAccessory.swift
│   ├── VixenDateAccessory.swift
│   └── VixenStringAccessory.swift
│
└── VixenMaterials/         # 资源配置
    ├── VixenLanguageConfig.swift
    └── VixenColorConfig.swift
```

## 🛠️ 技术栈

- **UI 框架**: SwiftUI
- **网络请求**: Moya + Alamofire
- **数据解析**: HandyJSON
- **图片加载**: Kingfisher
- **相机功能**: AVFoundation
- **照片保存**: Photos Framework
- **包管理**: CocoaPods

## 📝 核心类说明

### VixenCameraOperator
相机管理器，负责：
- 相机会话管理
- 照片拍摄
- 摄像头切换
- 权限检查

### VixenPhotoOperator
照片管理器，负责：
- 保存照片到相册
- 相册权限管理
- 批量保存照片
- 添加水印功能

### VixenHomeCanvas
首页视图，特点：
- 超大拍照按钮（160px）
- 持续脉动动画
- 多层视觉效果
- 弹性交互动画

### VixenCaptureCanvas
拍照界面视图，功能：
- 相机预览层
- 拍照操作
- 照片预览
- 保存确认

## 🎨 设计特点

1. **视觉焦点突出**
   - 大尺寸按钮设计
   - 脉动动画吸引注意
   - 渐变边框和阴影效果

2. **交互反馈完善**
   - 按钮点击缩放动画
   - 保存进度显示
   - 成功/失败提示

3. **用户体验优化**
   - 权限引导流程
   - 错误处理机制
   - 一键跳转设置

## 🔐 权限配置

应用需要以下权限：

1. **相机权限** (`NSCameraUsageDescription`)
   - 用途：进行拍照功能
   
2. **相册权限** (`NSPhotoLibraryAddUsageDescription`)
   - 用途：保存拍摄的照片

## 🚀 运行项目

1. 确保已安装 CocoaPods
2. 在项目目录运行 `pod install`
3. 打开 `VixenAI.xcworkspace`
4. 选择模拟器或真机
5. 运行项目 (⌘ + R)

## 📱 使用流程

1. **启动应用**
   - 显示首页，中央显示大尺寸拍照按钮

2. **开始拍照**
   - 点击拍照按钮
   - 首次使用会请求相机权限
   - 进入相机界面

3. **拍摄照片**
   - 点击底部拍照按钮拍摄
   - 可切换前后摄像头
   - 可点击返回按钮退出

4. **保存照片**
   - 拍照后预览照片
   - 点击"重拍"可重新拍摄
   - 点击"确认"保存到相册
   - 首次保存会请求相册权限
   - 显示保存进度
   - 保存成功后自动关闭

## 🎯 后续功能扩展

- [ ] 照片滤镜
- [ ] 照片编辑
- [ ] 照片美颜
- [ ] AI 智能识别
- [ ] 云端上传
- [ ] 照片分享
- [ ] 相册管理
- [ ] 视频录制

## 📄 开源协议

MIT License

## 👨‍💻 开发者

Vixen AI Team

