//
//  AlbumListBottomTableViewCell.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/30.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit

class AlbumListBottomTableViewCell: UITableViewCell, AlbumListCellType {

    var artworkImageView: UIImageView?

    var albumNameLabel: UILabel?

    @IBOutlet weak var trackNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        selectionStyle = .none
        clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
