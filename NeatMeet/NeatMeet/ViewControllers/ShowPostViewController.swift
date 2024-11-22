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
    
    override func loadView() {
        view = showPost
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assuming you have the event ID (for example, passed from the previous view)
        let eventId = "eventDocumentId" // Replace with the actual event document ID
        fetchEventAndDisplay(eventId: eventId)
    }

    // Function to fetch the event from Firestore
    func fetchEventAndDisplay(eventId: String) {
        let db = Firestore.firestore()
        
        // Fetch the event document by ID
        db.collection("events").document(eventId).getDocument { (document, error) in
            if let error = error {
                print("Error fetching event: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Event document does not exist")
                return
            }
            
            // Decode the document data into an Event object
            do {
                let event = try document.data(as: Event.self)
                if let event = event {
                    // Configure ShowPostView with event data
                    self.showPost.configureWithEvent(event: event)
                }
            } catch {
                print("Error decoding event data: \(error.localizedDescription)")
            }
        }
    }
}
