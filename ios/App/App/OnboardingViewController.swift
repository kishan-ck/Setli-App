//
//  OnboardingViewController.swift
//  App
//
//  Created on 08/09/26.
//

import UIKit

struct OnboardingSlide {
    let illustrationName: String
    let categoryText: String
    let categoryDotColor: UIColor
    let categoryBgColor: UIColor
    let categoryTextColor: UIColor
    let titlePrefix: String
    let titleHighlight: String
    let subtitle: String

    init(
        illustrationName: String,
        categoryText: String,
        categoryDotHex: String,
        categoryBgHex: String,
        categoryTextHex: String,
        titlePrefix: String,
        titleHighlight: String,
        subtitle: String
    ) {
        self.illustrationName = illustrationName
        self.categoryText = categoryText
        self.categoryDotColor = UIColor(hex: categoryDotHex)
        self.categoryBgColor = UIColor(hex: categoryBgHex)
        self.categoryTextColor = UIColor(hex: categoryTextHex)
        self.titlePrefix = titlePrefix
        self.titleHighlight = titleHighlight
        self.subtitle = subtitle
    }

    init(
        illustrationName: String,
        categoryText: String,
        categoryDotColor: UIColor,
        categoryBgColor: UIColor,
        categoryTextColor: UIColor,
        titlePrefix: String,
        titleHighlight: String,
        subtitle: String
    ) {
        self.illustrationName = illustrationName
        self.categoryText = categoryText
        self.categoryDotColor = categoryDotColor
        self.categoryBgColor = categoryBgColor
        self.categoryTextColor = categoryTextColor
        self.titlePrefix = titlePrefix
        self.titleHighlight = titleHighlight
        self.subtitle = subtitle
    }
}

class OnboardingCell: UICollectionViewCell {
    static let reuseIdentifier = "OnboardingCell"

    private let illustrationImageView = UIImageView()
    private let textStack = UIStackView()
    private let categoryPillContainer = UIView()
    private let categoryPillStack = UIStackView()
    private let categoryDotView = UIView()
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

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

        // Illustration Image View
        illustrationImageView.translatesAutoresizingMaskIntoConstraints = false
        illustrationImageView.contentMode = .scaleAspectFit
        illustrationImageView.clipsToBounds = true
        illustrationImageView.layer.cornerRadius = 16
        contentView.addSubview(illustrationImageView)

        // Category Pill
        categoryDotView.translatesAutoresizingMaskIntoConstraints = false
        categoryDotView.layer.cornerRadius = 3.5
        categoryDotView.clipsToBounds = true

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = AppFont.bold(size: 10)

        categoryPillStack.translatesAutoresizingMaskIntoConstraints = false
        categoryPillStack.axis = .horizontal
        categoryPillStack.alignment = .center
        categoryPillStack.spacing = 6
        categoryPillStack.addArrangedSubview(categoryDotView)
        categoryPillStack.addArrangedSubview(categoryLabel)

        categoryPillContainer.translatesAutoresizingMaskIntoConstraints = false
        categoryPillContainer.layer.cornerRadius = 12
        categoryPillContainer.clipsToBounds = true
        categoryPillContainer.addSubview(categoryPillStack)

        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left

        // Subtitle Label
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .left

        // Text Stack (Left aligned)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.distribution = .fill
        textStack.spacing = 12

        textStack.addArrangedSubview(categoryPillContainer)
        textStack.setCustomSpacing(10, after: categoryPillContainer)
        textStack.addArrangedSubview(titleLabel)
        textStack.setCustomSpacing(10, after: titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            // Category pill inner constraints
            categoryDotView.widthAnchor.constraint(equalToConstant: 7),
            categoryDotView.heightAnchor.constraint(equalToConstant: 7),

            categoryPillStack.topAnchor.constraint(equalTo: categoryPillContainer.topAnchor, constant: 5),
            categoryPillStack.bottomAnchor.constraint(equalTo: categoryPillContainer.bottomAnchor, constant: -5),
            categoryPillStack.leadingAnchor.constraint(equalTo: categoryPillContainer.leadingAnchor, constant: 10),
            categoryPillStack.trailingAnchor.constraint(equalTo: categoryPillContainer.trailingAnchor, constant: -10),

            // Illustration image view
            illustrationImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            illustrationImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            illustrationImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            illustrationImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.46),

