//
//  StakeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class StakeViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = StakeViewModel()
	private var cancellable: AnyCancellable?
	private let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 2))
	private let blankView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionHeaderHeight = 0
		tableView.sectionFooterHeight = 4
		tableView.tableHeaderView = blankView
		footerView.backgroundColor = .clear
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView()
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success(_):
					self?.hideLoadingView(completion: nil)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
	
	public func enteredCustomBaker(address: String) {
		if address == "" {
			let currentDelegate = DependencyManager.shared.balanceService.account.delegate
			let name = currentDelegate?.alias ?? currentDelegate?.address.truncateTezosAddress() ?? ""
			var logo: String? = nil
			
			if let add = currentDelegate?.address {
				logo = TzKTClient.avatarURL(forToken: add)?.absoluteString
			}
			
			let baker = TzKTBaker(address: "", name: name, logo: logo)
			
			TransactionService.shared.delegateData.chosenBaker = baker
			TransactionService.shared.delegateData.isAdd = false
			
		} else {
			let baker = TzKTBaker(address: address, name: address.truncateTezosAddress(), logo: nil)
			TransactionService.shared.delegateData.chosenBaker = baker
			TransactionService.shared.delegateData.isAdd = true
		}
		
		createOperationsAndConfirm(toAddress: address)
	}
	
	public func stakeTapped() {
		if let baker = TransactionService.shared.delegateData.chosenBaker {
			createOperationsAndConfirm(toAddress: baker.address)
		}
	}
	
	func createOperationsAndConfirm(toAddress: String) {
		guard let selectedWallet = DependencyManager.shared.selectedWallet else {
			self.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
			return
		}
		
		self.showLoadingView()
		let operations = OperationFactory.delegateOperation(to: toAddress, from: selectedWallet.address)
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWallet.address, base58EncodedPublicKey: selectedWallet.publicKeyBase58encoded()) { [weak self] estimationResult in
			self?.hideLoadingView()
			
			switch estimationResult {
				case .success(let estimationResult):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimationResult.operations)
					TransactionService.shared.currentForgedString = estimationResult.forgedString
					self?.performSegue(withIdentifier: "confirm", sender: nil)
					
				case .failure(let estimationError):
					self?.windowError(withTitle: "error".localized(), description: estimationError.description)
			}
		}
	}
}

extension StakeViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return footerView
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.bounds, toView: c)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let baker = viewModel.bakerFor(indexPath: indexPath) {
			
			TransactionService.shared.delegateData.chosenBaker = baker
			TransactionService.shared.delegateData.isAdd = true
			self.performSegue(withIdentifier: "details", sender: nil)
			
		} else if viewModel.isEnterCustom(indePath: indexPath) {
			self.performSegue(withIdentifier: "custom", sender: nil)
		}
	}
}
