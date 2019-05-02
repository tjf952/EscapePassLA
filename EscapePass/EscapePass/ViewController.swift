//
//  ViewController.swift
//  EscapePass
//
//  Created by Anup Sankarraman on 1/31/19.
//  Copyright © 2019 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKLoginKit

class ViewController: UIViewController, GIDSignInUIDelegate, FBSDKLoginButtonDelegate {
    
    

    @IBOutlet weak var fbSignInButton: FBSDKLoginButton!
    let userDefault = UserDefaults()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //fbSignInButton.delegate = self
        //fbSignInButton.readPermissions = ["email"] //to read the user email IO
        GIDSignIn.sharedInstance()?.uiDelegate = self
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error == nil
        {
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                print(authResult?.user.email)
                // User is signed in
                // ...
            }

        }
        else
        {
            print(error.localizedDescription)
        }
    }
    
    
    @IBAction func skipSignin(_ sender: UIButton)
    {
        self.userDefault.set("skip", forKey: "newOrOldUser")
        self.userDefault.synchronize()
        print("user skipped signin")
        self.performSegue(withIdentifier: "loggedIn", sender: nil)
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("user logged out")
    }


}

