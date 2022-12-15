//
//  CollectiblesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit
import Combine

class CollectiblesViewController: UIViewController, UICollectionViewDelegate {
	
	//@IBOutlet weak var controlsStackView: UIStackView!
	//@IBOutlet weak var searchTextField: ValidatorTextField!
	//@IBOutlet weak var buttonsStackView: UIStackView!
	//@IBOutlet weak var filterButton: UIButton!
	//@IBOutlet weak var sortButton: UIButton!
	//@IBOutlet weak var moreButton: UIButton!
	//@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
	
	private let viewModel = CollectiblesViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		//self.navigationController?.hidesBarsWhenKeyboardAppears = true
		
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
		viewModel.refresh(animate: false)
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
				UIView.animate(withDuration: 0.5, delay: 0.1) {
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
	
	
	
	
	
	
	
	/*
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionHeaderTopPadding = 4
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isPresentedForSelectingToken = (self.parent != nil && self.tabBarController == nil)
		viewModel.isVisible = true
		viewModel.refresh(animate: false)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if viewModel.shouldOpenCloseForIndexPathTap(indexPath) {
			viewModel.openOrCloseGroup(forTableView: tableView, atIndexPath: indexPath)
			
		} else if viewModel.isPresentedForSelectingToken, let nft = viewModel.nft(atIndexPath: indexPath), let parent = self.parent as? SendChooseTokenViewController {
			TransactionService.shared.sendData.chosenNFT = nft
			TransactionService.shared.sendData.chosenToken = nil
			parent.tokenChosen()
			
		} else if let nft = viewModel.nft(atIndexPath: indexPath) {
			TransactionService.shared.sendData.chosenToken = nil
			TransactionService.shared.sendData.chosenNFT = nft
			self.performSegue(withIdentifier: "details", sender: self)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? NFTGroupCell {
			
			if viewModel.isSectionExpanded(indexPath.section) {
				c.addGradientBorder(withFrame: c.containerView.bounds)
				
			} else {
				c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
			}
			
		} else if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
			
		} else if let c = cell as? NFTItemCell {
			let numberOfCellsInSection = tableView.numberOfRows(inSection: indexPath.section)
			c.addGradientBorder(withFrame: c.containerView.bounds, isLast: indexPath.row == numberOfCellsInSection-1)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0.1
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.1
	}
	
	
	
	// MARK: Button actions
	
	@IBAction func filterTapped(_ sender: Any) {
		self.alert(withTitle: "Hang on", andMessage: "Slow down cowboy, not done yet")
	}
	
	@IBAction func sortTapped(_ sender: Any) {
		self.alert(withTitle: "Hang on", andMessage: "Slow down cowboy, not done yet")
	}
	
	@IBAction func moreTapped(_ sender: Any) {
		self.alert(withTitle: "Hang on", andMessage: "Slow down cowboy, not done yet")
	}
	
	
	
	// MARK: - UI functions
	
	func setupUI() {
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		searchTextField.placeholderFont = UIFont.custom(ofType: .bold, andSize: 14)
		searchTextField.validatorTextFieldDelegate = self
		searchTextField.clearButtonTint = UIColor.colorNamed("Grey200")
	}
	
	private func animateButtonsOut() {
		buttonsStackView.isHidden = true
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.view.layoutIfNeeded()
		}
	}
	
	private func animatedButtonsIn() {
		buttonsStackView.isHidden = false
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.view.layoutIfNeeded()
		}
	}
	 */

/*
extension CollectiblesViewController: ValidatorTextFieldDelegate {
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		animateButtonsOut()
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		animatedButtonsIn()
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		
	}
}
*/
