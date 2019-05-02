//
//  UserProfileViewController.swift
//  EscapePass
//
//  Created by KaoAlbert on 2019/2/26.
//  Copyright © 2019年 Anup Sankarraman. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class UserProfileViewController: UIViewController , UITableViewDelegate, UITableViewDataSource  {
    
    
    @IBOutlet weak var imageDisplayView: UIImageView!
    @IBOutlet weak var userInfoTable: UITableView!
    
    let userDefault = UserDefaults.standard
    var uid: String?
    let infoKeys = ["name", "email", "escapeRoomCount"]
    let displayKeys = ["Name", "E-mail", "Escape Room Count"]
    let allowChanges = ["name"]
    var changeFlag: Bool = false
    let ref = Database.database().reference(fromURL: "https://escapepaa.firebaseio.com/")
    var infoValues: Array<String> = Array()
    var imagePicker = UIImagePickerController()
    var stor: StorageReference!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        uid = (Auth.auth().currentUser?.uid)!
        stor = Storage.storage().reference()
        updateContent()
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
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "userInfoCell")
        if infoValues.count == 0
        {
            cell.textLabel?.text = "No Result Found"
        }
        else
        {
            cell.textLabel?.text = displayKeys[indexPath.row] + ": " + infoValues[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("selected: " + infoKeys[indexPath.row])
        var flag: Bool = false
        for each in allowChanges
        {
            if infoKeys[indexPath.row] == each
            {
                flag = true
                break
            }
        }
        if flag
        {
            self.userDefault.set(infoKeys[indexPath.row], forKey: "userInfoChange")
            self.userDefault.synchronize()
            NotificationCenter.default.addObserver(self, selector: #selector(handleChangeInfoClosing), name: NSNotification.Name(rawValue: "changeUserInfoReturn"), object: nil)
            //show popup view for user to change info
            let changeUserInfoPop = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "changeUserInfo") as! ChangeUserInfoViewController
            self.addChild(changeUserInfoPop)
            changeUserInfoPop.view.frame = self.view.frame
            self.view.addSubview(changeUserInfoPop.view)
            changeUserInfoPop.didMove(toParent: self)
        }
    }
    
    @objc func handleChangeInfoClosing(notification: Notification)
    {
        print("receive change user info popup result")
        let changeUserInfo = notification.object as! ChangeUserInfoViewController
        let changeUserInfoResult = changeUserInfo.userResponse
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "changeUserInfoReturn"), object: nil)
        if((changeUserInfoResult.isEmpty))
        {
            print("no response")
        }
        else
        {
            let userReference = ref.child("users").child(uid!)
            let chosenKey = (userDefault.object(forKey: "userInfoChange")) as? String
            userReference.updateChildValues([(chosenKey)!: changeUserInfoResult])
            if chosenKey == "name"
            {
                changeFlag = true
                self.userDefault.set(changeUserInfoResult, forKey: "changedName")
                self.userDefault.synchronize()
            }
            updateContent()
        }
    }
    
    func updateContent()
    {
        if infoValues.count != 0
        {
            infoValues.removeAll()
        }
        let userReference = ref.child("users").child(uid!)
        userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
            if let userInfo = userSnapshot.value as? [String: AnyObject]
            {
                if userInfo["pngData"] != nil
                {
                    let imagePNGString = (userInfo["pngData"] as? String)!
                    self.displayImage(imagePNGString: imagePNGString)
                }
                else
                {
                    print("can't fetch image URL")
                }
                for each in self.infoKeys
                {
                    if userInfo[each] != nil
                    {
                        let info = (userInfo[each] as? String)!
                        self.infoValues.append(info)
                    }
                    else
                    {
                        self.infoValues.append("Unavailable")
                        print("can't find value for " + each)
                    }
                }
                DispatchQueue.main.async
                    {
                        self.userInfoTable.reloadData()
                }
                
            }
            else
            {
                print("can't fetch user info")
            }
        }, withCancel: nil)
    }
    
    func displayImage(imagePNGString: String)
    {
        let picRef = stor.child("images/Optional(\"\(imagePNGString)\")").getData(maxSize: 29*1024*1024) { data, error in
            if let error = error {
                print("This is the error: ", error)
            }
            else
            {
                print("Picture about to be loaded")
                
                if let img = UIImage(data: data!) {
                    self.imageDisplayView.image = self.resizeImage( image: img, targetSize: CGSize(width: 100, height: 100) )
                    print("Image set.")
                }
                
            }
        }
    }
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
            
        let widthRatio  = targetSize.width  / size.width
            let heightRatio = targetSize.height / size.height
            
            // Figure out what our orientation is, and use that to form the rectangle
            var newSize: CGSize
            if(widthRatio > heightRatio) {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            } else {
                newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
            }
            
            // This is the rect that we've calculated out and this is what is actually used below
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            
            // Actually do the resizing to the rect using the ImageContext stuff
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage!
        }
    
    //When user clicks upload photo
    @IBAction func onClickUploadPhoto(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
        
        
        
    }
    
    @IBAction func toEventPage(_ sender: UIButton)
    {
        self.performSegue(withIdentifier: "toUserEvent", sender: nil)
    }
    
    
    @IBAction func returnSearchPage(_ sender: UIButton)
    {
        if changeFlag
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userNameChanged"), object: self)
        }
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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension UserProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let uid: String = (Auth.auth().currentUser?.uid)!
        if let image = info[.editedImage] as? UIImage
        {
            imageDisplayView.image = image
            stor.child("images/\(String(describing: image.pngData()?.description))").putData((image.pngData()!), metadata: nil)
            print("PNG Data: ", image.pngData()?.description as Any)
            
            let value = ["pngData": image.pngData()?.description]
            let usersReference = ref.child("users").child(uid)
            usersReference.updateChildValues(value, withCompletionBlock: {
                (err, ref) in
                if err != nil
                {
                    print(err)
                    return
                }
                print("successfully added initial info")
                //self.displayName(name: name)
            })
                
//                \(image.pngData()?.description)"] as [String: Any])
//            userReference.observeSingleEvent(of: .value, with: { (userSnapshot) in
//                if let userInfo = userSnapshot.value as? [String: AnyObject]
//                {
//                    if userInfo["imageURL"] != nil
//                    {
//                        let imageURL = (userInfo["imageURL"] as? String)!
//                        self.displayImage(imageURL: imageURL)
//                    }
//                    else
//                    {
//                        print("can't fetch image URL")
//                    }
//                    for each in self.infoKeys
//                    {
//                        if userInfo[each] != nil
//                        {
//                            let info = (userInfo[each] as? String)!
//                            self.infoValues.append(info)
//                        }
//                        else
//                        {
//                            self.infoValues.append("Unavailable")
//                            print("can't find value for " + each)
//                        }
//                    }
//                    DispatchQueue.main.async
//                        {
//                            self.userInfoTable.reloadData()
//                    }
//
//                }
//                else
//                {
//                    print("can't fetch user info")
//                }
//            }, withCancel: nil)
        }
        
        
        
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
