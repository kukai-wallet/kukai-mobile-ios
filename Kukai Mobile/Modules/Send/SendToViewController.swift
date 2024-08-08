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
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.contentInsetAdjustmentBehavior = .never
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
		enterAddressComponent.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView()
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
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
		
		if viewModel.handleMoreCellIfNeeded(indexPath: indexPath) {
			tableView.scrollToRow(at: IndexPath(row: 0, section: indexPath.section), at: .top, animated: true)
			return
		}
		
		guard indexPath.row > 0, let walletObj = viewModel.walletObj(forIndexPath: indexPath) else { return }
		
		TransactionService.shared.currentTransactionType = .send
		TransactionService.shared.sendData.destinationIcon = walletObj.icon
		TransactionService.shared.sendData.destination = walletObj.address
		TransactionService.shared.sendData.destinationAlias = walletObj.subtitle == nil ? nil : walletObj.title
		
		self.navigate()
	}
	
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType) {
		if !validAddress {
			return
		}
		
		TransactionService.shared.currentTransactionType = .send
		enterAddressComponent.textField.resignFirstResponder()
		
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
		
		enterAddressComponent.findAddress(forText: text) { [weak self] result in
			self?.hideLoadingModal()
			
			guard let res = try? result.get() else {
				self?.hideLoadingModal(completion: {
					self?.windowError(withTitle: "error-fetch-address".localized(), description: result.getFailure().description)
				})
				return
			}
			
			TransactionService.shared.sendData.destinationAlias = res.alias
			TransactionService.shared.sendData.destination = res.address
			TransactionService.shared.sendData.destinationIcon = res.icon
			
			self?.navigate()
		}
	}
}
