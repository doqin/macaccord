import Foundation
import SwiftUI
import Combine
import Compression
import Collections
import OSLog

// MARK: - Structs and stuff
struct DiscordEvent<D: Codable>: Codable {
    let t: String?
    let s: Int?
    let op: Int
    let d: D?
}

struct HelloPayload: Codable {
    let heartbeat_interval: Int
}

struct PresenceUpdate: Codable {
    let user: PresenceUser
    let status: String
    // let activities: Activity
    // let guild_id: String
}

struct Ready: Codable {
    let users: [User]
    let user: User // That's you
    let guilds: [Guild]
}

struct ReadySupplemental: Codable {
    let merged_presences: MergedPresence
}

struct MergedPresence: Codable {
    let friends: [MergedPresence_Friend]
    // TODO: let guilds: [Guilds]
}

// This is so bullshit
struct MergedPresence_Friend: Codable {
    let status: String
    let user_id: String
    // let activities: [asdasd]
}

// tf is this api
struct PresenceUser: Codable {
    let id: String
}

struct TypingStart: Codable {
    let user_id: String
    let channel_id: String
}

// MARK: - Definitions
class DiscordWebSocket: NSObject, ObservableObject {
    
    @Published var ready: Bool = false
    
    // MARK: - Message Subject
    private let messageSubject = PassthroughSubject<(String, Message), Never>()

