//
//  SearchUserDetailsVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/19.
//

import UIKit
import OpenIMSDKiOS
import OpenIMUI
import Foundation

class SearchUserDetailsVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        switch param {
        case let uid as String:
//            _ = rxRequest(showLoading: true, action: { OIMManager.getUsers(uids: [uid], callback: $0) })
//                .subscribe(onSuccess: { array in
//                    super.show(param: array.first, callback: callback)
//                })
            OpenIMiOSSDK.shared().getUsersInfo([uid]) { array in
                DispatchQueue.main.async {
                    super.show(param: array.first, callback: callback)
                }
            } onError: { code, msg in
                
            }

        case is UserInfo:
            super.show(param: param, callback: callback)
        default:
            fatalError()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        refreshUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onFriendApplicationListAcceptNotification(_:)),
                                               name: NSNotification.Name("OUIKit.onFriendApplicationListAcceptNotification"),
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var accountLabel: UILabel!
    
    lazy var model: UserInfo = {
        assert(param is UserInfo)
        return param as! UserInfo
    }()
    
    private func bindAction() {
        let layer = contentView.superview!.layer
        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.14).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        
        accountLabel.rx.tapGesture()
            .when(.ended)
            .subscribe(onNext: { [unowned self] _ in
                UIPasteboard.general.string = self.model.uid
                MessageModule.showMessage(LocalizedString("The account has been copied!"))
            })
            .disposed(by: disposeBag)
    }
    
    private func refreshUI() {
        avatarImageView.setImage(with: model.icon,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = model.name
        accountLabel.text = LocalizedString("Account:") + model.uid!
        
        if model.uid == AccountManager.shared.model.userInfo.uid {
            button.eec_collapsed = true
            return
        }
        
        button.eec_collapsed = false
        if model.flag == 1 {
            button.setTitle(" " + LocalizedString("Chat"), for: .normal)
            button.setImage(UIImage(named: "friend_detail_icon_msg"), for: .normal)
        } else {
            button.setTitle(" " + LocalizedString("Add friend"), for: .normal)
            button.setImage(UIImage(named: "friend_detail_icon_add"), for: .normal)
        }
    }
    
    @IBOutlet var button: UIButton!
    @IBAction func btnAction() {
        if model.flag == 1 {
            EEChatVC.show(uid: model.uid!, groupID: "")
            return
        }
        
//        let param = OIMFriendAddApplication(uid: model.uid, reqMessage: "")
//        rxRequest(showLoading: true, action: { OIMManager.addFriend(param, callback: $0) })
//            .subscribe(onSuccess: { _ in
//                MessageModule.showMessage(LocalizedString("Sent friend request"))
//            })
//            .disposed(by: disposeBag)
        OpenIMiOSSDK.shared().addFriend(model.uid!, reqMessage: "") { msg in
            DispatchQueue.main.async {
                MessageModule.showMessage(LocalizedString("Sent friend request"))
            }
        } onError: { code, msg in
            
        }

    }
    
    @objc
    func onFriendApplicationListAcceptNotification(_ notification: Notification) {
        guard let user = notification.object as? UserInfo else {
            return
        }
        if self.model == user {
            self.model.flag = 1
            refreshUI()
        }
    }
}
