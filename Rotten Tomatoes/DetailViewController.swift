//
//  DetailViewController.swift
//  Rotten Tomatoes
//
//  Created by Dave Vo on 8/29/15.
//  Copyright (c) 2015 Chau Vo. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var releaseDateLabel: UILabel!
    
    @IBOutlet weak var synopsisLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var mpaaRatingLabel: UILabel!
    
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var emojiView: UIImageView!
    
    @IBOutlet weak var errorView: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedMovie: NSDictionary!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadImage()
        loadDetail()
        addGesture()
    }
    
    func loadImage() {
        
        // Use NSURLCache
        
        var sUrl = selectedMovie.valueForKeyPath("posters.thumbnail") as! String
        let lowResUrl = NSURL(string: sUrl)
        
        var range = sUrl.rangeOfString(".*cloudfront.net/", options: .RegularExpressionSearch)
        if let range = range {
            sUrl = sUrl.stringByReplacingCharactersInRange(range, withString: "https://content6.flixster.com/")
        }
        let url = NSURL(string: sUrl)
        
        var urlRequest = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 600)
        if hasConnectivity() {
            
            var placeholderImg = UIImage(data: NSData(contentsOfURL: lowResUrl!)!)
            
            imageView.setImageWithURLRequest(urlRequest, placeholderImage: placeholderImg,
                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
                    if ((request) != nil) {
                        self.imageView.image = image
                    }
                    
                }, failure: {
                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
                    
            })
        } else {
            
            imageView.setImageWithURLRequest(urlRequest, placeholderImage: nil,
                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
                    self.imageView.image = image
                }, failure: {
                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
                    
            })
        }
        

//        if hasConnectivity() {
//            var sUrl = selectedMovie.valueForKeyPath("posters.original") as? String
//            let lowResUrl = NSURL(string: sUrl!)
//            let start = NSDate()
//            var placeholderImg = UIImage(data: NSData(contentsOfURL: lowResUrl!)!)
//            let end = NSDate()
//            let timeElapsed = end.timeIntervalSinceDate(start)
//            println("Time elapsed: \(timeElapsed)")
//            
//            var range = sUrl!.rangeOfString(".*cloudfront.net/", options: .RegularExpressionSearch)
//            if let range = range {
//                sUrl = sUrl!.stringByReplacingCharactersInRange(range, withString: "https://content6.flixster.com/")
//            }
//            let url = NSURL(string: sUrl!)
//            
//            let urlRequest = NSURLRequest(URL: url!)
//            imageView.setImageWithURLRequest(urlRequest, placeholderImage: placeholderImg,
//                success: { (request:NSURLRequest!,response:NSHTTPURLResponse!, image:UIImage!) -> Void in
//                    self.imageView.image = image
//                }, failure: {
//                    (request:NSURLRequest!,response:NSHTTPURLResponse!, error:NSError!) -> Void in
//                    
//            })
//        }
        
        
    }
    
    func loadDetail() {
        let title = selectedMovie["title"] as? String
        self.title = title
        titleLabel.text = title
        
        let date = selectedMovie.valueForKeyPath("release_dates.theater") as? String
        releaseDateLabel.text = date!
        
        let synopsis = selectedMovie["synopsis"] as? String
        synopsisLabel.text = synopsis
        synopsisLabel.sizeToFit()
        
        mpaaRatingLabel.text = selectedMovie["mpaa_rating"] as? String
        mpaaRatingLabel.layer.borderWidth = 0.5
        mpaaRatingLabel.layer.borderColor = UIColor.whiteColor().CGColor
        mpaaRatingLabel.layer.cornerRadius = 3
        
        let duration = selectedMovie["runtime"] as? Int
        if let duration = duration {
            durationLabel.text = String(stringInterpolationSegment: duration) + " min"
        } else {
            durationLabel.text = ""
        }
        
        let score = selectedMovie.valueForKeyPath("ratings.critics_score") as? Int
        if let score = score {
            ratingLabel.text = String(stringInterpolationSegment: score)
        } else {
            ratingLabel.text = ""
        }
        
        if score >= 80 {
            emojiView.image = UIImage(named: "HappyWhite")
        } else if score < 40 {
            emojiView.image = UIImage(named: "SadWhite")
        } else {
            emojiView.image = UIImage(named: "NeutralWhite")
        }
        
        scrollView.contentSize.height = 130 + synopsisLabel.layer.frame.height
    }
    
    // MARK: Network error
    
    func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus.hashValue
        println(networkStatus)
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
    }
    
    // MARK: Gesture
    
    func addGesture() {
        let tapScrollView = UITapGestureRecognizer(target: self, action: "expandDetail:")
        self.scrollView.addGestureRecognizer(tapScrollView)
        
        imageView.userInteractionEnabled = true
        let tapPoster = UITapGestureRecognizer(target: self, action: "collapseDetail:")
        self.imageView.addGestureRecognizer(tapPoster)
        
    }
    
    func expandDetail(sender:UITapGestureRecognizer) {
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.scrollView.frame = CGRectMake(0 , 178, self.view.frame.width, 390)
            }, completion: nil)
    }
    
    func collapseDetail(sender:UITapGestureRecognizer) {
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.scrollView.frame = CGRectMake(0 , 378, self.view.frame.width, 190)
            }, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
