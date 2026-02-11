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
    
    init(analysis: WordAnalysis, config: DisplayConfig) {
        self.word = analysis.word
        
        switch config.phoneticType {
        case .uk:
            self.phonetic = analysis.phonetics.uk
        case .us:
            self.phonetic = analysis.phonetics.us
        }
        
        self.type = analysis.type
        self.isPhoneticsHidden = !config.showPhonetics
        self.isTypeHidden = !config.showWordType
        
        // Color logic moved to ViewModel
        switch analysis.tag {
        case "pronoun_subject": self.wordColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0) // Light Blue
        case "verb_be": self.wordColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Light Red
        case "article_indefinite": self.wordColor = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0) // Light Green
        case "noun_object": self.wordColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) // Yellow/Orange
        default: self.wordColor = .white
        }
    }
}

// MARK: - WordCell
class WordCell: UICollectionViewCell {
    static let identifier = "WordCell"
    
    private let wordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let phoneticLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .orange
        label.textAlignment = .center
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(wordLabel)
        stackView.addArrangedSubview(phoneticLabel)
        stackView.addArrangedSubview(typeLabel)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(40)
        }
    }
    
    func configure(with viewModel: WordCellViewModel) {
        wordLabel.text = viewModel.word
        wordLabel.textColor = viewModel.wordColor
        phoneticLabel.text = viewModel.phonetic
        phoneticLabel.isHidden = viewModel.isPhoneticsHidden
        typeLabel.text = viewModel.type
        typeLabel.isHidden = viewModel.isTypeHidden
    }
}
