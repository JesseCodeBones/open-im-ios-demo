//
//  Message.swift
//  OpenIM
//
//  Created by Snow on 2021/5/11.
//

import Foundation
import OpenIMSDKiOS

public enum ContentType: CustomStringConvertible {
    case text(String)
    case image(ImageItem)
    case audio(AudioItem)
    case video(VideoItem)
    case system(Int, SystemItem)
    case unknown(Int, String)
    
    public var description: String {
        switch self {
        case .text(let text):
            return text
        case .image:
            return "[Image]"
        case .audio:
            return "[Audio]"
        case .video:
            return "[Video]"
        case .system(_, let item):
            return item.isDisplay != 0 ? item.defaultTips : ""
        case .unknown:
            return "[Unknown]"
        }
    }
}

public struct ImageItem: Codable, Hashable {
    public let url: URL?
    public let thumbnail: URL?
    
    public let width: Int
    public let height: Int
    
    public init(url: URL?, thumbnail: URL?, width: Int, height: Int) {
        self.url = url
        self.thumbnail = thumbnail
        self.width = width
        self.height = height
    }
}

public struct VideoItem: Codable, Hashable {
    public let url: URL?
    public let thumbnail: URL?
    
    public let width: Int
    public let height: Int
    
    public let duration: TimeInterval
    
    public init(url: URL?, thumbnail: URL?, width: Int, height: Int, duration: TimeInterval) {
        self.url = url
        self.thumbnail = thumbnail
        self.width = width
        self.height = height
        self.duration = duration
    }
}

public struct AudioItem: Codable {
    public let url: URL?
    public let duration: Int
    
    public init(url: URL?, duration: Int) {
        self.url = url
        self.duration = duration
    }
}

public struct SystemItem: Codable {
    public let isDisplay: Int
    public let defaultTips: String
    public let detail: String
}

public class MessageType: Hashable {
    
    public enum Status: UInt16, Codable {
        case none
        case sending
        case failure
        case success
        
        case deleted
        case imported
        case revoked
    }
    
    public var messageId: String
    
    public let userID: String
    public let groupID: String
    
    public var content: ContentType
    
    public let isSelf: Bool
    
    public let sendID: String
    
    public let sendTime: TimeInterval
    
    public var status: Status
    
    public var isRead: Bool
    
    public var at: [String] = []
    
    public let innerMessage: Message
    
    public var isDisplay: Bool {
        if case let ContentType.system(_, item) = content {
            if item.isDisplay == 0 {
                return false
            }
        }
        return true
    }
    
    public var isSystem: Bool {
        if case ContentType.system = content {
            return true
        }
        return false
    }
    
    public static func == (lhs: MessageType, rhs: MessageType) -> Bool {
        return lhs.userID == rhs.userID && lhs.groupID == rhs.groupID && lhs.messageId == rhs.messageId
    }
    
    public func hash(into hasher: inout Hasher) {
        userID.hash(into: &hasher)
        groupID.hash(into: &hasher)
        messageId.hash(into: &hasher)
    }
    
    public init(message: Message) {
        innerMessage = message
        messageId = (message.serverMsgID != "" ? message.serverMsgID : message.clientMsgID) ?? ""
        sendTime = TimeInterval(message.sendTime != 0 ? message.sendTime : message.createTime)
        let loginUID = OpenIMiOSSDK.shared().getLoginUid()
        isSelf = message.sendID == loginUID
        sendID = message.sendID ?? ""
        if message.groupID!.isEmpty {
            let uid = isSelf ? message.recvID : message.sendID
            userID = uid!
        } else {
            userID = ""
        }
        groupID = message.groupID!
        
        if isSelf {
            switch message.status {
            case 0:
                status = .none
            case 3:
                status = .failure
            case 1:
                status = .sending
            case 2:
                status = .success
            default:
                status = .success
            }
        } else {
            status = .success
        }
        
        isRead = message.isRead
        
        func getURL(_ path: String, url: String) -> URL? {
            if url != "" {
                return URL(string: url)
            }
            return URL(fileURLWithPath: path)
        }
        
        switch message.contentType {
        case 101:
            content = ContentType.text(message.content!)
        case 106:
            content = ContentType.text(message.atElem!.text!)
            at = message.atElem!.atUserList!
        case 102:
            let data = message.pictureElem
            let url = getURL(data!.sourcePath ?? "", url: data!.sourcePicture?.url ?? "")
            let thumbnail = getURL(data!.sourcePath ?? "", url: data!.snapshotPicture?.url ?? "")
            let item = ImageItem(url: url,
                                 thumbnail: thumbnail,
                                 width: Int((data!.sourcePicture?.width ?? 0)),
                                 height: Int(data!.sourcePicture?.height ?? 0))
            content = .image(item)
        case 103:
            let data = message.soundElem
            let url = getURL(data!.soundPath!, url: data!.sourceUrl!)
            let item = AudioItem(url: url, duration: data!.duration)
            content = .audio(item)
        case 104:
            let data = message.videoElem
            let url = getURL(data!.videoPath!, url: data!.videoUrl!)
            let thumbnail = getURL(data!.snapshotPath!, url: data!.snapshotUrl!)
            let item = VideoItem(url: url,
                                 thumbnail: thumbnail,
                                 width: Int(exactly: data!.snapshotWidth)!,
                                 height: Int(exactly: data!.snapshotHeight)!,
                                 duration: TimeInterval(data!.duration))
            content = .video(item)
        default:
            if message.contentType >= 200 {
                let item: SystemItem
                do {
                    item = try JSONDecoder().decode(SystemItem.self, from: message.content!.data(using: .utf8)!)
                } catch {
                    item = SystemItem(isDisplay: 1, defaultTips: message.content!, detail: "")
                }
                content = ContentType.system(Int(message.contentType), item)
            } else {
                content = ContentType.unknown(Int(message.contentType), message.content!)
            }
        }
    }
}

extension Message {
    public func toUIMessage() -> MessageType {
        return MessageType(message: self)
    }
}
