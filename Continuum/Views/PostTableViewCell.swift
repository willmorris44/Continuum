//
//  PostTableViewCell.swift
//  Continuum
//
//  Created by Will morris on 6/4/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    func updateViews() {
        guard let post = post else { return }
        postImageView.image = post.photo
        captionLabel.text = post.caption
        commentCountLabel.text = "\(post.commentCount)"
    }
}
