//
//  MoviesViewController.swift
//  Rotten Tomatoes
//
//  Created by Dave Vo on 8/27/15.
//  Copyright (c) 2015 Chau Vo. All rights reserved.
//

import UIKit

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITabBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let defaults = NSUserDefaults.standardUserDefaults()

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tabBar: UITabBar!
    
    @IBOutlet weak var viewButton: UIBarButtonItem!
    
    @IBOutlet weak var errorView: UIView!
    
    @IBOutlet weak var noResultsLabel: UILabel!
    
    var data: [NSDictionary]?
    
    var refreshControl: UIRefreshControl?
    var refreshControl2: UIRefreshControl?
    
    let movieUrl = NSURL(string: "https://gist.githubusercontent.com/timothy1ee/d1778ca5b944ed974db0/raw/489d812c7ceeec0ac15ab77bf7c47849f2d1eb2b/gistfile1.json")!
    
    let dvdUrl = NSURL(string: "https://gist.githubusercontent.com/timothy1ee/e41513a57049e21bc6cf/raw/b490e79be2d21818f28614ec933d5d8f467f0a66/gistfile1.json")!
    
    var searchActive : Bool = false
    
    var filtered = [NSDictionary]()
    
    var currentTab = 0
    
    var selectedIndexPath: NSIndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.hidden = true
        noResultsLabel.hidden = true

        tableView.dataSource = self
        tableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        tabBar.delegate = self
        
        tabBar.selectedItem = tabBar.items?.first as? UITabBarItem
        
        loadData()
        
        // Pull to refresh
        pullToRefresh()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadData() {
        
        if hasConnectivity() {
            self.errorView.alpha = 0.0
            
            var url: NSURL?
            if tabBar.selectedItem!.tag == 0 {
                url = movieUrl
            } else {
                url = dvdUrl
            }
            
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
            
            let request = NSURLRequest(URL: url!)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse!, data: NSData!, error:NSError!) -> Void in
                let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary
                
                if let json = json {
                    self.data = json["movies"] as? [NSDictionary]
                    self.tableView.reloadData()
                    self.collectionView.reloadData()
                    
                    // Save to NSUserDefaults
                    if self.tabBar.selectedItem!.tag == 0 {
                        self.defaults.setObject(self.data, forKey: "movies")
                    } else {
                        self.defaults.setObject(self.data, forKey: "dvds")
                    }
                }
                
                //            println(json)
            }
            
            PKHUD.sharedHUD.hide(afterDelay: 0.0)
            
            
        } else {
            UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.errorView.alpha = 1.0
                }, completion: nil)
            
            self.data = [NSDictionary]()
            
            if self.tabBar.selectedItem!.tag == 0 {
                self.data = defaults.objectForKey("movies") as? [NSDictionary]
            } else {
                self.data = defaults.objectForKey("dvds") as? [NSDictionary]
            }
            
            self.tableView.reloadData()
            self.collectionView.reloadData()
            
        }
        
        refreshControl?.endRefreshing()
        refreshControl2?.endRefreshing()
    }
    
    func editImgUrl(sUrl: String) -> NSURL {
        var originalUrl = sUrl
        
        var range = originalUrl.rangeOfString(".*cloudfront.net/", options: .RegularExpressionSearch)
        if let range = range {
            originalUrl = originalUrl.stringByReplacingCharactersInRange(range, withString: "https://content6.flixster.com/")
        }
        
        let url = NSURL(string: originalUrl)!
        return url
    }
    
    func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus.hashValue
