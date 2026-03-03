import AVFoundation

class TTSManager: NSObject {
    // 单例模式，方便全局调用
    static let shared = TTSManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var lockScreenPlaybackEnabled = true
    
    var onSpeechFinished: (() -> Void)?
    var onSpeechCancelled: (() -> Void)?
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let category: AVAudioSession.Category = lockScreenPlaybackEnabled ? .playback : .ambient
            try AVAudioSession.sharedInstance().setCategory(category, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    func setLockScreenPlaybackEnabled(_ enabled: Bool) {
        lockScreenPlaybackEnabled = enabled
        configureAudioSession()
    }
    
    /// 预热语音引擎，减少首次播放延迟
    /// - Note: 语音列表加载放后台，音频会话配置回主线程，避免阻塞 UI。
    func warmUpAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = AVSpeechSynthesisVoice.speechVoices()
            DispatchQueue.main.async { [weak self] in
                self?.configureAudioSession()
            }
        }
    }
    
    /// 播放文本
    /// - Parameters:
    ///   - text: 要播放的文字
    ///   - language: 语言代码 (例如 "en-US", "zh-CN")，默认美式英语
    ///   - voiceIdentifier: 指定发音人 ID (可选)
    ///   - rate: 语速 (0.0 ~ 1.0)，默认标准语速
    func play(_ text: String, language: String = "en-US", voiceIdentifier: String? = nil, rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        // 如果正在说话，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        if let identifier = voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }
        
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0 // 音调，1.0 为正常
        utterance.volume = 1.0 // 音量
        
        synthesizer.speak(utterance)
    }
    
    /// 获取指定语言的可用发音人列表
    func getVoices(for language: String) -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
    }
    
    /// 停止播放
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TTSManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("开始播放: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("播放结束")
        onSpeechFinished?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onSpeechCancelled?()
    }
}
