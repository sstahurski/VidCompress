//
//  ViewController.swift
//  VidCompress
//
//  Created by Scott Stahurski on 3/19/20.
//  Copyright © 2020 Scott Stahurski. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import AVKit
import AssetsLibrary

class ViewController: UIViewController,UINavigationControllerDelegate,UIImagePickerControllerDelegate {

    
    var cameraController = UIImagePickerController()
    
    let videoFilenames = ["client.mp4","client_medium.mp4","client_small.mp4"]

    
    @IBOutlet var playView: UIView!
    @IBOutlet var videoNormalQualityLabel: UILabel!
    @IBOutlet var videoMediumQualityLabel: UILabel!
    @IBOutlet var videoLowQualityLabel: UILabel!
    
    @IBOutlet var exportButton: UIButton!
    @IBOutlet var exportActivityIndicator: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //set up the camera to take video
        //set this view controller as the delegate
        cameraController.delegate = self
        
        //hide the play view
        self.showHidePlayView( show:false )
        exportActivityIndicator.alpha = 0.0
    
    }
    
    func showHidePlayView( show:Bool ){
            
        if show {
            playView.alpha = 1.0
            exportButton.alpha = 1.0
        }
        else {
            playView.alpha = 0.0
            exportButton.alpha = 0.0
        }
    }
    
    //helper method for asyc call
    func updateMediumQualityLabel(_ filesize:String) {
        DispatchQueue.main.async {
            self.videoMediumQualityLabel.text = filesize
        }
    }
    //helper method for asyc call
    func updateLowQualityLabel(_ filesize:String) {
        DispatchQueue.main.async {
            self.videoLowQualityLabel.text = filesize
        }
    }
    
    
    //************************************************
    //Selectors

    @IBAction func recordVideoSelector(_ sender: Any) {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            //setup to take video only
            cameraController.sourceType = .camera
            cameraController.mediaTypes = [kUTTypeMovie as String]
            
            //dispay the camera view controller
            present(cameraController, animated: true, completion: nil)
            
        }
        else {
            let alertController = UIAlertController(title: "No Camera Present", message: "There is no camera available for video.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
        
    }
    
    // Play the video selected.
    @IBAction func playSelector(_ sender: UIButton) {
        
        //Button tag holds the quality/file index that should be played.
        let filename:String = videoFilenames[sender.tag]

        //create path
        let appDocDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPathURL:URL = appDocDirectory.appendingPathComponent(filename)
        
        //play the video selected in the play controller
        let player = AVPlayer(url:fullPathURL )
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
        
    }
    
    
    @IBAction func ExportVideosSelector(_ sender: Any) {
        
        //start the activty indicator
        exportActivityIndicator.alpha = 1.0
        exportActivityIndicator.startAnimating()
        
        //save videos to photos
        let appDocDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        for filname in videoFilenames {
            let urlFilename = appDocDirectory.appendingPathComponent(filname)
            
            let videoSaved = #selector(videoSavedToPhotos(_:didFinishSavingWithError:context:))
            UISaveVideoAtPathToSavedPhotosAlbum(urlFilename.relativePath, self, videoSaved, nil)
        }

    }
    
    @objc func videoSavedToPhotos(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer){
        if let theError = error {
            print("error saving the video = \(theError)")
        } else {
           DispatchQueue.main.async {
                self.exportActivityIndicator.alpha = 0.0
                self.exportActivityIndicator.stopAnimating()
            }
        }
    }
    
    
    
    
    //*******************************************
    //UIImagePickerControllerDelegate
    
    //called when the image Picker controller is done recording
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.showHidePlayView(show:false)
        
        guard let videoURL: URL = ( info[UIImagePickerController.InfoKey.mediaURL] as? URL ) else {
            
            let alertController = UIAlertController(title: "Video Error", message: "There was a problem accessing the current video.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            picker.dismiss(animated: true)
            return
        }
        
        // Get the video
        let videoData = try? Data(contentsOf: videoURL)
        
        //create our URLS
        let appDocDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURLNormal:URL = appDocDirectory.appendingPathComponent(videoFilenames[0])
        let videoURLMedium:URL = appDocDirectory.appendingPathComponent(videoFilenames[1])
        let videoURLSmall:URL  = appDocDirectory.appendingPathComponent(videoFilenames[2])
        
        //remove any existing files
        do{
            try FileManager.default.removeItem(at: videoURLNormal )
        }
        catch { print("Delete error: " + error.localizedDescription) }
        
        do{
            try FileManager.default.removeItem(at: videoURLMedium)
        }
        catch { print("Delete error: " + error.localizedDescription) }
        
        do{
            try FileManager.default.removeItem(at: videoURLSmall)
        }
        catch { print("Delete error: " + error.localizedDescription) }
        
        //write files to document directory
        do{
            try videoData?.write(to: videoURLNormal, options: .atomic)
        }
        catch { print("Write error: " + error.localizedDescription) }

        //set label for original filesize
        do {
            let resourceValues = try videoURLNormal.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize!
            videoNormalQualityLabel.text = getFormattedFileSize(fileSize )
            print("Original file size \(fileSize)")
        } catch { print(error) }


        //compress to medium
        compressVideo(videoURLNormal, destinationFileURL: videoURLMedium, compressionType: AVAssetExportPresetMediumQuality, compressionCompleteClosure: updateMediumQualityLabel)
        
        //compress to small
        compressVideo(videoURLNormal, destinationFileURL: videoURLSmall, compressionType: AVAssetExportPresetLowQuality, compressionCompleteClosure: updateLowQualityLabel)
        

        //dismiss the uiImagePickerViewController
        picker.dismiss(animated: true)
        
        //show the play view
        self.showHidePlayView(show:true)
        
    }
    
    
    
}

