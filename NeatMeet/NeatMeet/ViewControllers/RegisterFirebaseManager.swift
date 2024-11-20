//
//  RegisterFirebaseManager.swift
//  NeatMeet
//
//  Created by Esha Chiplunkar on 11/19/24.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

extension RegisterViewController {

    func registerNewAccount() {
        Task {
            if let name = registerView.nameText.text,
                let email = registerView.emailText.text,
                let password = registerView.passwordText.text
            {
                do {
                    let exists = try await checkIfEmailExistsInFirestore(
                        email: email)
                    if exists {
                        self.showAlert("This email is already registered.")
                    } else {
                        do {
                            try await Auth.auth().createUser(
                                withEmail: email, password: password)
                            async let setName: Void =
                                setNameOfTheUserInFirebaseAuth(name: name)
                            async let storeUserToFireStore: Void =
                                saveUserToFirestore(name: name, email: email)
                            _ = await (
                                setName, storeUserToFireStore
                            )
                            let options = ["Option1", "Option2", "Option3"] // Replace with your actual options
                            let selectedOption = "Option1" // Replace with the appropriate value
                            let notificationName = NSNotification.Name("registered")
                            let landingVC = LandingPagePickerViewController(options: options, selectedOption: selectedOption, notificationName: notificationName)
                            navigationController?.setViewControllers(
                                [landingVC], animated: true)
                            self.setLoading(false)
                            self.notificationCenter.post(
                                name: .registered, object: nil)
                            print("registered successfully")
                        } catch {
                            self.setLoading(false)
                            print("Error creating user: \(error)")
                        }
                    }
                } catch {
                    print("Error checking email existence: \(error)")
                }
            }
        }
    }

    func saveUserToFirestore(name: String, email: String) async {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": name,
            "email": email,
        ]

        do {
            try await db.collection("users").document(email).setData(userData)
            print("User saved successfully to Firestore")
        } catch {
            print("Error saving user to Firestore: \(error)")
        }
    }

    func checkIfEmailExistsInFirestore(email: String) async throws -> Bool {
        let db = Firestore.firestore()
        let document = try await db.collection("users").document(email)
            .getDocument()
        return document.exists
    }

    func setNameOfTheUserInFirebaseAuth(name: String) async {
        if let changeRequest = Auth.auth().currentUser?
            .createProfileChangeRequest()
        {
            changeRequest.displayName = name
            do {
                try await changeRequest.commitChanges()
                print("Profile update successful")
            } catch {
                print("Error occurred: \(error)")
            }
        }
    }

    func showAlert(_ message: String) {
        let alertController = UIAlertController(
            title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