    func messagesPublisher(for channelId: String) -> AnyPublisher<Message, Never> {
        messageSubject
            .filter { $0.0 == channelId }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    func messagesPublisherFull() -> AnyPublisher<Message, Never> {
        messageSubject
            .map(\.1)
            .eraseToAnyPublisher()
    }
    
    func receiveMessage(channelId: String, message: Message) {
        messageSubject.send((channelId, message))
    }
    
    // MARK: - Guild Subject
    private let guildSubject = PassthroughSubject<(String, Guild), Never>()
    
    func guildPublisher(for guildId: String) -> AnyPublisher<Guild, Never> {
        guildSubject
            .filter { $0.0 == guildId }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    func guildPublisherFull() -> AnyPublisher<Guild, Never> {
        guildSubject
            .map(\.1)
            .eraseToAnyPublisher()
    }
    
    func receiveGuild(guildId: String, guild: Guild) {
        guildSubject.send((guildId, guild))
    }
    
    // MARK: - Typing Start Subject
    private let typingSubject = PassthroughSubject<(String, TypingStart), Never>()
    
    func typingStartPublisher(for channelId: String) -> AnyPublisher<TypingStart, Never> {
        typingSubject
            .filter { $0.0 == channelId }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    func receiveTypingStart(channelId: String, typingStart: TypingStart) {
        typingSubject.send((channelId, typingStart))
    }
    
    // MARK: - Presence Update Subject
    private let presenceUpdateSubject = PassthroughSubject<(String, PresenceUpdate), Never>()
    
    func presenceUpdatePublisher(for userId: String) -> AnyPublisher<PresenceUpdate, Never> {
        presenceUpdateSubject
            .filter { $0.0 == userId }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    func presenceUpdatePublisherFull() -> AnyPublisher<PresenceUpdate, Never> {
        presenceUpdateSubject
            .map(\.1)
            .eraseToAnyPublisher()
    }
    
    func receivePresenceUpdate(userId: String, presenceUpdate: PresenceUpdate) {
        presenceUpdateSubject.send((userId, presenceUpdate))
    }
    
    // MARK: - User Subject
    private let userSubject = PassthroughSubject<(String, User), Never>()
    
    func usersPublisher(for userId: String) -> AnyPublisher<User, Never> {
        userSubject
            .filter { $0.0 == userId}
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    func usersPublisherFull() -> AnyPublisher<User, Never> {
        userSubject
            .map(\.1)
            .eraseToAnyPublisher()
    }
    
    func receiveUser(userId: String, user: User) {
        userSubject.send((userId, user))
    }
        
    // MARK: - Variables
    
    @Published var isConnected: Bool = false
    private let messageLimit = 100
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var token: String?
    
    private var heartbeatInterval: TimeInterval = 0
    private var heartbeatTimer: Timer?
    private var lastHeartbeatAck: Date = Date()
    private var awaitingHeartbeatAck: Bool = false
    private var lastSequence: Int? = nil
    
    private var decoder: JSONDecoder = MessageDecoder.createDecoder()
    private var urlSession: URLSession!
    
    private var useCompression = false
    private var connectionAttempts = 0
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var isReconnecting = false
    
    // Pointer for the compression stream
    private var compressionStreamPointer: UnsafeMutablePointer<compression_stream>?
    
    override init() {
        self.lastHeartbeatAck = Date()
        
        super.init()
        
        // Create URLSession with delegate and proper configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.shouldUseExtendedBackgroundIdleMode = true
        
        // Create a dedicated queue for WebSocket operations
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "DiscordWebSocketQueue"
        
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
    }
    
    func connect() {
        let token = KeychainHelper.standard.read(service: "auth", account: "token")
        
        if token == nil {
            Log.general.error("Token is empty")
            return
        }
        
        // Prevent rapid reconnection attempts
        guard !isConnected else {
            Log.general.warning("Already connected or connecting")
            return
        }
        
        self.token = token
        
        // Clean up any existing connection
        disconnect()
        
        // Add a small delay to prevent rapid reconnection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performConnect()
        }
    }
    
    private func attemptReconnect() {
        guard !isReconnecting && reconnectAttempts < maxReconnectAttempts else {
            if reconnectAttempts >= maxReconnectAttempts {
                Log.network.error("Max reconnection attempts reached")
                // Try switching compression mode as last resort
                if !useCompression && connectionAttempts > 3 {
                    Log.network.notice("Trying with compression enabled...")
                    useCompression = true
                    reconnectAttempts = 0
                } else if useCompression {
                    Log.network.critical("Compression mode also failed, giving up")
                    return
                }
            }
            return
        }
        
        // If we've had multiple failures without compression, try with compression
        if !useCompression && connectionAttempts >= 3 && reconnectAttempts >= 2 {
            Log.network.notice("Multiple failures without compression, trying with compression")
            useCompression = true
        }
        
        isReconnecting = true
        reconnectAttempts += 1
        
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        Log.network.notice("Attempting reconnection #\(self.reconnectAttempts) in \(delay) seconds (compression: \(self.useCompression))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.isReconnecting = false
            if self.token == nil {
                self.performConnect()
            }
        }
    }
    
    private func performConnect() {
        // Try without compression first, then with compression if that fails
        let baseURL = "wss://gateway.discord.gg/?encoding=json&v=10"
        let urlString = useCompression ? baseURL + "&compress=zlib-stream" : baseURL
        
        guard let url = URL(string: urlString) else {
            Log.network.error("Invalid URL: \(urlString)")
            return
        }
        
        Log.network.info("Connecting to: \(urlString)")
        
        // Create request with proper headers
        var request = URLRequest(url: url)
        request.setValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
        request.setValue("websocket", forHTTPHeaderField: "Upgrade")
        request.setValue("upgrade", forHTTPHeaderField: "Connection")
        request.setValue("macaccord/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        webSocketTask = urlSession.webSocketTask(with: request)
        
        // Set maximum message size to handle large Discord payloads (like READY event)
        webSocketTask?.maximumMessageSize = 16 * 1024 * 1024 // 16MB limit
        
        webSocketTask?.resume()
        
        if useCompression {
            initializeDecompression()
        }
        
        connectionAttempts += 1
        Log.network.notice("Connection attempt #\(self.connectionAttempts)")
    }
    
    private func initializeDecompression() {
        // Clean up existing stream if any
        if let pointer = compressionStreamPointer {
            compression_stream_destroy(pointer)
            pointer.deallocate()
        }
        
        compressionStreamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        let status = compression_stream_init(compressionStreamPointer!, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        if status == COMPRESSION_STATUS_ERROR {
            Log.general.error("Failed to initialize decompression stream")
            compressionStreamPointer?.deallocate()
            compressionStreamPointer = nil
        }
    }
    
    func disconnect() {
        isConnected = false
        isReconnecting = false
        reconnectAttempts = 0
        connectionAttempts = 0
        useCompression = false // Reset compression preference
        
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        if let pointer = compressionStreamPointer {
            compression_stream_destroy(pointer)
            pointer.deallocate()
            compressionStreamPointer = nil
        }
        
        Log.network.notice("Disconnected from Discord WebSocket")
    }
    
    private func startListening() {
        guard webSocketTask != nil else {
            Log.network.error("WebSocket task is nil, cannot start listening")
            return
        }
        
        listen()
    }
    
    // MARK: - Listen
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                Log.network.error("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                
                // Only attempt reconnect if we're not already reconnecting
                if let self = self, !self.isReconnecting {
                    self.attemptReconnect()
                }
                return
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleEvent(text)
                case .data(let data):
                    if self?.useCompression != nil {
                        if let decompressedText = self?.decompress(data) {
                            self?.handleEvent(decompressedText)
                        } else {
                            Log.network.warning("Failed to decompress data, treating as plain text")
                            if let text = String(data: data, encoding: .utf8) {
                                self?.handleEvent(text)
                            }
                        }
                    } else {
                        // Without compression, data should be treated as plain text
                        if let text = String(data: data, encoding: .utf8) {
                            self?.handleEvent(text)
                        }
                    }
                @unknown default:
                    break
                }
            }
            
            // Continue listening only if still connected
            if self?.isConnected == true {
                self?.listen()
            }
        }
    }
    
    private func decompress(_ input: Data) -> String? {
        guard let streamPointer = compressionStreamPointer else {
            Log.general.error("Decompression not initialized")
            return nil
        }
        
        var outputData = Data()
        let bufferSize = 8192
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        input.withUnsafeBytes { srcBuffer in
            guard let srcPointer = srcBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }
            
            streamPointer.pointee.src_ptr = srcPointer
            streamPointer.pointee.src_size = input.count
            
            repeat {
                streamPointer.pointee.dst_ptr = buffer
                streamPointer.pointee.dst_size = bufferSize
                
                let status = compression_stream_process(streamPointer, 0)
                
                switch status {
                case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                    let outputBytesCount = bufferSize - streamPointer.pointee.dst_size
                    if outputBytesCount > 0 {
                        outputData.append(buffer, count: outputBytesCount)
                    }
                    if status == COMPRESSION_STATUS_END {
                        break
                    }
                case COMPRESSION_STATUS_ERROR:
                    Log.general.error("Decompression error")
                    return
                default:
                    break
                }
            } while streamPointer.pointee.src_size > 0
        }
        
        return String(data: outputData, encoding: .utf8)
    }
    
    private func handleHeartbeatAck() {
        Log.network.info("💘 Received heartbeat ACK")
        lastHeartbeatAck = Date()
        awaitingHeartbeatAck = false
    }
    
    // MARK: - Handle events
    private func handleEvent(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            Log.general.error("Could not convert text to data")
            return
        }
        
        // Log message size for debugging
        let sizeKB = data.count / 1024
        if sizeKB > 100 {
            Log.general.notice("📦 Received large message: \(sizeKB)KB")
        }
        
        // Try to decode as Hello event first
        Log.general.info("Decoding event...")
        // MARK: - HELLO EVENT
        if let event = try? decoder.decode(DiscordEvent<HelloPayload>.self, from: data),
           event.op == 10, let hello = event.d {
            Log.general.info("Event is a hello event")
            if let seq = event.s {
                self.lastSequence = seq
            }
            self.heartbeatInterval = Double(hello.heartbeat_interval) / 1000.0
            Log.general.info("Received Hello event, heartbeat interval: \(self.heartbeatInterval)s")
            self.startHeartbeat()
            self.identify()
        }
        // Try to decode as Message event
        // MARK: - MESSAGE_CREATE EVENT
        else if let event = try? decoder.decode(DiscordEvent<Message>.self, from: data),
                event.t == "MESSAGE_CREATE", let message = event.d {
            Log.network.info("Event is a MESSAGE_CREATE")
            if let seq = event.s {
                self.lastSequence = seq
            }
            DispatchQueue.main.async {
                self.receiveMessage(channelId: message.channel_id, message: message)
            }
            Log.network.info("Received message: '\(message.content)' from \(message.author.username)")
        }
        // Try to decode as Presence update event
        // MARK: - PRESENCE_UPDATE EVENT
        else if let event = try? decoder.decode(DiscordEvent<PresenceUpdate>.self, from: data),
                event.t == "PRESENCE_UPDATE", let update = event.d {
            Log.network.info("Event is a PRESENCE_UPDATE")
            if let seq = event.s {
                self.lastSequence = seq
            }
            DispatchQueue.main.async {
                self.receivePresenceUpdate(userId: update.user.id, presenceUpdate: update)
            }
            Log.network.info("Updated presence for user \(update.user.id): \(update.status)")
        }
        // Try to decode as a Ready event
        // MARK: - READY EVENT
        else if let event = try? decoder.decode(DiscordEvent<Ready>.self, from: data),
                event.t == "READY", let ready = event.d {
            Log.network.info("Event is a READY")
            if let seq = event.s {
                self.lastSequence = seq
            }
            /*
             if let eventDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
             let _ = eventDict["op"] as? Int {
             if let data = try? JSONSerialization.data(withJSONObject: eventDict, options: .prettyPrinted),
             let jsonString = String(data: data, encoding: .utf8) {
             print("Handling opcode 0\n\(jsonString)")
             }
             }
             */
            DispatchQueue.main.async {
                for user in ready.users {
                    self.receiveUser(userId: user.id, user: user)
                    Log.network.info("Sent user \(user.id)")
                }
                self.receiveUser(userId: "me", user: ready.user)
                Log.network.info("Send my profie")
                for guild in ready.guilds {
                    self.receiveGuild(guildId: guild.id, guild: guild)
                    Log.network.info("Send guild \(guild.id)")
                }
            }
        }
        // Try to decode as a Ready supplemental event
        // MARK: - READY_SUPPLEMENTAL EVENT
        else if let event = try? decoder.decode(DiscordEvent<ReadySupplemental>.self, from: data),
                event.t == "READY_SUPPLEMENTAL", let readySupplemental = event.d {
            Log.network.info("Event is a READY_SUPPLEMENTAL")
            if let seq = event.s {
                self.lastSequence = seq
            }
            
            
            DispatchQueue.main.async {
                for friend in readySupplemental.merged_presences.friends {
                    let presenceUpdate = PresenceUpdate(user: PresenceUser(id: friend.user_id), status: friend.status)
                    self.receivePresenceUpdate(userId: friend.user_id, presenceUpdate: presenceUpdate)
                    Log.network.info("Updated presence for user \(friend.user_id): \(friend.status)")
                }
                self.ready = true
            }
        }
        // MARK: - TYPING_START EVENT
        else if let event = try? decoder.decode(DiscordEvent<TypingStart>.self, from: data),
                event.t == "TYPING_START", let typingStart = event.d {
            Log.network.info("Event is a TYPING_START")
            if let seq = event.s {
                self.lastSequence = seq
            }
            DispatchQueue.main.async {
                self.receiveTypingStart(channelId: typingStart.channel_id, typingStart: typingStart)
                Log.network.info("Received typing_start for channel \(typingStart.channel_id) from user \(typingStart.user_id)")
            }
        }
        // Handle other opcodes
        // MARK: - OTHER EVENT
        else if let eventDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let op = eventDict["op"] as? Int {
            switch op {
            case 11: // Heartbeat ACK
                handleHeartbeatAck()
            case 1: // Heartbeat request
                sendHeartbeat()
            case 7: // Reconnect
                Log.network.warning("Discord requested reconnect")
                DispatchQueue.main.async {
                    self.disconnect() // Clean disconnect first
                    self.connect()
                }
            case 9: // Invalid session
                Log.network.error("Invalid session, reconnecting...")
                DispatchQueue.main.async {
                    self.disconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.connect()
                    }
                }
            case 0:
                if let event = eventDict["t"] as? String {
                    Log.network.info("Handling opcode 0: \(event)")
                    if event == "TYPING_START" {
                        if let data = try? JSONSerialization.data(withJSONObject: eventDict, options: .prettyPrinted),
                           let jsonString = String(data: data, encoding: .utf8) {
                            print("Handling opcode 0\n\(jsonString)")
                        }
                    }
                }
                // Log.network.info("Handling opcode 0\n\(eventDict)")
                /*
                if let data = try? JSONSerialization.data(withJSONObject: eventDict, options: .prettyPrinted),
                   let jsonString = String(data: data, encoding: .utf8) {
                    print("Handling opcode 0\n\(jsonString)")
                }
                */
                break
            default:
                Log.network.warning("Unhandled opcode: \(op)")
                break
            }
        }
    }
    
