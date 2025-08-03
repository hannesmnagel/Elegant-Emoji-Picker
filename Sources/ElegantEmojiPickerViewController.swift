//
//  ElegantEmojiPickerViewController.swift
//  Demo
//
//  Created by Grant Oganyan on 3/10/23.
//

import Foundation
import UIKit

/// Internal view controller that handles the actual emoji picker UI
internal class ElegantEmojiPickerViewController: UIViewController {
    
    public weak var delegate: ElegantEmojiPickerDelegate?
    public let localization: ElegantLocalization
    
    let padding = 16.0
    let topElementHeight = 40.0
    
    let backgroundBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    
    var searchController: UISearchController?
    
    let fadeContainer = UIView()
    let collectionLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 40.0, height: 40.0)
        return layout
    }()
    var collectionView: UICollectionView!
    
    var toolbar: SectionsToolbar?
    var toolbarBottomConstraint: NSLayoutConstraint?
    
    var skinToneSelector: SkinToneSelector?
    var emojiPreview: EmojiPreview?
    public var previewingEmoji: Emoji?
    
    var emojiSections = [EmojiSection]()
    var searchResults: [Emoji]?
    
    private var prevFocusedSection: Int = 0
    var focusedSection: Int = 0
    
    var isSearching: Bool = false
    var overridingFocusedSection: Bool = false
    
    /// Initialize the internal picker view controller
    /// - Parameters:
    ///   - delegate: provide a delegate to interact with the picker
    ///   - localization: provide a localization to change texts on all labels
    init(delegate: ElegantEmojiPickerDelegate? = nil, localization: ElegantLocalization = ElegantLocalization()) {
        self.delegate = delegate
        self.localization = localization
        super.init(nibName: nil, bundle: nil)
    }
    
    func setupEmojiSections() {
        self.emojiSections = self.delegate?.emojiPicker(ElegantEmojiPicker.shared, loadEmojiSections: localization) ?? ElegantEmojiPicker.getDefaultEmojiSections(localization: localization)
        
        setupUI()
    }
    
    private func setupUI() {
        // Set up navigation bar with cancel button
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        // Set initial navigation title to first section
        if !emojiSections.isEmpty {
            self.navigationItem.title = emojiSections[0].title
        }
        
        self.view.addSubview(backgroundBlur, anchors: LayoutAnchor.fullFrame)
        
        // Set up search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.delegate = self
        searchController!.obscuresBackgroundDuringPresentation = false
        searchController!.searchBar.placeholder = localization.searchFieldPlaceholder
        searchController!.hidesNavigationBarDuringPresentation = false
        
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.definesPresentationContext = true
        
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.05)
        fadeContainer.layer.mask = gradient
        self.view.addSubview(fadeContainer, anchors: [.safeAreaLeading(0), .safeAreaTrailing(0), .bottom(0)])
        fadeContainer.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset.bottom = 50 + padding // Compensating for the toolbar
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView!.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView!.register(CollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
        fadeContainer.addSubview(collectionView, anchors: LayoutAnchor.fullFrame)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(LongPress))
        longPress.minimumPressDuration = 0.3
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        if emojiSections.count > 1 { AddToolbar() }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func AddToolbar () {
        toolbar = SectionsToolbar(sections: emojiSections, emojiPicker: self)
        self.view.addSubview(toolbar!, anchors: [.centerX(0)])
        
        toolbar!.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: padding).isActive = true
        toolbar!.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -padding).isActive = true
        
        toolbarBottomConstraint = toolbar!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -padding)
        toolbarBottomConstraint?.isActive = true
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionLayout.headerReferenceSize = CGSize(width: collectionView.frame.width, height: 50)
        fadeContainer.layer.mask?.frame = fadeContainer.bounds
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.view.backgroundColor = UIScreen.main.traitCollection.userInterfaceStyle == .light ? .black.withAlphaComponent(0.1) : .clear
    }
    
    @objc func cancelTapped() {
        self.dismiss(animated: true)
    }
    
    func didSelectEmoji (_ emoji: Emoji?) {
        delegate?.emojiPicker(ElegantEmojiPicker.shared, didSelectEmoji: emoji)
        if delegate?.emojiPickerShouldDismissAfterSelection(ElegantEmojiPicker.shared) ?? true { 
            self.dismiss(animated: true) 
        }
    }
}

