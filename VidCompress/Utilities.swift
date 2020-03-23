//
//  Utilities.swift
//  VidCompress
//
//  Created by Scott Stahurski on 3/19/20.
//  Copyright © 2020 Scott Stahurski. All rights reserved.
//

import Foundation
import AssetsLibrary
import AVFoundation
import AVKit

//AVAssetExportPresetLowQuality, AVAssetExportPresetMediumQuality, AVAssetExportPresetHighestQuality for compression type

func compressVideo(_ sourceFileURL:URL, destinationFileURL:URL, compressionType:String, compressionCompleteClosure: @escaping (_ filesize:String ) -> Void  ) {
    
    print("Source URL \(sourceFileURL)")
    print("Destination URL \(destinationFileURL)")
    
    var fileSize:String = "Error"
    
    //error check on compression type
    //compression type should be an enum
    if compressionType == AVAssetExportPresetLowQuality || compressionType == AVAssetExportPresetMediumQuality || compressionType == AVAssetExportPresetHighestQuality {
    
        //create the asset
        let videoAsset = AVURLAsset(url: sourceFileURL, options: nil)
         
         //Compress the video possible values are
         //AVAssetExportPresetLowQuality, AVAssetExportPresetMediumQuality, AVAssetExportPresetHighestQuality
         guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: compressionType) else {
             compressionCompleteClosure("Error with AV")
            return
         }
         
         exportSession.outputURL = destinationFileURL
         exportSession.outputFileType = AVFileType.mp4
         exportSession.shouldOptimizeForNetworkUse = true
         exportSession.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)
        
         
         exportSession.exportAsynchronously {
             switch exportSession.status{
             case  AVAssetExportSessionStatus.failed:
                print("failed compression \(String(describing: exportSession.error))")
                fileSize = "Failed Compression"
             case AVAssetExportSessionStatus.cancelled:
                print("cancelled compression\(String(describing: exportSession.error))")
                fileSize = "Failed Compression"
             default:
                 print("compression complete")
                 fileSize = getFormattedFileSize( Int( exportSession.estimatedOutputFileLength) )
                 compressionCompleteClosure(fileSize)
             }
         }
        
        
    }
    
}


func getFormattedFileSize(_ size:Int ) -> String {
    
    var fileSize:String = ""
    
    
    let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB] // MB only
        bcf.countStyle = .file
    
    fileSize = bcf.string(fromByteCount: Int64(size) ) 
    
    print( "Video Size: " + fileSize )
    
    return fileSize;
}
