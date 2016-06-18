//: Playground - noun: a place where people can play

import UIKit
import iTunesMusic
import APIKit
import RealmSwift
import XCPlayground

let when = { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * Double(NSEC_PER_SEC))) }

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

let history = History.instance
history.changes.subscribe { changes in
    print("first", changes)
}

for h in history {
    
}

class RootViewController: UIViewController {
    
    let playingTrackViewController = PlayingTrackViewController(player: iTunesMusic.player)
    let historyViewController = HistoryViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(historyViewController)
        view.addSubview(historyViewController.view)
        historyViewController.didMoveToParentViewController(self)
        
        historyViewController.tableView.contentInset.top = 50
        
        addChildViewController(playingTrackViewController)
        view.addSubview(playingTrackViewController.view)
        playingTrackViewController.didMoveToParentViewController(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playingTrackViewController.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
    }
}

class PlayingTrackViewController: UIViewController {
 
    let titleLabel = UILabel()
    
    let timeLabel = UILabel()
    
    let player: Player
    
    init(player: Player) {
        
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor.whiteColor()
        timeLabel.textColor = UIColor.whiteColor()
        
        player.nowPlaying.subscribeNext { [weak self] track in
            guard let `self` = self else { return }
            
            self.titleLabel.text = track?.trackName
        }
        
        player.currentTime.subscribeNext { [weak self] time in
            guard let `self` = self else { return }
            
            self.timeLabel.text = String(format: "%.2f", time)
            self.timeLabel.sizeToFit()
            self.timeLabel.frame.origin.x = self.view.frame.width - self.timeLabel.frame.width
        }
        
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        view.addSubview(titleLabel)
        view.addSubview(timeLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        titleLabel.frame = view.bounds
        
    }
}


class HistoryViewController: UIViewController, UITableViewDataSource {
    
    let history = History.instance
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        history.changes.subscribeNext { [weak self] changes in
            guard let `self` = self else { return }
            
            switch changes {
            case .Initial:
                self.tableView.reloadData()
            case let .Update(deletions: deletions, insertions: insertions, modifications: modifications):
                self.tableView.beginUpdates()
                
                func indexPaths(values: [Int]) -> [NSIndexPath] {
                    return values.map { NSIndexPath(forRow: $0, inSection: 0) }
                }
                
                self.tableView.deleteRowsAtIndexPaths(indexPaths(deletions), withRowAnimation: .Automatic)
                self.tableView.insertRowsAtIndexPaths(indexPaths(insertions), withRowAnimation: .Automatic)
                self.tableView.reloadRowsAtIndexPaths(indexPaths(modifications), withRowAnimation: .Automatic)
                
                self.tableView.endUpdates()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let (track, createAt) = history.record(atIndex: indexPath.row)
        
        cell.textLabel?.text = track.trackName
        cell.detailTextLabel?.text = "\(createAt)"
        
        return cell
    }
}

let search = Search(term: "ジョーカー・ゲーム DOUBLE")

search.addInto(player: player)
history.addInto(player: player)
//

XCPlaygroundPage.currentPage.liveView = RootViewController()
