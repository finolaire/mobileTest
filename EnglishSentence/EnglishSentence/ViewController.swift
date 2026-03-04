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
}

enum ImmersiveConfigStore {
    static let key = "ImmersiveReadingConfig"
    
    static let defaultConfig = ImmersiveReadingConfig(
        enableSound: true,
        playbackRate: AVSpeechUtteranceDefaultSpeechRate,
        lockScreenPlayback: true,
        autoStopEnabled: false,
        autoStopMinutes: 15,
        playSentencePattern: true,
        playTranslation: true,
        playOriginal: true,
        sentenceCountOption: "all",
        customSentenceCount: 10,
        orderPattern: 3,
        orderTranslation: 2,
        orderOriginal: 1
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

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {

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
    
    private let patternLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let translationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let englishSentenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let translationAudioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "speaker.wave.3.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    
    private let englishAudioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "speaker.wave.3.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        btn.setImage(UIImage(systemName: "chevron.left.circle", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        return btn
    }()
    
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        btn.setImage(UIImage(systemName: "chevron.right.circle", withConfiguration: config), for: .normal)
        btn.tintColor = .white
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        TTSManager.shared.warmUpAsync()
        
        setupUI()
        setupBindings()
        setupImmersiveCallbacks()
        viewModel.loadData()
        updateBackground() // Set initial background
        
        translationAudioButton.addTarget(self, action: #selector(translationAudioTapped), for: .touchUpInside)
        englishAudioButton.addTarget(self, action: #selector(englishAudioTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(backgroundDimmingView)
        view.addSubview(collectionView)
        view.addSubview(patternLabel)
        view.addSubview(translationLabel)
        view.addSubview(englishSentenceLabel)
        view.addSubview(translationAudioButton)
        view.addSubview(englishAudioButton)
        view.addSubview(settingsButton)
        view.addSubview(immersiveButton)
        view.addSubview(bookshelfButton)
        
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
        
        bookshelfButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(settingsButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.55) // Adjusted height
        }
        
        patternLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        translationLabel.snp.makeConstraints { make in
            make.top.equalTo(patternLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-50) // Make room for audio button
        }
        
        translationAudioButton.snp.makeConstraints { make in
            make.centerY.equalTo(translationLabel)
            make.leading.equalTo(translationLabel.snp.trailing).offset(10)
            make.width.height.equalTo(30)
        }
        
        englishSentenceLabel.snp.makeConstraints { make in
            make.top.equalTo(translationLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-50) // Make room for audio button
        }
        
        englishAudioButton.snp.makeConstraints { make in
            make.centerY.equalTo(englishSentenceLabel)
            make.leading.equalTo(englishSentenceLabel.snp.trailing).offset(10)
            make.width.height.equalTo(30)
        }
        
        prevButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.leading.equalToSuperview().offset(44)
            make.width.height.equalTo(50)
        }
        
        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.trailing.equalToSuperview().offset(-44)
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
        TTSManager.shared.onSpeechFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.handleImmersiveSpeechFinished()
            }
        }
        TTSManager.shared.onSpeechCancelled = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Ignore cancel callback during pause/stop flow.
                if self.isImmersivePaused || !self.isImmersivePlaying { return }
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
        if immersiveConfig.playSentencePattern {
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
        TTSManager.shared.play(item.text, language: item.language, rate: immersiveConfig.playbackRate)
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
            playCurrentImmersiveItem()
            return
        }
        
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
        removeImmersivePauseOverlay()
        setMainControlButtonsHidden(false)
    }
    
    private func setMainControlButtonsHidden(_ hidden: Bool) {
        bookshelfButton.isHidden = hidden
        settingsButton.isHidden = hidden
        immersiveButton.isHidden = hidden
        prevButton.isHidden = hidden
        nextButton.isHidden = hidden
        immersiveTouchLayer.isHidden = !hidden
        immersiveStatusView.isHidden = !hidden
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
        patternLabel.isHidden = !viewModel.displayConfig.showSentencePattern
        
        translationLabel.attributedText = viewModel.currentTranslationAttributed
        translationLabel.isHidden = !viewModel.displayConfig.showTranslation
        
        englishSentenceLabel.attributedText = viewModel.currentEnglishSentenceAttributed
        englishSentenceLabel.isHidden = !viewModel.displayConfig.showEnglishSentence
        
        translationAudioButton.isHidden = !viewModel.displayConfig.showTranslationAudioButton || !viewModel.displayConfig.showTranslation
        englishAudioButton.isHidden = !viewModel.displayConfig.showEnglishAudioButton || !viewModel.displayConfig.showEnglishSentence
        
        collectionView.reloadData()
        
        prevButton.isEnabled = viewModel.isPrevEnabled
        nextButton.isEnabled = viewModel.isNextEnabled
        
        updateBackground()
    }
    
    @objc private func translationAudioTapped() {
        guard let sentence = viewModel.currentSentence else { return }
        TTSManager.shared.play(sentence.sentenceInfo.translation, language: "zh-CN")
    }
    
    @objc private func englishAudioTapped() {
        guard let sentence = viewModel.currentSentence else { return }
        
        // Determine language based on config
        let language = viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
        let voiceId = viewModel.displayConfig.selectedVoiceIdentifier
        TTSManager.shared.play(sentence.sentenceInfo.original, language: language, voiceIdentifier: voiceId)
    }
    
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
        backgroundDimmingView.backgroundColor = UIColor.black.withAlphaComponent(CGFloat(viewModel.displayConfig.maskOpacity))
    }
    
    // MARK: - Actions
    @objc private func immersiveTapped() {
        let configVC = ImmersiveReadingConfigViewController(config: immersiveConfig)
        configVC.onStart = { [weak self] config in
            self?.immersiveConfig = config
            ImmersiveConfigStore.save(config)
            self?.startImmersivePlayback()
        }
        present(configVC, animated: true)
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
            self?.viewModel.updateConfig(newConfig)
        }
        present(settingsVC, animated: true, completion: nil)
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
            cell.configure(with: cellViewModel)
            
            // Handle audio tap
            cell.onAudioTapped = { [weak self] in
                guard let self = self,
                      let analysis = self.viewModel.analysisForCell(at: indexPath.item) else { return }
                
                // Determine language based on config
                let language = self.viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
                let voiceId = self.viewModel.displayConfig.selectedVoiceIdentifier
                TTSManager.shared.play(analysis.word, language: language, voiceIdentifier: voiceId)
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

