
// Persistence/SamplerPackRepository.swift
//
// Thin repository over Fountain-Store for loading/saving Sampler Packs.
// Storage backends (local FS, cloud, git) are delegated to Fountain-Store.
//
import Foundation
#if canImport(FountainStore)
import FountainStore
#endif

public protocol SamplerPackStorable {
    func read(path: String) throws -> Data
    func write(path: String, data: Data) throws
    func exists(path: String) -> Bool
    func list(prefix: String) throws -> [String]
}

/// Adapter that uses Fountain-Store if available.
public struct FountainStoreAdapter: SamplerPackStorable {
    public init() {}

    public func read(path: String) throws -> Data {
        #if canImport(FountainStore)
        return try FountainStore.API.read(at: path)
        #else
        return try Data(contentsOf: URL(fileURLWithPath: path))
        #endif
    }
    public func write(path: String, data: Data) throws {
        #if canImport(FountainStore)
        try FountainStore.API.write(data, at: path)
        #else
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        #endif
    }
    public func exists(path: String) -> Bool {
        #if canImport(FountainStore)
        return FountainStore.API.exists(at: path)
        #else
        return FileManager.default.fileExists(atPath: path)
        #endif
    }
    public func list(prefix: String) throws -> [String] {
        #if canImport(FountainStore)
        return try FountainStore.API.list(prefix: prefix)
        #else
        let url = URL(fileURLWithPath: prefix)
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        return items.map { url.appendingPathComponent($0).path }
        #endif
    }
}

public final class SamplerPackRepository {
    private let store: SamplerPackStorable
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(store: SamplerPackStorable = FountainStoreAdapter()) {
        self.store = store
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load(at path: String) throws -> SamplerPack {
        let data = try store.read(path: path)
        return try decoder.decode(SamplerPack.self, from: data)
    }

    public func save(_ pack: SamplerPack, to path: String) throws {
        let data = try encoder.encode(pack)
        try store.write(path: path, data: data)
    }

    public func exists(_ path: String) -> Bool { store.exists(path: path) }

    public func list(in directory: String) throws -> [String] {
        try store.list(prefix: directory).filter { $0.hasSuffix(".json") }
    }
}