// MARK: Built-in toolbar

extension ElegantEmojiPickerViewController {
    func didSelectSection(_ index: Int) {
        collectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .centeredVertically, animated: true)
        
        // Update navigation title immediately when section is selected
        if index < emojiSections.count {
            self.navigationItem.title = emojiSections[index].title
        }
        
        overridingFocusedSection = true
        self.focusedSection = index
        self.toolbar?.UpdateCorrectSelection(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.overridingFocusedSection = false
        }
    }
    
    func HideBuiltInToolbar () {
        toolbarBottomConstraint?.constant = 50
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4) {
            self.toolbar?.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func ShowBuiltInToolbar () {
        toolbarBottomConstraint?.constant = -padding
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4) {
            self.toolbar?.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: Search

extension ElegantEmojiPickerViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""
        let count = searchTerm.count
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            if count == 0 {
                self.searchResults = nil
            } else {
                self.searchResults = self.delegate?.emojiPicker(ElegantEmojiPicker.shared, searchResultFor: searchTerm, fromAvailable: self.emojiSections) ?? ElegantEmojiPicker.getSearchResults(searchTerm, fromAvailable: self.emojiSections)
            }
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.collectionView.setContentOffset(.zero, animated: false)
            }
        }
        
        if !isSearching && count > 0 {
            isSearching = true
            self.navigationItem.title = localization.searchResultsTitle
            delegate?.emojiPickerDidStartSearching(ElegantEmojiPicker.shared)
            HideBuiltInToolbar()
        }
        else if isSearching && count == 0 {
            isSearching = false
            // Restore navigation title to current section
            if focusedSection < emojiSections.count {
                self.navigationItem.title = emojiSections[focusedSection].title
            }
            delegate?.emojiPickerDidEndSearching(ElegantEmojiPicker.shared)
            ShowBuiltInToolbar()
        }
    }
    
    public func willPresentSearchController(_ searchController: UISearchController) {
        if !isSearching {
            self.navigationItem.title = localization.searchResultsTitle
        }
        delegate?.emojiPickerDidStartSearching(ElegantEmojiPicker.shared)
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        if isSearching {
            isSearching = false
            // Restore navigation title to current section
            if focusedSection < emojiSections.count {
                self.navigationItem.title = emojiSections[focusedSection].title
            }
        }
        delegate?.emojiPickerDidEndSearching(ElegantEmojiPicker.shared)
    }
}

//MARK: Collection view

extension ElegantEmojiPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! CollectionViewSectionHeader
        
        let categoryTitle = emojiSections[indexPath.section].title
        sectionHeader.label.text = searchResults == nil ? categoryTitle : searchResults!.count == 0 ? localization.searchResultsEmptyTitle : localization.searchResultsTitle
        return sectionHeader
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searchResults == nil ? emojiSections.count : 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults?.count ?? emojiSections[section].emojis.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        
        var emoji: Emoji? = nil
        if searchResults != nil && searchResults!.indices.contains(indexPath.row) { emoji = searchResults![indexPath.row] }
        else if emojiSections.indices.contains(indexPath.section) {
            if emojiSections[indexPath.section].emojis.indices.contains(indexPath.row) {
                emoji = emojiSections[indexPath.section].emojis[indexPath.row]
            }
        }
        if emoji != nil { cell.Setup(emoji: emoji!, self) }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let searchResults = searchResults, indexPath.row < searchResults.count {
            didSelectEmoji(searchResults[indexPath.row])
        } else if indexPath.section < emojiSections.count && indexPath.row < emojiSections[indexPath.section].emojis.count {
            didSelectEmoji(emojiSections[indexPath.section].emojis[indexPath.row])
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 10 { searchController?.searchBar.resignFirstResponder() }
        
        DetectCurrentSection()
        HideSkinToneSelector()
    }
}

