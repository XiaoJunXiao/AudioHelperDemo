//
//  ViewController.swift
//  AudioHelperDemo
//
//  Created by Xiao on 2019/12/31.
//  Copyright © 2019 xiao. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var audioPlayer:AudioHelper?
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.audioPlayer = AudioHelper()
        
        let filePaths : [String] = Bundle.main.paths(forResourcesOfType: ".mp3", inDirectory: "Musics")
        self.audioPlayer?.loopModeToPlay(filePaths: filePaths)
    }

}

class AudioHelper: NSObject {
        
    //第一种方式，简单的音频播放
    func playSound(audioUrl: NSURL, isAlert: Bool , playFinish: ()->()) {
        // 一. 获取 SystemSoundID
        //   参数1: 文件路径
        //   参数2: SystemSoundID, 指针
        let urlCF = audioUrl as CFURL
        var systemSoundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(urlCF, &systemSoundID)
//        AudioServicesDisposeSystemSoundID(systemSoundID)
        // 二. 开始播放
        if isAlert {
            // 3. 带振动播放, 可以监听播放完成(模拟器不行)
            AudioServicesPlayAlertSound(systemSoundID)
        }else {
            // 3. 不带振动播放, 可以监听播放完成
            AudioServicesPlaySystemSound(systemSoundID)
        }
        playFinish()
        
    }
    
    //第二种使用AVAudioPlayer播放
    // 获取音频会话
    let session = AVAudioSession.sharedInstance()
    var player: AVAudioPlayer?
    var currentURL : NSURL?
    let playFinish = "playFinsh"
    
    var filePaths : [String]?
    var loopMode : Bool = false
    var loopModeIndex : NSInteger = 0
    
    override init() {
        super.init()
        do{
            //  设置会话类别
            try session.setCategory(AVAudioSession.Category.playback)
            //  激活会话
            try session.setActive(true)
        }catch {
            print(error)
            return
        }
    }
    
    func loopModeToPlay(filePaths:[String]!){
        self.filePaths = filePaths
        self.loopMode = true
        self.loopModeIndex = 0
        let filePath = self.filePaths![self.loopModeIndex]
        self.playMusic(filePath: filePath)
    }
    
    //paly music
    func playMusic(filePath: String) {
        guard let url = NSURL(string: filePath) else {
            return//url不存在
        }
        do{
            //AVAudioSessionCategoryPlayback扬声器模式
            try session.setCategory(AVAudioSession.Category.playback)
        }catch {
            print(error)
            return
        }
       //如果播放的音乐与之前的一样，则继续播放
        if currentURL == url {
            player?.play()
            return
        }
        do {
            player = try AVAudioPlayer(data: FileManager.default.contents(atPath: filePath)!)
            currentURL = url
            player?.delegate = self
            //开启红外感知功能
//            UIDevice.currentDevice().proximityMonitoringEnabled = true
//            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(proxumityStateChange), name: "UIDeviceProximityStateDidChangeNotification", object: nil)
            player?.prepareToPlay()
            player?.play()
            print("播放成功，文件路径 ==\(url)")
        }catch {
            print(error)
            return
        }
    }
    
    // 暂停当前歌曲/pause current music
    func pauseCurrentMusic() -> () {
        player?.pause()
    }
    
    // 继续播放当前歌曲/continue to play current music
    func resumeCurrentMusic() -> () {
        player?.play()
    }
    
    // 播放到指定时间/play music to specified time
    func seekToTime(time: TimeInterval) -> () {
        player?.currentTime = time
    }
    
    
    class func getFormatTime(timeInterval: TimeInterval) -> String {
        let min = Int(timeInterval) / 60
        let sec = Int(timeInterval) % 60
        let timeStr = String(format: "%02d:%02d", min, sec)
        return timeStr
    }
    
    class func getTimeInterval(formatTime: String) -> TimeInterval {
        // 00:00.89 == formatTime
        let minSec = formatTime.components(separatedBy: ":")
        if minSec.count == 2 {
            let min = TimeInterval(minSec[0]) ?? 0
            let sec = TimeInterval(minSec[1]) ?? 0
            return min * 60 + sec
        }
        return 0
    }
}

extension AudioHelper: AVAudioPlayerDelegate {
    //播放完成后的回调
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("播放完成")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: playFinish), object: nil)
        
        if (self.filePaths != nil) {
            if self.loopModeIndex == self.filePaths!.count - 1 {
                self.loopModeIndex = 0;
            }else{
                self.loopModeIndex += 1
            }
            let path = self.filePaths![self.loopModeIndex]
            self.playMusic(filePath: path)
        }else{
            self.currentURL = nil
        }
    }
}

