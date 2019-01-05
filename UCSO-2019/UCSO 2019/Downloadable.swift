  //
//  Downloadables.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 1/2/18.
//  Copyright © 2018 bayser. All rights reserved.
//

import Foundation

class Downloadable {
    let fileCount = 7
    let files: [CSVFile] //initialized in the Downloadable init() function
    let fileNames = ["soevents", "teams", "tests", "builds", "impounds",  "scheduledevents", "locations"]
    //var downloadInProgress = 0

    //load from disk
    func load() {
        DispatchQueue.main.async {
            for i in 0..<self.fileCount {
                self.files[i].load(fileName: self.fileNames[i])
            }
            self.parse()
        }
    }
    
    //start the downloads
    func beginUpdate() {
        for i in 0..<self.fileCount {
            self.files[i].downloadFile(sourceURL: CSVFile.addressesList[i])
        }
    }
    
    //save and parse
    func finishUpdate() {
        self.save()
    }
    
    //saves all the tracked files
    func save() {
        DispatchQueue.main.async {
            for i in 0..<self.fileCount {
                self.files[i].save(name: self.fileNames[i])
            }
        }
    }
    
    //to try to start early
    //don't think this works...
    func manualStart() {
        self.load()
        self.beginUpdate()
    }
    
    //initialize the files
    init() {
        //self.files = [CSVFile](repeating: CSVFile(), count: self.fileCount)
        var tmp: [CSVFile] = []
        for i in 0..<self.fileCount {
            tmp.append(CSVFile())
            tmp[i].whichFile = i
        }
        self.files = tmp
        //self.load()
        //self.beginUpdate()
        //Notification center hasn't started up yet
        //self.downloadInProgress = 0
        
    }
    
    //should be pretty quick to run
    //loads contents from *.file to *.data
    func parse() {
        //first make sure everything is downloaded
        for i in 0..<fileCount {
            if self.files[i].file.count < 1 {
                //break
                //print("\(self.fileNames[i]) is not ready to be parsed")
                return
            }
        }
        //parse into the data files
        for i in 0..<fileCount {
            self.files[i].parse()
        }
        
        //put into proper places
        //file 0
        let eventNumbers = (getCol(array: self.files[0].data, col: 0) as! [String]).map{Int($0)!}
        EventsData.soEventNumbers = eventNumbers
        EventsData.completeSOEventList = getCol(array: self.files[0].data, col: 1) as! [String]
        EventsData.soEventProperties = (self.files[0].data as [[String]]).map{
            $0[2...].map{stringToBool(s: $0)}
        }
        //file 1
        EventsData.roster = getCol(array: self.files[1].data, col: 3) as! [String]
        EventsData.officialNumbers = (getCol(array: self.files[1].data, col:1) as! [String]).map{Int($0)!}
        loadSchoolName()
        let cs = EventsData.currentSchool
        if (cs < self.files[1].data.count) && (2 < self.files[1].data[cs].count) && (0 < self.files[1].data[cs][2].count) {
            EventsData.div = self.files[1].data[cs][2].first!
        }
        
        //the rest of the files
        self.prepareSOEvents()
        self.prepareSchedEvents()
        self.prepareLocations()
    }
    
    //load the scioly events from the downloaded/loaded CSVs into ScheduleData.completeSOEvents
    func prepareSOEvents() -> Void {
        let trials = EventsData.eventsThat(have: true, prop: 1).map{$0.0}
        var tmp: [EventLabel] = []
        let cTB = EventsData.currentTimeBlock()
        //add contributions from file 2, testing events
        for i in 0..<self.files[2].data.count {
            let info = self.files[2].data[i]
            //print (info)
            let (evNum, loc) = (Int(info[0])!, info[3])
            let evName = info[1] + (trials.contains(evNum) ? " (Trial)" : "")
            let locCode = Int(info[4]) ?? -1
            let tmpTime = info[4+cTB!]
            let dur = (info[2]=="") ? 50 : Int(info[2])! //timeblock events are 50 minutes unless otherwise specified
            let evTime = ScheduleData.formatTime(time: tmpTime, duration: dur)
            let entry = EventLabel(num: evNum, name: evName, loc: loc, locCode: locCode, time: evTime)
            tmp.append(entry)
        }
        //add contributions from file 3, self-scheduled events
        for i in 0..<self.files[3].data.count {
            let info = self.files[3].data[i]
            let (evNum, loc) = (Int(info[0])!, info[3])
            let evName = info[1] + (trials.contains(evNum) ? " (Trial)" : "")
            let locCode = Int(info[4]) ?? -1
            let ind = 4+EventsData.teamNumber()
            let tmpTime = ind>=info.count ? "?" : info[ind] //not pretty yet
            let duration = Int(info[2]) ?? 0
            let evTime = ScheduleData.formatTime(time: tmpTime, duration: duration)
            let entry = EventLabel(num: evNum, name: evName, loc: loc, locCode: locCode, time: evTime)
            tmp.append(entry)
        }
        //add contributions from file 4, the impound times
        for i in 0..<self.files[4].data.count {
            let info = self.files[4].data[i]
            let (evNum, loc) = (Int(info[0])!, info[3])
            let evName = info[1] + (trials.contains(evNum) ? " (Trial)" : "")
            let locCode = Int(info[4]) ?? -1
            let dur = (info[2]=="") ? 60 : Int(info[2])! //putting default duration of impound as 1 hour
            let evTime = ScheduleData.formatTime(time: info[5], duration: dur)
            let evTitle = "Impound for \(evName)"
            let entry = EventLabel(num: evNum, name: evTitle, loc: loc, locCode: locCode, time: evTime)
            tmp.append(entry)
        }
        ScheduleData.completeSOEvents = ScheduleData.orderEvents(eventList: tmp) //reordered by time
    }
    
    func prepareSchedEvents() -> Void {
        var tmp: [EventLabel] = []
        //comes directly from file 5, the scheduled events
        for i in 0..<self.files[5].data.count {
            let info = self.files[5].data[i]
            let (evName, date, loc) = (info[0], info[3], info[4])
            let evTime = ScheduleData.formatTime(time: info[2])
            let locCode = Int(info[5]) ?? -1
            var divC = info[1].lowercased().contains("c") //true if c
            var divB = info[1].lowercased().contains("b") //true if b -- can be both if "bc" or something
            if !(divB || divC) {
                //In case the thing is blank, assume it's valid for both
                divB = true
                divC = true
            }
            
            let entry = EventLabel(name: evName, loc: loc, locCode: locCode, time: evTime, date: date, divB: divB, divC: divC)
            tmp.append(entry)
        }
        ScheduleData.schedEvents = tmp //need to reorder later anyway
    }
    //load into Locations.swift's class
    func prepareLocations() -> Void {
        var tmp: [(String, String, Int, Double, Double)] = []  
        //load from file 6, the location coordinates
        for i in 0..<self.files[6].data.count {
            let info: [String] = self.files[6].data[i]
            let locCode = Int(info[2])!
            let latlong = Array(info[3...]).map{Double($0)!}
            tmp.append((info[0], info[1], locCode, latlong[0], latlong[1]))
        }
        Locs.locList = tmp //apparently this is okay despite the scopes changing
        //behavior seems to be that it makes a full copy rather than just passing a pointer...
        //Map will be called by notification dude
    }
}
