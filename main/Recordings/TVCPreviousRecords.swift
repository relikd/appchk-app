import UIKit

class TVCPreviousRecords: UITableViewController {
	private var dataSource: [Recording] = []
	
	override func viewDidLoad() {
		dataSource = DBWrp.listOfRecordings().reversed() // newest on top
		NotifyRecordingChanged.observe(call: #selector(recordingDidChange(_:)), on: self)
	}
	
	func stopRecording(_ record: Recording?) {
		guard let r = record?.stoppedCopy() else {
			return
		}
		insertNewRecord(r)
		editRecord(r, isNewRecording: true)
	}
	
	@objc private func recordingDidChange(_ notification: Notification) {
		let (new, deleted) = notification.object as! (Recording, Bool)
		if let i = dataSource.firstIndex(where: { $0.start == new.start }) {
			if deleted {
				dataSource.remove(at: i)
				tableView.deleteRows(at: [IndexPath(row: i)], with: .automatic)
			} else {
				dataSource[i] = new
				tableView.reloadRows(at: [IndexPath(row: i)], with: .automatic)
			}
		} else if !deleted {
			insertNewRecord(new)
		}
	}
	
	private func insertNewRecord(_ record: Recording) {
		dataSource.insert(record, at: 0)
		tableView.insertRows(at: [IndexPath(row: 0)], with: .top)
	}
	
	
	// MARK: - Table View Delegate
	
	override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		editRecord(dataSource[indexPath.row])
	}
	
	private func editRecord(_ record: Recording, isNewRecording: Bool = false) {
		performSegue(withIdentifier: "editRecordSegue", sender: (record, isNewRecording))
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "editRecordSegue" {
			let (record, newlyCreated) = sender as! (Recording, Bool)
			let target = segue.destination as! VCEditRecording
			target.record = record
			target.deleteOnCancel = newlyCreated
		} else if segue.identifier == "openRecordDetailsSegue" {
			if let i = tableView.indexPathForSelectedRow {
				(segue.destination as? TVCRecordingDetails)?.record = dataSource[i.row]
			}
		}
	}
	
	
	// MARK: - Table View Data Source
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		dataSource.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "PreviousRecordCell")!
		let x = dataSource[indexPath.row]
		cell.textLabel?.text = x.title ?? x.fallbackTitle
		cell.textLabel?.textColor = (x.title == nil) ? .systemGray : nil
		cell.detailTextLabel?.text = "at \(x.start.asDateTime()),  duration: \(x.durationString  ?? "?")"
		return cell
	}
}
