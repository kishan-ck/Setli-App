//
//  OnboardingViewController.swift
//  App
//
//  Created on 08/09/26.
//

import UIKit

struct OnboardingSlide {
    let imageName: String
    let title: String
    let subtitle: String
}

class OnboardingCell: UICollectionViewCell {
    static let reuseIdentifier = "OnboardingCell"

    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let contentStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear

        // Logo Image View
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.clipsToBounds = true

        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.07, green: 0.10, blue: 0.16, alpha: 1.0) // #121A28
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // Subtitle Label
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 0.42, green: 0.46, blue: 0.52, alpha: 1.0) // #6B7585
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Content Stack
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.distribution = .fill
        contentStack.spacing = 16

        contentStack.addArrangedSubview(logoImageView)
        contentStack.setCustomSpacing(32, after: logoImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.setCustomSpacing(12, after: titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)

        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 130),
            logoImageView.heightAnchor.constraint(equalToConstant: 130),

            contentStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -30),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
        ])
    }

    func configure(with slide: OnboardingSlide) {
        if let image = UIImage(named: slide.imageName) {
            logoImageView.image = image
        } else {
            // Fallback to blue S icon if image set is loading
            logoImageView.image = UIImage(named: "Splash")
        }
        titleLabel.text = slide.title
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        
        let attributedSubtitle = NSAttributedString(
            string: slide.subtitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor(red: 0.42, green: 0.46, blue: 0.52, alpha: 1.0),
                .paragraphStyle: paragraphStyle
            ]
        )
        subtitleLabel.attributedText = attributedSubtitle
    }
}

class OnboardingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    static let onboardingCompletedKey = "hasCompletedOnboarding"

    public static func resetOnboardingStatus() {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
    }

    var onCompletion: (() -> Void)?

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            imageName: "AppLogo",
            title: "Welcome to Setli",
            subtitle: "Streamline your property maintenance, settlements, and updates all in one place."
        ),
        OnboardingSlide(
            imageName: "AppLogo",
            title: "Track & Manage Requests",
            subtitle: "Effortlessly submit maintenance issues, upload documentation, and receive real-time updates."
        ),
        OnboardingSlide(
            imageName: "AppLogo",
            title: "Seamless Settlement Experience",
            subtitle: "Connect directly with property managers and enjoy a stress-free transition."
        )
    ]

    private var currentIndex: Int = 0
    private var isProgrammaticScroll: Bool = false

    private var collectionView: UICollectionView!
    private let pageControl = UIPageControl()
    private let bottomControlsContainer = UIView()
    private let leftArrowButton = UIButton(type: .system)
    private let rightArrowButton = UIButton(type: .system)
    private let getStartedButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateControls(for: 0, animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private func setupUI() {
        view.backgroundColor = .white

        // Layout CollectionView
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: OnboardingCell.reuseIdentifier)

        view.addSubview(collectionView)

        // Page Control
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPageIndicatorTintColor = UIColor(red: 0.0, green: 0.45, blue: 1.0, alpha: 1.0) // #0073FF
        pageControl.pageIndicatorTintColor = UIColor(red: 0.86, green: 0.89, blue: 0.93, alpha: 1.0)
        view.addSubview(pageControl)

        // Bottom Controls Container
        bottomControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomControlsContainer)

        setupButtons()

        NSLayoutConstraint.activate([
            // Collection view fills top down to page control
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -16),

            // Page control centered above bottom buttons
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: bottomControlsContainer.topAnchor, constant: -20),
            pageControl.heightAnchor.constraint(equalToConstant: 20),

            // Bottom controls container
            bottomControlsContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            bottomControlsContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            bottomControlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            bottomControlsContainer.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func setupButtons() {
        let arrowSymbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)

        // Left Arrow Button (circular, gray background)
        leftArrowButton.translatesAutoresizingMaskIntoConstraints = false
        let leftImage = UIImage(systemName: "arrow.left", withConfiguration: arrowSymbolConfig) ?? createArrowImage(isLeft: true)
        leftArrowButton.setImage(leftImage, for: .normal)
        leftArrowButton.tintColor = UIColor(red: 0.20, green: 0.24, blue: 0.30, alpha: 1.0)
        leftArrowButton.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0)
        leftArrowButton.layer.cornerRadius = 27
        leftArrowButton.layer.masksToBounds = true
        leftArrowButton.addTarget(self, action: #selector(leftArrowTapped), for: .touchUpInside)
        bottomControlsContainer.addSubview(leftArrowButton)

        // Right Arrow Button (circular, Setli blue background)
        rightArrowButton.translatesAutoresizingMaskIntoConstraints = false
        let rightImage = UIImage(systemName: "arrow.right", withConfiguration: arrowSymbolConfig) ?? createArrowImage(isLeft: false)
        rightArrowButton.setImage(rightImage, for: .normal)
        rightArrowButton.tintColor = .white
        rightArrowButton.backgroundColor = UIColor(red: 0.0, green: 0.45, blue: 1.0, alpha: 1.0) // Setli Blue #0073FF
        rightArrowButton.layer.cornerRadius = 27
        rightArrowButton.layer.masksToBounds = true
        rightArrowButton.addTarget(self, action: #selector(rightArrowTapped), for: .touchUpInside)
        bottomControlsContainer.addSubview(rightArrowButton)

        // "Get Started" Button (pill shape, Setli blue background)
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        getStartedButton.backgroundColor = UIColor(red: 0.0, green: 0.45, blue: 1.0, alpha: 1.0)
        getStartedButton.layer.cornerRadius = 27
        getStartedButton.layer.masksToBounds = true
        getStartedButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        bottomControlsContainer.addSubview(getStartedButton)

        NSLayoutConstraint.activate([
            // Left Arrow Button anchored to bottom-left
            leftArrowButton.leadingAnchor.constraint(equalTo: bottomControlsContainer.leadingAnchor),
            leftArrowButton.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            leftArrowButton.widthAnchor.constraint(equalToConstant: 54),
            leftArrowButton.heightAnchor.constraint(equalToConstant: 54),

            // Right Arrow Button anchored to bottom-right
            rightArrowButton.trailingAnchor.constraint(equalTo: bottomControlsContainer.trailingAnchor),
            rightArrowButton.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            rightArrowButton.widthAnchor.constraint(equalToConstant: 54),
            rightArrowButton.heightAnchor.constraint(equalToConstant: 54),

            // Get Started Button anchored to bottom-right
            getStartedButton.trailingAnchor.constraint(equalTo: bottomControlsContainer.trailingAnchor),
            getStartedButton.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor),
            getStartedButton.heightAnchor.constraint(equalToConstant: 54),
            getStartedButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }

    // Dynamic visibility conforming strictly to specifications:
    // Index 0: only bottom-right arrow.
    // Index 1: bottom-left arrow and right-side arrow.
    // Index 2: bottom-left arrow and 'Get Started' button on right side.
    private func updateControls(for index: Int, animated: Bool) {
        currentIndex = index
        pageControl.currentPage = index

        let showLeft = (index > 0)
        let showRightArrow = (index < slides.count - 1)
        let showGetStarted = (index == slides.count - 1)

        // Make targets visible before animating alpha
        if showLeft { leftArrowButton.isHidden = false }
        if showRightArrow { rightArrowButton.isHidden = false }
        if showGetStarted { getStartedButton.isHidden = false }

        let animations = {
            self.leftArrowButton.alpha = showLeft ? 1.0 : 0.0
            self.leftArrowButton.isUserInteractionEnabled = showLeft

            self.rightArrowButton.alpha = showRightArrow ? 1.0 : 0.0
            self.rightArrowButton.isUserInteractionEnabled = showRightArrow

            self.getStartedButton.alpha = showGetStarted ? 1.0 : 0.0
            self.getStartedButton.isUserInteractionEnabled = showGetStarted
        }

        let completion: (Bool) -> Void = { _ in
            if !showLeft { self.leftArrowButton.isHidden = true }
            if !showRightArrow { self.rightArrowButton.isHidden = true }
            if !showGetStarted { self.getStartedButton.isHidden = true }
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: animations,
                completion: completion
            )
        } else {
            animations()
            completion(true)
        }
    }

    @objc private func leftArrowTapped() {
        guard currentIndex > 0 else { return }
        let prevIndex = currentIndex - 1
        scrollToPage(at: prevIndex)
    }

    @objc private func rightArrowTapped() {
        guard currentIndex < slides.count - 1 else { return }
        let nextIndex = currentIndex + 1
        scrollToPage(at: nextIndex)
    }

    @objc private func getStartedTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        UserDefaults.standard.set(true, forKey: OnboardingViewController.onboardingCompletedKey)
        onCompletion?()
    }

    private func scrollToPage(at index: Int) {
        guard index >= 0 && index < slides.count else { return }
        isProgrammaticScroll = true
        let targetOffset = CGPoint(x: CGFloat(index) * collectionView.frame.width, y: 0)
        collectionView.setContentOffset(targetOffset, animated: true)
        updateControls(for: index, animated: true)
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnboardingCell.reuseIdentifier,
            for: indexPath
        ) as? OnboardingCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: slides[indexPath.item])
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - UIScrollViewDelegate (Swipe Detection & Programmatic Scroll Guard)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Ignore scroll events caused by programmatic button clicks to prevent flickering
        guard !isProgrammaticScroll, scrollView.isDragging || scrollView.isDecelerating else { return }
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        let fractionalPage = scrollView.contentOffset.x / pageWidth
        let roundedIndex = Int(round(fractionalPage))
        if roundedIndex != currentIndex && roundedIndex >= 0 && roundedIndex < slides.count {
            updateControls(for: roundedIndex, animated: true)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        let newIndex = Int(round(scrollView.contentOffset.x / pageWidth))
        if newIndex != currentIndex && newIndex >= 0 && newIndex < slides.count {
            updateControls(for: newIndex, animated: true)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }

    // Fallback arrow image generator if SF Symbols are unavailable
    private func createArrowImage(isLeft: Bool) -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let path = UIBezierPath()
            if isLeft {
                path.move(to: CGPoint(x: 15, y: 5))
                path.addLine(to: CGPoint(x: 8, y: 12))
                path.addLine(to: CGPoint(x: 15, y: 19))
            } else {
                path.move(to: CGPoint(x: 9, y: 5))
                path.addLine(to: CGPoint(x: 16, y: 12))
                path.addLine(to: CGPoint(x: 9, y: 19))
            }
            path.lineWidth = 2.5
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            UIColor.white.setStroke()
            path.stroke()
        }.withRenderingMode(.alwaysTemplate)
    }
}
