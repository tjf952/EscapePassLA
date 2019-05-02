//
//  LocationPopUpViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/2/9.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit

class LocationPopUpViewController: UIViewController {

    
    @IBOutlet weak var popUpTitle: UILabel!
    @IBOutlet weak var zipCodeInput: UITextField!
    var zipCode: Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        print("location popup view setup")
        // Do any additional setup after loading the view.
    }
    

    @IBAction func addLocation(_ sender: UIButton)
    {
        let userLocationInput = zipCodeInput.text
        if (userLocationInput?.isEmpty)!
        {
            popUpTitle.text = "Please Enter a Value"
            zipCodeInput.text = ""
        }
        else
        {
            zipCode = Int(userLocationInput!)
            if zipCode == nil
            {
                popUpTitle.text = "Please Enter Integer"
                zipCodeInput.text = ""
            }
            else
            {
                if zipCode! > 96162 || zipCode! < 90001
                {
                    popUpTitle.text = "Out of Support Range"
                    zipCodeInput.text = ""
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
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationPopUpReturn"), object: self)
        print("location pop up post message")
        popUpTitle.text = "Please Enter Your Zip Code"
        zipCodeInput.text = ""
        print("exit location pop up")
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
