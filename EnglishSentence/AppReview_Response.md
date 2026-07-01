# App Store 审核回复指南

## 📌 被拒原因分析
Guideline 2.1 - Information Needed：审核团队需要更多信息才能完成审核（这是新应用的常规流程，不是技术问题）。

---

## ✅ 需要准备的内容

### 1. 真机录屏（最重要！）

#### 录屏要求：
- **必须在真机上录制**（不能用模拟器）
- **从启动 App 开始录制**
- **展示所有核心功能**
- **时长建议**：2-3 分钟
- **格式**：MP4 / MOV
- **上传位置**：App Store Connect → App 审核 → 回复审核团队 → 上传附件

#### 录屏内容清单（按顺序展示）：

1. **启动应用**（0:00-0:05）
   - 显示启动画面和主界面

2. **主界面功能**（0:05-0:40）
   - 展示句子显示（单词网格、音标、类型、句型、翻译）
   - 点击单词网格上的喇叭按钮播放单词发音
   - 点击翻译旁的喇叭按钮播放中文
   - 点击英文句子旁的喇叭按钮播放英文
   - 点击单词弹出详情（中文定义 + 解释）
   - 点击"上一句"/"下一句"按钮切换句子

3. **书架功能**（0:40-1:00）
   - 点击左上角"书架"图标
   - 展示课程列表（展开/折叠分类）
   - 选择一个课程切换
   - 点击"查看全文"按钮查看完整课程内容
   - 点击全文页面中的单词显示详情弹窗

4. **沉浸式阅读**（1:00-1:30）
   - 点击主界面的"耳机"图标（沉浸式阅读设置）
   - 展示配置选项（循环次数、播放速度、间隔时间、间隔音效等）
   - 点击"开始"或"快速播放"按钮
   - 展示自动播放效果（单词逐个朗读、句型/翻译播放、间隔音效）
   - 点击"停止"按钮

5. **设置功能**（1:30-2:00）
   - 点击右上角"齿轮"图标
   - 展示显示选项（音标、类型、句型、翻译等开关）
   - 展示音频按钮显示开关
   - 展示音色选择
   - 展示背景设置（不透明度、选择自定义背景）

6. **相册权限**（2:00-2:20）
   - 在设置中点击"选择自定义背景"
   - 系统弹出相册权限请求对话框
   - 点击"允许访问所选照片"或"允许访问所有照片"
   - 从相册选择一张图片
   - 返回主界面展示自定义背景效果

7. **锁屏播放**（2:20-2:40，可选但建议展示）
   - 开始沉浸式阅读
   - 按 Home 键或锁屏
   - 展示锁屏界面上的播放控制
   - 解锁回到 App

8. **Widget**（2:40-3:00）
   - 回到主屏幕
   - 长按主屏幕进入编辑模式
   - 点击"+"添加小组件
   - 搜索"兔子英语"
   - 添加小组件到主屏幕
   - 点击小组件打开 App

#### 录屏工具：
- **iOS 原生录屏**：控制中心 → 屏幕录制（圆点图标）
- **Mac QuickTime**：连接设备 → 文件 → 新建影片录制 → 选择 iPhone

---

### 2. 在 App Store Connect 回复审核团队

登录 App Store Connect → 我的 App → 选择"兔子英语" → App 审核 → 回复审核团队，粘贴以下**英文**内容：

---

## 📝 完整英文回复模板（直接复制到 App Store Connect）

