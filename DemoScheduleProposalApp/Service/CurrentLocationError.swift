import Foundation

enum CurrentLocationError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied:
            return "現在地を利用できません。設定でこのアプリの位置情報を許可してから再試行してください。"
        case .unavailable:
            return "現在地を取得できませんでした。場所や通信環境を確認して再試行してください。"
        }
    }
}
