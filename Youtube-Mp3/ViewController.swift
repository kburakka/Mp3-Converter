//
//  ViewController.swift
//  Youtube-Mp3
//
//  Created by burak kaya on 20/11/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import Alamofire
import WebKit
import SwiftyJSON
import RxSwift
import RxCocoa
import CoreData
import Toast_Swift

class VideoCell {
    let title :String
    let id : String
    let image : UIImageView?
    var duration : String?
    init(title : String, id :String, image : UIImageView?, duration : String?) {
        self.title = title
        self.id = id
        self.image = image
        self.duration = duration
    }
}

class ViewController: UIViewController,UISearchBarDelegate{
//    let key = "AIzaSyB8r2q2PWYS70cIYU2VdzlMsWwre0l_RvY"
    let key = "AIzaSyCEk9NowuSv6luXn1GL9esx13eL3lKE34M"
    let showVideoView = ShowVideo()
    var videoCellArr = [VideoCell]()
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let keyword = searchBar.text else {
            return
        }
        searchBar.endEditing(true)
        searchVideo(text: keyword)
    }

    func addVideoToDb(video :VideoCell){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let menagedContext = appDelegate.persistentContainer.viewContext
        let favoriteEntity = NSEntityDescription.entity(forEntityName: "Videos", in: menagedContext)!

        let favorite = NSManagedObject(entity: favoriteEntity, insertInto: menagedContext)
        favorite.setValue(video.id, forKey: "id")
        favorite.setValue(video.title, forKey: "title")
        favorite.setValue(video.duration, forKey: "duration")
        if let image = video.image?.image{
            favorite.setValue(imagetoBase64(image: image), forKey: "image")
        }

        do{
            try menagedContext.save()
        }catch{
            errorMessage(msg: "addVideoToDb")
        }
    }
    
      func setDurations(id : String){
            let url = "https://www.googleapis.com/youtube/v3/videos?id=\(id)&part=contentDetails&key=\(key)"
            Alamofire.request(url, method: .get).responseJSON{ response in
                if response.result.isSuccess
                {
                    let json : JSON = JSON(response.result.value!)
                    let duration = json["items"][0]["contentDetails"]["duration"].string
                    let id = json["items"][0]["id"].string
                    
                    self.videoCellArr.first(where: {$0.id == id})?.duration = duration
                }
        }
    }
    
    func listEntranceVideos(){
        let url = "https://www.googleapis.com/youtube/v3/search?part=snippet&chart=mostPopular&regionCode=TR&maxResults=50&type=video&videoDefinition=high&id=AKiiekaEHhI&key=\(key)"
        videoCellArr.removeAll()
        Alamofire.request(url, method: .get).responseJSON{ response in
            if response.result.isSuccess
            {
                let json : JSON = JSON(response.result.value!)
                let items = json["items"]
                for index in 0..<items.count{
                    if let title = items[index]["snippet"]["title"].string, let id = items[index]["id"]["videoId"].string {
                        let urlStr = items[index]["snippet"]["thumbnails"]["default"]["url"].string ?? ""
                        let url = URL(string: urlStr)
                        let img = UIImageView()
                        img.sd_setImage(with: url) { (_, _, _, _) in
                            self.tableView.reloadData()
                        }
                        self.videoCellArr.append(VideoCell(title: title, id: id, image: img, duration: nil))
                        self.setDurations(id: id)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func embedYoutube(video : VideoCell){
        addKategorikAramaView(video: video)
        showVideoView.webView.load(URLRequest(url: URL(string: "https://www.youtube.com/embed/\(video.id)")!))
    }
    
    func addKategorikAramaView(video : VideoCell){
        _ = showVideoView
        showVideoView.frame = view.frame
        showVideoView.center = view.center
        showVideoView.download.addAction(for: .touchUpInside) {
            self.showVideoView.removeFromSuperview()
            self.downloadVideo(video: video, completionHandler: { response in
                DispatchQueue.main.async {
                    let filtered = downloadingVideos.value?.filter({$0.id != video.id})
                    downloadingVideos.accept(filtered)
                    if response.success == true{
                        self.view.makeToast(response.message)
                    }else{
                        self.errorMessage(msg: response.message)
                    }
                }
            })
        }
        showVideoView.close.addAction(for: .touchUpInside) {
            self.showVideoView.removeFromSuperview()
        }
        view.addSubview(showVideoView)
    }

    struct Response {
        let success : Bool
        let message : String
        
        init(success: Bool , message: String) {
            self.success = success
            self.message = message
        }
    }
    func downloadVideo(video : VideoCell, completionHandler: @escaping  (_ json:Response) -> ()) {
        let url = "https://michaelbelgium.me/ytconverter/convert.php?youtubelink=https://www.youtube.com/watch?v=\(video.id)"
        
        var appended = downloadingVideos.value
        appended?.append(video)
        downloadingVideos.accept(appended)
        
        Alamofire.request(url, method: .get).responseJSON{ response in
            if response.result.isSuccess
            {
                let json : JSON = JSON(response.result.value!)
                guard let fileUrl = json["file"].string else {
                    if json["message"].string == "Video too large. Max video length is 360 seconds."{
                        completionHandler(Response(success: false, message: "\(video.title) too large. Max video length is 360 seconds."))
                    }else{
                        completionHandler(Response(success: false, message: "Error while saving \(video.title)"))
                    }
                    return
                }
                if let audioUrl = URL(string: fileUrl) {
                    let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let destination = documentsUrl.appendingPathComponent(audioUrl.lastPathComponent)
                    if FileManager().fileExists(atPath: destination.path) {
                        completionHandler(Response(success: true, message: "\(video.title) saved before"))
                    } else {
                        URLSession.shared.downloadTask(with: audioUrl, completionHandler: { (location, response, error) in
                            guard
                                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                                let mimeType = response?.mimeType, mimeType.hasPrefix("audio"),
                                let location = location, error == nil
                                else {
                                    completionHandler(Response(success: false, message: "Error while saving \(video.title)"))
                                    return
                            }
                            do {
                                try FileManager.default.moveItem(at: location, to: destination)
                                self.addVideoToDb(video: video)
                                completionHandler(Response(success: true, message: "\(video.title) saved"))
                            } catch {
                                completionHandler(Response(success: false, message: "Error while saving \(video.title)"))
                            }
                        }).resume()
                    }
                }else{
                  completionHandler(Response(success: false, message: "Error while saving \(video.title)"))
                }
            }
        }
    }
    
    override func viewDidLoad() {
        listEntranceVideos()
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }
    
    func searchVideo(text : String){
        let capital = text.capitalized
        var text = capital.replacingOccurrences(of: " ", with: "+")
        text = text.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!

        let url = "https://www.googleapis.com/youtube/v3/search?part=snippet&order=viewCount&q=\(text)&maxResults=50&type=video&videoDefinition=high&id=AKiiekaEHhI&key=\(key)"
        videoCellArr.removeAll()
        Alamofire.request(url, method: .get).responseJSON{ response in
            if response.result.isSuccess
            {
                let json : JSON = JSON(response.result.value!)
                let items = json["items"]
                for index in 0..<items.count{
                    if let title = items[index]["snippet"]["title"].string, let id = items[index]["id"]["videoId"].string {
                        let urlStr = items[index]["snippet"]["thumbnails"]["default"]["url"].string ?? ""
                        let url = URL(string: urlStr)
                        let img = UIImageView()
                        img.sd_setImage(with: url) { (_, _, _, _) in
                            self.tableView.reloadData()
                        }
                        self.videoCellArr.append(VideoCell(title: title, id: id, image: img, duration: nil))
                        self.setDurations(id: id)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    func errorMessage(msg:String){
         let alert = UIAlertController(title: "ERROR!", message: msg, preferredStyle: UIAlertController.Style.alert)
         
         alert.addAction(UIAlertAction(title: "Back", style: UIAlertAction.Style.default, handler: nil))
         
         self.present(alert, animated: true, completion: nil)
     }
}

extension ViewController: UITableViewDataSource,UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoCellArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("VideoViewCell", owner: self, options: nil)?.first as! VideoViewCell
        cell.configure(with: videoCellArr[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        embedYoutube(video: videoCellArr[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
class ClosureSleeve {
    let closure: () -> ()
    
    init(attachTo: AnyObject, closure: @escaping () -> ()) {
        self.closure = closure
        objc_setAssociatedObject(attachTo, "[\(arc4random())]", self, .OBJC_ASSOCIATION_RETAIN)
    }
    
    @objc func invoke() {
        closure()
    }
}
extension UIControl {
    func addAction(for controlEvents: UIControl.Event, action: @escaping () -> ()) {
        self.removeTarget(nil, action: nil, for: .allEvents)
        let sleeve = ClosureSleeve(attachTo: self, closure: action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
    }
}
