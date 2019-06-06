//
//  PostDetailTableViewController.swift
//  Continuum
//
//  Created by Will morris on 6/4/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    var post: Post? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var followPostButton: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let post = post else { return }
        PostController.shared.fetchCommentsFor(post: post) { (_) in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func updateFollowButtonText() {
        guard let post = post else { return }
        PostController.shared.checkForSubscription(to: post) { (found) in
            DispatchQueue.main.async {
                let followPostButtonText = found ? "Unfollow Post" : "Follow Post"
                self.followPostButton.setTitle(followPostButtonText, for: .normal)
                self.buttonStackView.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func commentButtonTapped(_ sender: Any) {
        presentCommentAlertController()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        guard let comment = post?.caption else { return }
        let shareSheet = UIActivityViewController(activityItems: [comment], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
    
    @IBAction func followButtonTapped(_ sender: Any) {
        guard let post = post else { return }
        PostController.shared.toggleSubscriptionTo(commentsForPost: post) { (success, error) in
            if let error = error {
                print("There was an error \(error.localizedDescription)")
                return
            }
            self.updateFollowButtonText()
        }
    }
    
    func updateViews() {
        guard let post = post else { return }
        photoImageView.image = post.photo
        tableView.reloadData()
        updateFollowButtonText()
    }
    
    func presentCommentAlertController() {
        let alert = UIAlertController(title: "Comment", message: "Add Comment", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Type here"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let comment = UIAlertAction(title: "Comment", style: .default) { (_) in
            guard let commentText = alert.textFields?.first?.text,
                !commentText.isEmpty,
                let post = self.post
                else { return }
            PostController.shared.addComment(text: commentText, post: post, completion: { (comment) in
            })
            self.tableView.reloadData()
        }
        
        alert.addAction(comment)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post!.comments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        
        let comment = post?.comments[indexPath.row]
        cell.textLabel?.text = comment?.text
        cell.detailTextLabel?.text = "\(comment!.timestamp)"

        return cell
    }
}