    // MARK: - Identify
    private func identify() {
        let payload: [String: Any] = [
            "op": 2,
            "d": [
                "capabilities": 4605, // not sure what this is
                "compress": false,
                "token": token ?? "",
                "properties": [
                    "os": "Mac OS X",
                    "os_version": "10.15.7",
                    "browser": "Chrome",
                    "device": "macaccord",
                    "browser_user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
                    "browser_version": "139.0.0.0",
                    "has_client_mods": false,
                    "system_locale": "en-US"
                ],
                "presence": [
                    "activities": [[
                        "name": "Developing Macaccord",
                        "type": 0
                    ]],
                    "status": "online",
                    "afk": false
                ]
                // "intents": 1 | 256 | 512 | 513 | 4096 | 32768, // GUILD_PRESENCES | GUILD_MESSAGES | GUILDS | DIRECT_MESSAGES | MESSAGE_CONTENT (not needed lmfao??)"
            ]
        ]
        sendJSON(payload)
        Log.network.info("Sent identify payload")
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        
        // Discord requires first heartbeat at random interval (jitter * heartbeat_interval)
        let jitter = Double.random(in: 0.0...1.0)
        let initialDelay = heartbeatInterval * jitter
        
        Log.general.info("Starting heartbeat with initial delay: \(initialDelay)s, then every \(self.heartbeatInterval)s")
        
        // Send first heartbeat after jitter delay
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) { [weak self] in
            self?.sendHeartbeat()
            
            // Then start regular timer
            self?.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: self?.heartbeatInterval ?? 41.25, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        // Check if we're waiting too long for heartbeat ACK
        if awaitingHeartbeatAck && Date().timeIntervalSince(lastHeartbeatAck) > heartbeatInterval * 2 {
            Log.network.warning("Haven't received heartbeat ACK in time, connection may be stale")
            // Force reconnection
            DispatchQueue.main.async {
                self.attemptReconnect()
            }
            return
        }
        
        let payload: [String: Any] = [
            "op": 1,
            "d": lastSequence ?? NSNull()
        ]
        
        awaitingHeartbeatAck = true
        sendJSON(payload)
        Log.network.info("💓 Sent heartbeat (seq=\(self.lastSequence ?? -1))")
    }
    
