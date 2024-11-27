//
//  ProfileViewController.swift
//  NeatMeet
//
//  Created by Saniya Anklesaria on 10/22/24.
//
import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
   
    let profileScreen = ProfileView()
    var delegate:LandingViewController!
    var pickedImage:UIImage?
    var events: [Event] = []
    let db = Firestore.firestore()
    let storage = Storage.storage()
    var refreshTimer: Timer?
    
    override func loadView() {
        view=profileScreen
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addEditNotiifcationObservor()
        profileScreen.editButton.menu = getMenuImagePicker()
        displayAllEvents()
        displayUserDetails()
        profileScreen.buttonSave.addTarget(self, action: #selector(onSaveButtonTapped), for: .touchUpInside)
        profileScreen.eventTableView.delegate = self
        profileScreen.eventTableView.dataSource = self
        profileScreen.eventTableView.separatorStyle = .none
        
    }
    
    
    
    @objc func onSaveButtonTapped() {
        guard let textFieldName = profileScreen.textFieldName.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            showAlert(title: "Error", message: "Please fill out all fields.")
            return
        }
        
        if textFieldName.isEmpty {
            showAlert(title: "Error", message: "Name cannot be empty!")
            return
        }
        
        
        Task {
            do {
                let ePhoto = pickedImage
                var imageUrl: String? = nil
                
                if let image = ePhoto,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    let imageRef = storage.reference().child("userImages/\(UUID().uuidString).jpg")
                
                    _ = try await imageRef.putDataAsync(imageData)
                    imageUrl = try await imageRef.downloadURL().absoluteString
                    
                    if let updatedImageUrl = imageUrl,
                       let userIdString = UserManager.shared.loggedInUser?.id {
                        try await db.collection("users").document(userIdString).updateData([
                            "imageUrl": updatedImageUrl
                        ])
                        UserManager.shared.loggedInUser?.imageUrl = updatedImageUrl
                    }
                }
                
                if let userIdString = UserManager.shared.loggedInUser?.id {
                    try await db.collection("users").document(userIdString).updateData([
                        "name": textFieldName,
                    ])
                    
                    UserManager.shared.loggedInUser?.name = textFieldName
                    
                    showAlert(title: "Success", message: "Profile updated successfully.")
                } else {
                    showAlert(title: "Error", message: "No logged-in user ID found.")
                }
            } catch {
                showAlert(title: "Error", message: "Failed to update profile in Firestore: \(error.localizedDescription)")
            }
        }
    }

    
    @objc func displayAllEvents() {
           Task {
               await getAllEvents()
           }
       }
    
    @objc func displayUserDetails() {
           Task {
               await setUpProfileData()
           }
       }
    
    func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
    func getAllEvents() async {
            do {
                
                events.removeAll()
                let calendar = Calendar.current
                let currentDate = calendar.startOfDay(for: Date())
                if let userIdString = UserManager.shared.loggedInUser?.id{
                    let snapshot = try await db.collection("events")
                        .whereField("publishedBy", isEqualTo: userIdString)
                        .getDocuments()
                    for document in snapshot.documents {
                        let data = document.data()
                        if let name = data["name"] as? String,
                            let likesCount = data["likesCount"] as? Int,
                            let datePublished = data["datePublished"] as? Timestamp,
                            let address = data["address"] as? String,
                            let city = data["city"] as? String,
                            let state = data["state"] as? String,
                            let imageUrl = data["imageUrl"] as? String,
                            let publishedBy = data["publishedBy"] as? String,
                            let eventDate = data["eventDate"] as? Timestamp,
                            let eDetails = data["eventDescription"] as? String
                        {
                            events.append(
                                Event(
                                    id: document.documentID,
                                    name: name,
                                    likesCount: likesCount,
                                    datePublished: datePublished.dateValue(),
                                    publishedBy: publishedBy,
                                    address: address,
                                    city: city,
                                    state: state,
                                    imageUrl: imageUrl,
                                    eventDate: eventDate.dateValue(),
                                    eventDescription: eDetails
                                )
                            )
                            events.sort { $0.datePublished > $1.datePublished }
                            self.profileScreen.eventTableView.reloadData()
                        }
                           
                        
                    }
                }

            } catch {
                print("Error getting documents: \(error)")
            }
        }
    
    

    
    func setUpProfileData() async {	
        do {
            guard let userIdString = UserManager.shared.loggedInUser?.id else {
                print("No logged-in user ID found.")
                return
            }
            let snapshot = try await db.collection("users").document(userIdString).getDocument()
            
            guard let data = snapshot.data() else {
                print("No user found with the given ID.")
                return
            }
            
            if let name = data["name"] as? String,
               let email = data["email"] as? String,
               let imageUrl = data["imageUrl"] as? String {
                
                profileScreen.textFieldName.text = name
                profileScreen.textFieldEmail.text = email
                
                if let imageUrlURL = URL(string: imageUrl) {
                    profileScreen.imageContacts.sd_setImage(
                        with: imageUrlURL,
                        placeholderImage: UIImage(systemName: "person.fill")
                    )
                }
                
                UserManager.shared.loggedInUser?.name = name
                UserManager.shared.loggedInUser?.email = email
                UserManager.shared.loggedInUser?.imageUrl = imageUrl
                
            } else {
                print("Invalid user data format.")
            }
        } catch {
            print("Error fetching user data from Firestore: \(error.localizedDescription)")
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
    
    
       
    
    
       
       //MARK: pick Photo using Gallery...
       func pickPhotoFromGallery(){
           var configuration = PHPickerConfiguration()
           configuration.filter = PHPickerFilter.any(of: [.images])
           configuration.selectionLimit = 1
           
           let photoPicker = PHPickerViewController(configuration: configuration)
           
           photoPicker.delegate = self
           present(photoPicker, animated: true, completion: nil)
           
       }
    
        func pickUsingCamera(){
                let cameraController = UIImagePickerController()
                cameraController.sourceType = .camera
                cameraController.allowsEditing = true
                cameraController.delegate = self
                present(cameraController, animated: true)
            }


}
extension ProfileViewController:PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        print(results)
        
        let itemprovider = results.map(\.itemProvider)
        
        for item in itemprovider{
            if item.canLoadObject(ofClass: UIImage.self){
                item.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
                    DispatchQueue.main.async{
                        if let uwImage = image as? UIImage {
                                                   self.profileScreen.imageContacts.image = uwImage
                                                   self.pickedImage = uwImage
                                               }
                    }
                })
            }
        }
    }
    
}


extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "events", for: indexPath)
            as! EventTableViewCell
        let event = events[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, HH:mm"
        cell.selectionStyle = .none
        cell.eventNameLabel?.text = event.name
        cell.eventLocationLabel?.text = event.address
        cell.eventDateTimeLabel?.text = dateFormatter.string(
            from: event.eventDate)
        cell.eventLikeLabel?.text = (String)(event.likesCount)
        if let imageUrl = URL(string: event.imageUrl) {
            cell.eventImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "event_ph_square"))
        } else {
            cell.eventImageView.image = UIImage(named: "event_ph_square")
        }
        return cell
    }
    
    func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        let event = events[indexPath.row]
        let showPostViewController = ShowPostViewController()
        showPostViewController.eventId = event.id!
        navigationController?.pushViewController(
            showPostViewController, animated: true)
    }
    
    func addEditNotiifcationObservor() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(displayAllEvents),
            name: .contentEdited, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(displayAllEvents),
            name: .likeUpdated, object: nil)
    }
    

}
