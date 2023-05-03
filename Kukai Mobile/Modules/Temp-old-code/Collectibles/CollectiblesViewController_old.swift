//
//  CollectiblesViewControllerOld.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

/*
import UIKit
import Combine
import KukaiCoreSwift

class CollectiblesViewControllerOld: UIViewController, UICollectionViewDelegate {
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
	
	private let viewModel = CollectiblesViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.sortMenu = sortMenu()
		viewModel.moreMenu = moreMenu()
		viewModel.validatorTextfieldDelegate = self
		viewModel.makeDataSource(withCollectionView: collectionView)
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					print("loading")
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					self?.setup()
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isVisible = true
		
		if !viewModel.isSearching {
			viewModel.refresh(animate: false)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	func setup() {
		self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		self.collectionView.collectionViewLayout = viewModel.layout
	}
	
	
	
	// MARK: - CollectionView
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if indexPath.section != viewModel.expandedIndex?.section, let c = cell as? ExpandableCell {
			c.addGradientBackground()
			
		} else if indexPath.section == viewModel.expandedIndex?.section, let c = cell as? CollectibleSpecialGroupCell {
			c.setOpen()
			
		} else if let c = cell as? CollectiblesListItemCell {
			let numberOfCellsInSection = collectionView.numberOfItems(inSection: indexPath.section)
			c.addGradientBorder(withFrame: CGRect(x: 0, y: 0, width: collectionView.frame.width - (collectionView.contentInset.left * 2), height: CollectibleListLayout.itemHeight), isLast: indexPath.row == numberOfCellsInSection-1)
			c.iconView.alpha = 0
			c.titleLabel.alpha = 0
			c.subTitleLabel.alpha = 0
			c.quantityView.alpha = 0
			
			DispatchQueue.main.asyncAfter(deadline: .now()) {
				UIView.animate(withDuration: 0.5, delay: 0.3) {
					c.iconView.alpha = 1
					c.titleLabel.alpha = 1
					c.subTitleLabel.alpha = 1
					c.quantityView.alpha = 1
				}
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if viewModel.shouldOpenCloseForIndexPathTap(indexPath) {
			viewModel.openOrCloseGroup(forCollectionView: collectionView, atIndexPath: indexPath)
			
		} else if let nft = viewModel.nft(atIndexPath: indexPath) {
			TransactionService.shared.sendData.chosenToken = nil
			TransactionService.shared.sendData.chosenNFT = nft
			self.performSegue(withIdentifier: "details", sender: self)
		}
	}
	
	func sortMenu() -> MenuViewController {
		let choices: [MenuChoice] = [
			MenuChoice(isSelected: true, action: UIAction(title: "Recent", image: UIImage(named: "Recents")?.resizedImage(size: CGSize(width: 24, height: 24)), identifier: nil, handler: { [weak self] action in
				self?.alert(errorWithMessage: "Recent sort not functional yet")
			})),
			MenuChoice(isSelected: false, action: UIAction(title: "Name", image: UIImage(named: "Alphabetical")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
				self?.alert(errorWithMessage: "Alphabetical sort not functional yet")
			})),
			MenuChoice(isSelected: false, action: UIAction(title: "Collection", image: UIImage(named: "CollectionGroupView")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
				self?.alert(errorWithMessage: "CollectionGroupView sort not functional yet")
			}))
		]
		
		return MenuViewController(choices: choices, header: "Sort Tokens", sourceViewController: self)
	}
	
	func moreMenu() -> MenuViewController {
		let actions: [UIAction] = [
			UIAction(title: "View Hidden Tokens", image: UIImage(named: "HiddenOn")?.resizedImage(size: CGSize(width: 24, height: 19)), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "hidden", sender: nil)
			}),
		]
		
		return MenuViewController(actions: [actions], header: nil, sourceViewController: self)
	}
}

extension CollectiblesViewController: ValidatorTextFieldDelegate {
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		self.showSearchingUI()
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		self.hideSearchingUI()
		return false // When user taps clear we want to resignFirstResponder, but apple re-focuses on clear. So we do our own clear and tell apple not too
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if text != "" {
			viewModel.searchFor(text)
			
		} else {
			self.hideSearchingUI()
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	private func showSearchingUI() {
		(collectionView.collectionViewLayout as? CollectibleListLayout)?.isSearching = true
		viewModel.isSearching = true
		
		self.navigationController?.setNavigationBarHidden(true, animated: true)
		
		let searchCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.buttonsStackView.isHidden = true
		searchCell?.searchBar.text = ""
		
		collectionViewTopConstraint.constant = 0
		UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
			self?.view.layoutIfNeeded()
		}
	}
	
	private func hideSearchingUI() {
		(collectionView.collectionViewLayout as? CollectibleListLayout)?.isSearching = false
		viewModel.isSearching = false
		viewModel.endSearching()
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		
		let searchCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.buttonsStackView.isHidden = false
		searchCell?.searchBar.text = ""
		searchCell?.searchBar.resignFirstResponder()
		
		collectionViewTopConstraint.constant = 12
		UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
			self?.view.layoutIfNeeded()
		}
	}
}
*/
