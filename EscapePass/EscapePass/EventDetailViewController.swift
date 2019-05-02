//
//  EventDetailViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/3/25.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class EventDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {

    @IBOutlet weak var removeEventButton: UIButton!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var hostName: UILabel!
    @IBOutlet weak var playerTable: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    let userDefault = UserDefaults.standard
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    var eventNum: String?
    var players: Array<String> = Array()
    var uids: Array<String> = Array()
    var hostFlag: Bool = true
    var selectedIndex: Int = -1
    var hostUid: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        eventNum = ((userDefault.object(forKey: "eventNum")) as? String)!
        loadPage()
        // Do any additional setup after loading the view.
    }
    
    func loadPage()
    {
        let eventReference = ref.child("events").child(eventNum!)
        eventReference.observeSingleEvent(of: .value, with: { (eventSnapshot) in
            if let eventInfo = eventSnapshot.value as? [String: AnyObject]
            {
                if eventInfo["host"] != nil && eventInfo["roomName"] != nil && eventInfo["time"] != nil && eventInfo["status"] != nil
                {
                    self.hostUid = (eventInfo["host"] as? String)!
                    if self.hostUid! != (Auth.auth().currentUser?.uid)!
                    {
                        self.removeButton.setTitle("Leave Event", for: .normal)
                        self.hostFlag = false
                        self.removeEventButton.isEnabled = false
                        self.removeEventButton.isHidden = true
                    }
                    let roomName = (eventInfo["roomName"] as? String)!
                    let date = (eventInfo["time"] as? String)!
                    let status = (eventInfo["status"] as? String)!
                    if status != "needrating"
                    {
                        self.rateButton.isEnabled = false
                        self.rateButton.isHidden = true
                    }
                    self.dateLabel.text = date
                    self.roomLabel.text = roomName
                    if status == "incomplete"
                    {
                        self.statusLabel.text = "Incomplete"
                    }
                    else if status == "needrating"
                    {
                        self.statusLabel.text = "Need Rating"
                    }
                    else if status == "completed"
                    {
                        self.statusLabel.text = "Completed"
                    }
                    else
                    {
                        self.statusLabel.text = "Removed"
                    }
                    if eventInfo["uids"] != nil
                    {
                        let playerUid = (eventInfo["uids"] as? Array<String>)!
                        for temp in playerUid
                        {
                            let userReference = self.ref.child("users").child(temp)
                            userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
                                if let userInfo = userSnapshot.value as? [String: AnyObject]
                                {
                                    if userInfo["email"] != nil
                                    {
                                        let email = (userInfo["email"] as? String)!
                                        if self.hostUid! == temp
                                        {
                                            self.hostName.text = email
                                        }
                                        self.players.append(email)
                                        self.uids.append(temp)
                                        DispatchQueue.main.async
                                        {
                                            self.playerTable.reloadData()
                                        }
                                    }
                                    else
                                    {
                                        print("can't get \(temp) email")
                                    }
                                }
                                else
                                {
                                    print("failed to pull user info")
                                }
                            }, withCancel: nil)
                        }
                    }
                }
                else
                {
                    print("incorrect event info")
                }
            }
        }, withCancel: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if players.count == 0
        {
            return 1
        }
        else
        {
            return players.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "playerCell")
        if players.count == 0
        {
            cell.textLabel?.text = "No Player Available"
            
        }
        else
        {
            cell.textLabel?.text = players[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if players.count != 0
        {
            selectedIndex = indexPath.row
        }
    }
    
    @IBAction func returnToPrevious(_ sender: UIButton)
    {
        backToEventList()
    }
    
    func backToEventList()
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateEventList"), object: self)
        print("leaving event detail page")
        if let nav = self.navigationController
        {
            nav.popViewController(animated: true)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func rateEvent(_ sender: UIButton)
    {
        print("TBD")
    }
    @IBAction func removePlayer(_ sender: UIButton)
    {
        if hostFlag
        {
            if selectedIndex != -1 && uids[selectedIndex] != hostUid!
            {
                let removedID = uids[selectedIndex]
                if selectedIndex < players.count
                {
                    players.remove(at: selectedIndex)
                }
                if selectedIndex < uids.count
                {
                    uids.remove(at: selectedIndex)
                }
                DispatchQueue.main.async
                {
                    self.playerTable.reloadData()
                }
                let eventReference = ref.child("events").child(eventNum!)
                eventReference.updateChildValues(["players": players])
                eventReference.updateChildValues(["uids": uids])
                let userReference = ref.child("users").child(removedID)
                userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
                    if let userInfo = userSnapshot.value as? [String: AnyObject]
                    {
                        if userInfo["eventsIn"] != nil
                        {
                            var userEvents = (userInfo["eventsIn"] as? Array<String>)!
                            let tempIndex = userEvents.firstIndex(of: self.eventNum!)!
                            userEvents.remove(at: tempIndex)
                            userReference.updateChildValues(["eventsIn": userEvents])
                        }
                    }
                    else
                    {
                        print("failed to pull user info")
                    }
                }, withCancel: nil)
            }
            else
            {
                print("1: can't remove host or 2: hasn't select a player")
            }
        }
        else
        {
            let removedID = (Auth.auth().currentUser?.uid)!
            var removedEmail: String?
            let userReference = ref.child("users").child(removedID)
            userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
                if let userInfo = userSnapshot.value as? [String: AnyObject]
                {
                    if userInfo["eventsIn"] != nil && userInfo["email"] != nil
                    {
                        var userEvents = (userInfo["eventsIn"] as? Array<String>)!
                        removedEmail = (userInfo["email"] as? String)!
                        let tempIndex = userEvents.firstIndex(of: self.eventNum!)!
                        userEvents.remove(at: tempIndex)
                        userReference.updateChildValues(["eventsIn": userEvents])
                        let playerIndex = self.players.firstIndex(of: removedEmail!)!
                        let uidIndex = self.uids.firstIndex(of: removedID)!
                        self.players.remove(at: playerIndex)
                        self.uids.remove(at: uidIndex)
                        let eventReference = self.ref.child("events").child(self.eventNum!)
                        eventReference.updateChildValues(["players": self.players])
                        eventReference.updateChildValues(["uids": self.uids])
                        self.backToEventList()
                    }
                    else
                    {
                        print("can't pull event or email")
                    }
                }
                else
                {
                    print("can't pull user info")
                }
            }, withCancel: nil)
        }
    }
    @IBAction func removeEvent(_ sender: UIButton)
    {
        let eventReference = ref.child("events").child(eventNum!)
        eventReference.updateChildValues(["status": "removed"])
        backToEventList()
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
