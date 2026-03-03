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
}

private enum ImmersiveConfigStore {
    static let key = "ImmersiveReadingConfig"
    
    static let defaultConfig = ImmersiveReadingConfig(
        enableSound: true,
        playbackRate: AVSpeechUtteranceDefaultSpeechRate,
        lockScreenPlayback: true,
        autoStopEnabled: false,
        autoStopMinutes: 15,
        playSentencePattern: true,
        playTranslation: true,
        playOriginal: true
    )
    
    static func load() -> ImmersiveReadingConfig {
        guard let data = UserDefaults.standard.data(forKey: key),
              let cfg = try? JSONDecoder().decode(ImmersiveReadingConfig.self, from: data) else {
            return defaultConfig
        }
        return cfg
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
        
        if immersiveConfig.playSentencePattern {
            immersiveQueue.append((sentence.sentenceInfo.sentencePattern, "zh-CN"))
        }
        if immersiveConfig.playTranslation {
            immersiveQueue.append((sentence.sentenceInfo.translation, "zh-CN"))
        }
        if immersiveConfig.playOriginal {
            let englishLang = viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
            immersiveQueue.append((sentence.sentenceInfo.original, englishLang))
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
    
    private func handleImmersiveSpeechFinished() {
        guard isImmersivePlaying, !isImmersivePaused else { return }
        
        immersiveQueueIndex += 1
        if immersiveQueueIndex < immersiveQueue.count {
            playCurrentImmersiveItem()
            return
        }
        
        // Current sentence finished, move to next sentence (cross JSON supported by ViewModel)
        if viewModel.isNextEnabled {
            viewModel.nextSentence()
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

final class ImmersiveReadingConfigViewController: UIViewController {
    var onStart: ((ImmersiveReadingConfig) -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.15, alpha: 0.88)
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let dragHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "沉浸式阅读"
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        return stack
    }()
    
    private let soundSwitch = UISwitch()
    private let rateSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 2.0
        return slider
    }()
    private let rateValueLabel = UILabel()
    
    private let lockScreenSwitch = UISwitch()
    private let autoStopSwitch = UISwitch()
    private let autoStopSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["自定义", "5分钟", "15分钟", "30分钟"])
        segment.selectedSegmentIndex = 2
        return segment
    }()
    private let autoStopSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 120
        return slider
    }()
    private let autoStopValueLabel = UILabel()
    
    private let patternSwitch = UISwitch()
    private let translationSwitch = UISwitch()
    private let originalSwitch = UISwitch()
    private let closeButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    
    private var config: ImmersiveReadingConfig
    private var isApplyingConfig = false
    
    init(config: ImmersiveReadingConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        setupUI()
        applyConfig()
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(dragHandleView)
        containerView.addSubview(titleLabel)
        
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        containerView.addSubview(scroll)
        scroll.addSubview(contentStack)
        
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(320)
            make.height.equalTo(560).priority(750)
            make.height.greaterThanOrEqualTo(360)
            make.height.lessThanOrEqualTo(view.safeAreaLayoutGuide).multipliedBy(0.86)
        }
        
        dragHandleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(5)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dragHandleView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        scroll.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(closeButton.snp.top).offset(-12)
            make.height.greaterThanOrEqualTo(220)
        }
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scroll.contentLayoutGuide).inset(16)
            make.width.equalTo(scroll.frameLayoutGuide).offset(-32)
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(38)
        }
        
        contentStack.addArrangedSubview(makeSwitchRow(title: "是否开启声音", switchView: soundSwitch))
        
        let rateTitle = UILabel()
        rateTitle.text = "播放速度调整 (0.5 - 2.0)"
        rateTitle.font = .systemFont(ofSize: 16, weight: .medium)
        rateTitle.textColor = .white
        contentStack.addArrangedSubview(rateTitle)
        contentStack.addArrangedSubview(rateSlider)
        rateValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        rateValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        contentStack.addArrangedSubview(rateValueLabel)
        
        contentStack.addArrangedSubview(makeSwitchRow(title: "支持锁定屏幕播放", switchView: lockScreenSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: "定时自动关闭播放", switchView: autoStopSwitch))
        contentStack.addArrangedSubview(autoStopSegment)
        contentStack.addArrangedSubview(autoStopSlider)
        autoStopValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        autoStopValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        contentStack.addArrangedSubview(autoStopValueLabel)
        
        let playOptionsTitle = UILabel()
        playOptionsTitle.text = "播放选项"
        playOptionsTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        playOptionsTitle.textColor = .white
        contentStack.addArrangedSubview(playOptionsTitle)
        contentStack.addArrangedSubview(makeSwitchRow(title: "播放语法 sentence_pattern", switchView: patternSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: "播放中文 translation", switchView: translationSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: "播放英文 original", switchView: originalSwitch))
        
        startButton.setTitle("开始播放", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(startButton)
        startButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        
        rateSlider.addTarget(self, action: #selector(rateChanged), for: .valueChanged)
        autoStopSlider.addTarget(self, action: #selector(autoStopChanged), for: .valueChanged)
        autoStopSegment.addTarget(self, action: #selector(autoStopPresetChanged), for: .valueChanged)
        soundSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        lockScreenSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        autoStopSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        patternSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        translationSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        originalSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        view.addGestureRecognizer(tapGesture)
        containerView.addGestureRecognizer(UITapGestureRecognizer())
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    private func applyConfig() {
        isApplyingConfig = true
        soundSwitch.isOn = config.enableSound
        rateSlider.value = config.playbackRate
        lockScreenSwitch.isOn = config.lockScreenPlayback
        autoStopSwitch.isOn = config.autoStopEnabled
        autoStopSlider.value = Float(config.autoStopMinutes)
        patternSwitch.isOn = config.playSentencePattern
        translationSwitch.isOn = config.playTranslation
        originalSwitch.isOn = config.playOriginal
        
        rateChanged()
        autoStopChanged()
        autoStopPresetChanged()
        isApplyingConfig = false
    }
    
    private func makeSwitchRow(title: String, switchView: UISwitch) -> UIView {
        let row = UIView()
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        row.addSubview(label)
        row.addSubview(switchView)
        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(switchView.snp.leading).offset(-8)
        }
        switchView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return row
    }
    
    @objc private func closeTapped() {
        persistCurrentConfig()
        dismiss(animated: true)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began, .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            if translation.y > 120 || velocity > 900 {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.22) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    @objc private func rateChanged() {
        rateValueLabel.text = String(format: "当前速度: %.2fx", rateSlider.value)
        persistCurrentConfig()
    }
    
    @objc private func autoStopChanged() {
        let minutes = Int(autoStopSlider.value.rounded())
        autoStopValueLabel.text = "自定义: \(minutes) 分钟"
        persistCurrentConfig()
    }
    
    @objc private func autoStopPresetChanged() {
        switch autoStopSegment.selectedSegmentIndex {
        case 1: autoStopSlider.value = 5
        case 2: autoStopSlider.value = 15
        case 3: autoStopSlider.value = 30
        default: break
        }
        autoStopChanged()
    }
    
    @objc private func anySwitchChanged() {
        persistCurrentConfig()
    }
    
    @objc private func startTapped() {
        let newConfig = currentConfigFromUI()
        ImmersiveConfigStore.save(newConfig)
        let startHandler = onStart
        dismiss(animated: true) {
            startHandler?(newConfig)
        }
    }
    
    private func currentConfigFromUI() -> ImmersiveReadingConfig {
        let minutes = Int(autoStopSlider.value.rounded())
        return ImmersiveReadingConfig(
            enableSound: soundSwitch.isOn,
            playbackRate: rateSlider.value,
            lockScreenPlayback: lockScreenSwitch.isOn,
            autoStopEnabled: autoStopSwitch.isOn,
            autoStopMinutes: minutes,
            playSentencePattern: patternSwitch.isOn,
            playTranslation: translationSwitch.isOn,
            playOriginal: originalSwitch.isOn
        )
    }
    
    private func persistCurrentConfig() {
        if isApplyingConfig { return }
        let newConfig = currentConfigFromUI()
        config = newConfig
        ImmersiveConfigStore.save(newConfig)
    }
}
