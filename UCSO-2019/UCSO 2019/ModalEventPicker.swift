//
//  ModalEventPicker.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 12/28/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import UIKit

class ModalEventPicker: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var eventPicker: UIPickerView!
    
    var divTeams: [Int] = []
    var trials: [Int] = []
    
    func updateVals() {
        self.divTeams = EventsData.divXEvents(div: EventsData.div)
        self.trials = EventsData.eventsThat(have: true, prop: 1).map{$0.0}
    }
    
    override func viewDidLoad() {
        self.updateVals()
        super.viewDidLoad()
        eventPicker.dataSource = self
        eventPicker.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.updateVals()
        super.viewDidAppear(animated)
    }
    

    func numberOfComponents(in eventPicker: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.divTeams.count
        //return EventsData.completeSOEventList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let internalNum = self.divTeams[row]
        let fakeIndex = internalNum - 1 //unrigorous
        if fakeIndex >= EventsData.completeSOEventList.count {
            return nil
        }
        
        var eventTitle = EventsData.completeSOEventList[fakeIndex]
        
        if self.trials.contains(row) {
            eventTitle += " (Trial)"
        }
        return eventTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //add the current selection into the events list
    @IBAction func addButton(_ sender: Any) {
        let row = eventPicker.selectedRow(inComponent: 0)
        let eventNum = (EventsData.div == "C") ? EventsData.divXEvents(div: "C")[row] : EventsData.divXEvents(div: "B")[row]
        if !(EventsData.selectedList.contains(eventNum)) {
            addEvent(eventNum: eventNum) //save to disk and ScheduleData
            EventsData.selectedList.append(eventNum)
            cancelButton(addButton)
        } else {
            let alert = UIAlertController(title: "Event Selection", message: "You've already selected this event", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(title:
                    NSLocalizedString("Ok", comment: "Default action"),
                    style: .default)
            )
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func cancelButton(_ sender: Any) {
        //sendNotificationToUpdate()
        self.dismiss(animated: true, completion: nil)
    }
    
    /*func sendNotificationToUpdate() -> Void {
        NotificationCenter.default.post(name: .reload, object: nil)
    }*/
}
