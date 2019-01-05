//
//  ScheduleData.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 12/29/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import Foundation
import UIKit

class EventLabel {
    var name = ""
    var loc = ""
    var time = ""
    var date = "" //optional
    var num: Int = -1 //optional but should have for SOEvents
    var locCode: Int = -1 //optional -- for linking to the map
    func getTime() -> String! {
        return self.time
    }
    func getTuple() -> (String, String, String) {
        return (self.name, self.loc, self.time)
    }
    func setTuple(setName: String, setLoc: String, setTime: String) {
         (self.name, self.loc, self.time) = (setName, setLoc, setTime)
    }
    //returns a string
    func printString() -> String! {
        return "\(self.time) @ \(self.loc): \(self.name)"
    }
    //returns the textlabel text as well as the detail text
    func printCell(cell: UITableViewCell) -> UITableViewCell {
        let cellCopy = cell
        cellCopy.textLabel?.text = "\(self.name)"
        cellCopy.detailTextLabel?.text = "\(self.time) @ \(self.loc)"
        return cellCopy
    }
    init(name: String, loc: String, time: String) {
        (self.name, self.loc, self.time) = (name, loc, time)
    }
    init(name: String, loc: String, locCode: Int, time: String, date: String) {
        (self.name, self.loc, self.locCode, self.time, self.date) = (name, loc, locCode, time, date)
    }
    init(name: String, loc: String, locCode: Int, time: String) {
        (self.name, self.loc, self.locCode, self.time) = (name, loc, locCode, time)
    }
    init(num: Int, name: String, loc: String, locCode: Int, time: String) {
        (self.num, self.name, self.loc, self.locCode, self.time) = (num, name, loc, locCode, time)
    }
    init () {}
}

class ScheduleData {
    static var selectedSOEvents: [EventLabel] = []
    static var completeSOEvents: [EventLabel] = []
    static var schedEvents: [EventLabel] = [] //arrange by date...

    static func reorganize() {
        ScheduleData.selectedSOEvents = orderEvents(eventList: selectedSOEvents)
        //print (ScheduleData.selectedSOEvents.map{$0.time})
    }
    
    
    //returns a list of events in chronological/alphabetical order
    static func orderEvents(eventList: [EventLabel]) -> [EventLabel] {
        return eventList.sorted(by: comesBefore)
    }
    
    //returns whether first event happens before the second event
    //can assume this is processing a standard time (either "?" or "9:20 AM")
    static func comesBefore (ev1: EventLabel, ev2: EventLabel) -> Bool {
        //first by date if possible:
        if (ev1.date != "" && ev2.date != "") { //both dates are defined
            if ev1.date < ev2.date {
                return true
            } //otherwise keep going
        }
        
        //in case time is unknown
        if (ev1.time == "?" || ev1.time == "" || ev2.time == "?" || ev2.time == "") {
            return true
        }
        let (t1, t2) = (formatTime(time:  ev1.time), formatTime(time: ev2.time))
        //fill in the blanks
        
        let (s1, s2) = (t1.index(of: " ")!, t2.index(of: " ")!)
        let (mm1, mm2) = (t1.index(of: "M")!, t2.index(of: "M")!)
        let (amInd1, amInd2) = (t1.index(mm1, offsetBy: -1), t2.index(mm2, offsetBy: -1))
        let (am1, am2) = (String(t1[amInd1]).first!, String(t2[amInd2]).first!)
        //if one is in the morning but the other is in the afternoon
        if am1 != am2 {
            return am1 < am2 //It's a convenient fact that 'A' < 'P'
        }
        let (col1, col2) = (t1.index(of: ":")!, t2.index(of: ":")!)
        let (hStr1, hStr2) = (String(t1[..<col1]), String(t2[..<col2]))
        let (h1, h2) = (Int(hStr1)!, Int(hStr2)!)
        
        if h1 != h2 {
            return h1 < h2
        }
        
        let (c1, c2) = (t1.index(col1, offsetBy: 1), t2.index(col2, offsetBy:1))
        let (mStr1, mStr2) = (String(t1[c1..<s1]), String(t2[c2..<s2]))
        let (m1, m2) = (Int(mStr1)!, Int(mStr2)!)
        
        if m1 != m2 {
            return m1 < m2
        }
        return ev1.name < ev2.name
    }
    
