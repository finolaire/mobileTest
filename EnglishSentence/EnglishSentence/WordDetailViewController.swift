import UIKit
import SnapKit

class WordDetailViewController: UIViewController {
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    init(analysis: WordAnalysis, color: UIColor) {
        super.init(nibName: nil, bundle: nil)
        setupContent(with: analysis)
        view.backgroundColor = color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.lessThanOrEqualTo(250) // Max width constraint
        }
    }
    
    private func setupContent(with analysis: WordAnalysis) {
        let attributedText = NSMutableAttributedString()
        
        // Chinese Definition (Bold, larger)
        let defAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.white
        ]
        attributedText.append(NSAttributedString(string: analysis.chineseDefinition, attributes: defAttributes))
        
        // New Line
        attributedText.append(NSAttributedString(string: "\n"))
        
        // Explanation (Regular, smaller, lighter color)
        let expAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor(white: 0.95, alpha: 1.0)
        ]
        attributedText.append(NSAttributedString(string: analysis.explanation, attributes: expAttributes))
        
        contentLabel.attributedText = attributedText
    }
    
    // Calculate preferred size based on content
    override var preferredContentSize: CGSize {
        get {
            let targetSize = CGSize(width: 250, height: UIView.layoutFittingCompressedSize.height)
            let size = contentLabel.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            return CGSize(width: size.width + 32, height: size.height + 32) // Add padding (16*2)
        }
        set { super.preferredContentSize = newValue }
    }
}
