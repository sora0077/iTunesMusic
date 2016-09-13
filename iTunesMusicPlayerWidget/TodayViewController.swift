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


class TodayViewController: UIViewController, NCWidgetProviding {

    private var track: Model.Track? {
        didSet {
            DispatchQueue.main.async {
                self.updateView()
            }
        }
    }

    private let disposeBag = DisposeBag()

    private let wormhole = MMWormhole(applicationGroupIdentifier: "group.jp.sora0077.itunesmusic", optionalDirectory: "wormhole")

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!


    private func updateView() {
        if let track = track?.track {
            artworkImageView.setArtwork(of: track, size: 100)
        } else {
            artworkImageView.image = nil
        }
        label.text = track?.track?.name
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.

        launch(with: LaunchOptions(location: .group("group.jp.sora0077.itunesmusic")))

        wormhole.listenForMessage(withIdentifier: "playerWidgetNeedsUpdating") { [weak self] info in
            print(info)
            let info = info as? [String: Any]
            let trackId = info?["currentTrackId"] as? Int
            self?.track = trackId.map(Model.Track.init)
        }

        wormhole.passMessageObject(nil, identifier: "playerWidgetDidFinishLaunching")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let info = wormhole.message(withIdentifier: "playerWidgetNeedsUpdating") as? [String: Any]
        let trackId = info?["currentTrackId"] as? Int
        track = trackId.map(Model.Track.init)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.newData)
    }
}
