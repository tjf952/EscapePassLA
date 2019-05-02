//
//  UserEventViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/3/24.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class UserEventViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var statusTab: UISegmentedControl!
    @IBOutlet weak var eventTable: UITableView!
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    var uid: String?
    var eventRooms: Array<String> = Array()
    var eventDates: Array<String> = Array()
    var eventNum: Array<String> = Array()
    let userDefault = UserDefaults.standard

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        loadTable()
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if eventRooms.count == 0
        {
            return 1
        }
        else
        {
            return eventRooms.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "eventCell")
        if eventRooms.count == 0
        {
            cell.textLabel?.text = "No Event Available"

        }
        else
        {
            cell.textLabel?.text = "\"\(eventRooms[indexPath.row])\" on \(eventDates[indexPath.row])"
        }
        return cell
    }
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if eventRooms.count != 0
        {
            print("selected: " + eventNum[indexPath.row])
            NotificationCenter.default.addObserver(self, selector: #selector(handleEventDetail), name: NSNotification.Name(rawValue: "updateEventList"), object: nil)
            self.userDefault.set(eventNum[indexPath.row], forKey: "eventNum")
            self.userDefault.synchronize()
            self.performSegue(withIdentifier: "toEventDetail", sender: nil)
        }
    }
    
    @objc func handleEventDetail(notification: Notification)
    {
        print("return from event detail page")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updateEventList"), object: nil)
        loadTable()
    }
    
    func loadTable()
    {
        eventRooms = Array()
        eventDates = Array()
        eventNum = Array()
        let currStatus = getSelectedStatus()
        let userReference = ref.child("users").child((Auth.auth().currentUser?.uid)!)
        userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
            if let user = userSnapshot.value as? [String: AnyObject]
            {
                if user["eventsIn"] != nil
                {
                    let userEvents = (user["eventsIn"] as? Array<String>)!
                    for each in userEvents
                    {
                        let eventReference = self.ref.child("events").child(each)
                        print("event \(each)")
                        eventReference.observeSingleEvent(of: .value, with: { (eventSnapshot) in
                            if let eventInfo = eventSnapshot.value as? [String: AnyObject]
                            {
                                if eventInfo["roomName"] != nil && eventInfo["time"] != nil && eventInfo["status"] != nil
                                {
                                    let roomName = (eventInfo["roomName"] as? String)!
                                    let eventTime = (eventInfo["time"] as? String)!
                                    var eventStatus = (eventInfo["status"] as? String)!
                                    if eventStatus != "removed"
                                    {
                                        if eventStatus == "incomplete" && self.getDateDifferenceFromNow(dateToCompare: eventTime) < 1
                                        {
                                            print("difference: \(self.getDateDifferenceFromNow(dateToCompare: eventTime))")
                                            eventStatus = "needrating"
                                            eventReference.updateChildValues(["status": eventStatus])
                                        }
                                        if currStatus == eventStatus
                                        {
                                            self.eventRooms.append(roomName)
                                            self.eventDates.append(eventTime)
                                            self.eventNum.append(each)
                                            DispatchQueue.main.async
                                            {
                                                self.eventTable.reloadData()
                                            }
                                        }
                                    }
                                    else
                                    {
                                        print("event \(each) was removed")
                                    }
                                }
                                else
                                {
                                    print("can't get event info for \(each)")
                                }
                            }
                            else
                            {
                                print("failed to pull event")
                            }
                        }, withCancel: nil)
                    }
                }
                else
                {
                    print("user has no event")
                }
            }
            else
            {
                print("failed to pull user info")
            }
        }, withCancel: nil)
        DispatchQueue.main.async
        {
            self.eventTable.reloadData()
        }
    }
    
    func getSelectedStatus() -> String
    {
        let statusIndex = statusTab.selectedSegmentIndex
        print("selected status index: \(statusIndex)")
        switch statusIndex
        {
        case 0:
            return "incomplete"
        case 1:
            return "needrating"
        case 2:
            return "completed"
        default:
            return "incomplete"
            
        }
    }
    
    func getDateDifferenceFromNow(dateToCompare: String) -> Int
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateObj = formatter.date(from: dateToCompare)
        let secondsBetween = abs(NSDate().timeIntervalSince(dateObj!))
        let numberDays = Int(secondsBetween / 86400)
        return numberDays
    }
    
    @IBAction func statusChanged(_ sender: UISegmentedControl)
    {
        loadTable()
    }
    
    @IBAction func leavePage(_ sender: UIButton)
    {
        print("leaving user event page")
        if let nav = self.navigationController
        {
            nav.popViewController(animated: true)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
