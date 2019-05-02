//
//  ChangeLocationPopUpViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/2/10.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit

class ChangeLocationPopUpViewController: UIViewController {

    @IBOutlet weak var userInputText: UITextField!
    @IBOutlet weak var displayLabel: UILabel!
    var zipcode: Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        print("change location popup view setup")
        // Do any additional setup after loading the view.
    }
    
    @IBAction func cancelResponse(_ sender: UIButton)
    {
        zipcode = -1
        closePopUp()
    }
    
    @IBAction func updateLocation(_ sender: UIButton)
    {
        let userInput = userInputText.text
        if((userInput?.isEmpty)!)
        {
            displayLabel.text = "Please Enter a Value"
            userInputText.text = ""
        }
        else
        {
            zipcode = Int(userInput!)
            if zipcode == nil
            {
                displayLabel.text = "Please Enter Integer"
                userInputText.text = ""
            }
            else
            {
                if zipcode! > 96162 || zipcode! < 90001
                {
                    displayLabel.text = "Out of Support Range"
                    userInputText.text = ""
                }
                else
                {
                    print("receive correct value")
                    closePopUp()
                }
            }
        }
    }
    
    func closePopUp()
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeLocationPopUpReturn"), object: self)
        print("change location pop up post message")
        displayLabel.text = "Please Enter Your Zip Code"
        userInputText.text = ""
        print("exit change location pop up")
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
