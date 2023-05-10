//
//  MenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/01/2023.
//

import UIKit

public struct MenuChoice {
	var isSelected: Bool
	let action: UIAction
}

class MenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
	
	private static let headerRowHeight: CGFloat = 38
	private static let actionRowHeight: CGFloat = 52
	private static let choiceRowHeight: CGFloat = 52
	private static let sectionFooterHeight: CGFloat = 4
	private static let preferredWidth: CGFloat = 274
	
	private var actions: [[UIAction]] = []
	private var choices: [MenuChoice] = []
	private var isMultiChoice = false
	private var oldIndexPathSlectionIndex: IndexPath = IndexPath(row: 0, section: 0)
	private var header: String? = nil
	private var alertStyleIndexes: [IndexPath]? = nil
	private weak var sourceVC: UIViewController? = nil
	
	/// Similar to default UIMenu control
	convenience init(actions: [[UIAction]], header: String?, alertStyleIndexes: [IndexPath]? = nil, sourceViewController: UIViewController) {
		self.init(style: .grouped)
		self.actions = actions
		self.header = header
		self.alertStyleIndexes = alertStyleIndexes
		self.sourceVC = sourceViewController
	}
	
	/// Based off a UIMenu control, but functions like a radio button group, presenting user with a list of items to choose. i.e. filtering options
	convenience init(choices: [MenuChoice], header: String?, sourceViewController: UIViewController) {
		self.init(style: .grouped)
		self.choices = choices
		self.header = header
		self.sourceVC = sourceViewController
		self.isMultiChoice = true
	}
	
	func setup() {
		var height = (header == nil) ? 0 : MenuViewController.headerRowHeight
		
		if isMultiChoice {
			height += MenuViewController.choiceRowHeight * CGFloat(choices.count)
		} else {
			height += MenuViewController.actionRowHeight * CGFloat(actions.map({ $0.count }).reduce(0, +))
		}
		
		if actions.count > 1 {
			height += (MenuViewController.sectionFooterHeight * CGFloat(actions.count-1))
		}
		
		let maxHeight = UIScreen.main.bounds.height * 0.75
		if height > maxHeight {
			height = maxHeight
		}
		
		modalPresentationStyle = .popover
		preferredContentSize = CGSize(width: MenuViewController.preferredWidth, height: height)
		presentationController?.delegate = self
		popoverPresentationController?.permittedArrowDirections = []
		
		self.tableView.backgroundColor = UIColor.colorNamed("BGMenuContext")
		self.tableView.separatorColor = UIColor.colorNamed("LineMenuContext")
		
		self.tableView.register(UINib(nibName: "MenuHeaderCell", bundle: nil), forCellReuseIdentifier: "MenuHeaderCell")
		self.tableView.register(UINib(nibName: "MenuActionCell", bundle: nil), forCellReuseIdentifier: "MenuActionCell")
		self.tableView.register(UINib(nibName: "MenuChoiceCell", bundle: nil), forCellReuseIdentifier: "MenuChoiceCell")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.separatorInset = .zero
		tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 0.1))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.popoverPresentationController?.containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if isMultiChoice {
			return 1
		} else {
			return actions.count
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isMultiChoice {
			if header != nil {
				return self.choices.count + 1
			} else {
				return self.choices.count
			}
			
		} else {
			if header != nil && section == 0 {
				return actions[section].count + 1
			} else {
				return actions[section].count
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if header != nil, indexPath.section == 0, indexPath.row == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "MenuHeaderCell", for: indexPath) as? MenuHeaderCell {
			cell.headerLabel.text = header
			return cell
		}
		
		if isMultiChoice, let cell = tableView.dequeueReusableCell(withIdentifier: "MenuChoiceCell", for: indexPath) as? MenuChoiceCell {
			let choiceIndex = (header == nil) ? indexPath.row : indexPath.row - 1
			let choice = self.choices[choiceIndex]
			
			cell.choiceLabel.text = choice.action.title
			cell.iconView.image = choice.action.image?.withTintColor(.colorNamed("BGB4"))
			
			if choice.isSelected {
				cell.setTick()
				oldIndexPathSlectionIndex = indexPath
			} else {
				cell.removeTick()
			}
			
			return cell
			
		} else if let cell = tableView.dequeueReusableCell(withIdentifier: "MenuActionCell", for: indexPath) as? MenuActionCell {
			let actionIndex = (header != nil && indexPath.section == 0) ? indexPath.row - 1 : indexPath.row
			let action = self.actions[indexPath.section][actionIndex]
			
			cell.actionLabel.text = action.title
			
			if let alertIndexes = self.alertStyleIndexes, alertIndexes.contains(where: { $0.section == indexPath.section && $0.row == actionIndex }) {
				cell.actionLabel.textColor = .colorNamed("TxtAlert4")
				cell.iconView.image = action.image?.withTintColor(.colorNamed("TxtAlert4"))
				cell.iconView.tintColor = .colorNamed("TxtAlert4")
				
			} else {
				cell.iconView.image = action.image?.withTintColor(.colorNamed("BGB4"))
				cell.iconView.tintColor = .colorNamed("BGB4")
			}
			return cell
		}
		
		return UITableViewCell()
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if header != nil, indexPath.section == 0, indexPath.row == 0 {
			return MenuViewController.headerRowHeight
		}
		
		if isMultiChoice {
			return MenuViewController.choiceRowHeight
			
		} else {
			return MenuViewController.actionRowHeight
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.dismiss(animated: true)
		
		let cell = tableView.cellForRow(at: indexPath)
		if cell is MenuHeaderCell {
			return
		}
		
		if isMultiChoice, let newSelectionCell = cell as? MenuChoiceCell, let oldSelectionCell = tableView.cellForRow(at: oldIndexPathSlectionIndex) as? MenuChoiceCell {
			if indexPath == oldIndexPathSlectionIndex {
				return
			}
			
			newSelectionCell.setTick()
			oldSelectionCell.removeTick()
			
			oldIndexPathSlectionIndex = indexPath
			
			let choiceIndex = (header != nil) ? indexPath.row - 1 : indexPath.row
			let choice = self.choices[choiceIndex]
			choice.action.performWithSender(nil, target: nil)
			
		} else {
			let actionIndex = (header != nil && indexPath.section == 0) ? indexPath.row - 1 : indexPath.row
			let action = self.actions[indexPath.section][actionIndex]
			action.performWithSender(nil, target: nil)
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0.1
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return nil
	}
	
	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if actions.count > 1 && actions.count-1 != section{
			return MenuViewController.sectionFooterHeight
		} else {
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let view = UIView(frame: CGRect(x: 0, y: 0, width: MenuViewController.preferredWidth, height: MenuViewController.sectionFooterHeight))
		view.backgroundColor = .colorNamed("LineMenuContext")
		
		return view
	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
	
	public func display(attachedTo sourceView: UIView) {
		self.setup()
		
		self.popoverPresentationController?.sourceView = sourceView
		self.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.origin.x, y: (preferredContentSize.height / 2) + sourceView.bounds.height, width: sourceView.bounds.width, height: sourceView.bounds.height)
		sourceVC?.present(self, animated: true, completion: nil)
	}
}
