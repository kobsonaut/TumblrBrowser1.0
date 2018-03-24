//
//  FeedViewController.swift
//  TumblrBrowser
//
//  Created by Kobsonauta on 20.03.2018.
//  Copyright © 2018 Kobsonauta. All rights reserved.
//

import UIKit


class FeedViewController: UITableViewController, UISearchBarDelegate {

    var searchController : UISearchController!
    var posts: [ImagePost] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupSearchController()
    }

    private func setupView() {
        self.tableView.register(ImagePrototypeCell.self, forCellReuseIdentifier: "postCell")
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 300
    }

    private func fetchTumblrData(withName url: String) {
        let jsonStringURL = URL(string: "https://\(url).tumblr.com/api/read/")
        guard let xml = XML(contentsOf: jsonStringURL!) else { return }
        print(xml)
        if (!xml.description.isEmpty) {
            let postsRange = xml[0][1].children.count
            if postsRange > 0 {
                for i in 0..<postsRange {
                    guard let postType = xml[0][1][i].attributes["type"] else { return }
                    if postType == "photo" {
                        guard let name = xml[0][1][i]["tumblelog"]?.attributes["name"] else { return }
                        guard let imageURL = xml[0][1][i]["photo-url"]?.text else { return }
                        guard let profileImage = xml[0][1][i]["tumblelog"]?.attributes["avatar-url-40"] else { return }

                        let postImageURL = URL(string: imageURL)
                        let profileImageURL = URL(string: profileImage)

                        let post = ImagePost(profileName: name, profileImageURL: profileImageURL, imageURL: postImageURL, type: postType)
                        self.posts.append(post)
                    } else if postType == "regular" {
                        guard let message = xml[0][1][i]["regular-body"]?.text else { return }
                        let post = TextPost(profileName: self.name, profileImageURL: self.profileImageURL, message: message, type: postType)
                    } else {
                        print("Different type.")
                    }
                }
            } else {
                print("Out of range.")
            }
        } else {
            let alert = UIAlertController(title: "No search results", message: "Sincerely, we found nothing.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! ImagePrototypeCell
        cell.profileName = posts[indexPath.row].profileName
        OperationQueue.main.addOperation {
            let profileImageUrl: URL? = self.posts[indexPath.row].profileImageURL
            if let imageUrl = profileImageUrl {
                PhotoManager.shared.getPhoto(from: imageUrl, completion: {(image) -> (Void) in
                    if let image = image {
                        cell.profileImageView.image = image
                    }
                })
            }

            let postImageUrl: URL? = self.posts[indexPath.row].imageURL
            if let imageUrl = postImageUrl {
                cell.postImageView.image = #imageLiteral(resourceName: "placeholder")
                PhotoManager.shared.getPhoto(from: imageUrl, completion: {(image) -> (Void) in
                    if let image = image {
                        cell.postImageView.image = image
                    }
                })
            }
        }
        cell.layoutSubviews()
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search Tumblr Profile"
        searchController.searchBar.delegate = self
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        fetchTumblrData(withName: searchBar.text!)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        searchController.isActive = false
    }
}

