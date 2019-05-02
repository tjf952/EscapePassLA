//
//  AddEventViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/3/18.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class AddEventViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var playerTable: UITableView!
    @IBOutlet weak var roomNameLabel: UILabel!
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    let userDefault = UserDefaults.standard
    var roomName: String?
    var currentUser: String?
    var players: Array<String> = Array()
    var uids: Array<String> = Array()
    var selectedIndex: Int = -1
    override func viewDidLoad()
    {
        super.viewDidLoad()
        roomName = (userDefault.object(forKey: "detailRoomName")) as? String
        roomNameLabel.text = roomName!
        currentUser = (Auth.auth().currentUser?.uid)!
        let uid: String = (Auth.auth().currentUser?.uid)!
        let email: String = (Auth.auth().currentUser?.email)!
        players.append(email)
        uids.append(uid)
        datePicker.backgroundColor = .white

        // Do any additional setup after loading the view.
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
            cell.textLabel?.text = "No Player Added"
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
    
    @IBAction func addPlayer(_ sender: UIButton)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAddPlayerClosing), name: NSNotification.Name(rawValue: "addPlayerReturn"), object: nil)
        print("observer setup")
        //show popup view for user to enter there zip code
        let addPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addNewPlayerVC") as! AddNewPlayerViewController
        self.addChild(addPlayerVC)
        addPlayerVC.view.frame = self.view.frame
        self.view.addSubview(addPlayerVC.view)
        addPlayerVC.didMove(toParent: self)
    }
    
    @objc func handleAddPlayerClosing(notification: Notification)
    {
        print("receive add player result")
        let addPlayerVC = notification.object as! AddNewPlayerViewController
        let addPlayerEmail = addPlayerVC.userEmail
        let addPlayerUid = addPlayerVC.uid
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "addPlayerReturn"), object: nil)
        if addPlayerEmail != "negative"
        {
            if players.contains(addPlayerEmail)
            {
                print("already added")
            }
            else
            {
                players.append(addPlayerEmail)
                uids.append(addPlayerUid)
                DispatchQueue.main.async
                {
                    self.playerTable.reloadData()
                }
            }
        }
        else
        {
            print("no user added")
        }
    }
    
    @IBAction func deletePlayer(_ sender: UIButton)
    {
        if selectedIndex != -1
        {
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
        }
    }
    
    @IBAction func createEvent(_ sender: UIButton)
    {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateSelected = formatter.string(from: datePicker.date)
        let dateAdded = formatter.string(from: date)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let values = snapshot.value as? [String: AnyObject]
            {
                if values["eventCount"] != nil
                {
                    let temp = (values["eventCount"] as? String)!
                    let currNum = Int(temp)! + 1
                    self.ref.updateChildValues(["eventCount": "\(currNum)"])
                    let eventReference = self.ref.child("events").child("\(currNum)")
                    let info = ["host": (Auth.auth().currentUser?.uid)!, "roomName": self.roomName, "time": dateSelected, "dateAdded": dateAdded, "numPlayers": "\(self.players.count)", "status": "incomplete"]
                    eventReference.updateChildValues(info, withCompletionBlock: {
                        (err, ref) in
                        if err != nil
                        {
                            print(err)
                            return
                        }
                        print("successfully added event")
                    })
                    eventReference.updateChildValues(["players": self.players])
                    eventReference.updateChildValues(["uids": self.uids])
                    for each in self.uids
                    {
                        let userReference = self.ref.child("users").child(each)
                        userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
                            if let userDetail = userSnapshot.value as? [String: AnyObject]
                            {
                                if userDetail["eventsIn"] != nil
                                {
                                    var userEvents = (userDetail["eventsIn"] as? Array<String>)!
                                    userEvents.append("\(currNum)")
                                    userReference.updateChildValues(["eventsIn": userEvents])
                                }
                                else
                                {
                                    var userEvents: Array<String> = Array()
                                    userEvents.append("\(currNum)")
                                    userReference.updateChildValues(["eventsIn": userEvents])
                                }
                            }
                        }, withCancel: nil)
                    }
                }
            }
            else
            {
                print("no event count")
            }
        }, withCancel: nil)
        returnToPrevious()
    }
    
    @IBAction func cancelAction(_ sender: UIButton)
    {
        returnToPrevious()
    }
    
    func returnToPrevious()
    {
        print("returning")
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
     @IBAction func createEvent(_ sender: UIButton) {
     }
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
