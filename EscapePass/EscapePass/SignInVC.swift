//
//  SignInVC.swift
//  EscapePass
//
//  Created by Anup Sankarraman on 2/4/19.
//  Copyright © 2019 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import CoreLocation
import FirebaseDatabase


class SignInVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    
    @IBOutlet weak var userProfileButton: UIButton!
    @IBOutlet weak var numberPlayerInput: UITextField!
    @IBOutlet weak var changeMilesTab: UISegmentedControl!
    @IBOutlet weak var searchKeyInput: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userLocationLabel: UILabel!
    @IBOutlet weak var DisplayTitle: UILabel!
    let userDefault = UserDefaults.standard
    var currentLocation: String = "unset"
    var currentLong: String = "unset"
    var currentLat: String = "unset"
    //connect to firebase realtime database
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    var searchList: Array<String> = Array()
    var userSearchKey: String = ""
    var newOrOld: String?
    var defaultDay: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        newOrOld = (userDefault.object(forKey: "newOrOldUser")) as? String
        numberPlayerInput.text = ""
        //add data to database
        /*
        let roomReference = ref.child("rooms").child("test1")
        let dummy = ["bookingURL": "https://www.usc.edu/", "company": "USC", "difficulty": "4.0", "location": "900 W 34th St, Los Angeles, CA 90007", "maxPlayer": "6", "minPlayer": "4", "newOrOld": "new", "passRate": "60", "phoneNumber": "2137402311", "pricePerPerson": "60", "rating": "4.2", "schedule": "https://www.usc.edu/", "latitude": "34.023499", "longitude": "-118.285988", "dateAdded": "2019-03-20", "roomID": "1", "description": "something", "imageURL": "https://firebasestorage.googleapis.com/v0/b/escapepaa.appspot.com/o/usc_logo.jpg?alt=media&token=e9fb5e32-d60d-4a89-912c-01c687fa4bae"]
        roomReference.updateChildValues(dummy)
        let leaderboard = ["a", "b", "c", "d"]
        let reviews = ["d", "c", "b", "a"]
        roomReference.updateChildValues(["leaderboard": leaderboard])
        roomReference.updateChildValues(["reviews": reviews])
        */
        if newOrOld == "new"
        {
            addNewUserInfo()
        }
        else if newOrOld == "old"
        {
            //if old, check whether location is available
            print("existing, check user location")
            checkUserLocation()
        }
        else if newOrOld == "skip"
        {
            userProfileButton.isHidden = true
            userProfileButton.isEnabled = false
            displayName(name: "New User")
            getLocationFromUser()
        }
    }
    
    func displayName(name: String)
    {
        DisplayTitle.text = "Hi, " + name
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if searchList.count == 0
        {
            return 1
        }
        else
        {
            return searchList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
        if searchList.count == 0
        {
            cell.textLabel?.text = "No Result Found"
        }
        else
        {
            cell.textLabel?.text = searchList[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if searchList.count != 0
        {
            print("selected: " + searchList[indexPath.row])
            self.userDefault.set(searchList[indexPath.row], forKey: "detailRoomName")
            self.userDefault.synchronize()
            self.performSegue(withIdentifier: "toDetailedPage", sender: nil)
        }
    }
    
    @IBAction func showProfilePage(_ sender: UIButton)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNameChanged), name: NSNotification.Name(rawValue: "userNameChanged"), object: nil)
        self.performSegue(withIdentifier: "toUserProfile", sender: nil)
    }
    
    @objc func handleNameChanged(notification: Notification)
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "userNameChanged"), object: nil)
        let name = (userDefault.object(forKey: "changedName")) as? String
        displayName(name: name!)
    }
    
    @IBAction func updateNumPlayerFilter(_ sender: UIButton)
    {
        displayEscapeRooms(searchKey: userSearchKey)
    }
    
    @IBAction func updateMilesFilter(_ sender: UISegmentedControl)
    {
        displayEscapeRooms(searchKey: userSearchKey)
    }
    
    @IBAction func changeLocation(_ sender: UIButton)
    {
        //add observer to listen to location popup result
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeLocationPopUpClosing), name: NSNotification.Name(rawValue: "changeLocationPopUpReturn"), object: nil)
        print("observer setup")
        //show popup view for user to enter there zip code
        let changeLocationPopVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "changeLocationPopUp") as! ChangeLocationPopUpViewController
        self.addChild(changeLocationPopVC)
        changeLocationPopVC.view.frame = self.view.frame
        self.view.addSubview(changeLocationPopVC.view)
        changeLocationPopVC.didMove(toParent: self)
    }
    
    @objc func handleChangeLocationPopUpClosing(notification: Notification)
    {
        print("receive change location popup result")
        let changeLocationPopVC = notification.object as! ChangeLocationPopUpViewController
        let changeLocationPopResult = changeLocationPopVC.zipcode
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "changeLocationPopUpReturn"), object: nil)
        if(changeLocationPopResult != -1)
        {
            if newOrOld != "skip"
            {
                let usersReference = ref.child("users").child((Auth.auth().currentUser?.uid)!)
                usersReference.updateChildValues(["location": "\(changeLocationPopResult!)"])
                print("update location on database")
            }
            currentLocation = "\(changeLocationPopResult!)"
            //update longitude and latitude
            updateLongAndLat(updateAddress: "\(changeLocationPopResult!)")
            print("finish update long and lat")
            userLocationLabel.text = "Current Location: \(changeLocationPopResult!)"
        }
    }
    
    @IBAction func searchOnInput(_ sender: UIButton)
    {
        userSearchKey = searchKeyInput.text!
        if((userSearchKey.isEmpty))
        {
            searchKeyInput.text = ""
            searchKeyInput.text = "Please Enter a Value"
            userSearchKey = ""
        }
        else
        {
            userSearchKey = userSearchKey.lowercased()
            defaultDay = false
            self.displayEscapeRooms(searchKey: userSearchKey)
        }
    }
    
    @IBAction func signOutPressed(_ sender: Any)
    {
        do
        {
            try Auth.auth().signOut()
            try GIDSignIn.sharedInstance()?.signOut()
            userDefault.removeObject(forKey: "usersignedin")
            userDefault.synchronize()
            self.dismiss(animated: true, completion: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func addNewUserInfo()
    {
        //if new, add initial info to database
        print("adding data to database")
        let uid: String = (Auth.auth().currentUser?.uid)!
        let name: String = (Auth.auth().currentUser?.displayName)!
        let email: String = (Auth.auth().currentUser?.email)!
        var providerID: String?
        if let providerData = Auth.auth().currentUser?.providerData
        {
            for userInfo in providerData
            {
                switch userInfo.providerID
                {
                case "facebook.com":
                    providerID = "Facebook"
                case "google.com":
                    providerID = "Google"
                default:
                    providerID = "unavailable"
                }
            }
        }
        let location: String = "-1"
        let escapeRoomCount: String = "0"
        let locationSetting: String = "false"
        let profilePNG: String = ""
        let values = ["uid": uid, "email": email, "name": name, "providerID": providerID, "location": location, "locationSetting": locationSetting, "escapeRoomCount": escapeRoomCount, "osType": "iOS", "userType": "user"]
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: {
            (err, ref) in
            if err != nil
            {
                print(err)
                return
            }
            print("successfully added initial info")
            self.displayName(name: name)
        })
        print("ask for location")
        getLocationFromUser()
    }
    
    //check whether user has location on record
    func checkUserLocation()
    {
        ref.child("users").child((Auth.auth().currentUser?.uid)!).observeSingleEvent(of: .value, with: { (DataSnapshot) in
            if let userInfo = DataSnapshot.value as? [String: AnyObject]
            {
                if userInfo["name"] != nil
                {
                    let name = (userInfo["name"] as? String)!
                    self.displayName(name: name)
                }
                else
                {
                    print("no name found")
                    self.displayName(name: "User")
                }
                if userInfo["location"] != nil
                {
                    if userInfo["location"] != nil
                    {
                        let location = Int((userInfo["location"] as? String)!)!
                        print(location)
                        if location == -1
                        {
                            //if no valid zip code existed
                            self.userDefault.set("no", forKey: "locationAvailable")
                            print("no valid location")
                            print("ask for location")
                            self.getLocationFromUser()
                        }
                        else
                        {
                            if userInfo["latitude"] != nil && userInfo["longitude"] != nil
                            {
                                self.currentLat = (userInfo["latitude"] as? String)!
                                self.currentLong = (userInfo["longitude"] as? String)!
                                self.userDefault.set("yes", forKey: "locationAvailable")
                                print("valid location")
                            }
                            else
                            {
                                print("can't fetch longitude or latitude")
                                self.updateLongAndLat(updateAddress: "\(location)")
                            }
                            self.userLocationLabel.text = "Current Location: \(location)"
                            self.displayEscapeRooms(searchKey: self.userSearchKey)
                        }
                    }
                }
                else
                {
                    self.userLocationLabel.text = "Current Location: N/A"
                    print("could not fetch location")
                }
            }
            else
            {
                print("can't fetch user info")
            }
        }, withCancel: nil)
    }
    
    func getLocationFromUser()
    {
        //add observer to listen to location popup result
        NotificationCenter.default.addObserver(self, selector: #selector(handleLocationPopUpClosing), name: NSNotification.Name(rawValue: "locationPopUpReturn"), object: nil)
        print("observer setup")
        //show popup view for user to enter there zip code
        let locationPopVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "getLocationPopUp") as! LocationPopUpViewController
        self.addChild(locationPopVC)
        locationPopVC.view.frame = self.view.frame
        self.view.addSubview(locationPopVC.view)
        locationPopVC.didMove(toParent: self)
    }
    
    //handle location popup result
    @objc func handleLocationPopUpClosing(notification: Notification)
    {
        print("receive location popup result")
        let locationPopVC = notification.object as! LocationPopUpViewController
        let locationPopResult = locationPopVC.zipCode
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "locationPopUpReturn"), object: nil)
        if newOrOld != "skip"
        {
            let usersReference = ref.child("users").child((Auth.auth().currentUser?.uid)!)
            usersReference.updateChildValues(["location": "\(locationPopResult!)"])
            print("update location on database")
        }
        currentLocation = "\(locationPopResult)"
        //update longitude and latitude
        updateLongAndLat(updateAddress: "\(currentLocation)")
        print("finish update long and lat")
        userLocationLabel.text = "Current Location: \(locationPopResult!)"
    }
    
    //display escape rooms within certain range from user and search keyword
    //defaultDate == true means only find result within 7 days
    func displayEscapeRooms(searchKey: String)
    {
        searchList.removeAll()
        let mileFilterIndex = getSelectedMiles()
        let numPlayers = getNumberPlayers()
        let roomReference = self.ref.child("rooms")
        roomReference.observeSingleEvent(of: .value, with: { (roomSnapshot) in
            if let allRooms = roomSnapshot.value as? [String: AnyObject]
            {
                for room in allRooms
                {
                    if searchKey == "" || (room.key as? String)!.lowercased().contains(searchKey)
                    {
                        let roomDetail = room.value as! [String: AnyObject]
                        if roomDetail["latitude"] != nil && roomDetail["longitude"] != nil && roomDetail["minPlayer"] != nil && roomDetail["dateAdded"] != nil && self.currentLong != "unset" && self.currentLong != "unset"
                        {
                            let roomLat = (roomDetail["latitude"] as? String)!
                            let roomLong = (roomDetail["longitude"] as? String)!
                            let minNumPlayer = Int((roomDetail["minPlayer"] as? String)!)!
                            let maxNumPlayer = Int((roomDetail["maxPlayer"] as? String)!)!
                            let dateAdded = (roomDetail["dateAdded"] as? String)!
                            let distance = self.calculateDistance(userLat: self.currentLat, userLong: self.currentLong, roomLat: roomLat, roomLong: roomLong)
                            if distance <= mileFilterIndex && (numPlayers == 1000 || (minNumPlayer <= numPlayers && maxNumPlayer >= numPlayers))
                            {
                                self.searchList.append((room.key as? String)!)
                                    print("distance with " + (room.key as? String)! + " is \(distance)")
                            }
                        }
                        else
                        {
                            print("can't fetch room location for: " + (room.key as? String)!)
                        }
                    }
                    else
                    {
                        continue
                    }
                }
                DispatchQueue.main.async
                    {
                        self.tableView.reloadData()
                }
            }
            else
            {
                print("can't fetch room info")
            }
        }, withCancel: nil)
        
    }
    
    
    //find longitude and latitude with given address and update onto database
    func updateLongAndLat(updateAddress: String)
    {
        getLatitude(address: updateAddress, completion: { (success) -> Void in
            if Int(success) < 100
            {
                if self.newOrOld != "skip"
                {
                    let usersReference = self.ref.child("users").child((Auth.auth().currentUser?.uid)!)
                    usersReference.updateChildValues(["latitude": String(success)])
                }
                self.currentLat = String(success)
                print("successfully added latitude")
                self.getLongitude(address: updateAddress, completion: { (success) -> Void in
                    if Int(success) < 200
                    {
                        if self.newOrOld != "skip"
                        {
                            let usersReference = self.ref.child("users").child((Auth.auth().currentUser?.uid)!)
                            usersReference.updateChildValues(["longitude": String(success)])
                        }
                        self.currentLong = String(success)
                        print("successfully added longitude")
                        print("calling update")
                        self.displayEscapeRooms(searchKey: self.userSearchKey)
                    }
                    else
                    {
                        print("long fail")
                    }
                })
            }
            else
            {
                print("lat fail")
            }
        })
    }
    
    //find longitude with given address
    func getLongitude(address: String, completion: @escaping (Double) -> Void)
    {
        print("longitude" + address)
        var longitude: Double?
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) in
            if((error) != nil)
            {
                print(error!)
                longitude = 3131
                completion(longitude!)
            }
            if let placemark = placemarks?.first
            {
                longitude = placemark.location?.coordinate.longitude
                completion(longitude!)
            }
            else{
                completion(longitude!)
            }
        })
    }
    //find latitude with given address
    func getLatitude(address: String, completion: @escaping (Double) -> Void)
    {
        print("latitude" + address)
        var latitude: Double?
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) in
            if((error) != nil)
            {
                print(error!)
                latitude = 3131
                completion(latitude!)
            }
            if let placemark = placemarks?.first
            {
                latitude = placemark.location?.coordinate.latitude
                completion(latitude!)
            } else {
                completion(latitude!)
            }
        })
    }
    
    //find distance between two addresses
    func calculateDistance(userLat: String, userLong: String, roomLat: String, roomLong: String) -> Double
    {
        let userCoordinate = CLLocation(latitude: Double(userLat)!, longitude: Double(userLong)!)
        let roomCoordinate = CLLocation(latitude: Double(roomLat)!, longitude: Double(roomLong)!)
        let distanceInMile = userCoordinate.distance(from: roomCoordinate) * 0.000621
        return distanceInMile
    }
    
    func getSelectedMiles() -> Double
    {
        let milesIndex = changeMilesTab.selectedSegmentIndex
        print("selected miles index: \(milesIndex)")
        switch milesIndex
        {
            case 0:
                return 5.0
            case 1:
                return 10.0
            case 2:
                return 25.0
            case 3:
                return 100.0
            default:
                return 25.0
            
        }
    }
    
    func getNumberPlayers() -> Int
    {
        let userInput = numberPlayerInput.text
        var numPlayers: Int?
        if((userInput?.isEmpty)!)
        {
            //The default should be that there is no filter on number of players until the user specifies one
            numberPlayerInput.text = ""
            numPlayers = 1000
        }
    
        else
        {
            numPlayers = Int(userInput!)
            if numPlayers == nil
            {
                numberPlayerInput.text = ""
                numPlayers = 1000
            }
        }
        return numPlayers!
    }
    
    func getDateDifferenceFromNow(dateToCompare: String) -> Int
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateObj = formatter.date(from: dateToCompare)
        let secondsBetween = NSDate().timeIntervalSince(dateObj!)
        let numberDays = Int(secondsBetween / 86400)
        return numberDays
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
