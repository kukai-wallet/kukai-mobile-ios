//
//  CollectiblesCollectionsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import Combine
import KukaiCoreSwift
import SDWebImage

class CollectiblesCollectionsViewController: UIViewController, UICollectionViewDelegate, CollectiblesViewControllerChild {
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesCollectionsViewModel()
	private var bag = [AnyCancellable]()
	private var refreshingFromParent = true
	private var movingToDetails = false
	private var textFieldDone = false
	private var lastSearchedTerm: String? = nil
	
	public weak var delegate: UIViewController? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.sortMenu = sortMenu()
		viewModel.validatorTextfieldDelegate = self
		viewModel.makeDataSource(withCollectionView: collectionView)
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.accessibilityIdentifier = "collectibles-list-view"
		collectionView.delegate = self
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					if self?.refreshingFromParent == true || self?.viewModel.needsLayoutChange == true {
						self?.collectionView.collectionViewLayout = self?.viewModel.layout() ?? UICollectionViewFlowLayout()
						self?.collectionView.contentOffset = CGPoint(x: 0, y: 0)
						self?.refreshingFromParent = false
						self?.viewModel.needsLayoutChange = false
					}
			}
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.collectionView.reloadData()
				
			}.store(in: &bag)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isVisible = true
		
		if !viewModel.isSearching {
			viewModel.refresh(animate: false)
			
		} else if let lastTerm = lastSearchedTerm {
			viewModel.refresh(animate: false)
			viewModel.searchFor(lastTerm)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		movingToDetails = false
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	func needsRefreshFromParent() {
		refreshingFromParent = true
		viewModel.refresh(animate: true)
	}
	
	
	// MARK: - CollectionView
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let c = cell as? CollectiblesCollectionCell {
			c.layoutIfNeeded()
			c.addGradientBackground()
			
			c.setupCollectionImage(url: viewModel.willDisplayCollectionImage(forIndexPath: indexPath))
			c.setupImages(imageURLs: viewModel.willDisplayImages(forIndexPath: indexPath))
			
		} else if let c = cell as? CollectiblesCollectionLargeCell, let url = viewModel.willDisplayImages(forIndexPath: indexPath).first {
			MediaProxyService.load(url: url, to: c.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
			
		} else if let c = cell as? CollectiblesCollectionSinglePageCell, let url = viewModel.willDisplayImages(forIndexPath: indexPath).first {
			MediaProxyService.load(url: url, to: c.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
			
		} else if let c = cell as? SearchResultCell, let url = viewModel.willDisplayImages(forIndexPath: indexPath).first {
			MediaProxyService.load(url: url, to: c.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
			
		} else if let c = cell as? LoadingGroupModeCell {
			c.addGradientBackground()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		guard let cell = cell as? UITableViewCellImageDownloading else {
			return
		}
		
		cell.downloadingImageViews().forEach({ $0.sd_cancelCurrentImageLoad() })
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			return
			
		} else if let obj = viewModel.token(forIndexPath: indexPath) {
			movingToDetails = true
			delegate?.performSegue(withIdentifier: "collection", sender: obj)
			
		} else if let obj = viewModel.nft(forIndexPath: indexPath) {
			movingToDetails = true
			delegate?.performSegue(withIdentifier: "detail", sender: obj)
		}
	}
	
	func sortMenu() -> MenuViewController {
		let choices: [MenuChoice] = [
			MenuChoice(isSelected: true, action: UIAction(title: "Recent", image: UIImage(named: "Recents"), identifier: nil, handler: { [weak self] action in
				self?.windowError(withTitle: "error".localized(), description: "Recent sort not functional yet")
			})),
			MenuChoice(isSelected: false, action: UIAction(title: "Name", image: UIImage(named: "Alphabetical"), identifier: nil, handler: { [weak self] action in
				self?.windowError(withTitle: "error".localized(), description: "Alphabetical sort not functional yet")
			})),
			MenuChoice(isSelected: false, action: UIAction(title: "Collection", image: UIImage(named: "CollectionGroupView"), identifier: nil, handler: { [weak self] action in
				self?.windowError(withTitle: "error".localized(), description: "Collection Group View sort not functional yet")
			}))
		]
		
		return MenuViewController(choices: choices, header: "Sort Tokens", sourceViewController: self)
	}
}

extension CollectiblesCollectionsViewController: ValidatorTextFieldDelegate {
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		// When moving back and forth from details we don't want the search page to refresh
		// however transitions cause the keyboard to disappear/reappear, triggering these functions
		if !movingToDetails {
			self.showSearchingUI()
		}
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		if !movingToDetails && !textFieldDone {
			self.hideSearchingUI()
		}
		
		textFieldDone = false
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		lastSearchedTerm = text
		viewModel.searchFor(text)
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		textFieldDone = true
	}
	
	private func showSearchingUI() {
		self.viewModel.isSearching = true
		
		let searchCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.cancelButton.isHidden = false
		
		UIView.animate(withDuration: 0.3) {
			searchCell?.contentView.layoutIfNeeded()
		}
		
		self.viewModel.startSearching(forColelctionView: self.collectionView, completion: {})
		
		
		/*
		self.navigationController?.setNavigationBarHidden(true, animated: true)
		
		let searchCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.buttonsStackView.isHidden = true
		searchCell?.searchBar.text = ""
		
		collectionViewTopConstraint.constant = 0
		UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
			self?.view.layoutIfNeeded()
		}
		*/
	}
	
	private func hideSearchingUI() {
		self.viewModel.isSearching = false
		
		let searchCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.searchBar.text = ""
		searchCell?.cancelButton.isHidden = true
		
		UIView.animate(withDuration: 0.3) {
			searchCell?.contentView.layoutIfNeeded()
		}
		
		viewModel.endSearching(forColelctionView: self.collectionView, completion: {})
		
		
		/*
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		
		let searchCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.buttonsStackView.isHidden = false
		searchCell?.searchBar.text = ""
		searchCell?.searchBar.resignFirstResponder()
		
		collectionViewTopConstraint.constant = 12
		UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
			self?.view.layoutIfNeeded()
		}
		*/
	}
}
