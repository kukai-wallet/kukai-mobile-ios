//
//  MenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/01/2023.
//

import UIKit

class MenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
	
	private static let rowHeight: CGFloat = 56
	private static let sectionFooterHeight: CGFloat = 8
	private static let preferredWidth: CGFloat = 274
	
	private var actions: [[UIAction]] = []
	private weak var sourceVC: UIViewController? = nil
	
	convenience init(actions: [[UIAction]], sourceViewController: UIViewController) {
		self.init(style: .grouped)
		self.actions = actions
		self.sourceVC = sourceViewController
		
		self.tableView.backgroundColor = UIColor.colorNamed("Grey1600")
		self.tableView.separatorColor = UIColor.colorNamed("Grey1500")
	}
	
	func setup() {
		var height = MenuViewController.rowHeight * CGFloat(actions.map({ $0.count }).reduce(0, +))
		
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
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
		tableView.rowHeight = MenuViewController.rowHeight
		tableView.separatorInset = .zero
		tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 0.1))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.popoverPresentationController?.containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return actions.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return actions[section].count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
		let action = actions[indexPath.section][indexPath.row]
		cell.textLabel?.text = action.title
		cell.textLabel?.textColor = UIColor.colorNamed("Grey400")
		cell.textLabel?.font = UIFont.custom(ofType: .bold, andSize: 18)
		
		let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
		var image = action.image
		image = image?.resizedImage(Size: imageView.frame.size)
		image = image?.withTintColor(.colorNamed("Brand1000"))
		imageView.image = image
		cell.accessoryView = imageView
		
		cell.backgroundColor = .clear
		cell.contentView.backgroundColor = .clear
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.dismiss(animated: true)
		actions[indexPath.section][indexPath.row].performWithSender(nil, target: nil)
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
		view.backgroundColor = .colorNamed("Grey1500")
		
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
