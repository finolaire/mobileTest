import UIKit
import SnapKit

class BookshelfViewController: UIViewController {

    var onCourseSelected: ((CourseUnit) -> Void)?
    
    // View Model for sections
    struct SectionViewModel {
        let title: String
        let courses: [CourseUnit]
        var isExpanded: Bool
    }
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain) // Changed to plain for tree look
        tv.register(CourseTreeCell.self, forCellReuseIdentifier: "CourseTreeCell")
        tv.register(CourseSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none // Remove separators for cleaner tree look
        return tv
    }()
    
    private var sections: [SectionViewModel] = []
    private var currentCourseId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Bookshelf"
        
        setupUI()
        loadCourses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh current course ID in case it changed elsewhere
        currentCourseId = CourseManager.shared.getLastPlayedCourseId()
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshCourses))
    }
    
    @objc private func refreshCourses() {
        loadCourses()
    }
    
    private func loadCourses() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let rawSections = CourseManager.shared.getAllCourses(forceReload: true)
            
            let viewModels = rawSections.map { section in
                SectionViewModel(
                    title: section.categoryName,
                    courses: section.courses,
                    isExpanded: true
                )
            }
            
            let totalCount = rawSections.flatMap { $0.courses }.count
            
            DispatchQueue.main.async {
                self?.sections = viewModels
                self?.title = "Bookshelf (\(totalCount))"
                self?.tableView.reloadData()
                
                if totalCount < 5 {
                    // Show alert if files are missing
                    self?.showMissingFilesAlert(count: totalCount)
                }
            }
        }
    }
    
    private func showMissingFilesAlert(count: Int) {
        let message = "Found \(count) courses. Expected at least 5.\n\nDebug Info:\n- Manifest loaded: \(CourseManager.shared.isManifestLoaded ? "Yes" : "No")\n\nTry this:\n1. Ensure 'SentenceJson' folder is added to Xcode (blue folder icon preferred).\n2. Clean Build Folder (Shift+Cmd+K)."
        let alert = UIAlertController(title: "Missing Files", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func toggleSection(_ sender: UITapGestureRecognizer) {
        guard let header = sender.view as? CourseSectionHeaderView else { return }
        let section = header.sectionIndex
        
        // Toggle state
        sections[section].isExpanded.toggle()
        
        // Update UI with animation
        // We reload the section to update rows
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        
        // Update header arrow state
        header.setExpanded(sections[section].isExpanded, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension BookshelfViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].isExpanded ? sections[section].courses.count : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as? CourseSectionHeaderView else {
            return nil
        }
        
        let viewModel = sections[section]
        header.configure(title: viewModel.title, isExpanded: viewModel.isExpanded, section: section)
        
        // Remove existing gestures
        header.gestureRecognizers?.forEach { header.removeGestureRecognizer($0) }
        
        // Add tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:)))
        header.addGestureRecognizer(tap)
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CourseTreeCell", for: indexPath) as? CourseTreeCell else {
            return UITableViewCell()
        }
        
        let course = sections[indexPath.section].courses[indexPath.row]
        let isCurrent = course.id == currentCourseId
        cell.configure(title: course.unitName, isCurrent: isCurrent)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Highlight selection briefly
        tableView.deselectRow(at: indexPath, animated: true)
        
        let course = sections[indexPath.section].courses[indexPath.row]
        
        // Save as current course
        currentCourseId = course.id
        CourseManager.shared.saveLastPlayedCourseId(course.id)
        
        // Reload to update visuals
        tableView.reloadData()
        
        onCourseSelected?(course)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Custom Views for Tree Look

class CourseSectionHeaderView: UITableViewHeaderFooterView {
    
    var sectionIndex: Int = 0
    
    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let folderImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "folder.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        
        contentView.addSubview(arrowImageView)
        contentView.addSubview(folderImageView)
        contentView.addSubview(titleLabel)
        
        // Indentation for root level
        let leadingOffset = 16
        
        arrowImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(leadingOffset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
        
        folderImageView.snp.makeConstraints { make in
            make.leading.equalTo(arrowImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(folderImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    func configure(title: String, isExpanded: Bool, section: Int) {
        titleLabel.text = title
        self.sectionIndex = section
        setExpanded(isExpanded, animated: false)
    }
    
    func setExpanded(_ isExpanded: Bool, animated: Bool) {
        let rotationAngle: CGFloat = isExpanded ? CGFloat.pi / 2 : 0
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
            }
        } else {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
    }
}

class CourseTreeCell: UITableViewCell {
    
    private let fileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "doc.text") // Or "curlybraces" for JSON look
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .label
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .default
        backgroundColor = .clear
        
        contentView.addSubview(fileImageView)
        contentView.addSubview(titleLabel)
        
        // Indentation for child level (Arrow + Folder + Spacing)
        // 16 + 14 + 8 + 18 + 8 = 64 approx
        let indentation = 50 
        
        fileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(indentation)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(fileImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    func configure(title: String, isCurrent: Bool) {
        titleLabel.text = title
        
        if isCurrent {
            // Highlight style: Bold, Large, Red
            titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
            titleLabel.textColor = .systemRed
            fileImageView.tintColor = .systemRed
        } else {
            // Normal style
            titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            titleLabel.textColor = .label
            fileImageView.tintColor = .secondaryLabel
        }
    }
}
