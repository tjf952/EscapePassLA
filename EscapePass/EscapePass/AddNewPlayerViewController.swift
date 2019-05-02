//
//  AddNewPlayerViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/3/20.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class AddNewPlayerViewController: UIViewController {

    
    @IBOutlet weak var userInput: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    var userEmail: String = "negative"
    var uid: String = "negative"
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        print("add new user popup view setup")
        // Do any additional setup after loading the view.
    }
    

    @IBAction func addUser(_ sender: UIButton)
    {
        let email = self.userInput.text
        var findMatch: Bool = false
        if((email?.isEmpty)!)
        {
            warningLabel.text = "Please Enter a Value"
            userInput.text = ""
        }
        else
        {
            let userReference = ref.child("users")
            userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
                if let allUsers = userSnapshot.value as? [String: AnyObject]
                {
                    for user in allUsers
                    {
                        let userDetail = user.value as! [String: AnyObject]
                        if userDetail["email"] != nil
                        {
                            let temp = (userDetail["email"] as? String)!
                            if temp == email!
                            {
                                if userDetail["uid"] != nil
                                {
                                    self.userEmail = email!
                                    self.uid = (userDetail["uid"] as? String)!
                                    findMatch = true
                                    break
                                }
                                else
                                {
                                    self.warningLabel.text = "Failed to Add User"
                                    self.userInput.text = ""
                                }
                            }
                        }
                        else
                        {
                            self.warningLabel.text = "Failed to Add User"
                            self.userInput.text = ""
                        }
                    }
                    if findMatch
                    {
                        print("matches info in database")
                        self.closeUp()
                    }
                    else
                    {
                        self.warningLabel.text = "User Does Not Exist"
                        self.userInput.text = ""
                    }
                }
                else
                {
                    self.warningLabel.text = "Failed to Add User"
                    self.userInput.text = ""
                }
            }, withCancel: nil)
        }
    }
    
    @IBAction func cancelAction(_ sender: UIButton)
    {
        closeUp()
    }
    
    func closeUp()
    {
        warningLabel.text = ""
        userInput.text = ""
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addPlayerReturn"), object: self)
        print("add player post message")
        print("exit change add player")
        self.view.removeFromSuperview()
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
