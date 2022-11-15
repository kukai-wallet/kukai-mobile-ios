//
//  CollectiblesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit
import Combine

class CollectiblesViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var controlsStackView: UIStackView!
	@IBOutlet weak var searchTextField: ValidatorTextField!
	@IBOutlet weak var buttonsStackView: UIStackView!
	@IBOutlet weak var filterButton: UIButton!
	@IBOutlet weak var sortButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = CollectiblesViewModel()
	private var cancellable: AnyCancellable?
	
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
				c.addGradientBackground(withFrame: c.containerView.bounds)
			}
			
		} else if let c = cell as? NFTGroupSingleCell {
			c.addGradientBackground(withFrame: c.containerView.bounds)
			
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
		self.view.backgroundColor = UIColor.colorNamed("Grey-1900")
		let _ = self.view.addGradientBackgroundFull()
		
		searchTextField.placeholderFont = UIFont.roboto(ofType: .bold, andSize: 16)
		searchTextField.validatorTextFieldDelegate = self
		searchTextField.clearButtonTint = UIColor.colorNamed("Grey-200")
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
}

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
