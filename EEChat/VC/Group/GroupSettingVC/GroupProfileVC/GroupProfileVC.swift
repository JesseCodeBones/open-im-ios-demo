//
//  GroupProfileVC.swift
//  EEChat
//
//  Created by Snow on 2021/7/8.
//

import UIKit
import RxSwift
import OpenIMSDKiOS

class GroupProfileVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        assert(param is String)
        let groupID = param as! String
//        let uid = OIMManager.getLoginUser()
        let uid = OpenIMiOSSDK.shared().getLoginUid()
//        _ = rxRequest(showLoading: true, action: { OIMManager.getGroupsInfo(gids: [groupID], callback: $0) })
//            .subscribe(onSuccess: { array in
//                guard let groupInfo = array.first else {
//                    MessageModule.showError("The group was not found")
//                    return
//                }
//                _ = rxRequest(showLoading: true,
//                              showError: false,
//                              action: { OIMManager.getGroupMembersInfo(gid: groupID,
//                                                                       uids: [uid],
//                                                                       callback: $0) })
//                    .subscribe(onSuccess: { members in
//                        super.show(param: (groupInfo, members.first?.role), callback: callback)
//                    }, onFailure: { error in
//                        let role: OIMGroupRole? = nil
//                        super.show(param: (groupInfo, role), callback: callback)
//                    })
//            })
        OpenIMiOSSDK.shared().getGroupsInfo([groupID]) { array in
            guard let groupInfo = array.first else {
                DispatchQueue.main.async {
                    MessageModule.showError("The group was not found")
                }
                return
            }
            
            OpenIMiOSSDK.shared().getGroupMembersInfo(groupID, uidList: [uid]) { members in
                DispatchQueue.main.async {
                    super.show(param: (groupInfo, members.first?.role), callback: callback)
                }
            } onError: { code, msg in
                let role: GroupMemberRole? = nil
                DispatchQueue.main.async {
                    super.show(param: (groupInfo, role), callback: callback)
                }
            }

        } onError: { code, msg in
            
        }

    }
    
    var role: GroupMemberRole?
    var groupInfo: GroupInfo!

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var idLabel: UILabel!
    
    @IBOutlet var textView: QMUITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        refreshUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func bindAction() {
        assert(param is (GroupInfo, GroupMemberRole?))
        (groupInfo, role) = param as! (GroupInfo, GroupMemberRole?)
        textView.eec.autoHeight(minHeight: 200)
            .disposed(by: disposeBag)
        textView.returnKeyType = .done
        textView.delegate = self
        
        switch role {
        case .none:
            modifyBtn.setTitle("Add group chat", for: .normal)
        case .some(let value):
            if value.setRole == 0 {
                modifyBtn.eec_collapsed = true
            }
        }
    }
    
    private func refreshUI(needCallback: Bool = false) {
        avatarImageView.setImage(with: groupInfo.faceUrl,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = groupInfo.groupName
        idLabel.text = "Group number：" + groupInfo.groupID!
        textView.text = groupInfo.introduction
        if needCallback {
            callback?(groupInfo!)
        }
    }
    
    @IBAction func copyIDAction() {
        UIPasteboard.general.string = groupInfo.groupID
        MessageModule.showMessage(LocalizedString("The group number has been copied!"))
    }
    
    @IBOutlet var modifyBtn: UIButton!
    @IBAction func modifyAction() {
        if role == nil {
            let groupID = groupInfo.groupID!
//            rxRequest(showLoading: true, action: { OIMManager.joinGroup(gid: groupID, message: "", callback: $0) })
//                .subscribe(onSuccess: {
//                    MessageModule.showMessage("The application has been sent.")
//                })
//                .disposed(by: disposeBag)
            OpenIMiOSSDK.shared().joinGroup(groupID, reason: "") { msg in
                DispatchQueue.main.async {
                    MessageModule.showMessage("The application has been sent.")
                }
            } onError: { code, msg in
                
            }

            return
        }
        
        UIAlertController.show(title: "Modify group data",
                               message: nil,
                               buttons: [
                                "Group chat name",
                                "Group portrait",
                                "Group Introduction",
                               ],
                               cancel: "cancel")
        { [unowned self] index in
            switch index {
            case 1:
                modifyGroupName()
            case 2:
                modifyAvatar()
            case 3:
                textView.isEditable = true
                textView.becomeFirstResponder()
            default:
                break
            }
        }
    }
    
    func modifyAvatar() {
        PhotoModule.shared.showPicker(type: .image,
                                      allowTake: true,
                                      allowCrop: true,
                                      cropSize: CGSize(width: 100, height: 100))
        { image, _ in
            var icon = ""
            QCloudModule.shared.upload(prefix: "chat/group/avatar", files: [image]).subscribe(onSuccess: { [unowned self] paths in
                icon = paths[0]
//                    let param = OIMGroupInfoParam(groupInfo: groupInfo,
//                                                  faceUrl: icon)
//                    return rxRequest(showLoading: true, action: { OIMManager.setGroupInfo(param, callback: $0) })
                OpenIMiOSSDK.shared().setGroupInfo(groupInfo.groupID!, groupName: groupInfo.groupName!, notification: groupInfo.notification!, introduction: groupInfo.introduction!, faceUrl: icon) { msg in
                    DispatchQueue.main.async {
                        MessageModule.showMessage(LocalizedString("Modify the success"))
                        self.groupInfo.faceUrl = icon
                        self.refreshUI(needCallback: true)
                    }
                } onError: { code, msg in
                    
                }
            }, onFailure: { err in
                
            }, onDisposed: {
                
            }).disposed(by: self.disposeBag)
//                .flatMap { [unowned self] (paths) -> Single<Void> in
//                    icon = paths[0]
////                    let param = OIMGroupInfoParam(groupInfo: groupInfo,
////                                                  faceUrl: icon)
////                    return rxRequest(showLoading: true, action: { OIMManager.setGroupInfo(param, callback: $0) })
//                    OpenIMiOSSDK.shared().setGroupInfo(groupInfo.groupID!, groupName: groupInfo.groupName!, notification: groupInfo.notification!, introduction: groupInfo.introduction!, faceUrl: icon) { msg in
//                        MessageModule.showMessage(LocalizedString("Modify the success"))
//                        self.groupInfo.faceUrl = icon
//                        self.refreshUI(needCallback: true)
//                    } onError: { code, msg in
//
//                    }
//                }
//                .subscribe(onSuccess: { resp in
////                    MessageModule.showMessage(LocalizedString("Modify the success"))
////                    self.groupInfo.faceUrl = icon
////                    self.refreshUI(needCallback: true)
//                })
//                .disposed(by: self.disposeBag)
        }
    }
    
    func modifyGroupName() {
        let groupInfo = self.groupInfo!
        UIAlertController.show(title: "Change the group name?",
                               message: nil,
                               text: groupInfo.groupName,
                               placeholder: "") { text in
//            let param = OIMGroupInfoParam(groupInfo: groupInfo,
//                                          groupName: text)
//            rxRequest(showLoading: true, action: { OIMManager.setGroupInfo(param, callback: $0) })
//                .subscribe(onSuccess: {
//                    MessageModule.showMessage("Group name modification successful.")
//                    self.groupInfo.groupName = text
//                    self.refreshUI(needCallback: true)
//                })
//                .disposed(by: self.disposeBag)
            OpenIMiOSSDK.shared().setGroupInfo(groupInfo.groupID!, groupName: text, notification: groupInfo.notification!, introduction: groupInfo.introduction!, faceUrl: groupInfo.faceUrl!) { msg in
                DispatchQueue.main.async {
                    MessageModule.showMessage("Group name modification successful.")
                    self.groupInfo.groupName = text
                    self.refreshUI(needCallback: true)
                }
            } onError: { code, msg in
                
            }
        }
    }
    
    func modifyIntroduction() {
        view.endEditing(true)
        let introduction = textView.text!
//        let param = OIMGroupInfoParam(groupInfo: groupInfo,
//                                      introduction: introduction)
//        rxRequest(showLoading: true, action: { OIMManager.setGroupInfo(param, callback: $0) })
//            .subscribe(onSuccess: { [unowned self] in
//                MessageModule.showMessage("Modify the introduction successfully.")
//                self.textView.isEditable = false
//                self.groupInfo.introduction = introduction
//                self.refreshUI(needCallback: true)
//            })
//            .disposed(by: self.disposeBag)
        OpenIMiOSSDK.shared().setGroupInfo(groupInfo.groupID!, groupName: groupInfo.groupName!, notification: groupInfo.notification!, introduction: introduction, faceUrl: groupInfo.faceUrl!) { msg in
            DispatchQueue.main.async {
                MessageModule.showMessage("Modify the introduction successfully.")
                self.textView.isEditable = false
                self.groupInfo.introduction = introduction
                self.refreshUI(needCallback: true)
            }
        } onError: { code, msg in
            
        }
    }
}

extension GroupProfileVC: QMUITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            modifyIntroduction()
            return false
        }
        return true
    }
}
