//
//  SendToViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import Combine

class SendToViewController: UIViewController, UITableViewDelegate, EnterAddressComponentDelegate {
	
	@IBOutlet weak var enterAddressComponent: EnterAddressComponent!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = SendToViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.contentInsetAdjustmentBehavior = .never
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
		enterAddressComponent.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true, successMessage: nil)
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.navigationController?.popToDetails()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard indexPath.row > 0, let walletObj = viewModel.walletObj(forIndexPath: indexPath) else { return }
		
		TransactionService.shared.currentTransactionType = .send
		TransactionService.shared.sendData.destinationIcon = walletObj.icon
		TransactionService.shared.sendData.destination = walletObj.address
		TransactionService.shared.sendData.destinationAlias = walletObj.subtitle == nil ? nil : walletObj.title
		
		self.navigate()
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType) {
		if !validAddress {
			return
		}
		
		TransactionService.shared.currentTransactionType = .send
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			
			if ofType == .tezosAddress {
				TransactionService.shared.sendData.destination = entered
				self?.navigate()
				
			} else {
				self?.findAddressThenNavigate(text: entered, type: ofType)
			}
		}
	}
	
	func navigate() {
		if TransactionService.shared.sendData.chosenToken != nil {
			self.performSegue(withIdentifier: "enter-amount", sender: self)
			
		} else if TransactionService.shared.sendData.chosenNFT != nil {
			self.performSegue(withIdentifier: "review-send-nft", sender: self)
		}
	}
	
	func findAddressThenNavigate(text: String, type: AddressType) {
		self.showLoadingModal()
		
		self.viewModel.convertStringToAddress(string: text, type: type) { [weak self] result in
			self?.hideLoadingModal()
			
			guard let res = try? result.get() else {
				self?.hideLoadingModal(completion: {
					self?.alert(errorWithMessage: result.getFailure().description)
				})
				return
			}
			
			TransactionService.shared.sendData.destinationAlias = text
			TransactionService.shared.sendData.destination = res
			TransactionService.shared.sendData.destinationIcon = UIImage(systemName: "xmark.octagon")
			
			self?.navigate()
		}
	}
}
