//
//  AppDelegate.swift
//  EscapePass
//
//  Created by Anup Sankarraman on 1/31/19.
//  Copyright © 2019 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKLoginKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
//    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
//        if error == nil
//        {
//            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
//
//            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
//                if let error = error {
//                    print(error.localizedDescription)
//                    return
//                }
//                print(authResult?.user.email)
//                // User is signed in
//                // ...
//            }
//
//        }
//        else
//        {
//            print(error.localizedDescription)
//        }
//    }
//
//    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
//        print("user logged out")
//    }
    
    
    

    var window: UIWindow?
    let userDefault = UserDefaults()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
    
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        } else {
            print("Im inside")
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
                if error == nil
                {
                    //check whether the signin user is new or not
                    if (result?.additionalUserInfo?.isNewUser)!
                    {
                        print("new user")
                        self.userDefault.set("new", forKey: "newOrOldUser")
                    }
                    else{
                        print("existing user")
                        self.userDefault.set("old", forKey: "newOrOldUser")
                    }
                    self.userDefault.set(true, forKey: "usersignedin")
                    self.userDefault.synchronize()
                    print("no errors logging in")
                    
                    
                self.window?.rootViewController?.performSegue(withIdentifier: "loggedIn", sender: nil)
                    //self.window?.rootViewController?.performSegue(withIdentifier: "SignInVC", sender: nil)
                }
                else
                {
                   
                    print(error?.localizedDescription)
                }
            }
        }
    }
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

