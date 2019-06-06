//
//  PostController.swift
//  Continuum
//
//  Created by Will morris on 6/4/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class PostController {
    
    static let shared = PostController()
    
    var posts: [Post] = []
    
    let publicDB = CKContainer.default().publicCloudDatabase
    
    private init() {
        subscribeToNewPosts(completion: nil)
    }
    
    func addComment(text: String, post: Post, completion: @escaping (Comment?) -> Void) {
        let comment = Comment(text: text, post: post)
        post.comments.append(comment)
        let record = CKRecord(comment: comment)
        publicDB.save(record) { (record , error) in
            if let error = error {
                print("There was an error saving the record to DB : \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let record = record else { completion(nil); return }
            let comment = Comment(ckRecord: record, post: post)
            self.incrementCommentCount(for: post, completion: nil)
            completion(comment)
        }
    }
    
    func createPostWith(image: UIImage, caption: String, completion: @escaping (Post?) -> Void) {
        let post = Post(caption: caption, photo: image)
        posts.append(post)
        let record = CKRecord(post: post)
        publicDB.save(record) { (record, error) in
            if let error = error {
                print("There was an error saving the record to DB : \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let record = record else { completion(nil); return }
            let post = Post(ckRecord: record)
            completion(post)
        }
    }
    
    func fetchPosts(completion: @escaping ([Post]?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PostConstants.typeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error performing query to fetch posts : \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let records = records else { completion(nil); return }
            let posts = records.compactMap{ Post(ckRecord: $0) }
            self.posts = posts
            completion(posts)
        }
    }
    
    func fetchCommentsFor(post: Post, completion: @escaping ([Comment]?) -> Void) {
        let postReference = post.recordID
        let predicate = NSPredicate(format: "%K == %@", CommentConstants.postReferenceKey, postReference)
        let commentIDs = post.comments.compactMap { $0.recordID }
        let predicate2 = NSPredicate(format: "NOT (recordID IN %@)", commentIDs)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        let query = CKQuery(recordType: CommentConstants.recordType, predicate: compoundPredicate)
        
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error performing query to fetch posts : \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let records = records else { completion(nil); return }
            let comments = records.compactMap { Comment(ckRecord: $0, post: post)}
            post.comments.append(contentsOf: comments)
            completion(comments)
        }
    }
    
    func incrementCommentCount(for post: Post, completion: ((Bool) -> Void)?) {
        post.commentCount += 1
        
        let modifyOperations = CKModifyRecordsOperation(recordsToSave: [CKRecord(post: post)], recordIDsToDelete: nil)
        modifyOperations.savePolicy = .changedKeys
        modifyOperations.modifyRecordsCompletionBlock = { (records, _, error) in
            if let error = error {
                print("There was an error modifying: \(error.localizedDescription)")
                completion?(false)
                return
            } else {
                completion?(true)
            }
        }
        publicDB.add(modifyOperations)
    }
    
    func subscribeToNewPosts(completion: ((Bool, Error?) -> Void)?){
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Post", predicate: predicate, subscriptionID: "AllPosts", options: CKQuerySubscription.Options.firesOnRecordCreation)
        let notifcationInfo = CKSubscription.NotificationInfo()
        notifcationInfo.alertBody = "New post added to Continuum"
        notifcationInfo.shouldBadge = true
        notifcationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notifcationInfo
        CKContainer.default().publicCloudDatabase.save(subscription) { (subscription, error) in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                completion?(false, error)
            }else {
                completion?(true, nil)
            }
        }
    }
    
    func addSubscritptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?){
        let postRecordID = post.recordID
        let predicate = NSPredicate(format: "%K = %@", CommentConstants.postReferenceKey, postRecordID)
        let subscription = CKQuerySubscription(recordType: "Comment", predicate: predicate, subscriptionID: post.recordID.recordName, options: CKQuerySubscription.Options.firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "A new comment was added a a post you follow!"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = nil
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { (_, error) in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                completion?(false, error)
            }else{
                completion?(true, nil)
            }
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool) -> ())?){
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: subscriptionID) { (_, error) in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                completion?(false)
                return
            }else {
                print("Subscription deleted")
                completion?(true)
            }
            
        }
    }
    
    func checkForSubscription(to post: Post, completion: ((Bool) -> ())?){
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                completion?(false)
                return
            }
            if subscription != nil{
                completion?(true)
            }else {
                completion?(false)
            }
            
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?){
        checkForSubscription(to: post) { (isSubscribed) in
            if isSubscribed{
                self.removeSubscriptionTo(commentsForPost: post, completion: { (success) in
                    if success{
                        print("Successfully removed the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    }else{
                        print("Whoops somthing went wrong removing the subscription to the post with caption: \(post.caption)")
                        completion?(false, nil)
                    }
                })
            }else {
                self.addSubscritptionTo(commentsForPost: post, completion: { (success, error) in
                    if let error = error {
                        print("There was an error: \(error.localizedDescription)")
                        completion?(false, error)
                        return
                    }
                    if success{
                        print("Successfully added the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    }else{
                        print("Whoops somthing went wrong adding the subscription to the post with caption: \(post.caption)")
                        completion?(false, nil)
                    }
                })
            }
        }
    }
}
