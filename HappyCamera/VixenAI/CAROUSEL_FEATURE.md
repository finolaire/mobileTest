# 🎡 3D 轮播选择器功能说明

## 📸 功能概述

将原来的单一拍照按钮改造为类似"地球仪"的 3D 轮播选择器，展示 4 种不同的拍摄模式（v_01 到 v_04），用户可以滑动选择并点击进入拍照界面。

## ✨ 核心特性

### 1. 3D 轮播效果
- **视觉效果**：卡片在滑动时呈现 3D 旋转效果
- **透视变换**：远离中心的卡片会缩小、透明度降低
- **旋转动画**：卡片随位置变化进行 Y 轴旋转
- **平滑过渡**：使用 Spring 动画实现流畅的过渡

### 2. 交互方式

#### 滑动操作
- **向左滑动**：显示下一个模式
- **向右滑动**：显示上一个模式
- **拖拽跟随**：卡片会跟随手指移动
- **阈值判断**：滑动超过 50px 才会切换

#### 点击操作
- **点击中间卡片**：进入拍照界面
- **点击侧边卡片**：将该卡片移到中间
- **震动反馈**：点击时有触觉反馈

### 3. 四种拍摄模式

| 模式 | 名称 | 图标 | 渐变色 |
|------|------|------|--------|
| v_01 | 标准拍摄 | camera.fill | 紫色渐变 |
| v_02 | 人像模式 | camera.circle.fill | 粉红渐变 |
| v_03 | 夜景模式 | camera.metering.matrix | 蓝色渐变 |
| v_04 | 全景模式 | camera.aperture | 绿色渐变 |

## 🎨 视觉设计

### 卡片样式
```
┌──────────────┐
│              │
│   📷 图标     │  ← 相机图标（60px）
│              │
│   v_01       │  ← 模式名称（24px）
│   标准拍摄   │  ← 模式说明（14px）
│              │
└──────────────┘
  200×280px
  圆角 20px
  渐变背景
  深色阴影
```

### 3D 变换效果
```
远处卡片        中间卡片        远处卡片
  (0.7x)         (1.0x)         (0.7x)
  30% 透明       不透明          30% 透明
  Y轴旋转        正面            Y轴旋转
```

### 页面指示器
```
○ ● ○ ○  ← 圆点指示器
  ^当前位置
```

## 🔧 技术实现

### 核心组件

#### VixenCarouselSelector.swift
3D 轮播选择器主组件
- **输入参数**：
  - `items: [VixenCarouselItem]` - 轮播项数据
  - `onItemSelected: (VixenCarouselItem) -> Void` - 选择回调
- **状态管理**：
  - `currentIndex` - 当前显示的项索引
  - `dragOffset` - 拖拽偏移量

#### VixenCarouselItem
轮播项数据模型
```swift
struct VixenCarouselItem: Identifiable {
    let id: UUID
    let imageName: String  // v_01, v_02, v_03, v_04
    let title: String      // 拍摄模式标题
}
```

### 计算逻辑

#### 1. 位置计算
```swift
// 卡片相对中心的偏移量
let itemOffset = CGFloat(index - currentIndex) * (itemWidth + spacing) + dragOffset

// 距离中心的距离
let distance = abs(itemOffset)
```

#### 2. 缩放比例
```swift
// 根据距离计算缩放比例（最小 0.7）
let scale = max(0.7, 1 - distance / 500)
```

#### 3. 透明度
```swift
// 根据距离计算透明度（最小 0.3）
let opacity = max(0.3, 1 - distance / 400)
```

#### 4. 旋转角度
```swift
// Y 轴旋转角度
let rotation = Double(itemOffset / 10)
```

### 动画配置

```swift
// Spring 弹性动画
Animation.spring(response: 0.5, dampingFraction: 0.7)

// 特点：
// - response: 0.5秒完成动画
// - dampingFraction: 0.7 阻尼系数（轻微回弹）
```

## 🎯 用户体验优化

### 1. 触觉反馈
```swift
let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
impactFeedback.impactOccurred()
```
- 点击选中时触发震动反馈
- 增强交互感受