    private func sendJSON(_ payload: [String: Any]) {
        guard let webSocketTask = webSocketTask else {
            Log.network.error("Cannot send JSON: WebSocket task is nil")
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let json = String(data: data, encoding: .utf8)!
            
            webSocketTask.send(.string(json)) { [weak self] error in
                if let error = error {
                    Log.network.error("WebSocket send error: \(error)")
                    DispatchQueue.main.async {
                        self?.isConnected = false
                    }
                    // Don't attempt reconnect here - let the close handler do it
                }
            }
        } catch {
            Log.general.error("JSON serialization error: \(error)")
        }
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - URLSessionWebSocketDelegate
extension DiscordWebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Log.network.info("WebSocket connected successfully")
        DispatchQueue.main.async {
            self.isConnected = true
            self.reconnectAttempts = 0 // Reset on successful connection
            self.isReconnecting = false
        }
        
        // Add a small delay before starting to listen to ensure connection is stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startListening()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason"
        Log.network.notice("\("WebSocket closed with code: \(closeCode), reason: \(reasonString)")")
        
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        // Handle different close codes appropriately
        switch closeCode {
        case .goingAway:
            Log.network.notice("Connection closed intentionally")
        case .abnormalClosure, .noStatusReceived:
            Log.network.notice("Abnormal closure, attempting reconnect")
            if !isReconnecting {
                // If we're getting immediate disconnects, try without compression
                if connectionAttempts <= 3 && useCompression {
                    Log.network.notice("Immediate disconnect with compression, trying without compression")
                    useCompression = false
                    reconnectAttempts = 0
                }
                attemptReconnect()
            }
        default:
            Log.network.notice("Connection closed with code \(closeCode.rawValue), attempting reconnect")
            if !isReconnecting {
                // If getting RST immediately after connection, likely compression issue
                if connectionAttempts <= 3 && useCompression {
                    Log.network.notice("TCP RST with compression, switching to no compression")
                    useCompression = false
                    reconnectAttempts = 0
                }
                attemptReconnect()
            }
        }
    }
}
