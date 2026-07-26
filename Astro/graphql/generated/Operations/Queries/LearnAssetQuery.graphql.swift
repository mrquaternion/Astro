// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension AstroAPI {
  nonisolated struct LearnAssetQuery: GraphQLQuery {
    static let operationName: String = "LearnAsset"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query LearnAsset { learn_assetCollection { __typename edges { __typename node { __typename id learn_asset_id default_component components updated_at } } } learn_componentCollection { __typename edges { __typename node { __typename id component_id short_name display_name category group agencies manufacturers materials summary source_ids timeline model_storage_path model_file_name snapshot_storage_path snapshot_file_name is_default_selection details } } } }"#
      ))

    public init() {}

    nonisolated struct Data: AstroAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("learn_assetCollection", Learn_assetCollection?.self),
        .field("learn_componentCollection", Learn_componentCollection?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LearnAssetQuery.Data.self
      ] }

      /// A pagable collection of type `learn_asset`
      var learn_assetCollection: Learn_assetCollection? { __data["learn_assetCollection"] }
      /// A pagable collection of type `learn_component`
      var learn_componentCollection: Learn_componentCollection? { __data["learn_componentCollection"] }

      /// Learn_assetCollection
      ///
      /// Parent Type: `Learn_assetConnection`
      nonisolated struct Learn_assetCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Learn_assetConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LearnAssetQuery.Data.Learn_assetCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Learn_assetCollection.Edge
        ///
        /// Parent Type: `Learn_assetEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Learn_assetEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LearnAssetQuery.Data.Learn_assetCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Learn_assetCollection.Edge.Node
          ///
          /// Parent Type: `Learn_asset`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Learn_asset }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("learn_asset_id", String.self),
              .field("default_component", String.self),
              .field("components", [String?].self),
              .field("updated_at", AstroAPI.Datetime.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LearnAssetQuery.Data.Learn_assetCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var learn_asset_id: String { __data["learn_asset_id"] }
            var default_component: String { __data["default_component"] }
            var components: [String?] { __data["components"] }
            var updated_at: AstroAPI.Datetime { __data["updated_at"] }
          }
        }
      }

      /// Learn_componentCollection
      ///
      /// Parent Type: `Learn_componentConnection`
      nonisolated struct Learn_componentCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Learn_componentConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LearnAssetQuery.Data.Learn_componentCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Learn_componentCollection.Edge
        ///
        /// Parent Type: `Learn_componentEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Learn_componentEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LearnAssetQuery.Data.Learn_componentCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Learn_componentCollection.Edge.Node
          ///
          /// Parent Type: `Learn_component`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Learn_component }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("component_id", String.self),
              .field("short_name", String?.self),
              .field("display_name", String.self),
              .field("category", String.self),
              .field("group", String?.self),
              .field("agencies", [String?].self),
              .field("manufacturers", [String?].self),
              .field("materials", [String?].self),
              .field("summary", String.self),
              .field("source_ids", [String?].self),
              .field("timeline", AstroAPI.JSON.self),
              .field("model_storage_path", String.self),
              .field("model_file_name", String.self),
              .field("snapshot_storage_path", String?.self),
              .field("snapshot_file_name", String?.self),
              .field("is_default_selection", Bool.self),
              .field("details", AstroAPI.JSON.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LearnAssetQuery.Data.Learn_componentCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var component_id: String { __data["component_id"] }
            var short_name: String? { __data["short_name"] }
            var display_name: String { __data["display_name"] }
            var category: String { __data["category"] }
            var group: String? { __data["group"] }
            var agencies: [String?] { __data["agencies"] }
            var manufacturers: [String?] { __data["manufacturers"] }
            var materials: [String?] { __data["materials"] }
            var summary: String { __data["summary"] }
            var source_ids: [String?] { __data["source_ids"] }
            var timeline: AstroAPI.JSON { __data["timeline"] }
            var model_storage_path: String { __data["model_storage_path"] }
            var model_file_name: String { __data["model_file_name"] }
            var snapshot_storage_path: String? { __data["snapshot_storage_path"] }
            var snapshot_file_name: String? { __data["snapshot_file_name"] }
            var is_default_selection: Bool { __data["is_default_selection"] }
            var details: AstroAPI.JSON { __data["details"] }
          }
        }
      }
    }
  }

}