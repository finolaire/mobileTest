import UIKit
import SnapKit

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
    private let orderSectionTitle: UILabel = {
        let label = UILabel()
        label.text = "排序菜单（仅显示已开启项）"
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
        let segment = UISegmentedControl(items: ["3", "5", "全部", "自定义"])
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
        contentStack.addArrangedSubview(makeSwitchRow(title: "播放英文 ", switchView: originalSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: "播放中文 ", switchView: translationSwitch))
        contentStack.addArrangedSubview(makeSwitchRow(title: "播放语法 ", switchView: patternSwitch))
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
        sentenceCountTitle.text = "播放句型数量"
        sentenceCountTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        sentenceCountTitle.textColor = .white
        contentStack.addArrangedSubview(sentenceCountTitle)
        contentStack.addArrangedSubview(sentenceCountSegment)
        customSentenceValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        customSentenceValueLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        contentStack.addArrangedSubview(customSentenceSlider)
        contentStack.addArrangedSubview(customSentenceValueLabel)
        
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
        soundSwitch.isOn = config.enableSound
        rateSlider.value = config.playbackRate
        lockScreenSwitch.isOn = config.lockScreenPlayback
        autoStopSwitch.isOn = config.autoStopEnabled
        autoStopSlider.value = Float(config.autoStopMinutes)
        patternSwitch.isOn = config.playSentencePattern
        translationSwitch.isOn = config.playTranslation
        originalSwitch.isOn = true
        originalSwitch.isEnabled = false
        customSentenceSlider.value = Float(min(max(config.customSentenceCount ?? 10, 1), 50))
        switch config.sentenceCountOption ?? "all" {
        case "three":
            sentenceCountSegment.selectedSegmentIndex = 0
        case "five":
            sentenceCountSegment.selectedSegmentIndex = 1
        case "custom":
            sentenceCountSegment.selectedSegmentIndex = 3
        default:
            sentenceCountSegment.selectedSegmentIndex = 2
        }
        
        rateChanged()
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
        // English is mandatory and cannot be turned off.
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
        case 0:
            option = "three"
        case 1:
            option = "five"
        case 3:
            option = "custom"
        default:
            option = "all"
        }
        return ImmersiveReadingConfig(
            enableSound: soundSwitch.isOn,
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
            orderOriginal: orderValue(for: .original)
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
        customSentenceValueLabel.text = "自定义数量: \(Int(customSentenceSlider.value.rounded()))"
    }
    
    private func rebuildOrderItemsFromConfig() {
        let enabledKinds = currentEnabledKinds()
        let source: [(OrderKind, Int, String)] = [
            (.original, config.orderOriginal, "播放英文"),
            (.translation, config.orderTranslation, "播放中文"),
            (.pattern, config.orderPattern, "播放语法")
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
            (.pattern, config.orderPattern, "播放语法"),
            (.translation, config.orderTranslation, "播放中文"),
            (.original, config.orderOriginal, "播放英文")
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
