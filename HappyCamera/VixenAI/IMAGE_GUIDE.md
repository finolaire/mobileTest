# 📸 图片资源添加指南

## 🎯 需要添加的图片

为了让轮播选择器显示真实图片，您需要添加以下 4 张图片到项目中：

```
v_01.png/jpg  - 标准拍摄模式图片
v_02.png/jpg  - 人像模式图片
v_03.png/jpg  - 夜景模式图片
v_04.png/jpg  - 全景模式图片
```

## 📐 推荐尺寸

- **图片尺寸**: 1120×1440 像素 (比例 7:9)
- **文件格式**: PNG 或 JPG
- **文件大小**: 建议 < 2MB

## 📱 添加步骤

### 方法一：通过 Assets.xcassets 添加（推荐）

1. **打开 Xcode 项目**
   ```
   打开 VixenAI.xcworkspace
   ```

2. **打开 Assets 文件夹**
   ```
   在左侧导航栏找到：
   VixenAI → Assets.xcassets
   ```

3. **添加图片资源**
   - 在 `Assets.xcassets` 空白处右键
   - 选择 "New Image Set"
   - 将新建的 Image Set 重命名为 `v_01`
   - 拖拽你的图片到对应的位置（1x、2x 或 3x）
   - 重复以上步骤添加 `v_02`、`v_03`、`v_04`

4. **配置图片属性（可选）**
   - 选中图片资源
   - 在右侧 Attributes inspector 中
   - 可以设置 "Render As" 为 "Original Image"

### 方法二：直接添加到项目（备选）

1. **准备图片文件**
   ```
   v_01.png
   v_02.png
   v_03.png
   v_04.png
   ```

2. **拖拽到 Xcode**
   - 选中这 4 张图片
   - 拖拽到 Xcode 左侧的 `VixenAI` 文件夹
   - 在弹出的对话框中：
     ✅ Copy items if needed
     ✅ Create groups
     ✅ Add to targets: VixenAI

3. **验证添加成功**
   - 图片应该出现在项目导航栏中
   - 可以在 `Assets.xcassets` 中看到

## 🎨 图片内容建议

### v_01 - 标准拍摄
- 展示普通拍照场景
- 明亮、清晰的照片
- 建议：风景、建筑、日常物品

### v_02 - 人像模式
- 展示人物肖像
- 突出背景虚化效果
- 建议：人物特写、肖像照

### v_03 - 夜景模式
- 展示夜间拍摄效果
- 低光环境场景
- 建议：夜景、灯光、城市夜景

### v_04 - 全景模式
- 展示宽幅全景照片
- 广角视野
- 建议：山脉、海滩、城市全景

## 🔍 图片不存在时的效果

如果项目中没有添加图片，轮播器会自动显示：
- ✨ 渐变色背景（每个模式不同颜色）
- 📷 相机图标
- 📝 模式名称和标题

这样即使没有图片，界面也能正常显示和使用。

## 🎯 图片显示逻辑

```swift
// 代码会自动检测图片是否存在
if UIImage(named: item.imageName) != nil {
    // 显示真实图片
    Image(item.imageName)
        .resizable()
        .aspectRatio(contentMode: .fill)
        // ...
} else {
    // 显示渐变色占位
    RoundedRectangle(cornerRadius: 25)
        .fill(LinearGradient(...))
        // ...
}
```

## 📊 当前渐变色配置

如果没有图片，将显示以下渐变色：

| 模式 | 渐变色 | 效果 |
|------|--------|------|
| v_01 | #667eea → #764ba2 | 紫色系 💜 |
| v_02 | #f093fb → #f5576c | 粉红系 💗 |
| v_03 | #4facfe → #00f2fe | 蓝色系 💙 |
| v_04 | #43e97b → #38f9d7 | 绿色系 💚 |

## ✅ 验证图片已添加

1. **在 Xcode 中验证**
   ```
   打开 Assets.xcassets
   应该看到 v_01, v_02, v_03, v_04 四个 Image Set
   ```

2. **运行项目验证**
   ```
   运行项目，查看首页轮播器
   如果显示真实图片而不是渐变色，说明添加成功
   ```

3. **代码验证**
   ```swift
   print(UIImage(named: "v_01") != nil)  // 应该输出 true
   ```

## 🔧 常见问题

### Q: 图片添加后不显示？
**A: 检查以下几点：**
1. 图片名称是否完全匹配（区分大小写）
2. 图片是否添加到正确的 target（VixenAI）
3. 清理项目后重新编译（Product → Clean Build Folder）

### Q: 图片显示变形？
**A: 调整以下设置：**
```swift
.aspectRatio(contentMode: .fill)  // 填充模式
.clipShape(RoundedRectangle(cornerRadius: 25))  // 裁剪
```

### Q: 想用不同的图片名称？
**A: 修改首页数据源：**
```swift
private let captureModels = [
    VixenCarouselItem(imageName: "你的图片名1", title: "标准拍摄"),
    VixenCarouselItem(imageName: "你的图片名2", title: "人像模式"),
    // ...
]
```

## 🎨 在线图片资源推荐

如果需要示例图片，可以从以下网站获取：

- **Unsplash**: https://unsplash.com/ （免费高质量照片）
- **Pexels**: https://www.pexels.com/ （免费商用图片）
- **Pixabay**: https://pixabay.com/ （免费图片和视频）

搜索关键词：
- v_01: "camera", "photography", "standard"
- v_02: "portrait", "people", "person"
- v_03: "night", "city lights", "dark"
- v_04: "panorama", "landscape", "wide"

## 💡 提示

- 添加图片后记得清理编译缓存
- 图片文件名不要包含空格和特殊字符
- 建议使用 @2x 或 @3x 高清图片
- 如果图片太大，可以先压缩再添加

---

**📌 记住：即使不添加图片，轮播器也能正常工作，只是显示渐变色占位而已！**

