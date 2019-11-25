//
//  DownloadedVideosController.swift
//  Youtube-Mp3
//
//  Created by burak kaya on 20/11/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import RxSwift
import RxCocoa
import MarqueeLabel

class DownloadedVideosController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var downloadedVides = [VideoCell]()
    private let bag = DisposeBag()

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var forward: UIButton!
    @IBOutlet weak var playPause: UIButton!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedVides.count
    }
    var player = RxPlayer()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("VideoViewCell", owner: self, options: nil)?.first as! VideoViewCell
        cell.configure(with: downloadedVides[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func subscibeToState() {
        player.state.subscribe(onNext: { [weak self] value in
            switch value {
            case .Playing:
                self?.playPause.setBackgroundImage(UIImage(named: "pauseBtn"), for: .normal)
            case .Paused:
                self?.playPause.setBackgroundImage(UIImage(named: "playBtn"), for: .normal)
            case .Failed:
                print("Failed")
            default:
                break
            }
        }).disposed(by: bag)
    }
    
    func currentSong(){
        player.currentItem.subscribe(onNext: { [weak self] item in
            guard let _ = item?.title , let index = self?.currentSongIndex else {
                return
            }
            self?.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .none)
            self?.songTitle.text = self?.downloadedVides[index].title
        }).disposed(by: bag)
    }

    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
    downloadedVides.removeAll()
       let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let urls = fileURLs.map({$0.absoluteString})
            for index in urls{
                let title = index.components(separatedBy: "/Documents/")[1].components(separatedBy: ".mp3")[0]
                if isVideoInDb(id: title) != nil{
                    downloadedVides.append(isVideoInDb(id: title)!)
                    print(title)
                }
            }
            tableView.reloadData()
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    @IBAction func changeAudioTime(_ sender: Any) {
        player.changeCurrentTime(value: slider.value)
    }
    func isVideoInDb(id:String)-> VideoCell?{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let menagedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Videos")

        do{
            let predicate = NSPredicate(format: "id = %@", id)
            fetchRequest.predicate = predicate
            
            let result = try menagedContext.fetch(fetchRequest)
            if result.count == 0 {
                return nil
            }else{
                let object = result as! [NSManagedObject]
                
                let video = VideoCell(title: object[0].value(forKey: "title") as! String, id: object[0].value(forKey: "id") as! String, image: UIImageView(image: base64toImage(base64String: object[0].value(forKey: "image") as? String)), duration: object[0].value(forKey: "duration") as? String)
                return video
            }
        }catch{
            return nil
        }
    }
    
    
    func deleteVideo(video:VideoCell){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let menagedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Videos")

        let predicate = NSPredicate(format: "id = %@", video.id)
        fetchRequest.predicate = predicate
        do{
            let objects = try menagedContext.fetch(fetchRequest)
            if objects.count > 0{
                let objectToDelete = objects[0] as! NSManagedObject
                menagedContext.delete(objectToDelete)
                try menagedContext.save()
            }
        }catch{
            print("error")
        }
    }
    
    func videosInDirectory(title : String ) -> URL?{
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

            let mp3File = directoryContents.filter{ $0.pathExtension == "mp3" }.first(where: {
                $0.lastPathComponent == "\(title).mp3"
            })

            return mp3File
        } catch {
            return nil
        }
    }
    
    var currentSongIndex : Int?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard let path = videosInDirectory(title: downloadedVides[indexPath.row].id) else{
                return
            }
            currentSongIndex = indexPath.row
        player.playItem(RxPlayerItem(title: downloadedVides[indexPath.row].title, artist: "aa", url: path))
    }
    override func viewDidLoad() {
        subscibeToState()
        currentSong()
        super.viewDidLoad()
        player.addProgressObserver { progress in
            self.slider.value = Float(progress)
        }
    }

    @IBAction func back(_ sender: Any) {
        guard let index = currentSongIndex else{
            return
        }
        
        let isIndexValid = downloadedVides.indices.contains(index)
        
        if index > -1 && isIndexValid{
            if index > 0{
                currentSongIndex = index - 1
            }
            guard let indexReal = currentSongIndex else{
                return
            }
            guard let path = videosInDirectory(title: downloadedVides[indexReal].id) else {
                return
            }
            player.playItem(RxPlayerItem(title: downloadedVides[index].title, artist: "aa", url: path))
        }
    }
    
    @IBAction func playPause(_ sender: Any) {
        player.playItem(nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            deleteVideo(video: downloadedVides[indexPath.row])
            removeFile(itemName:downloadedVides[indexPath.row].id, fileExtension: ".mp3")
            downloadedVides.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func removeFile(itemName:String, fileExtension: String) {
        let fileManager = FileManager.default
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        guard let dirPath = paths.first else {
            return
        }
        let filePath = "\(dirPath)/\(itemName).\(fileExtension)"
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    @IBAction func forward(_ sender: Any) {
        guard let index = currentSongIndex else{
            return
        }
        
        let isIndexValid = downloadedVides.indices.contains(index)
        
        if index > -1 && isIndexValid{
            
            if currentSongIndex != downloadedVides.count - 1{
                currentSongIndex = index + 1
            }
            guard let indexReal = currentSongIndex else{
                return
            }
            guard let path = videosInDirectory(title: downloadedVides[indexReal].id) else {
                return
            }
            player.playItem(RxPlayerItem(title: downloadedVides[index].title, artist: "aa", url: path))
        }
    }
}
