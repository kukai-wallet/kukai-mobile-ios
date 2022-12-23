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
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		enterAddressComponent.delegate = self
		
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
		
		viewModel.refresh(animate: true, successMessage: nil)
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return viewModel.heightForHeaderInSection(section, forTableView: tableView)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return viewModel.viewForHeaderInSection(section, forTableView: tableView)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		TransactionService.shared.currentTransactionType = .send
		TransactionService.shared.sendData.destination = viewModel.address(forIndexPath: indexPath)
		
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
		/*if TransactionService.shared.sendData.chosenToken == nil && TransactionService.shared.sendData.chosenNFT == nil {
			self.performSegue(withIdentifier: "choose-token", sender: self)
			
		} else*/
		
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
