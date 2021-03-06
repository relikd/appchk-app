import UIKit

class TVCDomains: UITableViewController, UISearchBarDelegate, GroupedDomainDataSourceDelegate {
	
	lazy var source = GroupedDomainDataSource(withParent: nil)
	
	@IBOutlet private var filterButton: UIBarButtonItem!
	@IBOutlet private var filterButtonDetail: UIBarButtonItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		NotifyDateFilterChanged.observe(call: #selector(didChangeDateFilter), on: self)
		didChangeDateFilter()
		source.delegate = self // init lazy var, ready for tableView data source
	}
	
	override func viewDidAppear(_ animated: Bool) {
		// iOS 11+ fix: fuse after `didAppear` to hide on app launch
		source.search.fuseWith(tableViewController: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let index = tableView.indexPathForSelectedRow?.row {
			(segue.destination as? TVCHosts)?.parentDomain = source[index].domain
		}
	}
	
	func pushOpen(domain: String) {
		let A: TVCHosts = storyboard!.load("requestsHosts")
		let B: TVCHostDetails = storyboard!.load("requestsOccurrences")
		A.parentDomain = domain.extractDomain()
		B.fullDomain = domain
		navigationController?.pushViewController(A, animated: false)
		navigationController?.pushViewController(B, animated: false)
	}
	
	
	// MARK: - Filter
	
	@IBAction private func filterButtonTapped(_ sender: UIBarButtonItem) {
		let vc = storyboard!.load("domainFilter")
		vc.modalPresentationStyle = .custom
		if #available(iOS 13.0, *) {
			vc.isModalInPresentation = true
		}
		present(vc, animated: true)
	}
	
	@objc private func didChangeDateFilter() {
		switch Prefs.DateFilter.Kind {
		case .ABRange: // read start/end time
			self.filterButtonDetail.title = "A – B"
			self.filterButton.image = UIImage(named: "filter-filled")
		case .LastXMin: // most recent
			let lastXMin = Prefs.DateFilter.LastXMin
			if lastXMin == 0 { fallthrough }
			self.filterButtonDetail.title = TimeFormat(.abbreviated).from(minutes: lastXMin)
			self.filterButton.image = UIImage(named: "filter-filled")
		default:
			self.filterButtonDetail.title = ""
			self.filterButton.image = UIImage(named: "filter-clear")
		}
	}
	
	
	// MARK: - Table View Data Source
	
	override func tableView(_ _: UITableView, numberOfRowsInSection _: Int) -> Int { source.numberOfRows }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DomainCell")!
		let entry = source[indexPath.row]
		cell.textLabel?.text = entry.domain
		cell.detailTextLabel?.text = entry.detailCellText
		cell.imageView?.image = entry.options?.tableRowImage()
		return cell
	}
	
	func groupedDomainDataSource(needsUpdate row: Int) {
		let entry = source[row]
		let cell = tableView.cellForRow(at: IndexPath(row: row))
		cell?.detailTextLabel?.text = entry.detailCellText
		cell?.imageView?.image = entry.options?.tableRowImage()
	}
}