//        println(networkStatus)
        return networkStatus != 0
    }
    
    
    @IBAction func cancelButtonClick(sender: UIButton) {
        UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.errorView.alpha = 0.0
            }, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if !hasConnectivity() {
            UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.errorView.alpha = 1.0
                }, completion: nil)
        }
        
        if selectedIndexPath != nil {
            tableView.cellForRowAtIndexPath(selectedIndexPath)?.contentView.backgroundColor = UIColor(red: 240/255, green: 255/255, blue: 240/255, alpha: 1.0)
        }
    }
    
    func pullToRefresh() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: "loadData", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
        
        self.refreshControl2 = UIRefreshControl()
        self.refreshControl2!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl2!.addTarget(self, action: "loadData", forControlEvents: UIControlEvents.ValueChanged)
        self.collectionView.addSubview(refreshControl2!)
    }
    
    // MARK: Table view
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let data = data {
            if (searchActive) {
                return filtered.count
            } else {
                return data.count
            }
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        if selectedIndexPath != nil {
            if indexPath == selectedIndexPath {
                cell.contentView.backgroundColor = UIColor(red: 240/255, green: 255/255, blue: 240/255, alpha: 1.0)
            }
        }
        
        var movie = NSDictionary()
        
        if (searchBar.text.isEmpty) {
            searchActive = false
        } else {
            searchActive = true
        }
        
        if (searchActive) {
            movie = filtered[indexPath.row]
        } else {
            movie = data![indexPath.row]
        }
        
        let year = movie["year"] as? Int
        if let year = year {
            cell.titleLabel.text = (movie["title"] as? String)! + " (" + String(stringInterpolationSegment: year) + ")"
        } else {
            cell.titleLabel.text = movie["title"] as? String
        }
        
        cell.mpaaRatingLabel.text = movie["mpaa_rating"] as? String
        
        let duration = movie["runtime"] as? Int
        if let duration = duration {
            cell.durationLabel.text = String(stringInterpolationSegment: duration) + " min"
        } else {
            cell.durationLabel.text = ""
        }
        
        let score = movie.valueForKeyPath("ratings.critics_score") as? Int
        if let score = score {
            cell.ratingLabel.text = String(stringInterpolationSegment: score)
        } else {
            cell.ratingLabel.text = ""
        }
        
        if score >= 80 {
            cell.emojiView.image = UIImage(named: "Happy")
        } else if score < 40 {
            cell.emojiView.image = UIImage(named: "Sad")
        } else {
            cell.emojiView.image = UIImage(named: "Neutral")
        }

        let url = NSURL(string: movie.valueForKeyPath("posters.thumbnail") as! String)!
        var urlRequest = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 600)
        
        if hasConnectivity() {
            cell.posterView.setImageWithURLRequest(urlRequest, placeholderImage: nil,
                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
                    cell.posterView.alpha = 0.0
                    if ((request) != nil) {
                        UIView.transitionWithView(cell.posterView, duration: 0.2, options: (UIViewAnimationOptions.CurveLinear | UIViewAnimationOptions.AllowUserInteraction), animations: {
                            cell.posterView.image = image
                            cell.posterView.alpha = 1.0
                            }, completion: nil)
                    }
                    
                }, failure: {
                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
                    
            })
            
        } else {
            cell.posterView.setImageWithURLRequest(urlRequest, placeholderImage: nil,
                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
                    cell.posterView.image = image
                    
                }, failure: {
                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
                    
            })
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        var selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
//        selectedCell.contentView.backgroundColor = UIColor(red: 240/255, green: 255/255, blue: 240/255, alpha: 1.0)
        selectedIndexPath = indexPath
        searchBar.resignFirstResponder()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var vc = segue.destinationViewController as! DetailViewController
        
        var indexPath: AnyObject?
        
        if viewButton.image == UIImage(named: "ListIcon") {
            indexPath = collectionView.indexPathForCell(sender as! UICollectionViewCell)
        } else {
            indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        }
        
        var movie = NSDictionary()
        
        if (searchBar.text.isEmpty) {
            searchActive = false
        } else {
            searchActive = true
        }
        
        if (searchActive) {
            movie = filtered[indexPath!.row]
        } else {
            movie = data![indexPath!.row]
        }
        
        vc.selectedMovie = movie as NSDictionary
        
    }
    
    // MARK: Collection view
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let data = data {
            if (searchActive) {
                return filtered.count
            } else {
                return data.count
            }
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionMovieCell", forIndexPath: indexPath) as! CollectionMovieCell
        
        var movie = NSDictionary()
        
        if (searchBar.text.isEmpty) {
            searchActive = false
        } else {
            searchActive = true
        }
        
        
        if (searchActive) {
            movie = filtered[indexPath.row]
        } else {
            movie = data![indexPath.row]
        }
        
        let year = movie["year"] as? Int
        if let year = year {
            cell.titleLabel.text = (movie["title"] as? String)! + " (" + String(stringInterpolationSegment: year) + ")"
        } else {
            cell.titleLabel.text = movie["title"] as? String
        }
        
        
        cell.mpaaRatingLabel.text = movie["mpaa_rating"] as? String
        
        let duration = movie["runtime"] as? Int
        if let duration = duration {
            cell.durationLabel.text = String(stringInterpolationSegment: duration) + " min"
        } else {
            cell.durationLabel.text = ""
        }
        
        let score = movie.valueForKeyPath("ratings.critics_score") as? Int
        if let score = score {
            cell.ratingLabel.text = String(stringInterpolationSegment: score)
        } else {
            cell.ratingLabel.text = ""
        }
        
        if score >= 80 {
            cell.emojiView.image = UIImage(named: "Happy")
        } else if score < 40 {
            cell.emojiView.image = UIImage(named: "Sad")
        } else {
            cell.emojiView.image = UIImage(named: "Neutral")
        }
        
        let lowResUrl = movie.valueForKeyPath("posters.thumbnail") as! String
        let url = editImgUrl(lowResUrl)
        
       
        var urlRequest = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 600)
        if hasConnectivity() {
            
//            var placeholderImg = UIImage(data: NSData(contentsOfURL: NSURL(string: lowResUrl)!)!)
            
            cell.imageView.setImageWithURLRequest(urlRequest, placeholderImage: nil,
                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
                    cell.imageView.alpha = 0.0
                    if ((request) != nil) {
                        UIView.transitionWithView(cell.imageView, duration: 0.2, options: (UIViewAnimationOptions.CurveLinear | UIViewAnimationOptions.AllowUserInteraction), animations: {
                            cell.imageView.image = image
                            cell.imageView.alpha = 1.0
                            }, completion: nil)
                    }
                    
                }, failure: {
                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
                    
            })
        } else {
            
            cell.imageView.setImageWithURLRequest(urlRequest, placeholderImage: nil,
                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
                    cell.imageView.image = image

                }, failure: {
                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
                    
            })
        }

        return cell

    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: Search bar
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        searchActive = false
        self.tableView.reloadData()
        self.collectionView.reloadData()
        showNoResultsLabel(false)
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text.isEmpty) {
            searchActive = false
            self.tableView.reloadData()
            self.collectionView.reloadData()
            showNoResultsLabel(false)
        } else {
            searchActive = true
            selectedIndexPath = nil
            filtered = data!.filter({ (movie) -> Bool in
                let tmp: NSDictionary = movie
                let range = tmp["title"]!.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
                return range.location != NSNotFound
            })
            
            if filtered.count == 0 {
                showNoResultsLabel(true)
            } else {
                showNoResultsLabel(false)
            }
            
            self.tableView.reloadData()
            self.collectionView.reloadData()
        }
    }
    
    func showNoResultsLabel(show: Bool) {
        noResultsLabel.hidden = !show
        let img = viewButton.image
        if img == UIImage(named: "GridIcon") {
            tableView.hidden = show
        } else {
            collectionView.hidden = show
        }
    }
    
    // MARK: Tab bar
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
//        println(item.tag);
        
        if item.tag != currentTab {
            currentTab = item.tag
            
            selectedIndexPath = nil
            
            searchBar.resignFirstResponder()
            searchBar.text = ""
            searchActive = false
            
            loadData()
        }
    }
    
    // MARK: View button
    
    @IBAction func viewButtonClick(sender: UIBarButtonItem) {
        let img = viewButton.image
        if img == UIImage(named: "GridIcon") {
            tableView.hidden = true
            collectionView.hidden = false
            viewButton.image = UIImage(named: "ListIcon")
        } else {
            tableView.hidden = false
            collectionView.hidden = true
            viewButton.image = UIImage(named: "GridIcon")
        }
    }
    
    


}
