//
//  SecondViewController.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 12/10/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import UIKit



class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var schoolTitle: UITextField!
    @IBOutlet weak var homeroomLocation: UITextField!
    @IBOutlet weak var schedView: UITableView!
    

    //var homeroomFile = CSVFile()
    //var dlFiles = Downloadable()
    
    // Get the refresh button to refresh
    @IBAction func refreshData(_ sender: UIBarButtonItem) {
        DLM.dlFiles.beginUpdate() //table gets refreshed if download finishes
        //NotificationCenter.default.post(name: .reloadSchoolName, object:nil)
    }

    //called every time the view is brought to view
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DLM.dlFiles.beginUpdate() // call the update now
        updateSchoolAndTable()
    }

    //called just at the beginning of the app
    override func viewDidLoad() {
        loadSchoolName()
        loadEvents()
        updateEvents()
        
        super.viewDidLoad()
        updateSchoolAndTable()
        
        //NotificationCenter.default.addObserver(self, selector: #selector(updateSchoolAndTable), name: .reloadSchoolName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDownloadSummoned), name: .downloadFinished, object: nil)
        
        //extra detail by tapping on a cell
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        recognizer.delegate = self as? UIGestureRecognizerDelegate
        schedView.addGestureRecognizer(recognizer)
    }
    
    //handle taps on the UITableView
    @objc func onTap(recognizer : UITapGestureRecognizer) {
        //if recognizer.state == .began {
        if recognizer.state == .ended {
            let touchPoint = recognizer.location(in: schedView)
            if let indexPath = schedView.indexPathForRow(at: touchPoint) {
                let cell = schedView.cellForRow(at: indexPath)
                print(indexPath)
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
    
    //on download finish (note: does not update view)
    @objc func onDownloadSummoned () {
        DLM.dlFiles.finishUpdate()
        updateSchoolAndTable()
    }
    
    //update the text to reflect current team set
    //called by onDownloadSummoned and onViewDidAppear
    @objc func updateSchoolAndTable() {
        DispatchQueue.main.async() {
            //update team info
            /*let sNumber = EventsData.teamNumber()!
            if DLM.dlFiles.homerooms.data.count > 1 {
                ScheduleData.updateHomerooms(dataFile: DLM.dlFiles.homerooms)
            }*/
            
            let sNumber = EventsData.currentSchool
            var currentHomeroom: String
            if DLM.dlFiles.homerooms.data.count > sNumber && sNumber >= 0 {
                currentHomeroom = DLM.dlFiles.homerooms.data[sNumber]
            } else {
                currentHomeroom = "Not currently available..."
            }
            self.schoolTitle.text = "Viewing as: (\(sNumber)) \(EventsData.roster[sNumber])"
            self.homeroomLocation.text = "Homeroom: \(currentHomeroom)"
            saveSelectedSchool(currentSchool: sNumber)
            
            //update the table itself
            self.updateEvents()
            
            self.schedView.reloadSections(IndexSet([0,1,2]) , with: .none)
            self.schedView.reloadInputViews()
        }
    }
    
    
    //put the events back into ScheduleData.events so that it can be nicely formatted
    func updateEvents() {
        var elList: [EventLabel] = []
        if DLM.dlFiles.testEvents.file == "" {return}
        //for elm in EventsData.selectedList {
        //    let i = EventsData.selectedList.index(of: elm)!
        for i in 0..<EventsData.selectedList.count {
            let elm = EventsData.selectedList[i]
            // make sure no index-out-of-bounds error for `loc`
            if DLM.dlFiles.testEvents.data.count <= i+1 {
                return
            } else if DLM.dlFiles.testEvents.data[i+1].count <= 5 {
                return
            }
            let loc = DLM.dlFiles.testEvents.data[i+1][5]

            var time = "?"
            
            //check for build events
            if (EventsData.isSelfScheduled(evnt: elm)) {
                //lookup from build event file
                let teamNumber = EventsData.teamNumber()!
                let j = 1+EventsData.selfScheduled.index(of: elm)!
                //print("Trying to access: team number \(teamNumber) for the \(j)th event")
                time = ScheduleData.cleanTime(time: DLM.dlFiles.buildEvents.data[j][teamNumber])
            } else {
                let teamBlock =  Int(ceil(Float(EventsData.currentSchool)/10)) //1-10,11-20,21-30,31-40
                time = ScheduleData.cleanTime(time: DLM.dlFiles.testEvents.data[i+1][teamBlock])
            }
            //print(time)
            let tmp = EventLabel(name: elm, loc: loc, time: time)
            elList.append(tmp)
        }
        ScheduleData.soEvents = ScheduleData.orderEvents(eventList: elList)
        
        //print("At the end of updateEvents, there are \(ScheduleData.events.count) events")
    }
    
    //MARK: mostly boring table management stuff below this point
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return ScheduleData.earlyEvents.count + EventsData.impoundList().count
        case 2:
            return ScheduleData.lateEvents.count
        default:
            return EventsData.selectedList.count //the meat and potatoes
        }
    }
    
    //give labels to the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("Getting Knowledge from section \(indexPath.section), I see...")
        var cell = tableView.dequeueReusableCell(withIdentifier: "schedule", for: indexPath)
        let section = indexPath.section
        switch section {
        case 0:
            //print(indexPath.row)
            if indexPath.row < ScheduleData.earlyEvents.count {
                //cell.textLabel!.text = (ScheduleData.earlyEvents[indexPath.row] as EventLabel).print()
                cell = (ScheduleData.earlyEvents[indexPath.row] as EventLabel).printCell(cell: cell)
            } else {
                let beName = EventsData.impoundList()[indexPath.row - ScheduleData.earlyEvents.count]
                let i = EventsData.completeList.index(of: beName)!
                let teamBlock = Int(ceil(Float(EventsData.currentSchool)/10))
                var loc = ""
                var time = ""
                //if beName == "Hovercraft" {
                    // make sure no index-out-of-bounds error for `ScheduleData.cleanTime`
                    if DLM.dlFiles.testEvents.data.count <= i+1 || DLM.dlFiles.testEvents.data[i+1].count <= teamBlock {
                        time = "8:00 - 8:30 AM"
                    } else {
                        time = ScheduleData.cleanTime(time: DLM.dlFiles.testEvents.data[i+1][teamBlock],
                                         duration: 30)!
                        loc = DLM.dlFiles.testEvents.data[i+1][5]
                    }
//                } else {
//                    time = "8:00 - 8:30 AM"
//                }
                var evName = "Impound for " + beName
                if beName == "Hovercraft" {
                    evName = "Written Test + " + evName
                }
                let buildEvent = EventLabel(name: evName, loc: loc, time: time)
                
                cell  = buildEvent.printCell(cell: cell)
            }
            break
        case 2:
            cell = (ScheduleData.lateEvents[indexPath.row] as EventLabel).printCell(cell: cell)
            break
        default:
            // check that ScheduleData.events is not empty
            if ScheduleData.soEvents.count == 0 {
                cell.textLabel!.text = "???"
                cell.detailTextLabel!.text = "pls connect to the internet :|"
            }
            // check that we actually have a testEvents file
            else if DLM.dlFiles.testEvents.file == "" || DLM.dlFiles.buildEvents.file == "" {
                cell.textLabel!.text = (ScheduleData.soEvents[indexPath.row] as EventLabel).name
                cell.detailTextLabel!.text = "Entry not found: Please connect to internet"
            } else {
                cell = (ScheduleData.events[indexPath.row] as EventLabel).printCell(cell: cell)
            }
        }
        return cell
    }
}
