import Foundation

/// A normalized, identifier-keyed store with canonical iteration order.
///
/// The dictionary is authoritative for lookup. Surfaces receive `values`, whose UUID ordering is
/// stable across launches, rather than relying on dictionary iteration order.
public struct EntityStore<Entity>: Codable, Sendable
where Entity: Codable & Sendable & Identifiable, Entity.ID == UUID {
    private var entitiesByID: [UUID: Entity]

    public init<S: Sequence>(_ entities: S) where S.Element == Entity {
        var indexed: [UUID: Entity] = [:]
        for entity in entities {
            indexed[entity.id] = entity
        }
        entitiesByID = indexed
    }

    public init() {
        entitiesByID = [:]
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode([UUID: Entity].self, forKey: .entitiesByID)
        guard decoded.allSatisfy({ key, entity in key == entity.id }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .entitiesByID,
                in: container,
                debugDescription: "An entity-store key does not match its entity identifier."
            )
        }
        entitiesByID = decoded
    }

    public var count: Int { entitiesByID.count }

    public var ids: [UUID] {
        entitiesByID.keys.sorted { $0.uuidString < $1.uuidString }
    }

    public var values: [Entity] {
        ids.compactMap { entitiesByID[$0] }
    }

    public subscript(id: UUID) -> Entity? {
        entitiesByID[id]
    }

    public mutating func insert(_ entity: Entity) {
        entitiesByID[entity.id] = entity
    }

    @discardableResult
    public mutating func remove(_ id: UUID) -> Entity? {
        entitiesByID.removeValue(forKey: id)
    }

    @discardableResult
    public mutating func update(_ id: UUID, _ body: (inout Entity) -> Void) -> Bool {
        guard var entity = entitiesByID[id] else { return false }
        body(&entity)
        guard entity.id == id else { return false }
        entitiesByID[id] = entity
        return true
    }
}

extension EntityStore: Equatable where Entity: Equatable {}
