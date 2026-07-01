import UIKit
import SnapKit
import AVFoundation

final class ImmersiveReadingConfigViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
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
        label.text = AppStrings.Immersive.title
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
    
    private let rateSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["0.5x", "1.0x", "1.5x", AppStrings.Immersive.custom])
        segment.selectedSegmentIndex = 1
        return segment
    }()
    
    private let rateSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 2.0
        slider.isHidden = true
        return slider
    }()
    private let rateValueLabel = UILabel()
    
    // Small Sentence Interval
    private let smallIntervalSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["1s", "2s", "3s", AppStrings.Immersive.custom])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    private let smallIntervalSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 5.0
        slider.isHidden = true
        return slider
    }()
    private let smallIntervalValueLabel = UILabel()
    
    // Large Sentence Interval
    private let largeIntervalSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["1s", "2s", "3s", AppStrings.Immersive.custom])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    private let largeIntervalSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 5.0
        slider.isHidden = true
        return slider
    }()
    private let largeIntervalValueLabel = UILabel()
    
    private let intervalSoundSwitch = UISwitch()
    private let intervalSoundButton = UIButton(type: .system)
    private var previewPlayer: AVAudioPlayer?
    
    private let lockScreenSwitch = UISwitch()
    private let autoStopSwitch = UISwitch()
    private let autoStopSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: [AppStrings.Immersive.custom, AppStrings.Immersive.time5Min, AppStrings.Immersive.time15Min, AppStrings.Immersive.time30Min])
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
    private let orderSectionTitle: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Immersive.orderMenuTitle
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        return label
    }()
    private let orderTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        table.layer.cornerRadius = 8
        table.separatorColor = UIColor(white: 1.0, alpha: 0.15)
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        table.rowHeight = 44
        return table
    }()
    private let sentenceCountSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["3", "5", AppStrings.Immersive.all, AppStrings.Immersive.custom])
        segment.selectedSegmentIndex = 2
        return segment
    }()
    private let customSentenceSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 50
        return slider
    }()
    private let customSentenceValueLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    
    private var config: ImmersiveReadingConfig
    private var isApplyingConfig = false
    private var orderTableHeightConstraint: Constraint?
    
    private enum OrderKind: String, CaseIterable {
        case pattern
        case translation
        case original
    }
    
    private struct OrderItem {
        let kind: OrderKind
        let title: String
    }
    
    private var orderItems: [OrderItem] = []
    
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
        
        closeButton.setTitle(AppStrings.Immersive.close, for: .normal)
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
        
        // Playback Speed
        let rateTitle = UILabel()
        rateTitle.text = AppStrings.Immersive.rateTitle
        rateTitle.font = .systemFont(ofSize: 16, weight: .medium)
        rateTitle.textColor = .white
        contentStack.addArrangedSubview(rateTitle)
        contentStack.addArrangedSubview(rateSegment)
        contentStack.addArrangedSubview(rateSlider)
        rateValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        rateValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        rateValueLabel.isHidden = true
        contentStack.addArrangedSubview(rateValueLabel)
        
        // Small Sentence Interval
        let smallIntervalTitle = UILabel()
        smallIntervalTitle.text = AppStrings.Immersive.smallIntervalTitle
        smallIntervalTitle.font = .systemFont(ofSize: 16, weight: .medium)
        smallIntervalTitle.textColor = .white
        contentStack.addArrangedSubview(smallIntervalTitle)
        contentStack.addArrangedSubview(smallIntervalSegment)
        contentStack.addArrangedSubview(smallIntervalSlider)
        smallIntervalValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        smallIntervalValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        smallIntervalValueLabel.isHidden = true
        contentStack.addArrangedSubview(smallIntervalValueLabel)
        
        // Large Sentence Interval
        let largeIntervalTitle = UILabel()
        largeIntervalTitle.text = AppStrings.Immersive.largeIntervalTitle
        largeIntervalTitle.font = .systemFont(ofSize: 16, weight: .medium)
        largeIntervalTitle.textColor = .white
        contentStack.addArrangedSubview(largeIntervalTitle)
        contentStack.addArrangedSubview(largeIntervalSegment)
        contentStack.addArrangedSubview(largeIntervalSlider)
        largeIntervalValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        largeIntervalValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        largeIntervalValueLabel.isHidden = true
        contentStack.addArrangedSubview(largeIntervalValueLabel)
        
        // Interval Sound
        let intervalRow = UIView()
        let intervalLabel = UILabel()
        intervalLabel.text = AppStrings.Immersive.intervalSound
        intervalLabel.font = .systemFont(ofSize: 16, weight: .regular)
        intervalLabel.textColor = .white
        
        intervalSoundButton.setTitle("NotificationSound2", for: .normal)
        intervalSoundButton.setTitleColor(.systemBlue, for: .normal)
        intervalSoundButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        intervalSoundButton.addTarget(self, action: #selector(intervalSoundButtonTapped), for: .touchUpInside)
        
        let intervalSpacer = UIView()
        intervalSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let intervalStack = UIStackView(arrangedSubviews: [intervalLabel, intervalSpacer, intervalSoundButton, intervalSoundSwitch])
        intervalStack.axis = .horizontal
        intervalStack.alignment = .center
        intervalStack.spacing = 12
        
        intervalRow.addSubview(intervalStack)
        intervalStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStack.addArrangedSubview(intervalRow)
        intervalRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(31)
        }
        
        contentStack.addArrangedSubview(makeSwitchRow(title: AppStrings.Immersive.lockScreen, switchView: lockScreenSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: AppStrings.Immersive.autoStop, switchView: autoStopSwitch))
        contentStack.addArrangedSubview(autoStopSegment)
        contentStack.addArrangedSubview(autoStopSlider)
        autoStopValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        autoStopValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        contentStack.addArrangedSubview(autoStopValueLabel)
        
        let playOptionsTitle = UILabel()
        playOptionsTitle.text = AppStrings.Immersive.playOptionsTitle
        playOptionsTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        playOptionsTitle.textColor = .white
        contentStack.addArrangedSubview(playOptionsTitle)
        contentStack.addArrangedSubview(makeSwitchRow(title: AppStrings.Immersive.playEnglish, switchView: originalSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: AppStrings.Immersive.playChinese, switchView: translationSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: AppStrings.Immersive.playPattern, switchView: patternSwitch))
        contentStack.addArrangedSubview(orderSectionTitle)
        contentStack.addArrangedSubview(orderTableView)
        orderTableView.snp.makeConstraints { make in
            orderTableHeightConstraint = make.height.equalTo(44).constraint
        }
        orderTableView.dataSource = self
        orderTableView.delegate = self
        orderTableView.register(UITableViewCell.self, forCellReuseIdentifier: "OrderCell")
        orderTableView.setEditing(true, animated: false)
        
        let sentenceCountTitle = UILabel()
        sentenceCountTitle.text = AppStrings.Immersive.sentenceCountTitle
        sentenceCountTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        sentenceCountTitle.textColor = .white
        contentStack.addArrangedSubview(sentenceCountTitle)
        contentStack.addArrangedSubview(sentenceCountSegment)
        customSentenceValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        customSentenceValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        contentStack.addArrangedSubview(customSentenceSlider)
        contentStack.addArrangedSubview(customSentenceValueLabel)
        
        startButton.setTitle(AppStrings.Immersive.start, for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(startButton)
        startButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        
        // Targets
        rateSegment.addTarget(self, action: #selector(rateSegmentChanged), for: .valueChanged)
        rateSlider.addTarget(self, action: #selector(rateChanged), for: .valueChanged)
        
        smallIntervalSegment.addTarget(self, action: #selector(smallIntervalSegmentChanged), for: .valueChanged)
        smallIntervalSlider.addTarget(self, action: #selector(smallIntervalChanged), for: .valueChanged)
        
        largeIntervalSegment.addTarget(self, action: #selector(largeIntervalSegmentChanged), for: .valueChanged)
        largeIntervalSlider.addTarget(self, action: #selector(largeIntervalChanged), for: .valueChanged)
        
        intervalSoundSwitch.addTarget(self, action: #selector(intervalSoundSwitchChanged), for: .valueChanged)
        autoStopSlider.addTarget(self, action: #selector(autoStopChanged), for: .valueChanged)
        autoStopSegment.addTarget(self, action: #selector(autoStopPresetChanged), for: .valueChanged)
        lockScreenSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        autoStopSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        patternSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        translationSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        originalSwitch.addTarget(self, action: #selector(anySwitchChanged), for: .valueChanged)
        sentenceCountSegment.addTarget(self, action: #selector(sentenceCountOptionChanged), for: .valueChanged)
        customSentenceSlider.addTarget(self, action: #selector(customSentenceChanged), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        view.addGestureRecognizer(tapGesture)
        containerView.addGestureRecognizer(UITapGestureRecognizer())
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        dragHandleView.addGestureRecognizer(panGesture)
    }
    
    private func applyConfig() {
        isApplyingConfig = true
        rateSlider.value = config.playbackRate
        
        // Rate Segment
        let rate = config.playbackRate
        if abs(rate - 0.5) < 0.01 { rateSegment.selectedSegmentIndex = 0 }
        else if abs(rate - 1.0) < 0.01 { rateSegment.selectedSegmentIndex = 1 }
        else if abs(rate - 1.5) < 0.01 { rateSegment.selectedSegmentIndex = 2 }
        else { rateSegment.selectedSegmentIndex = 3 }
        
        // Small Interval
        smallIntervalSlider.value = Float(config.smallSentenceInterval)
        let small = config.smallSentenceInterval
        if abs(small - 1.0) < 0.01 { smallIntervalSegment.selectedSegmentIndex = 0 }
        else if abs(small - 2.0) < 0.01 { smallIntervalSegment.selectedSegmentIndex = 1 }
        else if abs(small - 3.0) < 0.01 { smallIntervalSegment.selectedSegmentIndex = 2 }
        else { smallIntervalSegment.selectedSegmentIndex = 3 }
        
        // Large Interval
        largeIntervalSlider.value = Float(config.largeSentenceInterval)
        let large = config.largeSentenceInterval
        if abs(large - 1.0) < 0.01 { largeIntervalSegment.selectedSegmentIndex = 0 }
        else if abs(large - 2.0) < 0.01 { largeIntervalSegment.selectedSegmentIndex = 1 }
        else if abs(large - 3.0) < 0.01 { largeIntervalSegment.selectedSegmentIndex = 2 }
        else { largeIntervalSegment.selectedSegmentIndex = 3 }
        
        intervalSoundSwitch.isOn = config.enableIntervalSound
        intervalSoundButton.setTitle(config.intervalSoundFile, for: .normal)
        intervalSoundButton.isHidden = !config.enableIntervalSound
        lockScreenSwitch.isOn = config.lockScreenPlayback
        autoStopSwitch.isOn = config.autoStopEnabled
        autoStopSlider.value = Float(config.autoStopMinutes)
        patternSwitch.isOn = config.playSentencePattern
        translationSwitch.isOn = config.playTranslation
        originalSwitch.isOn = true
        originalSwitch.isEnabled = false
        customSentenceSlider.value = Float(min(max(config.customSentenceCount ?? 10, 1), 50))
        switch config.sentenceCountOption ?? "all" {
        case "three": sentenceCountSegment.selectedSegmentIndex = 0
        case "five": sentenceCountSegment.selectedSegmentIndex = 1
        case "custom": sentenceCountSegment.selectedSegmentIndex = 3
        default: sentenceCountSegment.selectedSegmentIndex = 2
        }
        
        rateSegmentChanged()
        smallIntervalSegmentChanged()
        largeIntervalSegmentChanged()
        
        rateChanged()
        smallIntervalChanged()
        largeIntervalChanged()
        
        autoStopChanged()
        autoStopPresetChanged()
        updateSentenceCountUI()
        rebuildOrderItemsFromConfig()
        updateOrderMenuUI()
        isApplyingConfig = false
    }
    
    private func makeSwitchRow(title: String, switchView: UISwitch) -> UIView {
        let row = UIView()
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [label, spacer, switchView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        
        row.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        row.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(31)
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
    
    @objc private func rateSegmentChanged() {
        let isCustom = rateSegment.selectedSegmentIndex == 3
        rateSlider.isHidden = !isCustom
        rateValueLabel.isHidden = !isCustom
        
        switch rateSegment.selectedSegmentIndex {
        case 0: rateSlider.setValue(0.5, animated: true)
        case 1: rateSlider.setValue(1.0, animated: true)
        case 2: rateSlider.setValue(1.5, animated: true)
        default: break
        }
        
        rateChanged()
    }
    
    @objc private func rateChanged() {
        rateValueLabel.text = AppStrings.Immersive.rateValue(value: rateSlider.value)
        persistCurrentConfig()
    }
    
    @objc private func smallIntervalSegmentChanged() {
        let isCustom = smallIntervalSegment.selectedSegmentIndex == 3
        smallIntervalSlider.isHidden = !isCustom
        smallIntervalValueLabel.isHidden = !isCustom
        
        switch smallIntervalSegment.selectedSegmentIndex {
        case 0: smallIntervalSlider.setValue(1.0, animated: true)
        case 1: smallIntervalSlider.setValue(2.0, animated: true)
        case 2: smallIntervalSlider.setValue(3.0, animated: true)
        default: break
        }
        smallIntervalChanged()
    }
    
    @objc private func smallIntervalChanged() {
        smallIntervalValueLabel.text = AppStrings.Immersive.smallIntervalValue(value: smallIntervalSlider.value)
        persistCurrentConfig()
    }
    
    @objc private func largeIntervalSegmentChanged() {
        let isCustom = largeIntervalSegment.selectedSegmentIndex == 3
        largeIntervalSlider.isHidden = !isCustom
        largeIntervalValueLabel.isHidden = !isCustom
        
        switch largeIntervalSegment.selectedSegmentIndex {
        case 0: largeIntervalSlider.setValue(1.0, animated: true)
        case 1: largeIntervalSlider.setValue(2.0, animated: true)
        case 2: largeIntervalSlider.setValue(3.0, animated: true)
        default: break
        }
        largeIntervalChanged()
    }
    
    @objc private func largeIntervalChanged() {
        largeIntervalValueLabel.text = AppStrings.Immersive.largeIntervalValue(value: largeIntervalSlider.value)
        persistCurrentConfig()
    }
    
    @objc private func intervalSoundSwitchChanged() {
        intervalSoundButton.isHidden = !intervalSoundSwitch.isOn
        persistCurrentConfig()
    }
    
    @objc private func intervalSoundButtonTapped() {
        let selectorVC = IntervalSoundSelectorViewController()
        selectorVC.currentSelection = intervalSoundButton.title(for: .normal)
        selectorVC.onSelect = { [weak self] selectedSound in
            self?.intervalSoundButton.setTitle(selectedSound, for: .normal)
            self?.persistCurrentConfig()
        }
        
        present(selectorVC, animated: true)
    }
    
    @objc private func autoStopChanged() {
        let minutes = Int(autoStopSlider.value.rounded())
        autoStopValueLabel.text = AppStrings.Immersive.autoStopValue(minutes: minutes)
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
        originalSwitch.isOn = true
        originalSwitch.isEnabled = false
        rebuildOrderItemsPreservingCurrentOrder()
        updateOrderMenuUI()
        persistCurrentConfig()
    }
    
    @objc private func sentenceCountOptionChanged() {
        updateSentenceCountUI()
        persistCurrentConfig()
    }
    
    @objc private func customSentenceChanged() {
        updateSentenceCountUI()
        persistCurrentConfig()
    }
    
    @objc private func startTapped() {
        let newConfig = currentConfigFromUI()
        print("DEBUG: Start tapped. Config rate: \(newConfig.playbackRate)")
        ImmersiveConfigStore.save(newConfig)
        let startHandler = onStart
        dismiss(animated: true) {
            startHandler?(newConfig)
        }
    }
    
    private func currentConfigFromUI() -> ImmersiveReadingConfig {
        let minutes = Int(autoStopSlider.value.rounded())
        let option: String
        switch sentenceCountSegment.selectedSegmentIndex {
        case 0: option = "three"
        case 1: option = "five"
        case 3: option = "custom"
        default: option = "all"
        }
        return ImmersiveReadingConfig(
            enableSound: true,
            playbackRate: rateSlider.value,
            lockScreenPlayback: lockScreenSwitch.isOn,
            autoStopEnabled: autoStopSwitch.isOn,
            autoStopMinutes: minutes,
            playSentencePattern: patternSwitch.isOn,
            playTranslation: translationSwitch.isOn,
            playOriginal: true,
            sentenceCountOption: option,
            customSentenceCount: Int(customSentenceSlider.value.rounded()),
            orderPattern: orderValue(for: .pattern),
            orderTranslation: orderValue(for: .translation),
            orderOriginal: orderValue(for: .original),
            enableIntervalSound: intervalSoundSwitch.isOn,
            intervalSoundFile: intervalSoundButton.title(for: .normal) ?? IntervalSoundDefinitions.defaultSound,
            smallSentenceInterval: Double(smallIntervalSlider.value),
            largeSentenceInterval: Double(largeIntervalSlider.value)
        )
    }
    
    private func persistCurrentConfig() {
        if isApplyingConfig { return }
        let newConfig = currentConfigFromUI()
        config = newConfig
        ImmersiveConfigStore.save(newConfig)
    }
    
    private func updateSentenceCountUI() {
        let isCustom = sentenceCountSegment.selectedSegmentIndex == 3
        customSentenceSlider.isHidden = !isCustom
        customSentenceValueLabel.isHidden = !isCustom
        customSentenceValueLabel.text = AppStrings.Immersive.customSentenceCount(count: Int(customSentenceSlider.value.rounded()))
    }
    
    private func rebuildOrderItemsFromConfig() {
        let enabledKinds = currentEnabledKinds()
        let source: [(OrderKind, Int, String)] = [
            (.original, config.orderOriginal, AppStrings.Immersive.playEnglish),
            (.translation, config.orderTranslation, AppStrings.Immersive.playChinese),
            (.pattern, config.orderPattern, AppStrings.Immersive.playPattern)
        ]
        
        orderItems = source
            .filter { enabledKinds.contains($0.0) }
            .sorted { $0.1 < $1.1 }
            .map { OrderItem(kind: $0.0, title: $0.2) }
    }
    
    private func rebuildOrderItemsPreservingCurrentOrder() {
        let enabledKinds = currentEnabledKinds()
        var newItems = orderItems.filter { enabledKinds.contains($0.kind) }
        
        let existingKinds = Set(newItems.map(\.kind))
        let source: [(OrderKind, Int, String)] = [
            (.pattern, config.orderPattern, AppStrings.Immersive.playPattern),
            (.translation, config.orderTranslation, AppStrings.Immersive.playChinese),
            (.original, config.orderOriginal, AppStrings.Immersive.playEnglish)
        ]
        let additions = source
            .filter { enabledKinds.contains($0.0) && !existingKinds.contains($0.0) }
            .sorted { $0.1 < $1.1 }
            .map { OrderItem(kind: $0.0, title: $0.2) }
        newItems.append(contentsOf: additions)
        
        orderItems = newItems
    }
    
    private func currentEnabledKinds() -> Set<OrderKind> {
        var kinds: Set<OrderKind> = [.original] // English always on.
        if patternSwitch.isOn { kinds.insert(.pattern) }
        if translationSwitch.isOn { kinds.insert(.translation) }
        return kinds
    }
    
    private func updateOrderMenuUI() {
        orderSectionTitle.isHidden = orderItems.isEmpty
        orderTableView.isHidden = orderItems.isEmpty
        orderTableView.reloadData()
        let height = max(CGFloat(orderItems.count) * orderTableView.rowHeight, 44)
        orderTableHeightConstraint?.update(offset: height)
    }
    
    private func orderValue(for kind: OrderKind) -> Int {
        var orderedKinds = orderItems.map(\.kind)
        for fallback in OrderKind.allCases where !orderedKinds.contains(fallback) {
            orderedKinds.append(fallback)
        }
        return (orderedKinds.firstIndex(of: kind) ?? 0) + 1
    }
    
    // MARK: - UITableViewDataSource / Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell", for: indexPath)
        let item = orderItems[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1). \(item.title)"
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.showsReorderControl = true
        
        let dragHint = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        dragHint.tintColor = UIColor(white: 1.0, alpha: 0.65)
        dragHint.contentMode = .scaleAspectFit
        dragHint.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        cell.accessoryView = dragHint
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return orderItems.count > 1
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moved = orderItems.remove(at: sourceIndexPath.row)
        orderItems.insert(moved, at: destinationIndexPath.row)
        tableView.reloadData() // Refresh row numbers after reordering
        persistCurrentConfig()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
