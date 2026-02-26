import UIKit
import SnapKit
import AVFoundation

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private var currentConfig: DisplayConfig
    var onConfigChanged: ((DisplayConfig) -> Void)?
    private var voiceButton: UIButton?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.15, alpha: 0.8) // Dark gray with 80% opacity
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let dragHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        view.layer.masksToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Close", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Init
    init(config: DisplayConfig) {
        self.currentConfig = config
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Dimmed background
        
        view.addSubview(containerView)
        containerView.addSubview(dragHandleView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)
        containerView.addSubview(closeButton)
        
        // Add switches
        addSwitchRow(title: "Show Phonetics", isOn: currentConfig.showPhonetics, action: #selector(phoneticsToggled(_:)))
        
        // Add Accent and Voice settings
        addPhoneticSettings()
        
        addSwitchRow(title: "Show Word Type", isOn: currentConfig.showWordType, action: #selector(wordTypeToggled(_:)))
        addSwitchRow(title: "Show Pattern", isOn: currentConfig.showSentencePattern, action: #selector(patternToggled(_:)))
        addSwitchRow(title: "Show Translation", isOn: currentConfig.showTranslation, action: #selector(translationToggled(_:)))
        addSwitchRow(title: "Show English Sentence", isOn: currentConfig.showEnglishSentence, action: #selector(englishSentenceToggled(_:)))
        addSwitchRow(title: "Show Word Audio", isOn: currentConfig.showAudioButton, action: #selector(audioButtonToggled(_:)))
        addSwitchRow(title: "Show Translation Audio", isOn: currentConfig.showTranslationAudioButton, action: #selector(translationAudioButtonToggled(_:)))
        addSwitchRow(title: "Show English Audio", isOn: currentConfig.showEnglishAudioButton, action: #selector(englishAudioButtonToggled(_:)))
        
        // Add Background Selector
        addBackgroundSelector()
        
        // Add Opacity Slider
        addOpacitySlider()
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
            // Height will be determined by content
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
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }
        
        // Tap outside to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        view.addGestureRecognizer(tapGesture)
        containerView.addGestureRecognizer(UITapGestureRecognizer()) // Consume tap on container
        
        // Drag gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    private func addPhoneticSettings() {
        // Accent Segmented Control
        let accentStack = UIStackView()
        accentStack.axis = .horizontal
        accentStack.distribution = .equalSpacing
        accentStack.alignment = .center
        
        let accentLabel = UILabel()
        accentLabel.text = "Accent"
        accentLabel.textColor = .white
        accentLabel.font = UIFont.systemFont(ofSize: 16)
        
        let accentSegment = UISegmentedControl(items: ["UK", "US"])
        accentSegment.selectedSegmentIndex = currentConfig.phoneticType == .uk ? 0 : 1
        accentSegment.selectedSegmentTintColor = .systemBlue
        accentSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        accentSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        accentSegment.addTarget(self, action: #selector(accentChanged(_:)), for: .valueChanged)
        
        accentStack.addArrangedSubview(accentLabel)
        accentStack.addArrangedSubview(accentSegment)
        stackView.addArrangedSubview(accentStack)
        
        // Voice Selection Button
        let voiceStack = UIStackView()
        voiceStack.axis = .horizontal
        voiceStack.distribution = .equalSpacing
        voiceStack.alignment = .center
        
        let voiceLabel = UILabel()
        voiceLabel.text = "Voice"
        voiceLabel.textColor = .white
        voiceLabel.font = UIFont.systemFont(ofSize: 16)
        
        let btn = UIButton(type: .system)
        btn.setTitle(currentVoiceName(), for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        self.voiceButton = btn
        
        voiceStack.addArrangedSubview(voiceLabel)
        voiceStack.addArrangedSubview(btn)
        stackView.addArrangedSubview(voiceStack)
    }

    private func currentVoiceName() -> String {
        if let id = currentConfig.selectedVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: id) {
            return voice.name
        }
        return "Default"
    }
    
    @objc private func accentChanged(_ sender: UISegmentedControl) {
        let newType: DisplayConfig.PhoneticType = sender.selectedSegmentIndex == 0 ? .uk : .us
        if currentConfig.phoneticType != newType {
            currentConfig.phoneticType = newType
            currentConfig.selectedVoiceIdentifier = nil // Reset voice when accent changes
            voiceButton?.setTitle("Default", for: .normal)
            onConfigChanged?(currentConfig)
        }
    }
    
    @objc private func voiceButtonTapped() {
        let language = currentConfig.phoneticType == .uk ? "en-GB" : "en-US"
        let voices = TTSManager.shared.getVoices(for: language)
        
        let alert = UIAlertController(title: "Select Voice", message: nil, preferredStyle: .actionSheet)
        
        // Default option
        let defaultAction = UIAlertAction(title: "Default", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.currentConfig.selectedVoiceIdentifier = nil
            self.voiceButton?.setTitle("Default", for: .normal)
            self.onConfigChanged?(self.currentConfig)
        }
        alert.addAction(defaultAction)
        
        for voice in voices {
            let action = UIAlertAction(title: voice.name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.currentConfig.selectedVoiceIdentifier = voice.identifier
                self.voiceButton?.setTitle(voice.name, for: .normal)
                self.onConfigChanged?(self.currentConfig)
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = voiceButton
            popover.sourceRect = voiceButton?.bounds ?? .zero
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func addSwitchRow(title: String, isOn: Bool, action: Selector) {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.distribution = .equalSpacing
        rowStack.alignment = .center
        
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.addTarget(self, action: action, for: .valueChanged)
        
        rowStack.addArrangedSubview(label)
        rowStack.addArrangedSubview(toggle)
        
        stackView.addArrangedSubview(rowStack)
    }
    
    private func addBackgroundSelector() {
        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.spacing = 8
        rowStack.alignment = .center
        
        let label = UILabel()
        label.text = "Background"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        
        let segmentedControl = UISegmentedControl(items: ["BG 0", "BG 1", "BG 2", "BG 3"])
        segmentedControl.selectedSegmentIndex = currentConfig.backgroundImageIndex
        segmentedControl.selectedSegmentTintColor = .systemBlue
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        segmentedControl.addTarget(self, action: #selector(backgroundChanged(_:)), for: .valueChanged)
        
        rowStack.addArrangedSubview(label)
        rowStack.addArrangedSubview(segmentedControl)
        
        stackView.addArrangedSubview(rowStack)
    }
    
    private func addOpacitySlider() {
        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.spacing = 8
        rowStack.alignment = .fill
        
        let label = UILabel()
        label.text = "Mask Opacity: \(String(format: "%.1f", currentConfig.maskOpacity))"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = currentConfig.maskOpacity
        slider.addTarget(self, action: #selector(opacityChanged(_:)), for: .valueChanged)
        
        // Store label reference to update it later
        slider.tag = 100 // Simple way to find label if needed, or use closure capture
        
        // Use a wrapper action to update label text
        slider.addAction(UIAction { [weak label] _ in
            label?.text = "Mask Opacity: \(String(format: "%.1f", slider.value))"
        }, for: .valueChanged)
        
        rowStack.addArrangedSubview(label)
        rowStack.addArrangedSubview(slider)
        
        stackView.addArrangedSubview(rowStack)
    }
    
    // MARK: - Actions
    @objc private func phoneticsToggled(_ sender: UISwitch) {
        currentConfig.showPhonetics = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func wordTypeToggled(_ sender: UISwitch) {
        currentConfig.showWordType = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func patternToggled(_ sender: UISwitch) {
        currentConfig.showSentencePattern = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func translationToggled(_ sender: UISwitch) {
        currentConfig.showTranslation = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func englishSentenceToggled(_ sender: UISwitch) {
        currentConfig.showEnglishSentence = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func audioButtonToggled(_ sender: UISwitch) {
        currentConfig.showAudioButton = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func translationAudioButtonToggled(_ sender: UISwitch) {
        currentConfig.showTranslationAudioButton = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func englishAudioButtonToggled(_ sender: UISwitch) {
        currentConfig.showEnglishAudioButton = sender.isOn
        onConfigChanged?(currentConfig)
    }
    
    @objc private func backgroundChanged(_ sender: UISegmentedControl) {
        currentConfig.backgroundImageIndex = sender.selectedSegmentIndex
        onConfigChanged?(currentConfig)
    }
    
    @objc private func opacityChanged(_ sender: UISlider) {
        currentConfig.maskOpacity = sender.value
        onConfigChanged?(currentConfig)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began, .changed:
            containerView.transform = containerView.transform.translatedBy(x: translation.x, y: translation.y)
            gesture.setTranslation(.zero, in: view)
        default:
            break
        }
    }
}
