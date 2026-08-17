import UIKit
import SnapKit
import AVFoundation

struct ImmersiveReadingConfig: Codable {
    var enableSound: Bool
    var playbackRate: Float
    var lockScreenPlayback: Bool
    var autoStopEnabled: Bool
    var autoStopMinutes: Int
    var playSentencePattern: Bool
    var playTranslation: Bool
    var playOriginal: Bool
    var sentenceCountOption: String?
    var customSentenceCount: Int?
    var orderPattern: Int
    var orderTranslation: Int
    var orderOriginal: Int
    var enableIntervalSound: Bool
    var intervalSoundFile: String
    var smallSentenceInterval: Double
    var largeSentenceInterval: Double
}

enum ImmersiveConfigStore {
    static let key = "ImmersiveReadingConfig"
    
    static let defaultConfig = ImmersiveReadingConfig(
        enableSound: true,
        playbackRate: 1.0,
        lockScreenPlayback: true,
        autoStopEnabled: false,
        autoStopMinutes: 15,
        playSentencePattern: false,
        playTranslation: true,
        playOriginal: true,
        sentenceCountOption: "all",
        customSentenceCount: 10,
        orderPattern: 3,
        orderTranslation: 2,
        orderOriginal: 1,
        enableIntervalSound: true,
        intervalSoundFile: IntervalSoundDefinitions.defaultSound,
        smallSentenceInterval: 1.0,
        largeSentenceInterval: 1.0
    )
    
    static func load() -> ImmersiveReadingConfig {
        guard let data = UserDefaults.standard.data(forKey: key),
              let cfg = try? JSONDecoder().decode(ImmersiveReadingConfig.self, from: data) else {
            return defaultConfig
        }
        var normalized = cfg
        // English playback is mandatory.
        normalized.playOriginal = true
        return normalized
    }
    