### 2. 延迟跳转
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
    navigateToCaptureCanvas = true
}
```
- 让用户看到选中效果
- 避免立即跳转的突兀感

### 3. 拍摄模式显示
在拍照界面顶部显示当前选中的模式：
```
┌──────────────────┐
│ ✕  [人像模式]  🔄 │  ← 顶部栏显示模式
│     [v_02]        │
└──────────────────┘
```

### 4. 页面指示器
- 当前页：白色实心圆（12px）
- 其他页：半透明圆（8px）
- 平滑的大小过渡动画

## 📱 界面布局

```
┌───────────────────────┐
│                       │
│    🎯 Logo (80px)     │  ← 标题区域（缩小）
│    Vixen AI           │
│    欢迎使用           │
│                       │
├───────────────────────┤
│                       │
│  滑动选择拍摄模式     │  ← 提示文字
│                       │
│    ┌─┐  ┌──┐  ┌─┐    │  ← 3D 轮播（主要区域）
│    │ │  │██│  │ │    │
│    └─┘  └──┘  └─┘    │
│                       │
│      ○ ● ○ ○         │  ← 页面指示器
│                       │
└───────────────────────┘
```

## 🎬 动画流程

### 滑动切换流程
```
1. 手指按下
   ↓
2. 拖拽移动（卡片跟随移动）
   ↓
3. 手指抬起
   ↓
4. 判断滑动距离
   ↓
5. 是否超过阈值？
   ├─ 是 → 切换到下一个/上一个
   └─ 否 → 回弹到原位
   ↓
6. Spring 动画过渡
   ↓
7. 完成
```

### 点击选择流程
```
1. 点击卡片
   ↓
2. 是中间卡片？
   ├─ 是 → 触发震动反馈
   │        ↓
   │      延迟 0.2 秒
   │        ↓
   │      进入拍照界面
   │
   └─ 否 → 滚动到该卡片
            ↓
          使用 Spring 动画
```

## 🔄 与拍照界面的集成

### 数据传递
```swift
VixenCaptureCanvas(captureMode: selectedMode)
```
- 将选中的模式传递给拍照界面
- 在拍照界面顶部显示模式信息

### 模式信息显示
- **位置**：顶部中央
- **内容**：模式标题 + 模式名称
- **样式**：半透明胶囊背景 + 白色边框

## 🎨 渐变色配置

### v_01 - 标准拍摄
```swift
[Color(hex: "#667eea"), Color(hex: "#764ba2")]
// 深紫色 → 深紫色
```

### v_02 - 人像模式
```swift
[Color(hex: "#f093fb"), Color(hex: "#f5576c")]
// 粉紫色 → 粉红色
```

### v_03 - 夜景模式
```swift
[Color(hex: "#4facfe"), Color(hex: "#00f2fe")]
// 天蓝色 → 青色
```

### v_04 - 全景模式
```swift
[Color(hex: "#43e97b"), Color(hex: "#38f9d7")]
// 绿色 → 青绿色
```

## 📊 性能优化

### 1. 视图复用
- 使用 `ForEach` 动态生成卡片
- 只渲染可见和临近的卡片

### 2. 动画优化
- 使用 `withAnimation` 批量更新
- Spring 动画提供自然的物理效果

### 3. 手势处理
- 实时更新拖拽偏移
- 结束时根据阈值判断

## 🚀 后续扩展

### 可以添加的功能
- [ ] 支持垂直滚动
- [ ] 无限循环轮播
- [ ] 自动播放
- [ ] 更多拍摄模式
- [ ] 自定义渐变色
- [ ] 卡片点击放大预览
- [ ] 添加真实图片
- [ ] 模式详情介绍

### 实际图片替换
当有真实图片资源时，替换占位渐变：
```swift
// 替换渐变为真实图片
Image(item.imageName)
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: itemWidth, height: itemHeight)
    .clipShape(RoundedRectangle(cornerRadius: 20))
```

## 🎯 使用说明

### 用户操作流程
1. 启动应用，看到 3D 轮播界面
2. 左右滑动浏览不同拍摄模式
3. 点击中间的卡片或将想要的模式移到中间后点击
4. 感受震动反馈
5. 自动进入拍照界面
6. 顶部显示当前选中的拍摄模式

### 开发者集成
```swift
// 1. 定义拍摄模式数据
let modes = [
    VixenCarouselItem(imageName: "v_01", title: "标准拍摄"),
    VixenCarouselItem(imageName: "v_02", title: "人像模式"),
    VixenCarouselItem(imageName: "v_03", title: "夜景模式"),
    VixenCarouselItem(imageName: "v_04", title: "全景模式")
]

// 2. 使用轮播选择器
VixenCarouselSelector(items: modes) { selectedItem in
    // 处理选中事件
    print("选中: \(selectedItem.imageName)")
}
```

## 💡 设计理念

这个 3D 轮播选择器的设计灵感来自：
- **地球仪旋转**：卡片像地球仪一样可以旋转查看
- **Cover Flow**：Apple 经典的专辑浏览效果
- **空间感**：通过 3D 变换营造空间深度
- **流畅性**：使用物理动画实现自然的交互

完美结合了视觉美感和交互体验！🎉