```
Dear App Review Team,

Thank you for reviewing our app. We have attached a screen recording demonstrating all core features as requested. Please find the detailed information below:

---

1. APP PURPOSE AND VALUE

"兔子英语" (Rabbit English) is an offline English learning app designed to help Chinese-speaking users master English sentence structures and grammar through interactive visualization and audio practice.

**Problem it solves:**
- Many learners struggle to understand the grammatical structure of English sentences
- Traditional textbooks lack interactive, visual word-by-word analysis
- Learners need convenient tools to practice pronunciation and listen to sentences repeatedly

**Value provided:**
- Visual breakdown: Each word in a sentence is displayed with its grammatical role, phonetics, and Chinese definition
- Audio practice: Built-in text-to-speech for both English (UK/US accents) and Chinese translation
- Immersive reading mode: Automated playback with customizable speed and intervals for hands-free learning
- Comprehensive content: 100+ sentences covering basic structures, tenses, voices, clauses, and special patterns
- 100% offline: All content and features work without internet connection

**Target audience:** Chinese-speaking English learners (students, professionals, or anyone improving their English)

---

2. HOW TO USE THE APP (No login required)

The app works immediately upon launch without any account or login:

a) **Main Screen:**
   - View a sentence with word-by-word analysis (grammatical tags, phonetics, types)
   - Tap speaker icons to play word pronunciation, English sentence, or Chinese translation
   - Tap any word cell to see detailed definition and explanation in a popover
   - Swipe or tap Previous/Next buttons to navigate between sentences

b) **Bookshelf (top-left icon):**
   - Browse 5 categories with 30+ courses (sentence patterns, tenses, voices, clauses, special patterns)
   - Tap any course to switch content
   - Tap "查看全文" (View Full Text) button to read all sentences in a course

c) **Immersive Reading (headphones icon):**
   - Configure automated playback: loop count, playback speed, sentence intervals, interval sounds
   - Start playback to practice listening hands-free
   - Supports lock screen playback (audio continues when screen is locked)

d) **Settings (gear icon):**
   - Toggle visibility of phonetics, word types, sentence patterns, translations
   - Show/hide audio buttons
   - Select TTS voice (system voices for UK/US English and Chinese)
   - Customize background image by selecting from photo library
   - Adjust background opacity

e) **Widget:**
   - Add the home screen widget to display daily background images (1-31 based on date)
   - Tap widget to open the app

---

3. PERMISSIONS AND PURPOSE STRINGS

The app requests the following permission:

**Photo Library Access (NSPhotoLibraryUsageDescription):**
- **Purpose String:** "我们需要访问您的相册，以便您选择喜欢的图片作为App的背景。"
- **English translation:** "We need access to your photo library so you can select your favorite image as the app background."
- **When triggered:** Only when user taps "选择自定义背景" (Select Custom Background) in Settings
- **Data handling:** Selected images are saved locally in the app's sandbox for display purposes only. No upload or sharing occurs.

**Background Audio (UIBackgroundModes - audio):**
- **Purpose:** Allow immersive reading to continue when the screen is locked or app is in background
- **Data handling:** No recording. Only playback of text-to-speech audio generated locally using system APIs.

---

4. EXTERNAL SERVICES AND THIRD-PARTY TOOLS

The app uses the following frameworks and services:

**a) Apple System Frameworks (No external accounts/servers):**
- **AVSpeechSynthesizer (AVFoundation):** For text-to-speech pronunciation of English words/sentences and Chinese translations. Uses built-in iOS voices, no network requests.
- **AVAudioPlayer (AVFoundation):** For playing local sound effects (interval sounds in immersive reading mode)
- **UIImagePickerController (UIKit):** For selecting custom background images from photo library

**b) Third-Party Libraries (via CocoaPods, no accounts required):**
- **SnapKit (https://github.com/SnapKit/SnapKit):** Swift Auto Layout library for UI constraints. Does not collect data or require network access.

**c) Data Sources:**
- All English sentence content, grammar analysis, and translations are pre-bundled JSON files within the app package
- No external APIs, databases, or cloud services are used
- No user authentication, payment processors, or AI services

---

5. REGIONAL DIFFERENCES

**The app functions consistently across all regions.**

There are no regional restrictions, geo-blocking, or feature differences based on user location. All content and features are available worldwide.

The app is designed for Chinese-speaking users learning English, so the UI language is primarily Chinese (Simplified) and translation content is in Chinese. However, the app can be used by anyone who understands Chinese.

---

6. REGULATORY COMPLIANCE

This app does not operate in a highly regulated industry (e.g., finance, healthcare, gambling). It is an educational tool for language learning.

No licenses, credentials, or regulatory documentation are required.

---

7. ADDITIONAL NOTES

- **No user accounts:** The app does not require registration, login, or account creation
- **No in-app purchases:** The app is completely free with no subscriptions or paid content
- **No user-generated content:** Users cannot create, upload, or share content
- **No social features:** No commenting, messaging, or content reporting mechanisms
- **Fully offline:** All features work without internet connection after installation
- **Privacy-first:** No data collection, no analytics, no tracking

---

We have attached a screen recording demonstrating all the features described above. Please let us know if you need any additional information.

Thank you for your time and consideration.

Best regards,
[Your Name/Team Name]
```

