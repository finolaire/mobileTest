import UIKit
import SnapKit
import AVFoundation

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private var currentConfig: DisplayConfig
    var onConfigChanged: ((DisplayConfig) -> Void)?
    private var voiceButton: UIButton?
    private var backgroundSegmentedControl: UISegmentedControl?
    private var customBackgroundButton: UIButton?
    
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
        label.text = AppStrings.Settings.title
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
        btn.setTitle(AppStrings.Settings.close, for: .normal)
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
        addSwitchRow(title: AppStrings.Settings.showPhonetics, isOn: currentConfig.showPhonetics, action: #selector(phoneticsToggled(_:)))
        
        // Add Accent and Voice settings
        addPhoneticSettings()
        
        addSwitchRow(title: AppStrings.Settings.showWordType, isOn: currentConfig.showWordType, action: #selector(wordTypeToggled(_:)))
        
        // Combined rows: 中文翻译 / 英文原句 / 显示句型（句型在英文下方）
        addCombinedRow(title1: AppStrings.Settings.translation, isOn1: currentConfig.showTranslation, action1: #selector(translationToggled(_:)),
                      title2: AppStrings.Settings.translationAudio, isOn2: currentConfig.showTranslationAudioButton, action2: #selector(translationAudioButtonToggled(_:)))
        
        addCombinedRow(title1: AppStrings.Settings.english, isOn1: currentConfig.showEnglishSentence, action1: #selector(englishSentenceToggled(_:)),
                      title2: AppStrings.Settings.englishAudio, isOn2: currentConfig.showEnglishAudioButton, action2: #selector(englishAudioButtonToggled(_:)))
        
        addCombinedRow(title1: AppStrings.Settings.showPattern, isOn1: currentConfig.showSentencePattern, action1: #selector(patternToggled(_:)),
                      title2: AppStrings.Settings.patternAudio, isOn2: currentConfig.speakSentencePattern, action2: #selector(patternSpeakToggled(_:)))
        
        addSwitchRow(title: AppStrings.Settings.showWordAudio, isOn: currentConfig.showAudioButton, action: #selector(audioButtonToggled(_:)))
        
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
        accentLabel.text = AppStrings.Settings.accent
        accentLabel.textColor = .white
        accentLabel.font = UIFont.systemFont(ofSize: 16)
        
        let accentSegment = UISegmentedControl(items: [AppStrings.Settings.accentUK, AppStrings.Settings.accentUS])
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
        voiceLabel.text = AppStrings.Settings.voice
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
        return AppStrings.Settings.voiceDefault
    }
    
    @objc private func accentChanged(_ sender: UISegmentedControl) {
        let newType: DisplayConfig.PhoneticType = sender.selectedSegmentIndex == 0 ? .uk : .us
        if currentConfig.phoneticType != newType {
            currentConfig.phoneticType = newType
            currentConfig.selectedVoiceIdentifier = nil // Reset voice when accent changes
            voiceButton?.setTitle(AppStrings.Settings.voiceDefault, for: .normal)
            onConfigChanged?(currentConfig)
        }
    }
    
    @objc private func voiceButtonTapped() {
        let language = currentConfig.phoneticType == .uk ? "en-GB" : "en-US"
        let voices = TTSManager.shared.getVoices(for: language)
        
        let alert = UIAlertController(title: AppStrings.Settings.selectVoiceTitle, message: nil, preferredStyle: .actionSheet)
        
        // Default option
        let defaultAction = UIAlertAction(title: AppStrings.Settings.voiceDefault, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.currentConfig.selectedVoiceIdentifier = nil
            self.voiceButton?.setTitle(AppStrings.Settings.voiceDefault, for: .normal)
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
        
        let cancelAction = UIAlertAction(title: AppStrings.Settings.cancel, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = voiceButton
            popover.sourceRect = voiceButton?.bounds ?? .zero
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func addCombinedRow(title1: String, isOn1: Bool, action1: Selector, title2: String, isOn2: Bool, action2: Selector) {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.distribution = .fill
        rowStack.alignment = .center
        rowStack.spacing = 8
        
        // Group 1
        let label1 = UILabel()
        label1.text = title1
        label1.textColor = .white
        label1.font = UIFont.systemFont(ofSize: 14)
        
        let toggle1 = UISwitch()
        toggle1.isOn = isOn1
        toggle1.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        toggle1.addTarget(self, action: action1, for: .valueChanged)
        
        // Group 2
        let label2 = UILabel()
        label2.text = title2
        label2.textColor = .white
        label2.font = UIFont.systemFont(ofSize: 14)
        
        let toggle2 = UISwitch()
        toggle2.isOn = isOn2
        toggle2.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        toggle2.addTarget(self, action: action2, for: .valueChanged)
        
        rowStack.addArrangedSubview(label1)
        rowStack.addArrangedSubview(toggle1)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rowStack.addArrangedSubview(spacer)
        
        rowStack.addArrangedSubview(label2)
        rowStack.addArrangedSubview(toggle2)
        
        stackView.addArrangedSubview(rowStack)
        
        rowStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
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
        label.text = AppStrings.Settings.background
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        
        let controlsStack = UIStackView()
        controlsStack.axis = .horizontal
        controlsStack.spacing = 16
        controlsStack.alignment = .center
        
        let segmentedControl = UISegmentedControl(items: [AppStrings.Settings.bg0, AppStrings.Settings.bg1, AppStrings.Settings.bg2, AppStrings.Settings.bg3])
        if currentConfig.useCustomBackground {
            segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        } else {
            segmentedControl.selectedSegmentIndex = currentConfig.backgroundImageIndex
        }
        segmentedControl.selectedSegmentTintColor = .systemBlue
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        segmentedControl.addTarget(self, action: #selector(backgroundChanged(_:)), for: .valueChanged)
        self.backgroundSegmentedControl = segmentedControl
        
        let addImageBtn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        addImageBtn.setImage(UIImage(systemName: "photo.badge.plus", withConfiguration: config), for: .normal)
        addImageBtn.tintColor = currentConfig.useCustomBackground ? .systemBlue : .white
        addImageBtn.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
        self.customBackgroundButton = addImageBtn
        
        controlsStack.addArrangedSubview(segmentedControl)
        controlsStack.addArrangedSubview(addImageBtn)
        
        rowStack.addArrangedSubview(label)
        rowStack.addArrangedSubview(controlsStack)
        
        stackView.addArrangedSubview(rowStack)
    }
    
    private func addOpacitySlider() {
        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.spacing = 8
        rowStack.alignment = .fill
        
        let label = UILabel()
        label.text = AppStrings.Settings.maskOpacity(value: Float(currentConfig.maskOpacity))
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
            label?.text = AppStrings.Settings.maskOpacity(value: slider.value)
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
    
    @objc private func patternSpeakToggled(_ sender: UISwitch) {
        currentConfig.speakSentencePattern = sender.isOn
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
        currentConfig.useCustomBackground = false
        customBackgroundButton?.tintColor = .white
        onConfigChanged?(currentConfig)
    }
    
    @objc private func addImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        // Save image to documents directory
        if let data = image.jpegData(compressionQuality: 0.8) {
            let filename = "custom_background.jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            try? data.write(to: url)
            
            currentConfig.customBackgroundImageName = filename
            currentConfig.useCustomBackground = true
            
            // Update UI
            backgroundSegmentedControl?.selectedSegmentIndex = UISegmentedControl.noSegment
            customBackgroundButton?.tintColor = .systemBlue
            
            onConfigChanged?(currentConfig)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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
