//
//  PostListTableViewController.swift
//  Continuum
//
//  Created by Will morris on 6/4/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    
    var resultsArray: [Post] = []
    
    var isSearching = false
    
    var dataSource: [Post] {
        return isSearching ? resultsArray : PostController.shared.posts
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        performFullSync(completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        resultsArray = PostController.shared.posts
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell

        let post = dataSource[indexPath.row]
        cell?.post = post
        
        return cell ?? UITableViewCell()
    }
    
    // MARK: - Methods
    
    func performFullSync(completion: ((Bool) -> Void)?) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        PostController.shared.fetchPosts { (posts) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.tableView.reloadData()
                completion?(posts != nil)
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toPostDetailView" {
            if let index = tableView.indexPathForSelectedRow {
                guard let destinationVC = segue.destination as? PostDetailTableViewController else { return }
                let post = dataSource[index.row]
                destinationVC.post = post
            }
        }
    }
}

extension PostListTableViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            resultsArray = PostController.shared.posts
        } else {
            resultsArray = PostController.shared.posts.filter { $0.matches(searchTerm: searchText.lowercased()) }
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resultsArray = PostController.shared.posts
        tableView.reloadData()
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
    }
}
