//
//  TodayViewController.swift
//  iTunesMusicPlayerWidget
//
//  Created by 林達也 on 2016/09/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import NotificationCenter
import iTunesMusic
import RxSwift
import MediaPlayer
import MMWormhole


let appGroupIdentifier = "group.jp.sora0077.itunesmusic"



final class NowPlayingInfo: NSCoding {

    let title: String
    let albumTitle: String
    let artistName: String
    let trackId: Int
    let artworkImage: UIImage?

    init?(dict: [String: Any]) {
        guard
            let title = dict[MPMediaItemPropertyTitle] as? String,
            let albumTitle = dict[MPMediaItemPropertyAlbumTitle] as? String,
            let artistName = dict[MPMediaItemPropertyArtist] as? String,
            let trackId = dict["currentTrackId"] as? Int
            else {
                return nil
        }
        self.title = title
        self.albumTitle = albumTitle
        self.artistName = artistName
        self.trackId = trackId
        self.artworkImage = dict["artworkImage"] as? UIImage
    }

    init?(coder aDecoder: NSCoder) {

        guard
            let title = aDecoder.decodeObject(forKey: MPMediaItemPropertyTitle) as? String,
            let albumTitle = aDecoder.decodeObject(forKey: MPMediaItemPropertyAlbumTitle) as? String,
            let artistName = aDecoder.decodeObject(forKey: MPMediaItemPropertyArtist) as? String
            else {
                return nil
        }

        self.title = title
        self.albumTitle = albumTitle
        self.artistName = artistName
        self.trackId = aDecoder.decodeInteger(forKey: "currentTrackId")
        self.artworkImage = aDecoder.decodeObject(forKey: "artworkImage") as? UIImage
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: MPMediaItemPropertyTitle)
        aCoder.encode(albumTitle, forKey: MPMediaItemPropertyAlbumTitle)
        aCoder.encode(artistName, forKey: MPMediaItemPropertyArtist)
        aCoder.encode(trackId, forKey: "currentTrackId")
        aCoder.encode(artworkImage, forKey: "artworkImage")
    }
}


class TodayViewController: UIViewController, NCWidgetProviding {

    private lazy var genres = Model.Genres()

    private let disposeBag = DisposeBag()

    private let wormhole = MMWormhole(applicationGroupIdentifier: "group.jp.sora0077.itunesmusic", optionalDirectory: "wormhole")

    @IBOutlet weak var label: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.

        launch(with: LaunchOptions(location: .group("group.jp.sora0077.itunesmusic")))

        wormhole.listenForMessage(withIdentifier: "playerWidgetNeedsUpdating") { [weak self] info in
            print(info)
            let info = info as? [String: Any]
            self?.label.text = info?[MPMediaItemPropertyTitle] as? String

        }

        wormhole.passMessageObject(nil, identifier: "playerWidgetDidFinishLaunching")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let info = wormhole.message(withIdentifier: "playerWidgetNeedsUpdating") as? [String: Any]
        label.text = info?[MPMediaItemPropertyTitle] as? String

        print("widgwt-- ", wormhole.message(withIdentifier: "playerWidgetNeedsUpdating") as? [String: NSCoding])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.newData)
    }

    @IBAction func buttonAction(_ sender: AnyObject) {
        wormhole.passMessageObject(nil, identifier: "aaa")
    }
}
