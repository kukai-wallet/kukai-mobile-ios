//
//  CollectiblesCollectionsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import Combine
import KukaiCoreSwift

class CollectiblesCollectionsViewController: UIViewController, UICollectionViewDelegate, CollectiblesViewControllerChild {
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesCollectionsViewModel()
	private var bag = [AnyCancellable]()
	private var refreshingFromParent = true
	
	public weak var delegate: UIViewController? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.sortMenu = sortMenu()
		viewModel.validatorTextfieldDelegate = self
		viewModel.makeDataSource(withCollectionView: collectionView)
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
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
		}
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
			c.addGradientBackground()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			return
			
		} else if viewModel.isGroupMode, let obj = viewModel.token(forIndexPath: indexPath) {
			delegate?.performSegue(withIdentifier: "collection", sender: obj)
			
		} else if !viewModel.isGroupMode, let obj = viewModel.nft(forIndexPath: indexPath) {
			delegate?.performSegue(withIdentifier: "detail", sender: obj)
		}
	}
	
	func sortMenu() -> MenuViewController {
		let choices: [MenuChoice] = [
			MenuChoice(isSelected: true, action: UIAction(title: "Recent", image: UIImage(named: "Recents"), identifier: nil, handler: { [weak self] action in
				self?.alert(errorWithMessage: "Recent sort not functional yet")
			})),
			MenuChoice(isSelected: false, action: UIAction(title: "Name", image: UIImage(named: "Alphabetical"), identifier: nil, handler: { [weak self] action in
				self?.alert(errorWithMessage: "Alphabetical sort not functional yet")
			})),
			MenuChoice(isSelected: false, action: UIAction(title: "Collection", image: UIImage(named: "CollectionGroupView"), identifier: nil, handler: { [weak self] action in
				self?.alert(errorWithMessage: "CollectionGroupView sort not functional yet")
			}))
		]
		
		return MenuViewController(choices: choices, header: "Sort Tokens", sourceViewController: self)
	}
}

extension CollectiblesCollectionsViewController: ValidatorTextFieldDelegate {
	
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
			//viewModel.searchFor(text)
			
		} else {
			self.hideSearchingUI()
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	private func showSearchingUI() {
		/*(collectionView.collectionViewLayout as? CollectibleListLayout)?.isSearching = true
		viewModel.isSearching = true
		
		self.navigationController?.setNavigationBarHidden(true, animated: true)
		
		let searchCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CollectiblesSearchCell
		searchCell?.buttonsStackView.isHidden = true
		searchCell?.searchBar.text = ""
		
		collectionViewTopConstraint.constant = 0
		UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
			self?.view.layoutIfNeeded()
		}*/
	}
	
	private func hideSearchingUI() {
		/*(collectionView.collectionViewLayout as? CollectibleListLayout)?.isSearching = false
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
		}*/
	}
}
