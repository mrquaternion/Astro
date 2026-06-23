// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension AstroAPI {
  nonisolated struct AssetQuery: GraphQLQuery {
    static let operationName: String = "Asset"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Asset { assetCollection { __typename edges { __typename node { __typename id name summary model_file_name tle_file_name snapshot_file_name model_storage_path tle_storage_path snapshot_storage_path updated_at } } } }"#
      ))

    public init() {}

    nonisolated struct Data: AstroAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("assetCollection", AssetCollection?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AssetQuery.Data.self
      ] }

      /// A pagable collection of type `asset`
      var assetCollection: AssetCollection? { __data["assetCollection"] }

      /// AssetCollection
      ///
      /// Parent Type: `AssetConnection`
      nonisolated struct AssetCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.AssetConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AssetQuery.Data.AssetCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// AssetCollection.Edge
        ///
        /// Parent Type: `AssetEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.AssetEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AssetQuery.Data.AssetCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// AssetCollection.Edge.Node
          ///
          /// Parent Type: `Asset`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Asset }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("name", String.self),
              .field("summary", String.self),
              .field("model_file_name", String.self),
              .field("tle_file_name", String.self),
              .field("snapshot_file_name", String?.self),
              .field("model_storage_path", String.self),
              .field("tle_storage_path", String.self),
              .field("snapshot_storage_path", String?.self),
              .field("updated_at", AstroAPI.Datetime.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AssetQuery.Data.AssetCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var name: String { __data["name"] }
            var summary: String { __data["summary"] }
            var model_file_name: String { __data["model_file_name"] }
            var tle_file_name: String { __data["tle_file_name"] }
            var snapshot_file_name: String? { __data["snapshot_file_name"] }
            var model_storage_path: String { __data["model_storage_path"] }
            var tle_storage_path: String { __data["tle_storage_path"] }
            var snapshot_storage_path: String? { __data["snapshot_storage_path"] }
            var updated_at: AstroAPI.Datetime { __data["updated_at"] }
          }
        }
      }
    }
  }

}