    static func save(_ config: ImmersiveReadingConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Configuration
// Moved to shared location or keep here if it's app-wide config
// For now, it's used by ViewModel, so we can keep it here or move to a separate file.
// Since SentenceViewModel uses it, and WordCell uses it (via VM), it's fine.

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, AVAudioPlayerDelegate {

    // MARK: - ViewModel
    private var viewModel = SentenceViewModel()
    
    // MARK: - Immersive Reading
    private var immersiveConfig = ImmersiveConfigStore.load()
    private var isImmersivePlaying = false
    private var isImmersivePaused = false
    private var immersiveQueue: [(text: String, language: String)] = []
    private var immersiveQueueIndex = 0
    private var immersiveStopTimer: Timer?
    private var immersivePauseOverlay: UIView?
    private var audioPlayer: AVAudioPlayer?
    private let immersiveTouchLayer: UIControl = {
        let layer = UIControl()
        layer.backgroundColor = .clear
        layer.isHidden = true
        return layer
    }()
    
    private let immersiveStatusView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()
    
    private let immersiveStatusDot: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let immersiveStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "播放中"
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        return label
    }()
    
    // MARK: - UI Components
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let backgroundDimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8) // Dark mask with 80% opacity
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear // Transparent to show background
        cv.delegate = self
        cv.dataSource = self
        cv.register(WordCell.self, forCellWithReuseIdentifier: WordCell.identifier)
        return cv
    }()
    
    // New Container for bottom elements
    private let bottomCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.9) // Dark background
        view.layer.cornerRadius = 16
        //view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        return view
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let translationContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x172033)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let patternContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x172033)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let patternLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private let translationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .left // Changed to left
        label.numberOfLines = 0
        return label
    }()
    
    private let englishContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x172033)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let englishSentenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .left // Changed to left
        label.numberOfLines = 0
        return label
    }()
    
    private let translationAudioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        // Try to use speaker.wave.2.circle (iOS 14+), fallback to speaker.circle
        if let image = UIImage(systemName: "speaker.wave.2.circle", withConfiguration: config) {
            btn.setImage(image, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "speaker.circle", withConfiguration: config), for: .normal)
        }
        btn.tintColor = .white
        return btn
    }()
    
    private let englishAudioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        if let image = UIImage(systemName: "speaker.wave.2.circle", withConfiguration: config) {
            btn.setImage(image, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "speaker.circle", withConfiguration: config), for: .normal)
        }
        btn.tintColor = .white
        return btn
    }()
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        btn.layer.cornerRadius = 25
        btn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        return btn
    }()
    
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 30
        btn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return btn
    }()
    
    private let settingsButton: UIButton = {
        let btn = UIButton(type: .system)
        // Use a gear icon if available, otherwise text
        if let image = UIImage(systemName: "gearshape.fill") {
            btn.setImage(image, for: .normal)
        } else {
            btn.setTitle("Settings", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return btn
    }()
    
    private let quickPlayButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(quickPlayTapped), for: .touchUpInside)
        return btn
    }()
    
    private let immersiveButton: UIButton = {
        let btn = UIButton(type: .system)
        if let image = UIImage(systemName: "headphones.over.ear") {
            btn.setImage(image, for: .normal)
        } else {
            btn.setTitle("Read", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(immersiveTapped), for: .touchUpInside)
        return btn
    }()
    
    private let bookshelfButton: UIButton = {
        let btn = UIButton(type: .system)
        if let image = UIImage(systemName: "books.vertical.fill") {
            btn.setImage(image, for: .normal)
        } else {
            btn.setTitle("Books", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(bookshelfTapped), for: .touchUpInside)
        return btn
    }()

    private let eyebrowButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        if let image = UIImage(systemName: "eyebrow", withConfiguration: config) {
            btn.setImage(image, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "eye"), for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(eyebrowTapped), for: .touchUpInside)
        return btn
    }()

    private let sleepButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "moon.zzz.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(sleepTapped), for: .touchUpInside)
        return btn
    }()
    
    // Audio State
    private enum PlayingType: Equatable {
        case none
        case translation
        case english
        case word(Int)
    }
    private var currentPlayingType: PlayingType = .none {
        didSet {
            updateAudioButtonIcons()
            
            // Update cells directly without reloading to avoid flickering
            if case .word(let index) = oldValue {
                let indexPath = IndexPath(item: index, section: 0)
                if let cell = collectionView.cellForItem(at: indexPath) as? WordCell {
                    cell.updatePlaybackState(isPlaying: false)
                }
            }
            if case .word(let index) = currentPlayingType {
                let indexPath = IndexPath(item: index, section: 0)
                if let cell = collectionView.cellForItem(at: indexPath) as? WordCell {
                    cell.updatePlaybackState(isPlaying: true)
                }
            }
        }
    }
    private var currentUtterance: AVSpeechUtterance?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        TTSManager.shared.warmUpAsync()
        
        // 用设置页「句型朗读」初始化自动播放配置
        immersiveConfig.playSentencePattern = viewModel.displayConfig.speakSentencePattern
        
        setupUI()
        setupBindings()
        setupImmersiveCallbacks()
        viewModel.loadData()
        updateBackground() // Set initial background
        
        translationAudioButton.addTarget(self, action: #selector(translationAudioTapped), for: .touchUpInside)
        englishAudioButton.addTarget(self, action: #selector(englishAudioTapped), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOverlayDeepLinkNotification(_:)),
            name: OverlayDeepLinkRouter.didEnqueueNotification,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processPendingOverlayDeepLinkIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: OverlayDeepLinkRouter.didEnqueueNotification, object: nil)
    }
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(backgroundDimmingView)
        view.addSubview(collectionView)
        
        // Add Bottom Card
        view.addSubview(bottomCardView)
        bottomCardView.addSubview(contentStackView)
        
        // Add Translation Container
        contentStackView.addArrangedSubview(translationContainerView)
        translationContainerView.addSubview(translationLabel)
        translationContainerView.addSubview(translationAudioButton)
        
        // Add English Container
        contentStackView.addArrangedSubview(englishContainerView)
        englishContainerView.addSubview(englishSentenceLabel)
        englishContainerView.addSubview(englishAudioButton)
        
        // Add Pattern Container
        contentStackView.addArrangedSubview(patternContainerView)
        patternContainerView.addSubview(patternLabel)
        
        view.addSubview(settingsButton)
        view.addSubview(immersiveButton)
        view.addSubview(quickPlayButton)
        view.addSubview(bookshelfButton)
        view.addSubview(eyebrowButton)
        view.addSubview(sleepButton)
        
        view.addSubview(prevButton)
        view.addSubview(nextButton)
        view.addSubview(immersiveTouchLayer)
        view.addSubview(immersiveStatusView)
        immersiveStatusView.addArrangedSubview(immersiveStatusDot)
        immersiveStatusView.addArrangedSubview(immersiveStatusLabel)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundDimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(44)
        }
        
        immersiveButton.snp.makeConstraints { make in
            make.centerY.equalTo(settingsButton)
            make.trailing.equalTo(settingsButton.snp.leading).offset(-12)
            make.width.height.equalTo(44)
        }
        
        quickPlayButton.snp.makeConstraints { make in
            make.centerY.equalTo(settingsButton)
            make.trailing.equalTo(immersiveButton.snp.leading).offset(-4)
            make.width.height.equalTo(44)
        }
        
        bookshelfButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(44)
        }

        eyebrowButton.snp.makeConstraints { make in
            make.centerY.equalTo(bookshelfButton)
            make.leading.equalTo(bookshelfButton.snp.trailing).offset(8)
            make.width.height.equalTo(44)
        }

        sleepButton.snp.makeConstraints { make in
            make.centerY.equalTo(eyebrowButton)
            make.leading.equalTo(eyebrowButton.snp.trailing).offset(8)
            make.width.height.equalTo(44)
        }
        
        // CollectionView takes upper part
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(settingsButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomCardView.snp.top).offset(-20)
        }
        
        // Bottom Card Constraints
        bottomCardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(prevButton.snp.top).offset(-20)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        // Translation Constraints
        translationLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(translationAudioButton.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        translationAudioButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.height.equalTo(32)
        }
        
        // English Constraints
        englishSentenceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(englishAudioButton.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        englishAudioButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.height.equalTo(32)
        }
        
        // Pattern Constraints
        patternLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        // Navigation Buttons
        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-30)
            make.centerX.equalToSuperview().offset(40)
            make.width.height.equalTo(60)
        }
        
        prevButton.snp.makeConstraints { make in
            make.centerY.equalTo(nextButton)
            make.trailing.equalTo(nextButton.snp.leading).offset(-30)
            make.width.height.equalTo(50)
        }
        
        immersiveTouchLayer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        immersiveTouchLayer.addTarget(self, action: #selector(handleImmersiveScreenTap), for: .touchUpInside)
        
        immersiveStatusView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        immersiveStatusDot.snp.makeConstraints { make in
            make.width.height.equalTo(8)
        }
    }
    
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func setupImmersiveCallbacks() {
        TTSManager.shared.onSpeechFinished = { [weak self] utterance in
            DispatchQueue.main.async {
                self?.handleSpeechFinished(utterance: utterance)
            }
        }
        TTSManager.shared.onSpeechCancelled = { [weak self] utterance in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // If immersive mode is active, handle it there
                if self.isImmersivePlaying {
                    if self.isImmersivePaused { return }
                } else {
                    // Manual playback cancelled
                    // Only reset if the cancelled utterance matches our current tracking
                    if utterance == self.currentUtterance {
                        self.currentPlayingType = .none
                        self.currentUtterance = nil
                    }
                }
            }
        }
    }
    
    private func handleSpeechFinished(utterance: AVSpeechUtterance) {
        if isImmersivePlaying {
            handleImmersiveSpeechFinished()
        } else {
            // Manual playback finished
            if utterance == self.currentUtterance {
                currentPlayingType = .none
                currentUtterance = nil
            }
        }
    }
    
    private func buildImmersiveQueueForCurrentSentence() {
        immersiveQueue.removeAll()
        immersiveQueueIndex = 0
        
        guard immersiveConfig.enableSound, let sentence = viewModel.currentSentence else { return }
        
        enum PlayItemType {
            case pattern
            case translation
            case original
        }
        
        var candidates: [(order: Int, type: PlayItemType)] = []
        if viewModel.displayConfig.speakSentencePattern {
            candidates.append((immersiveConfig.orderPattern, .pattern))
        }
        if immersiveConfig.playTranslation {
            candidates.append((immersiveConfig.orderTranslation, .translation))
        }
        // English playback is always on.
        if true {
            candidates.append((immersiveConfig.orderOriginal, .original))
        }
        
        // Stable tie-breaker keeps deterministic behavior if legacy config has duplicates.
        let sorted = candidates.sorted {
            if $0.order == $1.order {
                return String(describing: $0.type) < String(describing: $1.type)
            }
            return $0.order < $1.order
        }
        
        for item in sorted {
            switch item.type {
            case .pattern:
                immersiveQueue.append((sentence.sentenceInfo.sentencePattern, "zh-CN"))
            case .translation:
                immersiveQueue.append((sentence.sentenceInfo.translation, "zh-CN"))
            case .original:
                let englishLang = viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
                immersiveQueue.append((sentence.sentenceInfo.original, englishLang))
            }
        }
    }
    
    private func playCurrentImmersiveItem() {
        guard isImmersivePlaying, !isImmersivePaused else { return }
        guard immersiveQueueIndex < immersiveQueue.count else {
            handleImmersiveSpeechFinished()
            return
        }
        
        let item = immersiveQueue[immersiveQueueIndex]
        // Convert multiplier (0.5 ~ 2.0) to AVSpeechUtterance rate
        // Base is AVSpeechUtteranceDefaultSpeechRate (0.5)
        let baseRate = AVSpeechUtteranceDefaultSpeechRate
        let adjustedRate = baseRate * immersiveConfig.playbackRate
        print("DEBUG: Playing immersive item. Multiplier: \(immersiveConfig.playbackRate), Base: \(baseRate), Adjusted: \(adjustedRate)")
        
        TTSManager.shared.play(item.text, language: item.language, rate: adjustedRate)
    }
    
    private func effectiveSentenceLimit(for totalInCourse: Int) -> Int {
        let option = immersiveConfig.sentenceCountOption ?? "all"
        let requested: Int
        switch option {
        case "three":
            requested = 3
        case "five":
            requested = 5
        case "custom":
            requested = min(max(immersiveConfig.customSentenceCount ?? 10, 1), 50)
        default:
            requested = totalInCourse
        }
        return min(max(requested, 1), max(totalInCourse, 1))
    }
    
    private func handleImmersiveSpeechFinished() {
        guard isImmersivePlaying, !isImmersivePaused else { return }
        
        immersiveQueueIndex += 1
        if immersiveQueueIndex < immersiveQueue.count {
            // Small interval delay
            let delay = immersiveConfig.smallSentenceInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isImmersivePlaying, !self.isImmersivePaused else { return }
                self.playCurrentImmersiveItem()
            }
            return
        }
        
        // Large interval delay
        let delay = immersiveConfig.largeSentenceInterval
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.isImmersivePlaying, !self.isImmersivePaused else { return }
            if self.immersiveConfig.enableIntervalSound {
                self.playIntervalSound()
            } else {
                self.proceedToNextImmersiveSentence()
            }
        }
    }
    
    private func playIntervalSound() {
        let soundName = immersiveConfig.intervalSoundFile.isEmpty ? IntervalSoundDefinitions.defaultSound : immersiveConfig.intervalSoundFile
        let fileName = IntervalSoundDefinitions.soundFileMapping[soundName] ?? soundName
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Resources/Media")
            ?? Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Resource")
            ?? Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            proceedToNextImmersiveSentence()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Failed to play interval sound: \(error)")
            proceedToNextImmersiveSentence()
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isImmersivePlaying && !isImmersivePaused {
            proceedToNextImmersiveSentence()
        }
    }
    
    private func proceedToNextImmersiveSentence() {
        // Sentence-level playback finished, decide whether to continue in current JSON.
        let totalInCurrentCourse = viewModel.currentCourseSentenceCount
        let limit = effectiveSentenceLimit(for: totalInCurrentCourse)
        let currentPos = viewModel.currentSentencePosition
        let hasReachedConfiguredLimit = (currentPos + 1) >= limit
        
        if !hasReachedConfiguredLimit && viewModel.isNextEnabled {
            // Continue in current JSON.
            viewModel.nextSentence()
            buildImmersiveQueueForCurrentSentence()
            if immersiveQueue.isEmpty {
                stopImmersivePlayback()
                return
            }
            playCurrentImmersiveItem()
            return
        }
        
        // Reached configured per-JSON limit or end-of-JSON: jump to next JSON.
        if viewModel.hasNextCourse {
            viewModel.moveToNextCourseFirstSentence()
            buildImmersiveQueueForCurrentSentence()
            if immersiveQueue.isEmpty {
                stopImmersivePlayback()
                return
            }
            playCurrentImmersiveItem()
        } else {
            stopImmersivePlayback()
        }
    }
    
    private func startImmersivePlayback() {
        isImmersivePlaying = true
        isImmersivePaused = false
        // Reset manual playback state
        currentPlayingType = .none
        currentUtterance = nil
        
        setMainControlButtonsHidden(true)
        
        TTSManager.shared.setLockScreenPlaybackEnabled(immersiveConfig.lockScreenPlayback)
        
        immersiveStopTimer?.invalidate()
        immersiveStopTimer = nil
        if immersiveConfig.autoStopEnabled {
            immersiveStopTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(immersiveConfig.autoStopMinutes * 60), repeats: false) { [weak self] _ in
            self?.stopImmersivePlayback()
            }
        }
        
        buildImmersiveQueueForCurrentSentence()
        if immersiveQueue.isEmpty {
            stopImmersivePlayback()
            return
        }
        playCurrentImmersiveItem()
    }
    
    private func pauseImmersiveAndShowOverlay() {
        guard isImmersivePlaying else { return }
        isImmersivePaused = true
        TTSManager.shared.stop()
        showImmersivePauseOverlay()
    }
    
    private func resumeImmersivePlayback() {
        guard isImmersivePlaying else { return }
        isImmersivePaused = false
        removeImmersivePauseOverlay()
        playCurrentImmersiveItem()
    }
    
    private func stopImmersivePlayback() {
        isImmersivePlaying = false
        isImmersivePaused = false
        immersiveStopTimer?.invalidate()
        immersiveStopTimer = nil
        immersiveQueue.removeAll()
        immersiveQueueIndex = 0
        TTSManager.shared.stop()
        audioPlayer?.stop()
        removeImmersivePauseOverlay()
        setMainControlButtonsHidden(false)
    }
    
    private func setMainControlButtonsHidden(_ hidden: Bool) {
        bookshelfButton.isHidden = hidden
        eyebrowButton.isHidden = hidden
        sleepButton.isHidden = hidden
        settingsButton.isHidden = hidden
        immersiveButton.isHidden = hidden
        quickPlayButton.isHidden = hidden
        prevButton.isHidden = hidden
        nextButton.isHidden = hidden
        translationAudioButton.isHidden = hidden
        englishAudioButton.isHidden = hidden
        immersiveTouchLayer.isHidden = !hidden
        immersiveStatusView.isHidden = !hidden
        
        // If unhiding, restore state based on config
        if !hidden {
            updateUI()
        } else {
            // Refresh collection view to hide audio buttons in cells
            collectionView.reloadData()
        }
    }
    
    private func showImmersivePauseOverlay() {
        removeImmersivePauseOverlay()
        
        let overlay = UIControl()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        overlay.addTarget(self, action: #selector(continueImmersiveTapped), for: .touchUpInside)
        view.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("继续播放", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        continueButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        continueButton.layer.cornerRadius = 12
        continueButton.addTarget(self, action: #selector(continueImmersiveTapped), for: .touchUpInside)
        
        let stopButton = UIButton(type: .system)
        stopButton.setTitle("停止播放", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        stopButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        stopButton.layer.cornerRadius = 12
        stopButton.addTarget(self, action: #selector(stopImmersiveTapped), for: .touchUpInside)
        
        overlay.addSubview(continueButton)
        overlay.addSubview(stopButton)
        
        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-36)
            make.width.equalTo(220)
            make.height.equalTo(56)
        }
        
        stopButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(continueButton.snp.bottom).offset(16)
            make.width.equalTo(220)
            make.height.equalTo(56)
        }
        
        immersivePauseOverlay = overlay
    }
    
    private func removeImmersivePauseOverlay() {
        immersivePauseOverlay?.removeFromSuperview()
        immersivePauseOverlay = nil
    }
    
    private func updateUI() {//更新数据
        patternLabel.attributedText = viewModel.currentPatternAttributed
        patternContainerView.isHidden = !viewModel.displayConfig.showSentencePattern
        
        translationLabel.attributedText = viewModel.currentTranslationAttributed
        translationContainerView.isHidden = !viewModel.displayConfig.showTranslation
        
        englishSentenceLabel.attributedText = viewModel.currentEnglishSentenceAttributed
        englishContainerView.isHidden = !viewModel.displayConfig.showEnglishSentence
        
        if isImmersivePlaying {
            translationAudioButton.isHidden = true
            englishAudioButton.isHidden = true
        } else {
            translationAudioButton.isHidden = !viewModel.displayConfig.showTranslationAudioButton || !viewModel.displayConfig.showTranslation
            englishAudioButton.isHidden = !viewModel.displayConfig.showEnglishAudioButton || !viewModel.displayConfig.showEnglishSentence
        }
        
        collectionView.reloadData()
        
        prevButton.isEnabled = viewModel.isPrevEnabled
        nextButton.isEnabled = viewModel.isNextEnabled
        
        updateBackground()
    }
    
    private func updateAudioButtonIcons() {
        switch currentPlayingType {
        case .translation:
            translationAudioButton.tintColor = .systemBlue
            englishAudioButton.tintColor = .white
        case .english:
            translationAudioButton.tintColor = .white
            englishAudioButton.tintColor = .systemBlue
        case .none, .word:
            translationAudioButton.tintColor = .white
            englishAudioButton.tintColor = .white
        }
    }
    
    @objc private func translationAudioTapped() {
        guard let sentence = viewModel.currentSentence else { return }
        
        if currentPlayingType == .translation {
            TTSManager.shared.stop()
            currentPlayingType = .none
            currentUtterance = nil
        } else {
            // Stop any existing playback first implicitly via TTSManager.play
            // Reset currentUtterance so cancellation of previous doesn't affect state
            currentUtterance = nil
            currentPlayingType = .translation
            currentUtterance = TTSManager.shared.play(sentence.sentenceInfo.translation, language: "zh-CN")
        }
    }
    
    @objc private func englishAudioTapped() {
        guard let sentence = viewModel.currentSentence else { return }
        
        if currentPlayingType == .english {
            TTSManager.shared.stop()
            currentPlayingType = .none
            currentUtterance = nil
        } else {
            currentUtterance = nil
            currentPlayingType = .english
            // Determine language based on config
            let language = viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
            let voiceId = viewModel.displayConfig.selectedVoiceIdentifier
            currentUtterance = TTSManager.shared.play(sentence.sentenceInfo.original, language: language, voiceIdentifier: voiceId)
        }
    }
    
    
    /// 更新背景透明度
    private func updateBackground() {
        if viewModel.displayConfig.useCustomBackground,
           let filename = viewModel.displayConfig.customBackgroundImageName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                backgroundImageView.image = image
            } else {
                // Fallback if file not found
                let imageName = "BackgroundImage\(viewModel.displayConfig.backgroundImageIndex)"
                backgroundImageView.image = UIImage(named: imageName)
            }
        } else {
            let imageName = "BackgroundImage\(viewModel.displayConfig.backgroundImageIndex)"
            backgroundImageView.image = UIImage(named: imageName)
        }
        
        let opacity = CGFloat(viewModel.displayConfig.maskOpacity)
        backgroundDimmingView.backgroundColor = UIColor.black.withAlphaComponent(opacity)
        
        // Update container opacities
        let containerColor = UIColor(hex: 0x172033).withAlphaComponent(opacity)
        translationContainerView.backgroundColor = containerColor
        englishContainerView.backgroundColor = containerColor
        patternContainerView.backgroundColor = containerColor
        
        // Update bottomCardView opacity
        if (opacity != 1) {
            bottomCardView.backgroundColor = .clear
        }
        else {
            bottomCardView.backgroundColor = UIColor(white: 0.1, alpha: 1.0).withAlphaComponent(opacity)
        }
    }
    
    // MARK: - Actions
    @objc private func immersiveTapped() {
        let configVC = ImmersiveReadingConfigViewController(config: immersiveConfig)
        configVC.onStart = { [weak self] config in
            guard let self = self else { return }
            self.immersiveConfig = config
            ImmersiveConfigStore.save(config)
            // 同步回设置页「句型朗读」开关
            var displayConfig = self.viewModel.displayConfig
            displayConfig.speakSentencePattern = config.playSentencePattern
            self.viewModel.updateConfig(displayConfig)
            self.startImmersivePlayback()
        }
        present(configVC, animated: true)
    }
    
    @objc private func quickPlayTapped() {
        startImmersivePlayback()
    }
    
    @objc private func handleImmersiveScreenTap() {
        if isImmersivePlaying && immersivePauseOverlay == nil {
            pauseImmersiveAndShowOverlay()
        }
    }
    
    @objc private func continueImmersiveTapped() {
        resumeImmersivePlayback()
    }
    
    @objc private func stopImmersiveTapped() {
        stopImmersivePlayback()
    }
    
    @objc private func prevTapped() {
        viewModel.prevSentence()
    }
    
    @objc private func nextTapped() {
        viewModel.nextSentence()
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController(config: viewModel.displayConfig)
        settingsVC.onConfigChanged = { [weak self] newConfig in
            guard let self = self else { return }
            self.viewModel.updateConfig(newConfig)
            // 与自动播放配置中的「播放语法」保持同步
            self.immersiveConfig.playSentencePattern = newConfig.speakSentencePattern
            ImmersiveConfigStore.save(self.immersiveConfig)
        }
        present(settingsVC, animated: true, completion: nil)
    }
    
    @objc private func eyebrowTapped() {
        presentEyesOverlay()
    }

    @objc private func sleepTapped() {
        presentSleepOverlay()
    }

    // MARK: - Siri / Deep Link

    @objc private func handleOverlayDeepLinkNotification(_ notification: Notification) {
        processPendingOverlayDeepLinkIfNeeded()
    }

    private func processPendingOverlayDeepLinkIfNeeded() {
        guard isViewLoaded, view.window != nil else { return }
        guard let link = OverlayDeepLinkRouter.shared.consume() else { return }
        switch link {
        case .eyes:
            presentEyesOverlay()
        case .sleep:
            presentSleepOverlay()
        }
    }

    private func presentEyesOverlay() {
        presentOverlay(EyesOverlayViewController())
    }

    private func presentSleepOverlay() {
        presentOverlay(SleepOverlayViewController())
    }

    private func presentOverlay(_ overlay: UIViewController) {
        overlay.modalPresentationStyle = .fullScreen

        // 若已有模态页（含另一个遮罩），先关掉再打开目标页
        if let presented = presentedViewController {
            presented.dismiss(animated: false) { [weak self] in
                self?.present(overlay, animated: true)
            }
        } else {
            present(overlay, animated: true)
        }
    }

    @objc private func bookshelfTapped() {
        let bookshelfVC = BookshelfViewController()
        bookshelfVC.onCourseSelected = { [weak self] course in
            self?.viewModel.loadData(unit: course)
        }
        present(bookshelfVC, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.identifier, for: indexPath) as? WordCell else {
            return UICollectionViewCell()
        }
        
        if let cellViewModel = viewModel.viewModelForCell(at: indexPath.item) {
            // Check if this cell is currently playing
            var isPlaying = false
            if case .word(let index) = currentPlayingType, index == indexPath.item {
                isPlaying = true
            }
            
            cell.configure(with: cellViewModel, isImmersiveMode: isImmersivePlaying, isPlaying: isPlaying)
            
            // Handle audio tap
            cell.onAudioTapped = { [weak self] in
                guard let self = self,
                      let analysis = self.viewModel.analysisForCell(at: indexPath.item) else { return }
                
                // If already playing this word, stop it
                if case .word(let index) = self.currentPlayingType, index == indexPath.item {
                    TTSManager.shared.stop()
                    self.currentPlayingType = .none
                    self.currentUtterance = nil
                    return
                }
                
                // Stop any existing playback
                TTSManager.shared.stop()
                self.currentUtterance = nil
                
                // Set new state
                self.currentPlayingType = .word(indexPath.item)
                
                // Determine language based on config
                let language = self.viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
                let voiceId = self.viewModel.displayConfig.selectedVoiceIdentifier
                self.currentUtterance = TTSManager.shared.play(analysis.word, language: language, voiceIdentifier: voiceId)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath),
              let analysis = viewModel.analysisForCell(at: indexPath.item) else { return }
        
        let detailVC = WordDetailViewController(analysis: analysis, color: AppTheme.color(forTag: analysis.tag))
        detailVC.modalPresentationStyle = .popover
        
        if let popover = detailVC.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            popover.permittedArrowDirections = [] // Remove arrow to make it a rounded rectangle
            popover.delegate = self
            popover.backgroundColor = AppTheme.color(forTag: analysis.tag)
        }
        
        present(detailVC, animated: true, completion: nil)
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Force popover on iPhone
    }
}