    //turn time into a string
    static func stringifyTime(hour: Int, mins: Int, ampm: Character ) -> String {
        let minString = ((mins<10) ? "0" : "") + String(mins) //add an extra 0 for 1-digit
        let hourString = String(hour)
        let output = "\(hourString):\(minString) \(ampm)M"
        return output
    }
    
    static func completeTime(time: String, duration: Int = 0) -> String {
        var ampm: Character = " "
        var result = ""
        //determine whether it's AM or PM for various formats
        if time == "" {
            return ""
        } else if time.contains("M") {
            let m = time.index(time.index(of: "M")!, offsetBy: -1)
            ampm = String(time[m]).first!
        } else { // infer
            var hours: Int = 0
            if time.contains(":") {
                let colon = time.index(of: ":")!
                hours = Int(String(time[..<colon]))!
            } else { //only a single number
                hours = Int(String(time))!
            }
            ampm = (hours>=7) ? "A" : "P"
        }
        //standardize and put into "stdTime"
        var startHour: Int, startMins: Int
        if time.contains(":") { //if it's written like 9:00 as opposed to 9
            let colon = time.index(of: ":")!
            let cHours = Int(String(time[..<colon]))! //extract current hour
            
            let startInd = time.index(colon, offsetBy: 1)
            let endInd = time.index(startInd, offsetBy: 2)
            let cMins = Int(String(time[startInd..<endInd]))! //get first two characters after the ":"
            
            startHour = cHours
            startMins = cMins
        } else { //:00 inferred
            var cHour = 0
            if time.contains(" ") {
                let space = time.index(of: " ")!
                cHour = Int(String(time[..<space]))!
            } else { //just a number
                cHour = Int(String(time))!
            }
            startHour = cHour
            startMins = 0
        }
        let stdTime = stringifyTime(hour: startHour, mins: startMins, ampm: ampm)
        result = stdTime
        
        if duration != 0 {
            //find the end time of the interval
            let mins = duration + startMins
            
            let endHour = startHour + (mins/60 as Int)
            let endMins = mins % 60
            
            //finish the interval
            let endTime = stringifyTime(hour: endHour, mins: endMins, ampm: ampm)
            if duration == 0 {
                result = stdTime
            } else if endHour >= 12 { //need to switch AM to PM or PM to AM //assume duration < 24 hours
                result = "\(stdTime) - \(endTime)" //no need to cut anything
            } else { //don't switch AM/PM -- cut off the end of stdTime
                let space = stdTime.index(of: " ")!
                let tmpTime = String(stdTime[..<space]) //looks something like "9:00" with no " AM"
                result = "\(tmpTime) - \(endTime)"
            }
        }
        return result
    }
    

    //helper function just for string processing
    static func formatTime(time: String, duration: Int = 50) -> String {
        var result = ""
        if time == "" || time == "?" { //don't know
            result = "?"
        } else if time.count > 8 { //don't change
            result = time
        } else { //need to finish formatting
            result = completeTime(time: time)
        }
        return result
    }
    
    //retrieves the event in the complete SOEvent list that matches requested event number
    //there *should* only be one result, but this only returns the first
    static func getEventsFromNumber(evNum: Int, completeList: Bool = true) -> [EventLabel] {
        let events = completeList ? completeSOEvents : selectedSOEvents
        var list: [EventLabel] = []
        for event in events {
            if event.num == evNum {
                list.append(event)
            }
        }
        return list //could be empty
    }
    
}
