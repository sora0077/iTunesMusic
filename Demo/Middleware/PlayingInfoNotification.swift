//
//  PlayingInfoNotification.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/28.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import UserNotifications
import iTunesMusic


final class PlayingInfoNotification: PlayerMiddleware {

    static func shouldHandle(_ notification: UNNotification) -> UNNotificationPresentationOptions? {
        if notification.request.identifier == "PlayingInfoNotification" {
            return .alert
        }
        return nil
    }

    func willStartPlayTrack(_ trackId: Int) {
        guard let track = Model.Track(trackId: trackId).entity else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = track.name
        content.subtitle = track.artist.name
        content.body = track.collection.name
        content.userInfo = ["trackId": track.id]

        let request = UNNotificationRequest(
            identifier: "PlayingInfoNotification",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))

        UNUserNotificationCenter.current().add(request)
    }
}
