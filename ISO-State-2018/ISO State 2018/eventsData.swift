//
//  eventsData.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 12/28/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as! AppDelegate
let context = appDelegate.persistentContainer.viewContext
let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Events")

class EventsData: NSObject {
    static var selectedList: [Int] = [] //for the events on the event picker; store as an index of EventsData.completeSOEventList
    static var completeSOEventList: [String] = []
    static var soEventNumbers: [Int] = [] //stores the Event Numbers in the same order as they appear in ED.copmleteSOEventList
    static var soEventProperties: [[Bool]] = [] //store division (if C), trial, test, self-scheduled, impound info
    static var roster: [String] = [] //load up outside
    static var officialNumbers: [Int] = [] //real official numbers
    static var currentSchool = 0 //This is actually different from the team number because of the fact that there's division B and C -- use a unique identifier internally
    //static var currentHomeroomLocCode = -1//fill externally
    static var div: Character = "C" // "B" or "C"
    
    static func getHomeroom() -> (String, Int) {
        var currentHomeroom = "Not currently available..."
        var currentHomeroomLocCode = -1
        if DLM.dlFiles.files[1].data.count>0 && EventsData.roster.count > 0 {
            //print("Homeroom file is done")
            let homeroomNames = getCol(array:DLM.dlFiles.files[1].data, col:4) as! [String]
            let homeroomLocCodes = (getCol(array:DLM.dlFiles.files[1].data, col:5) as! [String]).map{Locs.locCoder(input: $0)}
            if homeroomNames.count > currentSchool && currentSchool >= 0 {
                //currentHomeroom = DLM.dlFiles.homerooms.data[sNumber]
                currentHomeroom = homeroomNames[currentSchool]
                currentHomeroomLocCode = homeroomLocCodes[currentSchool]
            }
            div = DLM.dlFiles.files[1].data[currentSchool][2].first!
        }
        return (currentHomeroom, currentHomeroomLocCode)
    }
    
    
    static func teamNumber() -> Int {
        if currentSchool >= DLM.dlFiles.files[1].data.count {
            print("careful!")
        }
        let res = Int(DLM.dlFiles.files[1].data[currentSchool][1])
        return res!
    }
    
    //get current schoool's time block
    static func currentTimeBlock() -> Int? {
        let teamInfo = DLM.dlFiles.files[1].data
        return Int(teamInfo[currentSchool][6])
    }
    
    //fxns to return a list of events with (or without) a given property
    static func eventsThat(have: Bool, prop: Int) -> [(Int, String)] {
        var tmp:[(Int, String)] = []
        let propList = getCol(array: soEventProperties, col: prop) as! [Bool]
        for i in 0..<completeSOEventList.count {
            if have == propList[i] {
                tmp.append((i, completeSOEventList[i]))
            }
        }
        return tmp
    }
    
    static func lookupEventName(evNumber: Int) -> String! {
        let i = EventsData.soEventNumbers.index(of: evNumber) //the event name will be in the ith position
        return EventsData.completeSOEventList[i!]
    }
    
    //returns a list of teams in the given division in terms of internal numbers
    static func divXTeams(div: Character) -> [Int] {
        let teamInfo = DLM.dlFiles.files[1].data
        var divTeams: [Int] = []
        for i in 0..<teamInfo.count {
            if teamInfo[i][2].first == div {
                divTeams.append(Int(teamInfo[i][0])!) //that's the internal number...
            }
        }
        return divTeams
    }
    
    static func divXEvents(div: Character) -> [Int] {
        let eventInfo = DLM.dlFiles.files[0].data
        var divEvents: [Int] = []
        for i in 0..<eventInfo.count {
            if eventInfo[i][2].first == div {
                divEvents.append(Int(eventInfo[i][0])!) //that's the internal number...
            }
        }
        return divEvents
    }
}

func stringToBool(s: String) -> Bool {
    if s == "1" || s.uppercased() == "C" || s.uppercased() == "Y" {return true} //takes care of div C/div B stuff easily
    else {return false}
}

//fetches events from CoreData
func loadEvents() -> Void {
    request.returnsObjectsAsFaults = false
    do {
        let results = try context.fetch(request)
        if results.count > 0 {
            var tmpRes = [Int]()
            for result in results {
                if let eventNum = (result as AnyObject).value(forKey:"event") as? Int {
                    if !tmpRes.contains(eventNum) {
                        tmpRes.append(eventNum)
                    }
                }
            }
            EventsData.selectedList = tmpRes
        }
    }
    catch {
        print("Something went wrong with the request...")
    }
}

//Dumps everything to storage
func firstSaveEvents() -> Void {
    for eachEvent in EventsData.selectedList {
        addEvent(eventNum: eachEvent)
    }
}

//Save the event list in storage
func saveEvents() -> Void {
    clearEvents() //for convenience
    for eachEvent in EventsData.selectedList {
        addEvent(eventNum: eachEvent)
    }
}


//add an event with CoreData as well as ScheduleData's list
//eventNum  is the internal event number code (converted when added in ModalEventPicker.swift)
func addEvent(eventNum: Int) -> Void {
    //adds to EventsData version
    //EventsData.selectedList.append(eventNum) //already there-- we're adding FROM EventsData!!
    
    //add to ScheduleData list
    //let evNum = Int(DLM.dlFiles.files[0].data[eventNum][0])!
    let evLabels = ScheduleData.getEventsFromNumber(evNum: eventNum)
    if evLabels.count == 0 {
        print("Couldn't add event! Maybe the files aren't available")
        guard let i = EventsData.selectedList.index(of: eventNum) else {
            return
        }
        EventsData.selectedList.remove(at: i)
        return
    } else {
        for ev in evLabels {
            ScheduleData.selectedSOEvents.append(ev)
        }
    }
    //save to CoreData
    let newEventThing = NSEntityDescription.insertNewObject(forEntityName: "Events", into: context)
    newEventThing.setValue (eventNum, forKey: "event")
    do {
        try context.save()
        print("Saved!")
    }
    catch {
        print("Something went wrong with adding an event")
    }
}

//removes the first occurrence of an event
func removeEvent(eventNum: Int, indexPath: IndexPath) -> Bool {
    
    //remove from ScheduleData.selectedSOEvents
    for i in 0..<ScheduleData.selectedSOEvents.count {
        if eventNum == ScheduleData.selectedSOEvents[i].num {
            ScheduleData.selectedSOEvents.remove(at: i)
            break
        }
    }
    
    //remove from EventsData.selectedList
    EventsData.selectedList.remove(at: indexPath.row)
    
    //remove from Core Data storage
    let tmp = request.predicate //just storing for later
    request.predicate = NSPredicate(format: "event = %ld", eventNum) //??
    var res : Bool = false
    do {
        let results = try context.fetch(request) as? [NSManagedObject]
        if results!.count > 0 {
            let object = results!.first
            //print("Removed \(String(describing: object))")
            context.delete(object!)
            res = true
        }
    } catch {
        print("Something went wrong deleting the event #\(eventNum)")
    }
    request.predicate = tmp //undo what just happened
    return res
}
//remove all events
func clearEvents() -> Void {
    do {
        let results = try context.fetch(request) as? [NSManagedObject]
        if results!.count > 0 {
            //delete all results
            for object in results! {
                //print("Removed \(object)")
                context.delete(object)
            }
        }
    } catch {
        print("Something went wrong clearing out all the events")
    }
}

