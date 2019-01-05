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

    var trials: [Int] = []
    
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
        
        schoolTitle.addTarget(self, action: #selector(schoolTap), for: UIControlEvents.touchDown)
        homeroomLocation.addTarget(self, action: #selector(schoolTap), for: UIControlEvents.touchDown)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDownloadSummoned), name: .downloadFinished, object: nil)
        
        //extra detail by tapping on a cell
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        recognizer.delegate = self as? UIGestureRecognizerDelegate
        schedView.addGestureRecognizer(recognizer)
        
        DLM.dlFiles.finishUpdate()
    }
    
    //handle taps on the UITableView
    @objc func onTap(recognizer : UITapGestureRecognizer) {
        //if recognizer.state == .began {
        if recognizer.state == .ended {
            let touchPoint = recognizer.location(in: schedView)
            if let indexPath = schedView.indexPathForRow(at: touchPoint) {
                let cell = schedView.cellForRow(at: indexPath)
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
    
    //displays a message box whenever the homeroom/team info area is tapped
    @objc func schoolTap(textField: UITextField) {
        //print(indexPath)
        //modify when cells get prettier!
        let school = EventsData.roster[EventsData.currentSchool]
        let teamNumber = EventsData.officialNumbers[EventsData.currentSchool]
        let team = "\(teamNumber)\(EventsData.div)"
        let (homeroom, code) = EventsData.getHomeroom()
        let title = school
        let msg = "\n Team Number: \(team)\n\n Homeroom: \(homeroom)"
        let alert = UIAlertController(title: title, message: msg,  preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title:
                NSLocalizedString("Ok", comment: "Default action"),
                          style: .default)
        )
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //on download finish
    @objc func onDownloadSummoned () {
        //print("Download ready! *** Downloads in progress: \(DLM.dlFiles.downloadInProgress)")
        DLM.dlFiles.finishUpdate()
        updateSchoolAndTable()
    }
    
    //update the text to reflect current team set
    //called by onDownloadSummoned and onViewDidAppear
    @objc func updateSchoolAndTable() {
        trials = EventsData.eventsThat(have: true, prop: 1).map{$0.0}
        DLM.dlFiles.parse()
        DispatchQueue.main.async() {
            let (hrString, _) = EventsData.getHomeroom()
            
            self.schoolTitle.text = "Viewing as: (\(EventsData.teamNumber())\(EventsData.div)) \(EventsData.roster[EventsData.currentSchool])"
            self.homeroomLocation.text = "Homeroom: \(hrString)"
            
            //update the table itself
            ScheduleData.reorganize()
            self.updateEvents()
            
            self.schedView.reloadSections(IndexSet([0]) , with: .none)
            self.schedView.reloadInputViews()
        }
    }
    
    
    //put the events back into ScheduleData.selectedSOEvents so that it can be nicely formatted
    //we may have loaded the selected events in EventsData (via core data)
    func updateEvents() {
        var elList: [EventLabel] = []
        //if any of these are empty, this process is not ready
        if DLM.dlFiles.files[0].file == ""
            || DLM.dlFiles.files[2].file == ""
            || DLM.dlFiles.files[3].file == ""
            || DLM.dlFiles.files[4].file == ""
            || ScheduleData.completeSOEvents.count == 0
        {
            return
        }
        for i in 0..<EventsData.selectedList.count { //for each active event, as accounted by EventsData
            let evnc: Int = EventsData.selectedList[i] //event number code
            let newEvLab: [EventLabel] = ScheduleData.getEventsFromNumber(evNum: evnc)
            if newEvLab.count == 0 {
                print("No events to add!")
            }
            for ev in newEvLab {
                elList.append(ev)
            }
        }
        ScheduleData.selectedSOEvents = ScheduleData.orderEvents(eventList: elList)
        //print("At the end of updateEvents, there are \(ScheduleData.events.count) events")
    }
    
    //MARK: mostly boring table management stuff below this point
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ScheduleData.selectedSOEvents.count //the meat and potatoes
    }
    
    //give labels to the cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("Getting Knowledge from section \(indexPath.section), I see...")
        var cell = tableView.dequeueReusableCell(withIdentifier: "event", for: indexPath)
        
        cell = (ScheduleData.selectedSOEvents[indexPath.row] as EventLabel).printCell(cell: cell)
        
        return cell
    }
}
