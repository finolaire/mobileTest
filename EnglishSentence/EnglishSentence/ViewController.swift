import UIKit

// MARK: - Configuration
struct DisplayConfig {
    enum PhoneticType {
        case uk
        case us
    }
    var phoneticType: PhoneticType = .uk
    var showWordType: Bool = true
}

class ViewController: UIViewController {

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        // Estimated size to help with self-sizing if needed, but we'll calculate size
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black // Dark background as per sketch
        cv.delegate = self
        cv.dataSource = self
        cv.register(WordCell.self, forCellWithReuseIdentifier: WordCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let patternLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let translationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Previous", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let controlsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Data
    private var courseUnit: CourseUnit?
    private var currentSentenceIndex: Int = 0
    private var displayConfig = DisplayConfig()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(patternLabel)
        view.addSubview(translationLabel)
        
        controlsStack.addArrangedSubview(prevButton)
        controlsStack.addArrangedSubview(nextButton)
        view.addSubview(controlsStack)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            patternLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 20),
            patternLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            patternLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            translationLabel.topAnchor.constraint(equalTo: patternLabel.bottomAnchor, constant: 20),
            translationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            translationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            controlsStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadData() {
        // Try to load from Bundle first, then fallback to direct path (for simulator/dev env)
        if let url = Bundle.main.url(forResource: "sentence_01", withExtension: "json") {
            parseJSON(from: url)
        } else {
            // Fallback for development environment if bundle resource isn't set up yet
            let path = "/Users/apple2026/mobileTest/EnglishSentence/EnglishSentence/SentenceJson/sentence_01.json"
            let url = URL(fileURLWithPath: path)
            parseJSON(from: url)
        }
    }
    
    private func parseJSON(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            courseUnit = try decoder.decode(CourseUnit.self, from: data)
            updateUI()
        } catch {
            print("Error loading JSON: \(error)")
            // Show alert
            let alert = UIAlertController(title: "Error", message: "Failed to load data: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func updateUI() {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return }
        
        let sentence = unit.sentences[currentSentenceIndex]
        
        // Update Labels
        patternLabel.text = sentence.sentenceInfo.sentencePattern
        translationLabel.text = sentence.sentenceInfo.translation
        
        // Update CollectionView
        collectionView.reloadData()
        
        // Update Buttons
        prevButton.isEnabled = currentSentenceIndex > 0
        nextButton.isEnabled = currentSentenceIndex < unit.sentences.count - 1
    }
    
    // MARK: - Actions
    @objc private func prevTapped() {
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            updateUI()
        }
    }
    
    @objc private func nextTapped() {
        guard let unit = courseUnit else { return }
        if currentSentenceIndex < unit.sentences.count - 1 {
            currentSentenceIndex += 1
            updateUI()
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courseUnit?.sentences[currentSentenceIndex].analysis.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.identifier, for: indexPath) as? WordCell else {
            return UICollectionViewCell()
        }
        
        if let wordAnalysis = courseUnit?.sentences[currentSentenceIndex].analysis[indexPath.item] {
            cell.configure(with: wordAnalysis, config: displayConfig)
        }
        
        return cell
    }
    
    // Use automatic size, but we can provide hints if needed
    // The WordCell will use AutoLayout to determine its size
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
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(wordLabel)
        stackView.addArrangedSubview(phoneticLabel)
        stackView.addArrangedSubview(typeLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Add a minimum width to prevent cramping
            contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with data: WordAnalysis, config: DisplayConfig) {
        wordLabel.text = data.word
        wordLabel.textColor = colorForTag(data.tag)
        
        switch config.phoneticType {
        case .uk:
            phoneticLabel.text = data.phonetics.uk
        case .us:
            phoneticLabel.text = data.phonetics.us
        }
        
        typeLabel.text = data.type
        typeLabel.isHidden = !config.showWordType
    }
    
    private func colorForTag(_ tag: String) -> UIColor {
        switch tag {
        case "pronoun_subject": return UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0) // Light Blue
        case "verb_be": return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Light Red
        case "article_indefinite": return UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0) // Light Green
        case "noun_object": return UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) // Yellow/Orange
        default: return .white
        }
    }
}
