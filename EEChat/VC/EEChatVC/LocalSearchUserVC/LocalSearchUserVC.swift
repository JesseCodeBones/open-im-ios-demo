//
//  LocalSearchUserVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/22.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import OpenIMSDKiOS
import OpenIMUI

class LocalSearchUserVC: BaseViewController {

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    @IBOutlet var textField: UITextField!
    
    lazy var relay = BehaviorRelay<[SectionModel<String, Any>]>(value: [])
    private var conversationList: [ConversationInfo] = []
    
    private func bindAction() {
        switch param {
        case nil:
            title = LocalizedString("Search")
            tableView.rx.modelSelected(Any.self)
                .subscribe(onNext: { model in
                    switch model {
                    case let model as UserInfo:
                        SearchUserDetailsVC.show(param: model.uid)
                    case let model as ConversationInfo:
                        if !model.userID!.isEmpty {
                            SearchUserDetailsVC.show(param: model.userID)
                        } else {
                            GroupProfileVC.show(param: model.groupID)
                        }
                    default:
                        break
                    }
                })
                .disposed(by: disposeBag)
        case let message as MessageType:
            title = LocalizedString("Select")
            tableView.rx.modelSelected(Any.self)
                .subscribe(onNext: { [unowned self] model in
                    self.forward(model: model, messages: [message])
                })
                .disposed(by: disposeBag)
        case let messages as [MessageType]:
            title = LocalizedString("Select")
            tableView.rx.modelSelected(Any.self)
                .subscribe(onNext: { [unowned self] model in
                    self.forward(model: model, messages: messages)
                })
                .disposed(by: disposeBag)
        default:
            fatalError()
        }
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Any>>(
            configureCell: { _, tv, _, element in
                let cell = tv.dequeueReusableCell(withIdentifier: "cell")! as! LocalSearchUserCell
                cell.model = element

                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                dataSource[sectionIndex].model
            },
            canMoveRowAtIndexPath: { _, _ in
                return false
            }
        )
        
        relay
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
//        OIMManager.getConversationList { [weak self] result in
//            guard let self = self else { return }
//            if case let .success(array) = result {
//                self.conversationList = array
//                self.reload(users: [])
//            }
//        }
        
        OpenIMiOSSDK.shared().getAllConversationList { [weak self] array in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.conversationList = array
                self.reload(users: [])
            }
        } on: { code, msg in
            
        }

        
        textField.rx.text
            .skip(1)
            .debounce(DispatchTimeInterval.microseconds(500), scheduler: MainScheduler.instance)
            .startWith("")
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                
                if let key = text?.lowercased(), key != "" {
//                    OIMManager.getFriendList { result in
//                        if case let .success(array) = result {
//                            let user = array.filter {
//                                $0.name.range(of: key, options: .caseInsensitive) != nil
//                                    || $0.comment.range(of: key, options: .caseInsensitive) != nil
//                            }
//                            self.reload(users: user)
//                        }
//                    }
                    OpenIMiOSSDK.shared().getFriendList { array in
                        let user = array.filter {
                            $0.name!.range(of: key, options: .caseInsensitive) != nil
                            || $0.comment!.range(of: key, options: .caseInsensitive) != nil
                        }
                        DispatchQueue.main.async {
                            self.reload(users: user)
                        }
                    } onError: { code, msg in
                        
                    }

                } else {
                    DispatchQueue.main.async {
                        self.reload(users: [])
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func reload(users: [UserInfo]) {
        var array: [SectionModel<String, Any>] = [SectionModel(model: "", items: users as [Any])]
        if conversationList.count > 0 {
            array.append(SectionModel(model: LocalizedString("Recent Session"), items: conversationList as [Any]))
        }
        relay.accept(array)
    }
    
    private func forward(model: Any, messages: [MessageType]) {
        let (uid, groupID, name): (String, String, String) = {
            switch model {
            case let model as UserInfo:
                return (model.uid!, "", model.name!)
            case let model as ConversationInfo:
                return (model.userID!, model.groupID!, model.showName!)
            default:
                fatalError()
            }
        }()
        UIAlertController.show(title: String(format: LocalizedString("Send to %@?"), name),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
                for message in messages {

                }
                MessageModule.showMessage(LocalizedString("Sent"))
            }
        }
    }
}
