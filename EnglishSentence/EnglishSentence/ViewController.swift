import UIKit
import SnapKit

// MARK: - Configuration
// Moved to shared location or keep here if it's app-wide config
// For now, it's used by ViewModel, so we can keep it here or move to a separate file.
// Since SentenceViewModel uses it, and WordCell uses it (via VM), it's fine.

class ViewController: UIViewController {

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
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Previous", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        return btn
    }()
    
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return btn
    }()
    
    private let controlsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupUI()
        setupBindings()
        viewModel.loadData()
        updateBackground() // Set initial background
    }
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(backgroundDimmingView)
        view.addSubview(collectionView)
        view.addSubview(patternLabel)
        view.addSubview(translationLabel)
        view.addSubview(settingsButton)
        
        controlsStack.addArrangedSubview(prevButton)
        controlsStack.addArrangedSubview(nextButton)
        view.addSubview(controlsStack)
        
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
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        controlsStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.height.equalTo(44)
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
    
    private func updateUI() {
        patternLabel.text = viewModel.currentPattern
        patternLabel.isHidden = !viewModel.displayConfig.showSentencePattern
        
        translationLabel.text = viewModel.currentTranslation
        translationLabel.isHidden = !viewModel.displayConfig.showTranslation
        
        collectionView.reloadData()
        
        prevButton.isEnabled = viewModel.isPrevEnabled
        nextButton.isEnabled = viewModel.isNextEnabled
        
        updateBackground()
    }
    
    private func updateBackground() {
        let imageName = "BackgroundImage\(viewModel.displayConfig.backgroundImageIndex)"
        backgroundImageView.image = UIImage(named: imageName)
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
        }
        
        return cell
    }
}
