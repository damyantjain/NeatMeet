//
//  CreatePostViewController.swift
//  NeatMeet
//
//
//  Created by Gautam Raju on 10/28/24.
//

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class CreatePostViewController: UIViewController {

    var createPost = CreatePost()
    var pickedImage:UIImage?
    var currentUser:FirebaseAuth.User?
    let showPost = ShowPostViewController()
    let database = Firestore.firestore()
    
    
    override func loadView() {
        view = createPost
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        hideKeyboardOnTapOutside()
        createPost.buttonTakePhoto.menu = getMenuImagePicker()
        
        addPostButton()

    }
 
    func addPostButton() {
        let profileButton = UIButton(type: .system)
        profileButton.setImage(
            UIImage(systemName: "plus.circle"), for: .normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            customView: profileButton)

        profileButton.addTarget(
            self, action: #selector(onTapPost), for: .touchUpInside)
    }
    
    @objc func onTapPost() {
        // push to next screen.
        // set all the second screen variables
        guard let eName = createPost.eventNameTextField.text, !eName.isEmpty,
              let eLocation = createPost.locationTextField.text, !eLocation.isEmpty,
              let eDetails = createPost.descriptionTextField.text, !eDetails.isEmpty else {
            print("Please fill all required fields.") // show alert later
            return
        }
        let eDateTime = createPost.timePicker.date
        let ePhoto = createPost.buttonTakePhoto.imageView?.image
        
        // Need to upload the image to Firebase Storage and retrieve the URL for it to populate in the db
        var imageUrl: String? = nil
        if let image = ePhoto, let imageData = image.jpegData(compressionQuality: 0.8) {
            // Upload image to Firebase Storage
            let imageRef = Storage.storage().reference().child("eventImages/\(UUID().uuidString).jpg")
            
            let uploadTask = imageRef.putData(imageData, completion: {(url, error) in
                if error == nil {
                    imageRef.downloadURL(completion: {(url, error) in
                        if error == nil {
                            imageUrl = url?.absoluteString
                            self.postEventToFirestore(eventName: eName, location: eLocation, description: eDetails, eventDate: eDateTime, imageUrl: imageUrl)
                        }
                    })
                }
            })
        }

    }
    
    
    func postEventToFirestore(eventName: String, location: String, description: String, eventDate: Date, imageUrl: String?) {
        let db = Firestore.firestore()
    
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }
        
        // Create the event data
        let event = Event(name: eventName,
                          likesCount: 0,
                          datePublished: Date(),
                          publishedBy: userId,
                          address: location,
                          city: "Boston",
                          state: "Massachusetts",
                          imageUrl: imageUrl ?? "",
                          eventDate: eventDate)
        
        
        // Add the event to Firestore under the "events" collection
        do {
            try db.collection("events").addDocument(from: event) { error in
                 if let error = error {
                     print("Error adding event to Firestore")
                 } else {
                     print("Event successfully added to Firestore!")
                     // Navigate to the Show Post Page
                     self.navigationController?.pushViewController(self.showPost, animated: true)
                 }
             }
        } catch {
            print("Error adding document!")
        }
    }
    
    
    
     func getMenuImagePicker() -> UIMenu{
         let menuItems = [
             UIAction(title: "Camera",handler: {(_) in
                 self.pickUsingCamera()
             }),
             UIAction(title: "Gallery",handler: {(_) in
                 self.pickPhotoFromGallery()
             })
         ]
         
         return UIMenu(title: "Select source", children: menuItems)
     }
    
    func pickUsingCamera(){
        let cameraController = UIImagePickerController()
        cameraController.sourceType = .camera
        cameraController.allowsEditing = true
        cameraController.delegate = self
        present(cameraController, animated: true)
     }

     func pickPhotoFromGallery(){
         var configuration = PHPickerConfiguration()
            configuration.filter = PHPickerFilter.any(of: [.images])
            configuration.selectionLimit = 1
            
            let photoPicker = PHPickerViewController(configuration: configuration)
            
            photoPicker.delegate = self
            present(photoPicker, animated: true, completion: nil)
     }
    
    func hideKeyboardOnTapOutside(){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardOnTap))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func hideKeyboardOnTap(){
        view.endEditing(true)
    }


}


extension CreatePostViewController: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        print(results)
        
        let itemprovider = results.map(\.itemProvider)
        
        for item in itemprovider{
            if item.canLoadObject(ofClass: UIImage.self){
                item.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
                    DispatchQueue.main.async{
                        if let uwImage = image as? UIImage{
                            self.createPost.buttonTakePhoto.setImage(
                                uwImage.withRenderingMode(.alwaysOriginal),
                                for: .normal
                            )
                            self.pickedImage = uwImage
                        }
                    }
                })
            }
        }
    }
}

extension CreatePostViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage{
            self.createPost.buttonTakePhoto.setImage(
                image.withRenderingMode(.alwaysOriginal),
                for: .normal
            )
            self.pickedImage = image
        }else{
            // Do your thing for No image loaded...
        }
    }
}

