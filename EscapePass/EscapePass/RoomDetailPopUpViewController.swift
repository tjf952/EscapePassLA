//
//  RoomDetailPopUpViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/2/11.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class RoomDetailPopUpViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var detailDisplayTable: UITableView!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var detailLabel: UILabel!
    let infoKeys = ["leaderboard", "reviews"]
    let displayKeys = ["Leaderboard Info", "Reviews"]
    var detailArray: Array<String> = Array()
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    let userDefault = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        print("change location popup view setup")
        let infoKey = (userDefault.object(forKey: "roomDetailPopUp")) as? String
        for each in infoKeys
        {
            if infoKey == each
            {
                detailLabel.text = displayKeys[infoKeys.firstIndex(of: infoKey!)!]
            }
        }
        let roomName = (userDefault.object(forKey: "detailRoomName")) as? String
        let roomReference = ref.child("rooms").child(roomName!).child(infoKey!)
        roomReference.observeSingleEvent(of: .value, with: { (detailSnapshot) in
            if let detailInfo = detailSnapshot.value as? Array<String>
            {
                self.detailArray = detailInfo
                DispatchQueue.main.async
                {
                    self.detailDisplayTable.reloadData()
                }
            }
            else
            {
                print("can't get " + infoKey! + "'s detail")
            }
        }, withCancel: nil)
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func returnPressed(_ sender: UIButton)
    {
        detailLabel.text = "Info"
        detailArray.removeAll()
        DispatchQueue.main.async
        {
                self.detailDisplayTable.reloadData()
        }
        print("exit change room detail pop up")
        self.view.removeFromSuperview()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if detailArray.count == 0
        {
            return 1
        }
        else
        {
            return detailArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "displayDetailCell")
        if detailArray.count == 0
        {
            cell.textLabel?.text = "No Result Found"
        }
        else
        {
            cell.textLabel?.text = detailArray[indexPath.row]
        }
        return cell
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
