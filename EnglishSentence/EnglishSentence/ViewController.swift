import UIKit
import SnapKit

// MARK: - Configuration
// Moved to shared location or keep here if it's app-wide config
// For now, it's used by ViewModel, so we can keep it here or move to a separate file.
// Since SentenceViewModel uses it, and WordCell uses it (via VM), it's fine.

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    // MARK: - ViewModel
    private var viewModel = SentenceViewModel()
    
    // MARK: - UI Components
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let backgroundDimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8) // Dark mask with 80% opacity
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear // Transparent to show background
        cv.delegate = self
        cv.dataSource = self
        cv.register(WordCell.self, forCellWithReuseIdentifier: WordCell.identifier)
        return cv
    }()
    
    private let patternLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let translationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let englishSentenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let translationAudioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "speaker.wave.3.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    
    private let englishAudioButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "speaker.wave.3.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        btn.setImage(UIImage(systemName: "chevron.left.circle", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        return btn
    }()
    
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        btn.setImage(UIImage(systemName: "chevron.right.circle", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return btn
    }()
    
    private let settingsButton: UIButton = {
        let btn = UIButton(type: .system)
        // Use a gear icon if available, otherwise text
        if let image = UIImage(systemName: "gearshape.fill") {
            btn.setImage(image, for: .normal)
        } else {
            btn.setTitle("Settings", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return btn
    }()
    
    private let bookshelfButton: UIButton = {
        let btn = UIButton(type: .system)
        if let image = UIImage(systemName: "books.vertical.fill") {
            btn.setImage(image, for: .normal)
        } else {
            btn.setTitle("Books", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(bookshelfTapped), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupUI()
        setupBindings()
        viewModel.loadData()
        updateBackground() // Set initial background
        
        translationAudioButton.addTarget(self, action: #selector(translationAudioTapped), for: .touchUpInside)
        englishAudioButton.addTarget(self, action: #selector(englishAudioTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(backgroundDimmingView)
        view.addSubview(collectionView)
        view.addSubview(patternLabel)
        view.addSubview(translationLabel)
        view.addSubview(englishSentenceLabel)
        view.addSubview(translationAudioButton)
        view.addSubview(englishAudioButton)
        view.addSubview(settingsButton)
        view.addSubview(bookshelfButton)
        
        view.addSubview(prevButton)
        view.addSubview(nextButton)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundDimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(44)
        }
        
        bookshelfButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(settingsButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.55) // Adjusted height
        }
        
        patternLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        translationLabel.snp.makeConstraints { make in
            make.top.equalTo(patternLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-50) // Make room for audio button
        }
        
        translationAudioButton.snp.makeConstraints { make in
            make.centerY.equalTo(translationLabel)
            make.leading.equalTo(translationLabel.snp.trailing).offset(10)
            make.width.height.equalTo(30)
        }
        
        englishSentenceLabel.snp.makeConstraints { make in
            make.top.equalTo(translationLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-50) // Make room for audio button
        }
        
        englishAudioButton.snp.makeConstraints { make in
            make.centerY.equalTo(englishSentenceLabel)
            make.leading.equalTo(englishSentenceLabel.snp.trailing).offset(10)
            make.width.height.equalTo(30)
        }
        
        prevButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.leading.equalToSuperview().offset(44)
            make.width.height.equalTo(50)
        }
        
        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.trailing.equalToSuperview().offset(-44)
            make.width.height.equalTo(50)
        }
    }
    
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func updateUI() {//更新数据
        patternLabel.attributedText = viewModel.currentPatternAttributed
        patternLabel.isHidden = !viewModel.displayConfig.showSentencePattern
        
        translationLabel.attributedText = viewModel.currentTranslationAttributed
        translationLabel.isHidden = !viewModel.displayConfig.showTranslation
        
        englishSentenceLabel.attributedText = viewModel.currentEnglishSentenceAttributed
        englishSentenceLabel.isHidden = !viewModel.displayConfig.showEnglishSentence
        
        translationAudioButton.isHidden = !viewModel.displayConfig.showTranslationAudioButton || !viewModel.displayConfig.showTranslation
        englishAudioButton.isHidden = !viewModel.displayConfig.showEnglishAudioButton || !viewModel.displayConfig.showEnglishSentence
        
        collectionView.reloadData()
        
        prevButton.isEnabled = viewModel.isPrevEnabled
        nextButton.isEnabled = viewModel.isNextEnabled
        
        updateBackground()
    }
    
    @objc private func translationAudioTapped() {
        guard let sentence = viewModel.currentSentence else { return }
        TTSManager.shared.play(sentence.sentenceInfo.translation, language: "zh-CN")
    }
    
    @objc private func englishAudioTapped() {
        guard let sentence = viewModel.currentSentence else { return }
        
        // Determine language based on config
        let language = viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
        let voiceId = viewModel.displayConfig.selectedVoiceIdentifier
        TTSManager.shared.play(sentence.sentenceInfo.original, language: language, voiceIdentifier: voiceId)
    }
    
    private func updateBackground() {
        if viewModel.displayConfig.useCustomBackground,
           let filename = viewModel.displayConfig.customBackgroundImageName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                backgroundImageView.image = image
            } else {
                // Fallback if file not found
                let imageName = "BackgroundImage\(viewModel.displayConfig.backgroundImageIndex)"
                backgroundImageView.image = UIImage(named: imageName)
            }
        } else {
            let imageName = "BackgroundImage\(viewModel.displayConfig.backgroundImageIndex)"
            backgroundImageView.image = UIImage(named: imageName)
        }
        backgroundDimmingView.backgroundColor = UIColor.black.withAlphaComponent(CGFloat(viewModel.displayConfig.maskOpacity))
    }
    
    // MARK: - Actions
    @objc private func prevTapped() {
        viewModel.prevSentence()
    }
    
    @objc private func nextTapped() {
        viewModel.nextSentence()
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController(config: viewModel.displayConfig)
        settingsVC.onConfigChanged = { [weak self] newConfig in
            self?.viewModel.updateConfig(newConfig)
        }
        present(settingsVC, animated: true, completion: nil)
    }
    
    @objc private func bookshelfTapped() {
        let bookshelfVC = BookshelfViewController()
        bookshelfVC.onCourseSelected = { [weak self] course in
            self?.viewModel.loadData(unit: course)
        }
        present(bookshelfVC, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.identifier, for: indexPath) as? WordCell else {
            return UICollectionViewCell()
        }
        
        if let cellViewModel = viewModel.viewModelForCell(at: indexPath.item) {
            cell.configure(with: cellViewModel)
            
            // Handle audio tap
            cell.onAudioTapped = { [weak self] in
                guard let self = self,
                      let analysis = self.viewModel.analysisForCell(at: indexPath.item) else { return }
                
                // Determine language based on config
                let language = self.viewModel.displayConfig.phoneticType == .uk ? "en-GB" : "en-US"
                let voiceId = self.viewModel.displayConfig.selectedVoiceIdentifier
                TTSManager.shared.play(analysis.word, language: language, voiceIdentifier: voiceId)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath),
              let analysis = viewModel.analysisForCell(at: indexPath.item) else { return }
        
        let detailVC = WordDetailViewController(analysis: analysis, color: AppTheme.color(forTag: analysis.tag))
        detailVC.modalPresentationStyle = .popover
        
        if let popover = detailVC.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            popover.permittedArrowDirections = [] // Remove arrow to make it a rounded rectangle
            popover.delegate = self
            popover.backgroundColor = AppTheme.color(forTag: analysis.tag)
        }
        
        present(detailVC, animated: true, completion: nil)
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Force popover on iPhone
    }
}
