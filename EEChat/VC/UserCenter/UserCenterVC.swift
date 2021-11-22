//
//  UserCenterVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/8.
//

import UIKit
import Kingfisher
import RxSwift
import OpenIMSDKiOS

class UserCenterVC: BaseViewController {

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var accountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        refresh()
    }
    
    private func bindAction() {
        
        accountLabel.rx.tapGesture()
            .when(.ended)
            .subscribe(onNext: { _ in
                UIPasteboard.general.string = AccountManager.shared.model.userInfo.uid
                MessageModule.showMessage(LocalizedString("The account has been copied!"))
            })
            .disposed(by: disposeBag)
    }
    
    private func refresh() {
        let userInfo = AccountManager.shared.model.userInfo
        avatarImageView.setImage(with: userInfo.icon,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = userInfo.name
        accountLabel.text = LocalizedString("Account:") + userInfo.uid!
    }
    
    // MARK: - Action
    
    @IBAction func changeAvatarAction() {
        PhotoModule.shared.showPicker(allowTake: true,
                                       allowCrop: true,
                                       cropSize: CGSize(width: 200, height: 200))
        { [unowned self] (image, asset) in
            var icon = ""
            QCloudModule.shared.upload(prefix: "chat/avatar", files: [image])
                .flatMap { (paths) -> Single<Void> in
                    icon = paths[0]
//                    return rxRequest(showLoading: true) { OIMManager.setSelfInfo([.icon: icon], callback: $0) }
                    return Single<Void>.create { single in
                        OpenIMiOSSDK.shared().setSelfInfo("", icon: icon, gender: 0, mobile: "", birth: "", email: "") { msg in
                            
                        } onError: { code, msg in
                            
                        }
                        
                        return Disposables.create()

                    }
                }
                .subscribe(onSuccess: { resp in
                    AccountManager.shared.model.userInfo.icon = icon
                    MessageModule.showMessage(LocalizedString("Modify the success"))
                    self.refresh()
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    @IBAction func changeNickNameAction() {
        UIAlertController.show(title: LocalizedString("Modify the nickname"),
                               message: nil,
                               text: AccountManager.shared.model.userInfo.name,
                               placeholder: LocalizedString("Please enter a nickname"))
        { [unowned self] (text) in
//            rxRequest(showLoading: true) { OIMManager.setSelfInfo([.name: text], callback: $0) }
//                .subscribe(onSuccess: { _ in
//                    AccountManager.shared.model.userInfo.name = text
//                    MessageModule.showMessage(LocalizedString("Modify the success"))
//                    self.refresh()
//                })
//                .disposed(by: self.disposeBag)
            OpenIMiOSSDK.shared().setSelfInfo(text, icon: nil, gender: nil, mobile: nil, birth: nil, email: nil) { msg in
                DispatchQueue.main.async {
                    AccountManager.shared.model.userInfo.name = text
                    MessageModule.showMessage(LocalizedString("Modify the success"))
                    self.refresh()
                }
            } onError: { code, msg in
                
            }
        }
    }
    
    @IBAction func blacklistAction() {
        BlacklistVC.show()
    }

    @IBAction func logoutAction() {
        UIAlertController.show(title: LocalizedString("Are you sure to log out?"),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
                AccountManager.shared.logout()
            }
        }
    }
    
    @IBAction func notificationSettingAction() {
        NotificationSettingVC.show()
    }
}