            // Text content stack
            textStack.topAnchor.constraint(equalTo: illustrationImageView.bottomAnchor, constant: 20),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }

    func configure(with slide: OnboardingSlide) {
        // Load custom illustration with fallback
        if let image = UIImage(named: slide.illustrationName) {
            illustrationImageView.image = image
        } else {
            illustrationImageView.image = UIImage(named: "AppLogo")
        }

        // Category Pill Styling
        categoryDotView.backgroundColor = slide.categoryDotColor
        categoryPillContainer.backgroundColor = slide.categoryBgColor
        categoryLabel.text = slide.categoryText
        categoryLabel.textColor = slide.categoryTextColor

        // Dual-color Title (Black + Brand Blue)
        let titleAttr = NSMutableAttributedString()
        let boldFont = AppFont.extraBold(size: 28)

        let prefixPart = NSAttributedString(
            string: slide.titlePrefix,
            attributes: [
                .font: boldFont,
                .foregroundColor: AppColor.textPrimaryDark.color
            ]
        )

        let highlightPart = NSAttributedString(
            string: slide.titleHighlight,
            attributes: [
                .font: boldFont,
                .foregroundColor: AppColor.primaryBlue.color
            ]
        )

        titleAttr.append(prefixPart)
        titleAttr.append(highlightPart)
        titleLabel.attributedText = titleAttr

        // Subtitle with line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .left

        let attributedSubtitle = NSAttributedString(
            string: slide.subtitle,
            attributes: [
                .font: AppFont.regular(size: 15),
                .foregroundColor: AppColor.textSecondaryGray.color,
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
            illustrationName: "Onboarding1",
            categoryText: "ALL-IN-ONE RENT MANAGEMENT",
            categoryDotHex: AppColor.badgeBlueText.hex, // "#1D61E7"
            categoryBgHex: AppColor.badgeBlueBg.hex,     // "#EEF4FF"
            categoryTextHex: AppColor.badgeBlueText.hex, // "#1D61E7"
            titlePrefix: "Manage Your Rent, ",
            titleHighlight: "All in One Place",
            subtitle: "Collect rent, manage tenants, track payments, and keep your rental activity organized from one simple platform."
        ),
        OnboardingSlide(
            illustrationName: "Onboarding2",
            categoryText: "SMART PAYMENT TRACKING",
            categoryDotHex: AppColor.badgeBlueText.hex, // "#1D61E7"
            categoryBgHex: AppColor.badgeBlueBg.hex,     // "#EEF4FF"
            categoryTextHex: AppColor.badgeBlueText.hex, // "#1D61E7"
            titlePrefix: "Track Every Payment ",
            titleHighlight: "With Ease",
            subtitle: "Stay on top of rent collections, payment status, and tenant activity with simple tracking and helpful reminders."
        ),
        OnboardingSlide(
            illustrationName: "Onboarding3",
            categoryText: "REWARDS & SMARTER MANAGEMENT",
            categoryDotHex: AppColor.badgeAmberDot.hex,  // "#F59E0B"
            categoryBgHex: AppColor.badgeAmberBg.hex,    // "#FFF6EB"
            categoryTextHex: AppColor.badgeAmberText.hex, // "#D97706"
            titlePrefix: "Manage Smarter. ",
            titleHighlight: "Earn More.",
            subtitle: "Unlock rewards, discover useful insights, and make your rent management experience simpler and more rewarding."
        ),
        OnboardingSlide(
            illustrationName: "Onboarding4",
            categoryText: "FOR HOSTS & LANDLORDS",
            categoryDotHex: AppColor.badgeAmberDot.hex,  // "#F59E0B"
            categoryBgHex: AppColor.badgeAmberBg.hex,    // "#FFF6EB"
            categoryTextHex: AppColor.badgeAmberText.hex, // "#D97706"
            titlePrefix: "Manage Your Properties ",
            titleHighlight: "With Ease",
            subtitle: "List properties, manage tenants, track rent and stay on top of your property activity from one simple platform."
        ),
        OnboardingSlide(
            illustrationName: "Onboarding5",
            categoryText: "FOR TENANTS",
            categoryDotHex: AppColor.badgeAmberDot.hex,  // "#F59E0B"
            categoryBgHex: AppColor.badgeAmberBg.hex,    // "#FFF6EB"
            categoryTextHex: AppColor.badgeAmberText.hex, // "#D97706"
            titlePrefix: "Your Rental Life, ",
            titleHighlight: "Made Simple",
            subtitle: "Find your rental information, manage payments, stay connected with your host and keep everything organized in one place."
        )
    ]

    private var currentIndex: Int = 0
    private var isProgrammaticScroll: Bool = false

    // Header Views
    private let headerView = UIView()
    private let logoImageView = UIImageView()
    private let brandNameLabel = UILabel()
    private let skipButton = UIButton(type: .system)

    // Collection View
    private var collectionView: UICollectionView!

    // Bottom Controls
    private let bottomControlsContainer = UIView()
    private let primaryActionButton = UIButton(type: .system)
    private let secondaryRowView = UIView()
    private let backButton = UIButton(type: .system)
    private let dotsContainer = UIStackView()
    private var dotViews: [UIView] = []
    private var dotWidthConstraints: [NSLayoutConstraint] = []

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

        setupHeader()
        setupCollectionView()
        setupBottomControls()

        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            // Collection View fills between header and bottom controls
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomControlsContainer.topAnchor, constant: -12),

            // Bottom Controls
            bottomControlsContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            bottomControlsContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            bottomControlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Logo
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.clipsToBounds = true
        logoImageView.image = UIImage(named: "AppLogo")
        headerView.addSubview(logoImageView)

        // Brand Name "Setli"
        brandNameLabel.translatesAutoresizingMaskIntoConstraints = false
        brandNameLabel.text = "Setli"
        brandNameLabel.font = AppFont.bold(size: 22)
        brandNameLabel.textColor = AppColor.textPrimaryDark.color
        headerView.addSubview(brandNameLabel)

        // Skip Button
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(AppColor.textMutedGray.color, for: .normal)
        skipButton.titleLabel?.font = AppFont.semiBold(size: 14)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        headerView.addSubview(skipButton)

        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 30),
            logoImageView.heightAnchor.constraint(equalToConstant: 30),

            brandNameLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 8),
            brandNameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            skipButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            skipButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 44),
            skipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func setupCollectionView() {
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
    }

    private func setupBottomControls() {
        bottomControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomControlsContainer)

        // Primary Action Button ("Next >" or "Get Started >")
        primaryActionButton.translatesAutoresizingMaskIntoConstraints = false
        primaryActionButton.backgroundColor = AppColor.primaryBlue.color
        primaryActionButton.layer.cornerRadius = 27
        primaryActionButton.setTitleColor(.white, for: .normal)
        primaryActionButton.titleLabel?.font = AppFont.bold(size: 16)

        // Soft elevation shadow
        primaryActionButton.layer.shadowColor = AppColor.primaryBlue.withAlpha(0.35).cgColor
        primaryActionButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        primaryActionButton.layer.shadowRadius = 12
        primaryActionButton.layer.shadowOpacity = 1
        primaryActionButton.layer.masksToBounds = false

        primaryActionButton.addTarget(self, action: #selector(primaryActionTapped), for: .touchUpInside)
        bottomControlsContainer.addSubview(primaryActionButton)

        // Secondary Row (Back button on left, custom pill dots in center)
        secondaryRowView.translatesAutoresizingMaskIntoConstraints = false
        bottomControlsContainer.addSubview(secondaryRowView)

        // Back Button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let chevronLeft = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
        backButton.setImage(chevronLeft, for: .normal)
        backButton.setTitle(" Back", for: .normal)
        backButton.tintColor = AppColor.textSecondaryGray.color
        backButton.setTitleColor(AppColor.textSecondaryGray.color, for: .normal)
        backButton.titleLabel?.font = AppFont.semiBold(size: 14)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        secondaryRowView.addSubview(backButton)

        // Dots Container
        dotsContainer.translatesAutoresizingMaskIntoConstraints = false
        dotsContainer.axis = .horizontal
        dotsContainer.alignment = .center
        dotsContainer.spacing = 6
        secondaryRowView.addSubview(dotsContainer)

        // Build Indicator Dots
        for i in 0..<slides.count {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 3
            dot.clipsToBounds = true
            dot.backgroundColor = (i == 0) ? AppColor.indicatorActive.color : AppColor.indicatorInactive.color

            let widthConstraint = dot.widthAnchor.constraint(equalToConstant: (i == 0) ? 22 : 6)
            widthConstraint.isActive = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true

            dotViews.append(dot)
            dotWidthConstraints.append(widthConstraint)
            dotsContainer.addArrangedSubview(dot)
        }

        NSLayoutConstraint.activate([
            // Primary Action Button
            primaryActionButton.topAnchor.constraint(equalTo: bottomControlsContainer.topAnchor),
            primaryActionButton.leadingAnchor.constraint(equalTo: bottomControlsContainer.leadingAnchor),
            primaryActionButton.trailingAnchor.constraint(equalTo: bottomControlsContainer.trailingAnchor),
            primaryActionButton.heightAnchor.constraint(equalToConstant: 54),

            // Secondary Row
            secondaryRowView.topAnchor.constraint(equalTo: primaryActionButton.bottomAnchor, constant: 14),
            secondaryRowView.leadingAnchor.constraint(equalTo: bottomControlsContainer.leadingAnchor),
            secondaryRowView.trailingAnchor.constraint(equalTo: bottomControlsContainer.trailingAnchor),
            secondaryRowView.bottomAnchor.constraint(equalTo: bottomControlsContainer.bottomAnchor),
            secondaryRowView.heightAnchor.constraint(equalToConstant: 32),

            // Back Button anchored to leading
            backButton.leadingAnchor.constraint(equalTo: secondaryRowView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: secondaryRowView.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            // Dots Container centered horizontally
            dotsContainer.centerXAnchor.constraint(equalTo: secondaryRowView.centerXAnchor),
            dotsContainer.centerYAnchor.constraint(equalTo: secondaryRowView.centerYAnchor)
        ])
    }

    private func updateControls(for index: Int, animated: Bool) {
        currentIndex = index

        let isLastPage = (index == slides.count - 1)
        let showBack = (index > 0)

        // Button title with right arrow symbol
        let buttonTitle = isLastPage ? "Get Started  ›" : "Next  ›"
        primaryActionButton.setTitle(buttonTitle, for: .normal)

        // Update Skip button visibility (hide on last screen)
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.skipButton.alpha = isLastPage ? 0.0 : 1.0
            self.skipButton.isUserInteractionEnabled = !isLastPage

            self.backButton.alpha = showBack ? 1.0 : 0.0
            self.backButton.isUserInteractionEnabled = showBack
        }

        // Update Animated Pill Dots
        for (i, dot) in dotViews.enumerated() {
            let isActive = (i == index)
            dotWidthConstraints[i].constant = isActive ? 22 : 6

            if animated {
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: {
                    dot.backgroundColor = isActive ? AppColor.indicatorActive.color : AppColor.indicatorInactive.color
                    self.dotsContainer.layoutIfNeeded()
                })
            } else {
                dot.backgroundColor = isActive ? AppColor.indicatorActive.color : AppColor.indicatorInactive.color
                self.dotsContainer.layoutIfNeeded()
            }
        }
    }

    @objc private func primaryActionTapped() {
        if currentIndex < slides.count - 1 {
            let nextIndex = currentIndex + 1
            scrollToPage(at: nextIndex)
        } else {
            completeOnboarding()
        }
    }

    @objc private func backTapped() {
        guard currentIndex > 0 else { return }
        let prevIndex = currentIndex - 1
        scrollToPage(at: prevIndex)
    }

    @objc private func skipTapped() {
        completeOnboarding()
    }

    private func completeOnboarding() {
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
}
