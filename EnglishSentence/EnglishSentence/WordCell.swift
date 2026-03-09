import UIKit
import SnapKit

// MARK: - WordCellViewModel
struct WordCellViewModel {
    let word: String
    let phonetic: String
    let type: String
    let wordColor: UIColor
    let isPhoneticsHidden: Bool
    let isTypeHidden: Bool
    let isAudioButtonHidden: Bool
    
    init(analysis: WordAnalysis, config: DisplayConfig) {
        self.word = analysis.word
        
        switch config.phoneticType {
        case .uk:
            self.phonetic = analysis.phonetics.uk ?? ""
        case .us:
            self.phonetic = analysis.phonetics.us ?? ""
        }
        
        self.type = analysis.type
        self.isPhoneticsHidden = !config.showPhonetics
        self.isTypeHidden = !config.showWordType
        self.isAudioButtonHidden = !config.showAudioButton
        
        // Color logic moved to ViewModel
        self.wordColor = AppTheme.color(forTag: analysis.tag)
    }
}

// MARK: - WordCell
class WordCell: UICollectionViewCell {
    static let identifier = "WordCell"
    
    static let allTextAlignment = NSTextAlignment.center
    
    private let wordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = allTextAlignment
        return label
    }()
    
    private let phoneticLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = allTextAlignment
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .orange
        label.textAlignment = allTextAlignment
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let audioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        btn.setImage(UIImage(systemName: "speaker.wave.2.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.alpha = 0.7
        return btn
    }()
    
    var onAudioTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        audioButton.addTarget(self, action: #selector(audioButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(stackView)
        contentView.addSubview(audioButton)
        
        stackView.addArrangedSubview(wordLabel)
        stackView.addArrangedSubview(phoneticLabel)
        stackView.addArrangedSubview(typeLabel)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        audioButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.trailing.equalToSuperview().offset(4)
            make.width.height.equalTo(20)
        }
        
        contentView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(40)
        }
    }
    
    func configure(with viewModel: WordCellViewModel, isImmersiveMode: Bool = false, isPlaying: Bool = false) {
        wordLabel.text = viewModel.word
        wordLabel.textColor = viewModel.wordColor
        phoneticLabel.text = viewModel.phonetic.isEmpty ? " " : viewModel.phonetic
        phoneticLabel.isHidden = viewModel.isPhoneticsHidden
        typeLabel.text = viewModel.type
        typeLabel.isHidden = viewModel.isTypeHidden
        audioButton.isHidden = isImmersiveMode ? true : viewModel.isAudioButtonHidden
        
        updatePlaybackState(isPlaying: isPlaying)
    }
    
    func updatePlaybackState(isPlaying: Bool) {
        audioButton.tintColor = isPlaying ? .systemBlue : .white
        audioButton.alpha = isPlaying ? 1.0 : 0.7
    }
    
    @objc private func audioButtonTapped() {
        onAudioTapped?()
    }
}