---

## 🎬 录屏操作步骤（中文）

### 方法 1：使用 iPhone 原生录屏

1. **准备录屏**
   - 打开"设置" → "控制中心" → 确保"屏幕录制"已添加
   - 从屏幕右上角下拉打开控制中心
   - 找到"屏幕录制"按钮（实心圆点）

2. **开始录制**
   - 长按"屏幕录制"按钮 → 确保"麦克风"关闭（除非你要配音解说）
   - 点击"开始录制"，3 秒倒计时后开始
   - 返回主屏幕，点击你的 App 图标启动

3. **按上面的"录屏内容清单"操作**

4. **结束录制**
   - 点击屏幕顶部的红色状态栏 → 点击"停止"
   - 或从控制中心再次点击"屏幕录制"按钮

5. **导出视频**
   - 打开"照片"App → 找到刚才的录屏视频
   - 用 AirDrop 传到 Mac，或通过 iCloud 同步
   - 如果文件太大（>500MB），可用 iMovie 或其他工具压缩

### 方法 2：使用 Mac + QuickTime（推荐，画质更稳定）

1. 用 USB 线连接 iPhone 到 Mac
2. 打开 Mac 上的 QuickTime Player
3. 菜单栏：文件 → 新建影片录制
4. 点击录制按钮旁的下拉箭头 → 选择你的 iPhone
5. 点击红色录制按钮
6. 在 iPhone 上按"录屏内容清单"操作
7. Mac 上点击停止，保存视频文件

---

## 📤 如何在 App Store Connect 提交回复

1. 登录 **App Store Connect**（https://appstoreconnect.apple.com）
2. 进入"我的 App" → 选择"兔子英语"
3. 点击左侧"App 审核"
4. 在被拒的版本下方，点击"回复审核团队"
5. **粘贴上面的英文回复模板**（从 "Dear App Review Team" 到 "Best regards"）
6. 点击"添加附件" → 上传录屏视频（如果超过 500MB，上传到 YouTube/Vimeo 私密链接，在回复里附上）
7. 点击"发送"

---

## ⚠️ 注意事项

### 录屏时避免：
- ❌ 不要展示个人隐私信息（相册里的私人照片）
- ❌ 不要出现系统通知（建议开启"勿扰模式"）
- ❌ 不要录制过程中接电话
- ❌ 不要跳过核心功能（每个主要按钮都要点一遍）

### 相册权限展示：
- ✅ **必须展示**权限弹窗出现的时机
- ✅ **必须展示**你点击"允许"后的效果
- ✅ 可以提前准备 2-3 张无关紧要的风景图在相册里，避免暴露私人照片

### 后台音频展示：
- ✅ 开始沉浸式阅读后，锁屏或按 Home 键，展示音频继续播放
- ✅ 可以展示锁屏界面上的播放控制（暂停/播放按钮）

---

## 🔄 预计审核时间

提交回复 + 录屏后，通常 **1-3 个工作日**内会重新审核。如果资料完整，这次应该能过。

---

## 📧 如果需要补充说明

若审核团队还有其他问题，他们会在 App Store Connect 里继续提问。保持邮件通知开启，及时回复即可。

---

**最后提醒**：上面"完整英文回复模板"里的 `[Your Name/Team Name]` 要改成你的真实姓名或团队名称。如果隐私政策里还有 `[您的联系邮箱]` 占位符，也要改成真实联系方式。
