import UIKit
import AVFoundation
import SnapKit

class IntervalSoundSelectorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    var currentSelection: String?
    var onSelect: ((String) -> Void)?
    
    private let sounds = IntervalSoundDefinitions.allSounds
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.15, alpha: 0.88) // Dark gray with high opacity
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
        label.text = "选择间隔声音"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.register(SoundSelectionCell.self, forCellReuseIdentifier: SoundSelectionCell.identifier)
        tv.rowHeight = 56
        tv.backgroundColor = .clear
        tv.separatorColor = UIColor(white: 1.0, alpha: 0.15)
        return tv
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
    init() {
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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Dimmed background
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(dragHandleView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(closeButton)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(400) // Fixed height or flexible
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
            make.height.equalTo(24)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }
        
        // Tap outside to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // Drag gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // If the touch is inside the container view, do not handle the tap gesture (which dismisses the VC)
        let location = touch.location(in: view)
        if containerView.frame.contains(location) {
            return false
        }
        return true
    }
    
    // MARK: - Actions
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
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SoundSelectionCell.identifier, for: indexPath) as? SoundSelectionCell else {
            return UITableViewCell()
        }
        
        let sound = sounds[indexPath.row]
        let isSelected = sound == currentSelection
        
        cell.configure(name: sound, isSelected: isSelected)
        
        cell.onPlayTapped = { [weak self] in
            self?.playSound(named: sound)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sound = sounds[indexPath.row]
        onSelect?(sound)
        dismiss(animated: true)
    }
    
    private func playSound(named name: String) {
        // 1. Configure Audio Session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        // 2. Find the file using mapping
        let fileName = IntervalSoundDefinitions.soundFileMapping[name] ?? name
        var soundURL: URL?
        let extensions = ["mp3", "wav", "m4a", "caf"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "Resources/Media")
                ?? Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "Resource")
                ?? Bundle.main.url(forResource: fileName, withExtension: ext) {
                soundURL = url
                break
            }
        }
        
        guard let url = soundURL else {
            print("Error: Sound file '\(fileName)' not found with extensions: \(extensions)")
            let alert = UIAlertController(title: "无法播放", message: "未找到音频文件: \(fileName)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 3. Play
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Playing sound: \(url.lastPathComponent)")
        } catch {
            print("Preview play failed: \(error)")
        }
    }
}

class SoundSelectionCell: UITableViewCell {
    static let identifier = "SoundSelectionCell"
    
    var onPlayTapped: (() -> Void)?
    
    private let nameLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    private let playButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.isHidden = true
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        playButton.setImage(UIImage(systemName: "speaker.wave.2.fill", withConfiguration: config), for: .normal)
        playButton.tintColor = .systemBlue
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkmarkImageView)
        contentView.addSubview(playButton)
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        checkmarkImageView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        playButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
    }
    
    func configure(name: String, isSelected: Bool) {
        nameLabel.text = name
        nameLabel.textColor = .white // Changed to white for dark theme
        checkmarkImageView.isHidden = !isSelected
    }
    
    @objc private func playTapped() {
        onPlayTapped?()
    }
}
