//
//  ShowPostViewController.swift
//  NeetMeetPostPage
//
//  Created by Gautam Raju on 11/3/24.
//

import UIKit
import FirebaseFirestore

class ShowPostViewController: UIViewController {

    var showPost = ShowPostView()
    var eventId: String = ""
    override func loadView() {
        view = showPost
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchEventAndDisplay(eventId: eventId)
        showPost.likeButton.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)

   
    }
    
    @objc func didTapLikeButton() {
        incrementLikeCount(eventId: eventId)
      }
    
    
    func incrementLikeCount(eventId: String) {
        let db = Firestore.firestore()
    
        let eventRef = db.collection("events").document(eventId)

        eventRef.updateData([
            "likesCount": FieldValue.increment(Int64(1))
        ]) { error in
            if error != nil {
                print("Like count updated successfully!")
            } else {
                print("Error incrementing like count")
            }
        }
    }

    
    
    // Function to fetch the event from Firestore
    func fetchEventAndDisplay(eventId: String) {
        let db = Firestore.firestore()
        
        db.collection("events").document(eventId).getDocument { (document, error) in
            if error != nil {
                print("Error fetching event")
                return
            }
            
            guard let document = document else {
                print("Event document does not exist")
                return
            }

            do {
                let event = try document.data(as: Event.self)
                // Configure ShowPostView with event data
                self.showPost.configureWithEvent(event: event)
                self.showPost.updateLikeCountLabel(count: event.likesCount)
                
            } catch {
                print("Error decoding event data")
            }
        }
    }
}
