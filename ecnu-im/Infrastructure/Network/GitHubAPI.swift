import Foundation

let gitHubProvider = APIProvider<GitHub>()

enum GitHub {
    case zen
    case userProfile(String)
    case userRepositories(String)
}

extension GitHub: TargetType {
    public var baseURL: URL { URL(string: "https://api.github.com")! }
    public var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name.urlEscaped)"
        case .userRepositories(let name):
            return "/users/\(name.urlEscaped)/repos"
        }
    }

    public var method: HTTPMethod { .get }

    public var task: RequestTask {
        switch self {
        case .userRepositories:
            return .requestParameters(parameters: ["sort": "pushed"], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }

    public var headers: [String: String]? { nil }
}
