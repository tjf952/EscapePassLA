//
//  RoomDetailsViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/2/11.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class RoomDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    
    @IBOutlet weak var addEventButton: UIButton!
    
    @IBOutlet weak var infoTable: UITableView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var imageDisplayView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    let userDefault = UserDefaults.standard
    let infoKeys = ["bookingURL", "company", "difficulty", "location", "maxPlayer", "minPlayer", "newOrOld", "passRate", "phoneNumber", "pricePerPerson", "rating", "leaderboard", "reviews", "schedule"]
    let urlKeys = ["bookingURL", "schedule"]
    let moreDetailKeys = ["leaderboard", "reviews"]
    let displayKeys = ["Booking URL", "Company", "Difficulty", "Location", "Maximum Players", "Minimum Players", "Status", "Pass Rate", "Phone Number", "Price/Person", "Rating", "Leaderboard", "Reviews", "Schedule"]
    var infoValues: Array<String> = Array()
    override func viewDidLoad() {
        super.viewDidLoad()
        let roomName = (userDefault.object(forKey: "detailRoomName")) as? String
        roomNameLabel.text = roomName
        let newOrOld = (userDefault.object(forKey: "newOrOldUser")) as? String
        if newOrOld == "skip"
        {
            addEventButton.isHidden = true
            addEventButton.isEnabled = false
        }
        let roomReference = ref.child("rooms").child(roomName!)
        roomReference.observeSingleEvent(of: .value, with: { (roomSnapshot) in
            if let roomInfo = roomSnapshot.value as? [String: AnyObject]
            {
                if roomInfo["imageURL"] != nil
                {
                    let imageURL = (roomInfo["imageURL"] as? String)!
                    self.displayImage(imageURL: imageURL)
                }
                else
                {
                    print("can't fetch image URL")
                }
                if roomInfo["description"] != nil
                {
                    let description = (roomInfo["description"] as? String)!
                    self.descriptionText.text = description
                }
                else
                {
                    print("can't fetch image URL")
                }
                for each in self.infoKeys
                {
                    var flag: Bool = false
                    for check in self.moreDetailKeys
                    {
                        if each == check
                        {
                            flag = true
                            break
                        }
                    }
                    if flag
                    {
                        self.infoValues.append("toPopUp")
                    }
                    else
                    {
                        if roomInfo[each] != nil
                        {
                            let info = (roomInfo[each] as? String)!
                            self.infoValues.append(info)
                        }
                        else
                        {
                            self.infoValues.append("Unavailable")
                            print("can't find value for " + each)
                        }
                    }
                }
                DispatchQueue.main.async
                {
                    self.infoTable.reloadData()
                }
                
            }
            else
            {
                print("can't fetch room info")
            }
        }, withCancel: nil)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func returnPreviousView(_ sender: UIButton)
    {
        print("here")
        if let nav = self.navigationController
        {
            nav.popViewController(animated: true)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func displayImage(imageURL: String)
    {
        if let url = URL(string: imageURL)
        {
            do
            {
                let data = try Data(contentsOf: url)
                self.imageDisplayView.image = UIImage(data: data)
            }
            catch let err
            {
                print(err.localizedDescription)
            }
        }
        else
        {
            print("problem with image URL")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if infoValues.count == 0
        {
            return 1
        }
        else
        {
           return displayKeys.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "infoCell")
        if infoValues.count == 0
        {
            cell.textLabel?.text = "No Result Found"
        }
        else
        {
            if infoValues[indexPath.row] == "toPopUp"
            {
                cell.textLabel?.text = displayKeys[indexPath.row]
            }
            else
            {
                cell.textLabel?.text = displayKeys[indexPath.row] + ": " + infoValues[indexPath.row]
            }
        }
        return cell
    }
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var flag1: Bool = false
        for checkDetail in moreDetailKeys
        {
            if infoKeys[indexPath.row] == checkDetail
            {
                flag1 = true
                break
            }
        }
        if flag1
        {
            print("selected: " + infoKeys[indexPath.row])
            self.userDefault.set(infoKeys[indexPath.row], forKey: "roomDetailPopUp")
            self.userDefault.synchronize()
            //show popup view for user to enter there zip code
            let roomDetailPopVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "roomDetailPopUp") as! RoomDetailPopUpViewController
            self.addChild(roomDetailPopVC)
            roomDetailPopVC.view.frame = self.view.frame
            self.view.addSubview(roomDetailPopVC.view)
            roomDetailPopVC.didMove(toParent: self)
        }
        else
        {
            var flag2: Bool = false
            for checkURL in urlKeys
            {
                if checkURL == infoKeys[indexPath.row]
                {
                    flag2 = true
                    break
                }
            }
            if flag2
            {
                if infoValues[indexPath.row] != "Unavailable"
                {
                    let url = URL(string: infoValues[indexPath.row])!
                    if UIApplication.shared.canOpenURL(url)
                    {
                        //open the url and handle the completion block
                        UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                            print("Open url : \(success)")
                        })
                    }
                }
                else
                {
                    print("url not available")
                }
            }
        }
    }
    
    @IBAction func addEvent(_ sender: UIButton)
    {
        self.performSegue(withIdentifier: "toAddEvent", sender: nil)
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
