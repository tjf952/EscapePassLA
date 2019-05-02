//
//  ChangeUserInfoViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/2/27.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit

class ChangeUserInfoViewController: UIViewController {

    
    
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var userInput: UITextField!
    var userResponse: String = ""
    let infoKeys = ["name", "email"]
    let displayKeys = ["Name", "E-mail"]
     let userDefault = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        print("change location popup view setup")
        let infoKey = (userDefault.object(forKey: "userInfoChange")) as? String
        for each in infoKeys
        {
            if infoKey == each
            {
                labelText.text = displayKeys[infoKeys.firstIndex(of: infoKey!)!]
            }
        }
        
        // Do any additional setup after loading the view.
    }
    

    @IBAction func updateUserInfo(_ sender: UIButton)
    {
        userResponse = userInput.text!
        closePopUp()
    }
    
    @IBAction func cancelResponse(_ sender: UIButton)
    {
        userResponse = ""
        closePopUp()
    }
    
    func closePopUp()
    {
        print("change user info post message " + userResponse)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeUserInfoReturn"), object: self)
        labelText.text = ""
        userInput.text = ""
        print("exit change change user info")
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
