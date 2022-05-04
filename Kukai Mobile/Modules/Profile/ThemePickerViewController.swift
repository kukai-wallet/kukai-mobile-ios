//
//  ThemePickerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/04/2022.
//

import UIKit

public class ThemePickerViewController: UITableViewController {
	
	private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	public override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ThemeManager.shared.availableThemes().count
	}
	
	public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "themeCell", for: indexPath)
		
		let currenetTitle = ThemeManager.shared.availableThemes()[indexPath.row]
		cell.textLabel?.text = currenetTitle
		
		if currenetTitle == ThemeManager.shared.currentTheme() {
			cell.accessoryType = .checkmark
			self.selectedIndex = indexPath
			
		} else {
			cell.accessoryType = .none
		}
		
		return cell
	}
	
	public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.cellForRow(at: selectedIndex)?.accessoryType = .none
		
		let selectedCell = self.tableView.cellForRow(at: indexPath)
		selectedCell?.accessoryType = .checkmark
		
		selectedIndex = indexPath
		ThemeManager.shared.setTheme(selectedCell?.textLabel?.text ?? "Light")
		
		self.navigationController?.popToRootViewController(animated: true)
	}
	
	
	
	
	/*
	private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		selectedIndex = index(forTheme: ThemeSelector.shared.currentTheme())
		self.tableView.cellForRow(at: selectedIndex)?.accessoryType = .checkmark
	}
	
	public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.cellForRow(at: selectedIndex)?.accessoryType = .none
		self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		
		selectedIndex = indexPath
		ThemeSelector.shared.set(theme: theme(forIndex: indexPath))
		
		self.navigationController?.popToRootViewController(animated: true)
	}
	
	private func index(forTheme theme: ThemeSelector.Theme) -> IndexPath {
		switch ThemeSelector.shared.currentTheme() {
			case .light:
				return IndexPath(row: 0, section: 0)
				
			case .dark:
				return IndexPath(row: 1, section: 0)
				
			case .red:
				return IndexPath(row: 2, section: 0)
				
			case .blue:
				return IndexPath(row: 3, section: 0)
		}
	}
	
	private func theme(forIndex index: IndexPath) -> ThemeSelector.Theme {
		switch index.row {
			case 0:
				return .light
				
			case 1:
				return .dark
				
			case 2:
				return .red
				
			case 3:
				return .blue
			
			default:
				return .light
		}
	}
	*/
}
