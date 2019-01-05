//
//  ScheduledEvents.swift
//  ISO State 2018
//
//  Created by Jung-Sun Yi-Tsang on 3/24/18.
//  Copyright © 2018 bayser. All rights reserved.
//

import UIKit


class SchedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
//class SchedViewController: UITableViewController {
    @IBOutlet weak var SchedView: UITableView!
    
    var datedSched: [(String, [EventLabel])] = []
    
    //reorganizes the events
    func sortByDate() {
        var dates: [String] = []
        //get the dates involved
        for ev in ScheduleData.schedEvents {
            if !(dates.contains(ev.date) ) {
                dates.append(ev.date)
            }
        }
        dates = dates.sorted()
        //sort by date
        var tmp: [(String, [EventLabel])] = []
        for date in dates {
            var relevantEvents: [EventLabel] = [] //events on the given day
            for ev in ScheduleData.schedEvents {
                //if the current event is on the date in question
                if ev.date == date {
                    relevantEvents.append(ev)
                }
            }
            relevantEvents = ScheduleData.orderEvents(eventList: relevantEvents)
            tmp.append((date, relevantEvents))
        }
        self.datedSched = tmp
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        //return 1
        self.sortByDate()
        return self.datedSched.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datedSched[section].1.count
        //return list.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "schedule", for: indexPath)
        
        cell = (self.datedSched[indexPath.section].1[indexPath.row] as EventLabel).printCell(cell: cell)
        //cell.textLabel?.text = list[indexPath.row]
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.datedSched[section].0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = self.datedSched[section].0
        label.backgroundColor = UIColor(red:0.81, green:0.81, blue: 0.81, alpha: 0.9)
        return label
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sortByDate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sortByDate()
        SchedView.reloadData()
        
        //extra detail by tapping on a cell
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        recognizer.delegate = self as? UIGestureRecognizerDelegate
        SchedView.addGestureRecognizer(recognizer)
    }
    
    //handle taps on the UITableView
    @objc func onTap(recognizer : UITapGestureRecognizer) {
        //if recognizer.state == .began {
        if recognizer.state == .ended {
            let touchPoint = recognizer.location(in: SchedView)
            if let indexPath = SchedView.indexPathForRow(at: touchPoint) {
                let cell = SchedView.cellForRow(at: indexPath)
                //print(indexPath)
                //modify when cells get prettier!
                let title = cell?.textLabel!.text
                let msg = cell?.detailTextLabel!.text
                let alert = UIAlertController(title: title, message: msg,  preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(title:
                        NSLocalizedString("Ok", comment: "Default action"),
                                  style: .default)
                )
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
