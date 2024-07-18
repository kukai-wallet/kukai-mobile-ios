//
//  SendBatchDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 30/01/2024.
//

import UIKit
import KukaiCoreSwift

class SendBatchDetailsViewController: UIViewController {
	
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var tableView: UITableView?
	
	@IBOutlet weak var descriptionStackViews: UIStackView!
	@IBOutlet weak var transferAmountStackView: UIStackView!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var contractCallStackView: UIStackView!
	@IBOutlet weak var entrypointLabel: UILabel!
	@IBOutlet weak var operationTypeStackView: UIStackView!
	@IBOutlet weak var operationTypeLabel: UILabel!
	
	@IBOutlet weak var operationTextView: UITextView!
	
	private var batchData: TransactionService.BatchData? = nil
	private var currentSummary: TransactionService.BatchOpSummary? = nil
	private var selectedIndex = 0
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		batchData = isWalletConnectOp() ? TransactionService.shared.walletConnectOperationData.batchData : TransactionService.shared.batchData
		currentSummary = batchData?.opSummaries?.first
		selectedIndex = batchData?.selectedOp ?? 0
		
		updateDisplay()
		
		tableView?.dataSource = self
		tableView?.delegate = self
    }
	
	private func updateDisplay() {
		
		if let amount = currentSummary?.chosenAmount, let token = currentSummary?.chosenToken {
			amountLabel.text = amount.normalisedRepresentation + " \(token.symbol)"
			transferAmountStackView.isHidden = false
		} else {
			transferAmountStackView.isHidden = true
		}
		
		if let entrypoint = currentSummary?.mainEntrypoint {
			entrypointLabel.text = entrypoint
			contractCallStackView.isHidden = false
			operationTypeStackView.isHidden = true
			
		} else {
			operationTypeLabel.text = currentSummary?.operationTypeString ?? "Unknown"
			contractCallStackView.isHidden = true
			operationTypeStackView.isHidden = false
		}
		
		addJSONToTextView()
	}
	
	private func isWalletConnectOp() -> Bool {
		return (self.presentingViewController as? SendBatchConfirmViewController)?.isWalletConnectOp ?? false
	}
	
	private func selectedOperationsAndFees() -> [KukaiCoreSwift.Operation] {
		if isWalletConnectOp() {
			return TransactionService.shared.currentRemoteOperationsAndFeesData.selectedOperationsAndFees()
			
		} else {
			return TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
		}
	}
	
	private func addJSONToTextView() {
		let ops = selectedOperationsAndFees()
		guard ops.count > selectedIndex else {
			operationTextView.text = ""
			return
		}
		
		let op = ops[selectedIndex]
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		
		let data = (try? encoder.encode(op)) ?? Data()
		let string = String(data: data, encoding: .utf8)
		operationTextView.text = string
	}
	
	@IBAction func operationCopyButton(_ sender: UIButton) {
		Toast.shared.show(withMessage: "copied!", attachedTo: sender)
		UIPasteboard.general.string = operationTextView.text
	}
}

extension SendBatchDetailsViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return batchData?.opSummaries?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "BatchDetailOperationCell", for: indexPath) as? BatchDetailOperationCell else {
			return UITableViewCell()
		}
		
		cell.addressLabel.text = batchData?.opSummaries?[indexPath.row].contractAddress?.truncateTezosAddress() ?? ""
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.row == selectedIndex {
			cell.setSelected(true, animated: true)
			
		} else {
			cell.setSelected(false, animated: true)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.cellForRow(at: IndexPath(row: selectedIndex, section: indexPath.section))?.setSelected(false, animated: true)
		tableView.cellForRow(at: indexPath)?.setSelected(true, animated: true)
		
		selectedIndex = indexPath.row
		currentSummary = batchData?.opSummaries?[selectedIndex]
		if isWalletConnectOp() {
			TransactionService.shared.walletConnectOperationData.batchData.selectedOp = indexPath.row
		} else {
			TransactionService.shared.batchData.selectedOp = indexPath.row
		}
		
		updateDisplay()
	}
}
