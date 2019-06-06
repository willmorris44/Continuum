//
//  AppDelegate.swift
//  Continuum
//
//  Created by Will morris on 6/4/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        checkAccountStatus { (success) in
            let message = success ? "Successfully retrieved logged in user" : "Failed retrieving user"
            print(message)
        }
        return true
    }
    
    func checkAccountStatus(completion: @escaping (Bool) -> Void) {
        CKContainer.default().accountStatus { (status, error) in
            if let error = error {
                print("Error checking accountStatus \(error) \(error.localizedDescription)")
                completion(false)
                return
            } else {
                DispatchQueue.main.async {
                    let tabBarController = self.window?.rootViewController
                    let errorText = "Sign into iCloud in settings"
                    switch status {
                    case .available:
                        completion(true)
                    case .couldNotDetermine:
                        tabBarController?.presentSimpleAlertWith(title: errorText, message: "Could not determine")
                        completion(false)
                    case .noAccount:
                        tabBarController?.presentSimpleAlertWith(title: errorText, message: "No account")
                        completion(false)
                    case .restricted:
                        tabBarController?.presentSimpleAlertWith(title: errorText, message: "Restricted")
                        completion(false)
                    }
                }
            }
        }
    }
}

extension UIViewController {
    func presentSimpleAlertWith(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
