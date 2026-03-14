import UIKit
import SnapKit

class ReadingViewController: UIViewController {
    
    // MARK: - Properties
    private let courseUnit: CourseUnit
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .black
        tv.separatorStyle = .singleLine
        tv.separatorColor = UIColor(white: 0.2, alpha: 1.0)
        tv.register(ReadingCell.self, forCellReuseIdentifier: ReadingCell.identifier)
        return tv
    }()
    
    // MARK: - Init
    init(courseUnit: CourseUnit) {
        self.courseUnit = courseUnit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = courseUnit.unitName
        view.backgroundColor = .black
        
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDelegate & DataSource
extension ReadingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseUnit.sentences.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReadingCell.identifier, for: indexPath) as? ReadingCell else {
            return UITableViewCell()
        }
        
        let sentence = courseUnit.sentences[indexPath.row]
        cell.configure(with: sentence)
        
        cell.onWordTapped = { [weak self] analysis in
            self?.showWordDetail(analysis: analysis, sourceView: cell)
        }
        
        return cell
    }
    
    private func showWordDetail(analysis: WordAnalysis, sourceView: UIView) {
        let detailVC = WordDetailViewController(analysis: analysis, color: AppTheme.color(forTag: analysis.tag))
        detailVC.modalPresentationStyle = .popover
        
        if let popover = detailVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = .any
            popover.delegate = self
            popover.backgroundColor = AppTheme.color(forTag: analysis.tag)
        }
        
        present(detailVC, animated: true, completion: nil)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ReadingViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - ReadingCell
class ReadingCell: UITableViewCell, UITextViewDelegate {
    
    static let identifier = "ReadingCell"
    
    var onWordTapped: ((WordAnalysis) -> Void)?
    private var currentSentence: Sentence?
    
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        tv.delegate = self
        tv.linkTextAttributes = [:] // Remove default link styling (blue/underline)
        return tv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with sentence: Sentence) {
        self.currentSentence = sentence
        
        let fullText = NSMutableAttributedString()
        
        // 1. Original Sentence (Clickable & Colored)
        let originalText = buildOriginalAttributed(sentence: sentence)
        fullText.append(originalText)
        fullText.append(NSAttributedString(string: "\n\n"))
        
        // 2. Translation (Colored)
        let translationText = buildTranslationAttributed(sentence: sentence)
        fullText.append(translationText)
        fullText.append(NSAttributedString(string: "\n\n"))
        
        // 3. Pattern (Colored)
        let patternText = buildPatternAttributed(sentence: sentence)
        fullText.append(patternText)
        
        textView.attributedText = fullText
    }
    
    // MARK: - Attributed String Builders
    
    private func buildOriginalAttributed(sentence: Sentence) -> NSAttributedString {
        let original = sentence.sentenceInfo.original
        let attrStr = NSMutableAttributedString(string: original, attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ])
        
        // Track ranges to avoid overlap
        var coloredRanges: [NSRange] = []
        
        for (index, analysis) in sentence.analysis.enumerated() {
            let color = AppTheme.color(forTag: analysis.tag)
            let word = analysis.word
            let ranges = original.ranges(of: word)
            
            for range in ranges {
                let isOverlapping = coloredRanges.contains { NSIntersectionRange($0, range).length > 0 }
                if !isOverlapping {
                    attrStr.addAttribute(.foregroundColor, value: color, range: range)
                    // Add link with index to identify the word analysis
                    let link = "word://\(index)"
                    attrStr.addAttribute(.link, value: link, range: range)
                    coloredRanges.append(range)
                    break
                }
            }
        }
        return attrStr
    }
    
    private func buildTranslationAttributed(sentence: Sentence) -> NSAttributedString {
        let translation = sentence.sentenceInfo.translation
        let attrStr = NSMutableAttributedString(string: translation, attributes: [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.systemFont(ofSize: 16, weight: .regular)
        ])
        
        // Reuse coloring logic from SentenceViewModel if needed
        // For now, let's keep it simple or copy the logic if the user wants it colored by word types
        // The user said "translation...也要根据类型显示不同颜色"
        // Let's try to match Chinese definitions
        
        var coloredRanges: [NSRange] = []
        for analysis in sentence.analysis {
            let color = AppTheme.color(forTag: analysis.tag)
            let definitions = analysis.chineseDefinition.components(separatedBy: "/")
            
            var found = false
            for def in definitions {
                if found { break }
                let ranges = translation.ranges(of: def)
                for range in ranges {
                    let isOverlapping = coloredRanges.contains { NSIntersectionRange($0, range).length > 0 }
                    if !isOverlapping {
                        attrStr.addAttribute(.foregroundColor, value: color, range: range)
                        coloredRanges.append(range)
                        found = true
                        break
                    }
                }
            }
        }
        
        return attrStr
    }
    
    private func buildPatternAttributed(sentence: Sentence) -> NSAttributedString {
        let pattern = sentence.sentenceInfo.sentencePattern
        let attrStr = NSMutableAttributedString()
        
        let components = pattern.components(separatedBy: " + ")
        for (index, component) in components.enumerated() {
            let color = AppTheme.color(forKeyword: component)
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ]
            attrStr.append(NSAttributedString(string: component, attributes: attributes))
            
            if index < components.count - 1 {
                attrStr.append(NSAttributedString(string: " + ", attributes: [
                    .foregroundColor: UIColor.darkGray,
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                ]))
            }
        }
        return attrStr
    }
    
    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "word", let indexStr = URL.host, let index = Int(indexStr) {
            if let sentence = currentSentence, index < sentence.analysis.count {
                onWordTapped?(sentence.analysis[index])
            }
            return false // Don't try to open URL
        }
        return true
    }
}
