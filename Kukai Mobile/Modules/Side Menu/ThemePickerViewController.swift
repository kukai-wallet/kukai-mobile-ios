//
//  ThemePickerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/04/2022.
//

import UIKit

public class ThemePickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		let currentTitle = ThemeManager.shared.currentTheme()
		let selectedRow = ThemeManager.shared.availableThemes().firstIndex(of: currentTitle) ?? 0
		selectedIndex = IndexPath(row: selectedRow, section: 0)
		
		tableView.dataSource = self
		tableView.delegate = self
	}
	
	
	
	// MARK: - TableView
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ThemeManager.shared.availableThemes().count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeChoiceCell", for: indexPath) as? ThemeChoiceCell else {
			return UITableViewCell()
		}
		
		let currenetTitle = ThemeManager.shared.availableThemes()[indexPath.row]
		cell.themeLabel?.text = currenetTitle
		
		return cell
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		deselectCurrentSelection()
		
		selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		
		let selectedCell = self.tableView.cellForRow(at: indexPath) as? ThemeChoiceCell
		ThemeManager.shared.setTheme(selectedCell?.themeLabel?.text ?? "Light")
		
		self.dismissBottomSheet()
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
		
		if indexPath == selectedIndex {
			cell.setSelected(true, animated: true)
			
		} else {
			cell.setSelected(false, animated: true)
		}
	}
	
	private func deselectCurrentSelection() {
		tableView.deselectRow(at: selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: selectedIndex)
		previousCell?.setSelected(false, animated: true)
	}
}
