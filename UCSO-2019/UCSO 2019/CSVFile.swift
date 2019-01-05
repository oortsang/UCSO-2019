//
//  CSVtoArray.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 1/1/18.
//  Copyright © 2018 bayser. All rights reserved.
//

import Foundation
import CoreData

/*extension Notification.Name {
    static let downloadFinished = Notification.Name("downloadFinished")
    //static let reload = Notification.Name("reload")
    //static let reloadSchoolName = Notification.Name("reloadSchool")
}*/

func getCol(array: [[Any]], col: Int) -> [Any]? {
    var tmp: [Any] = []
    for row in array {
        tmp.append(row[col])
    }
    return tmp
}


class CSVFile {
    //static let baseFileFolder = "https://raw.githubusercontent.com/oortsang/ISO-State-2018/master/Updatable%20Files/"
    static let baseFileFolder =   "https://raw.githubusercontent.com/oortsang/UCSO-2019/master/UCSO-2019/Updatable%20Files/"
    static let soEventAddress = baseFileFolder + "SOEventSummary.csv"
    static let teamsAddress = baseFileFolder + "Teams.csv"
    static let testsAddress = baseFileFolder + "Tests.csv"
    static let buildsAddress = baseFileFolder + "SelfScheduled.csv"
    static let impoundAddress = baseFileFolder + "Impound.csv"
    static let schedAddress = baseFileFolder + "ScheduledEvents.csv"
    static let locAddress = baseFileFolder + "Locations.csv"
    
    static let addressesList = [CSVFile.soEventAddress,
                                CSVFile.teamsAddress,
                                CSVFile.testsAddress,
                                CSVFile.buildsAddress,
                                CSVFile.impoundAddress,
                                CSVFile.schedAddress,
                                CSVFile.locAddress
                               ]
    var whichFile: Int = -1//for debugging
    var data: [[String]] = [[]]
    var file: String = ""
    
    //initializers
    init() {}
    init(input: [[String]]) {
        data = input
    }
    init (lookup: String) {
        self.load(fileName: lookup)
    }
    
    //takes the text info from a CSV and turns it into a 2D array
    //2D array gets dumped into the class
    func parse() {
        if self.file == "" {
            print("Empty File!")
            return
        }
        let rows: [String] = file.components(separatedBy: "\n")
        if rows.count > 1 { //want to make sure it's not just an empty file
            var data: [[String]] = []
            for i in 1..<rows.count {
                let content = rows[i].components(separatedBy: ",")
                if content != [""] {
                    data.append(content)
                }
            }
            self.data = data
        } //otherwise, leave it the same
    }
    
    //appDelegate is defined elsewhere
    static let fileContext = appDelegate.persistentContainer.viewContext
    //static let fileRequest = NSFetchRequest<String>(entityName: "Files")
    //static let fileRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Files")
    static let fileRequest = NSFetchRequest<Files>(entityName: "Files")
    //storing these csv guys
    //tell it what name to save under
    func save(name: String) {
        //don't want to overwrite existing things if there is nothing of use in the file at the moment
        if (self.file == "") {
            print("File not saved...")
            return
        }
        
        self.clear(fileName: name) //clean up any mess
        let newFile = NSEntityDescription.insertNewObject(forEntityName: "Files", into: CSVFile.fileContext)
        newFile.setValue (name, forKey: "fileName") //make an entry title
        newFile.setValue(self.file, forKey: "data") //put the string in it

        //print("saved under \(name): \(self.file)")

        do {
            try CSVFile.fileContext.save()
        }  catch {
            print("Something went wrong with saving a file")
        }



    }
    //load from disk
    func load(fileName: String) {
        CSVFile.fileRequest.returnsObjectsAsFaults = false
        let tmp = CSVFile.fileRequest.predicate
        CSVFile.fileRequest.predicate = NSPredicate(format: "fileName = %@", fileName)
        do {
            let results = try CSVFile.fileContext.fetch(CSVFile.fileRequest)
            //print("I have this many results: ",results.count)
            if results.count > 0 {
                //print(results)
                let result = results.first
                /*if let loadedData = (result as! NSManagedObject).value(forKey:"data") {
                    self.file = loadedData as! String
                    self.parse()
                }*/
                self.file = result!.data!
                self.parse()
                
            }
        }
        catch {
            print("Something went wrong with the request...")
        }
        CSVFile.fileRequest.predicate = tmp
        
        
    }
    //deletes every result when searching <name> in the fileRequest
    func clear(fileName: String) {
        CSVFile.fileRequest.returnsObjectsAsFaults = false
        do {
            let results = try CSVFile.fileContext.fetch(CSVFile.fileRequest) as [NSManagedObject]
            if results.count > 0 {
                
                for object in (results as [NSManagedObject]?)! {
                    //if object.value(forKey: "fileName") as! String == fileName {
                    if (object.value(forKey: "fileName") as? String) == fileName {
                        CSVFile.fileContext.delete(object)
                    }
                }
            }
        } catch {
            print("Something went wrong clearing out all the teams from disk")
        }
    }
    
    //clear all files from disk
    static func clearAll() -> Void {
        do {
            let results = try CSVFile.fileContext.fetch(fileRequest) as [NSManagedObject]
            if results.count > 0 {
                //delete all results
                for object in results {
                    //print("Removed \(object)")
                    CSVFile.fileContext.delete(object)
                }
            }
        } catch {
            print("Something went wrong clearing out all the files from disk")
        }
    }
    
    //downloads a file from the source URL and deposits into the object it's in
    func downloadFile(sourceURL: String) {
        let url = URL(string: sourceURL)
        let task = URLSession.shared.downloadTask(with: url!) { loc, resp, error in
            if let error = error {
                print("Error: \(error); not updated")
                //DLM.dlFiles.downloadInProgress -= 1
                return
            }
            guard let httpResponse = resp as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print("O O F")
                //DLM.dlFiles.downloadInProgress -= 1
                return
            }
            //DLM.dlFiles.downloadInProgress -= 1 //keep track instantly...
            
            guard let data = try? Data(contentsOf: loc!) , error == nil else {return}
            //self.file = (String(data: data, encoding: .utf8))!
            
            let tmpfile = (String(data: data, encoding: .utf8))!
            if tmpfile == "" {
                return
            }
            self.file = tmpfile
            //print("Just downloaded \(sourceURL): \n\(self.file)")
            //print("This is such a cool file! \(self.file)")
            self.parse()
            self.sendDownloadNotification()
        }
        task.resume()
    }
    func sendDownloadNotification() -> Void {
        NotificationCenter.default.post(name: .downloadFinished, object: nil)
    }
}