//MARK: Long press preview

extension ElegantEmojiPickerViewController: UIGestureRecognizerDelegate {
    
    @objc func LongPress (_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            HideEmojiPreview()
            return
        }
        
        let location = sender.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location), let cell = collectionView.cellForItem(at: indexPath) as? EmojiCell, !(sender.state == .began && cell.emoji.supportsSkinTones) else  {  return }
                
        if sender.state == .began {
            ShowEmojiPreview(emoji: cell.emoji)
        } else if sender.state == .changed {
            UpdateEmojiPreview(newEmoji: cell.emoji)
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func ShowEmojiPreview (emoji: Emoji) {
        previewingEmoji = emoji
        emojiPreview = EmojiPreview(emoji: emoji)
        self.present(emojiPreview!, animated: false)
        
        self.delegate?.emojiPicker(ElegantEmojiPicker.shared, didStartPreview: emoji)
    }
    
    func UpdateEmojiPreview (newEmoji: Emoji) {
        guard let previewingEmoji = previewingEmoji else { return }
        if previewingEmoji == newEmoji { return }
        
        self.delegate?.emojiPicker(ElegantEmojiPicker.shared, didChangePreview: newEmoji, from: previewingEmoji)
        
        emojiPreview?.Update(newEmoji: newEmoji)
        self.previewingEmoji = newEmoji
    }
    
    func HideEmojiPreview () {
        guard let previewingEmoji = previewingEmoji else { return }
        
        self.delegate?.emojiPicker(ElegantEmojiPicker.shared, didEndPreview: previewingEmoji)
        
        emojiPreview?.Dismiss()
        emojiPreview = nil
        self.previewingEmoji = nil
    }
}

// MARK: Skin tones

extension ElegantEmojiPickerViewController {
    
    func ShowSkinToneSelector (_ parentCell: EmojiCell) {
        let emoji = parentCell.emoji.duplicate(nil)
        
        skinToneSelector?.removeFromSuperview()
        skinToneSelector = SkinToneSelector(emoji, self, fontSize: parentCell.label.font.pointSize)
        
        collectionView.addSubview(skinToneSelector!, anchors: [.bottomToTop(parentCell, 0)])
        
        let leading = skinToneSelector?.leadingAnchor.constraint(equalTo: parentCell.leadingAnchor)
        leading?.priority = .defaultHigh
        leading?.isActive = true
        
        skinToneSelector?.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: padding).isActive = true
        skinToneSelector?.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -padding).isActive = true
    }
    
    func HideSkinToneSelector () {
        skinToneSelector?.Disappear() {
            self.skinToneSelector?.removeFromSuperview()
            self.skinToneSelector = nil
        }
    }
    
    func PersistSkinTone (originalEmoji: Emoji, skinTone: EmojiSkinTone?) {
        ElegantEmojiPicker.persistedSkinTones[originalEmoji.description] = skinTone?.rawValue ?? ""
    }
}

// MARK: Misc

extension ElegantEmojiPickerViewController {
    
    func DetectCurrentSection () {
        if overridingFocusedSection { return }
        
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
        DispatchQueue.global(qos: .userInitiated).async {
            var sectionCounts = [Int: Int]()
            
            for indexPath in visibleIndexPaths {
                let section = indexPath.section
                sectionCounts[section] = (sectionCounts[section] ?? 0) + 1
            }

            let mostVisibleSection = sectionCounts.max(by: { $0.1 < $1.1 })?.key ?? 0
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.focusedSection = mostVisibleSection
                if self.prevFocusedSection != self.focusedSection {
                    // Update navigation title to current section
                    if self.focusedSection < self.emojiSections.count {
                        self.navigationItem.title = self.emojiSections[self.focusedSection].title
                    }
                    
                    self.delegate?.emojiPicker(ElegantEmojiPicker.shared, focusedSectionChanged: self.focusedSection, from: self.prevFocusedSection)
                    self.toolbar?.UpdateCorrectSelection()
                }
                self.prevFocusedSection = self.focusedSection
            }
        }
    }
}