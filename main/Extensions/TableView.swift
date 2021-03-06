import UIKit

extension IndexPath {
	/// Convenience init with `section: 0`
	public init(row: Int) { self.init(row: row, section: 0) }
}

extension UIRefreshControl {
	convenience init(call: Selector, on target: Any) {
		self.init()
		addTarget(target, action: call, for: .valueChanged)
	}
}


// MARK: - UITableView

extension UITableView {
	/// Returns `true` if this `tableView` is the currently frontmost visible
	var isFrontmost: Bool { window?.isKeyWindow ?? false }
	
	/// If frontmost window, perform `insertRows()`; If not, perform `reloadData()`
	func safeInsertRow(_ index: Int, with animation: UITableView.RowAnimation = .automatic) {
		isFrontmost ? insertRows(at: [IndexPath(row: index)], with: animation) : reloadData()
	}
	/// If frontmost window, perform `insertRows()`; If not, perform `reloadData()`
	func safeInsertRows(_ range: Range<Int>, with animation: UITableView.RowAnimation = .automatic) {
		isFrontmost ? insertRows(at: range.map {IndexPath(row: $0)}, with: animation) : reloadData()
	}
	/// If frontmost window, perform `deleteRows()`; If not, perform `reloadData()`
	func safeDeleteRows(_ indices: [Int], with animation: UITableView.RowAnimation = .automatic) {
		isFrontmost ? deleteRows(at: indices.map {IndexPath(row: $0)}, with: animation) : reloadData()
	}
	/// If frontmost window, perform `deleteRows()`; If not, perform `reloadData()`
	func safeDeleteRows(_ range: Range<Int>, with animation: UITableView.RowAnimation = .automatic) {
		isFrontmost ? deleteRows(at: range.map {IndexPath(row: $0)}, with: animation) : reloadData()
	}
	/// If frontmost window, perform `reloadRows()`; If not, perform `reloadData()`
	func safeReloadRow(_ index: Int, with animation: UITableView.RowAnimation = .automatic) {
		isFrontmost ? reloadRows(at: [IndexPath(row: index)], with: animation) : reloadData()
	}
	/// If frontmost window, perform `moveRow()`; If not, perform `reloadData()`
	func safeMoveRow(_ from: Int, to: Int) {
		isFrontmost ? moveRow(at: IndexPath(row: from), to: IndexPath(row: to)) : reloadData()
	}
}


// MARK: - EditableRows

public enum RowAction {
	case ignore, block, delete
}

protocol EditableRows {
	func editableRowUserInfo(_ index: IndexPath) -> Any?
	func editableRowActions(_ index: IndexPath) -> [(RowAction, String)]
	func editableRowActionColor(_ index: IndexPath, _ action: RowAction) -> UIColor?
	@discardableResult func editableRowCallback(_ atIndexPath: IndexPath, _ action: RowAction, _ userInfo: Any?) -> Bool
}

extension EditableRows where Self: UITableViewDelegate {
	func getRowActionsIOS9(_ index: IndexPath, _ table: UITableView) -> [UITableViewRowAction]? {
		let userInfo = editableRowUserInfo(index)
		return editableRowActions(index).compactMap { a,t in
			let x = UITableViewRowAction(style: a == .delete ? .destructive : .normal, title: t) {
				self.editableRowCallback($1, a, userInfo)
				table.isEditing = false
			}
			if let color = editableRowActionColor(index, a) {
				x.backgroundColor = color
			}
			return x
		}
	}
	@available(iOS 11.0, *)
	func getRowActionsIOS11(_ index: IndexPath) -> UISwipeActionsConfiguration? {
		let userInfo = editableRowUserInfo(index)
		return UISwipeActionsConfiguration(actions: editableRowActions(index).compactMap { a,t in
			let x = UIContextualAction(style: a == .delete ? .destructive : .normal, title: t) { $2(self.editableRowCallback(index, a, userInfo)) }
			x.backgroundColor = editableRowActionColor(index, a)
			return x
		})
	}
	func editableRowUserInfo(_ index: IndexPath) -> Any? { nil }
}

protocol EditActionsRemove : EditableRows {}
extension EditActionsRemove where Self: UITableViewController {
	func editableRowActions(_: IndexPath) -> [(RowAction, String)] { [(.delete, "Remove")] }
	func editableRowActionColor(_: IndexPath, _: RowAction) -> UIColor? { nil }
}


// MARK: - Table Cell Tap Menu

struct TableCellTapMenu {
	private var index: Int = Int.max
	
	mutating func reset() { index = Int.max }
	
	/// Create a new tap manu and shows it immediatelly. With optional buttons.
	mutating func start(_ tableView: UITableView, _ indexPath: IndexPath, items: [UIMenuItem]? = nil) -> Bool {
		let menu = UIMenuController.shared
		if index == indexPath.row {
			menu.setMenuVisible(false, animated: true)
			reset()
			return false
		}
		index = indexPath.row
		let cell = tableView.cellForRow(at: indexPath)!
		menu.setTargetRect(cell.bounds, in: cell)
		menu.menuItems = items
		menu.setMenuVisible(true, animated: true)
		return true
	}
	
	/// Returns the item if the array index is in bounds.
	func getSelected<T>(_ source: [T]) -> T? {
		guard index < source.count else { return nil }
		return source[index]
	}
}
