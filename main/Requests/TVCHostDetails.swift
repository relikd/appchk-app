import UIKit

class TVCHostDetails: UITableViewController, SyncUpdateDelegate, AnalysisBarDelegate {

	public var fullDomain: String!
	private var dataSource: [GroupedTsOccurrence] = []
	// TODO: respect date reverse sort order
	
	override func viewDidLoad() {
		navigationItem.prompt = fullDomain
		super.viewDidLoad()
		sync.addObserver(self) // calls `syncUpdate(reset:)`
		if #available(iOS 10.0, *) {
			sync.allowPullToRefresh(onTVC: self, forObserver: self)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let index = tableView.indexPathForSelectedRow?.row {
			let tvc = segue.destination as? TVCOccurrenceContext
			tvc?.domain = fullDomain
			tvc?.ts = dataSource[index].ts
		}
	}
	
	func analysisBarWillOpenCoOccurrence() -> (domain: String, isFQDN: Bool) {
		(fullDomain, true)
	}
	
	// MARK: - Table View Data Source
	
	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int { dataSource.count }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "HostDetailCell")!
		let src = dataSource[indexPath.row]
		cell.textLabel?.text = DateFormat.seconds(src.ts)
		cell.detailTextLabel?.text = (src.total > 1) ? "\(src.total)×" : nil
		cell.imageView?.image = (src.blocked > 0 ? UIImage(named: "shield-x") : nil)
		return cell
	}
}

// ################################
// #
// #    MARK: - Partial Update
// #
// ################################

extension TVCHostDetails {
	
	func syncUpdate(_ _: SyncUpdate, reset rows: SQLiteRowRange) {
		dataSource = AppDB?.timesForDomain(fullDomain, range: rows) ?? []
		DispatchQueue.main.sync { tableView.reloadData() }
	}
	
	func syncUpdate(_ _: SyncUpdate, insert rows: SQLiteRowRange, affects: SyncUpdateEnd) {
		guard let latest = AppDB?.timesForDomain(fullDomain, range: rows), latest.count > 0 else {
			return
		}
		// Assuming they are ordered by ts and in descending order
		let range: Range<Int>
		switch affects {
		case .Earliest:
			range = dataSource.endIndex..<(dataSource.endIndex + latest.count)
			dataSource.append(contentsOf: latest)
		case .Latest:
			range = dataSource.startIndex..<(dataSource.startIndex + latest.count)
			dataSource.insert(contentsOf: latest, at: 0)
		}
		DispatchQueue.main.sync { tableView.safeInsertRows(range, with: .left) }
	}
	
	func syncUpdate(_ sender: SyncUpdate, remove _: SQLiteRowRange, affects: SyncUpdateEnd) {
		// Assuming they are ordered by ts and in descending order
		let range: Range<Int>
		switch affects {
		case .Earliest:
			guard let t = sender.tsEarliest,
				let i = dataSource.lastIndex(where: { $0.ts >= t }),
				(i+1) < dataSource.count else { return }
			range = (i+1)..<dataSource.endIndex
			dataSource.removeLast(dataSource.count - (i+1))
		case .Latest:
			guard let t = sender.tsLatest,
				let i = dataSource.firstIndex(where: { $0.ts <= t }),
				i > 0 else { return }
			range = dataSource.startIndex..<i
			dataSource.removeFirst(i)
		}
		DispatchQueue.main.sync { tableView.safeDeleteRows(range) }
	}
	
	func syncUpdate(_ sender: SyncUpdate, partialRemove affectedDomain: String) {
		if fullDomain.isSubdomain(of: affectedDomain) {
			syncUpdate(sender, reset: sender.rows)
		}
	}
}
