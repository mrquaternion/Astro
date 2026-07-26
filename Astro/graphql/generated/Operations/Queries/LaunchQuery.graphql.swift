// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension AstroAPI {
  nonisolated struct LaunchQuery: GraphQLQuery {
    static let operationName: String = "Launch"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Launch { launchCollection { __typename edges { __typename node { __typename id launch_id name status_id launch_service_provider_id mission_id rocket_id pad_id net window_start window_end image_url_string thumbnail_url_string last_updated } } } launch_statusCollection { __typename edges { __typename node { __typename id status_id name abbrev } } } launch_service_providerCollection { __typename edges { __typename node { __typename id launch_service_provider_id name } } } launch_missionCollection { __typename edges { __typename node { __typename id mission_id name type description orbit_id orbit_name orbit_abbrev } } } launch_rocketCollection { __typename edges { __typename node { __typename id rocket_id full_name manufacturer } } } launch_padCollection { __typename edges { __typename node { __typename id pad_id name latitude longitude location country alpha_3_code } } } launch_video_urlCollection { __typename edges { __typename node { __typename id launch_id video_url } } } }"#
      ))

    public init() {}

    nonisolated struct Data: AstroAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("launchCollection", LaunchCollection?.self),
        .field("launch_statusCollection", Launch_statusCollection?.self),
        .field("launch_service_providerCollection", Launch_service_providerCollection?.self),
        .field("launch_missionCollection", Launch_missionCollection?.self),
        .field("launch_rocketCollection", Launch_rocketCollection?.self),
        .field("launch_padCollection", Launch_padCollection?.self),
        .field("launch_video_urlCollection", Launch_video_urlCollection?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LaunchQuery.Data.self
      ] }

      /// A pagable collection of type `launch`
      var launchCollection: LaunchCollection? { __data["launchCollection"] }
      /// A pagable collection of type `launch_status`
      var launch_statusCollection: Launch_statusCollection? { __data["launch_statusCollection"] }
      /// A pagable collection of type `launch_service_provider`
      var launch_service_providerCollection: Launch_service_providerCollection? { __data["launch_service_providerCollection"] }
      /// A pagable collection of type `launch_mission`
      var launch_missionCollection: Launch_missionCollection? { __data["launch_missionCollection"] }
      /// A pagable collection of type `launch_rocket`
      var launch_rocketCollection: Launch_rocketCollection? { __data["launch_rocketCollection"] }
      /// A pagable collection of type `launch_pad`
      var launch_padCollection: Launch_padCollection? { __data["launch_padCollection"] }
      /// A pagable collection of type `launch_video_url`
      var launch_video_urlCollection: Launch_video_urlCollection? { __data["launch_video_urlCollection"] }

      /// LaunchCollection
      ///
      /// Parent Type: `LaunchConnection`
      nonisolated struct LaunchCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.LaunchConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.LaunchCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// LaunchCollection.Edge
        ///
        /// Parent Type: `LaunchEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.LaunchEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.LaunchCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// LaunchCollection.Edge.Node
          ///
          /// Parent Type: `Launch`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("launch_id", String.self),
              .field("name", String.self),
              .field("status_id", AstroAPI.BigInt.self),
              .field("launch_service_provider_id", AstroAPI.BigInt.self),
              .field("mission_id", AstroAPI.BigInt?.self),
              .field("rocket_id", AstroAPI.BigInt.self),
              .field("pad_id", AstroAPI.BigInt.self),
              .field("net", AstroAPI.Datetime.self),
              .field("window_start", AstroAPI.Datetime.self),
              .field("window_end", AstroAPI.Datetime.self),
              .field("image_url_string", String?.self),
              .field("thumbnail_url_string", String?.self),
              .field("last_updated", AstroAPI.Datetime.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.LaunchCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var launch_id: String { __data["launch_id"] }
            var name: String { __data["name"] }
            var status_id: AstroAPI.BigInt { __data["status_id"] }
            var launch_service_provider_id: AstroAPI.BigInt { __data["launch_service_provider_id"] }
            var mission_id: AstroAPI.BigInt? { __data["mission_id"] }
            var rocket_id: AstroAPI.BigInt { __data["rocket_id"] }
            var pad_id: AstroAPI.BigInt { __data["pad_id"] }
            var net: AstroAPI.Datetime { __data["net"] }
            var window_start: AstroAPI.Datetime { __data["window_start"] }
            var window_end: AstroAPI.Datetime { __data["window_end"] }
            var image_url_string: String? { __data["image_url_string"] }
            var thumbnail_url_string: String? { __data["thumbnail_url_string"] }
            var last_updated: AstroAPI.Datetime { __data["last_updated"] }
          }
        }
      }

      /// Launch_statusCollection
      ///
      /// Parent Type: `Launch_statusConnection`
      nonisolated struct Launch_statusCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_statusConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.Launch_statusCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Launch_statusCollection.Edge
        ///
        /// Parent Type: `Launch_statusEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_statusEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.Launch_statusCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Launch_statusCollection.Edge.Node
          ///
          /// Parent Type: `Launch_status`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_status }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("status_id", AstroAPI.BigInt.self),
              .field("name", String.self),
              .field("abbrev", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.Launch_statusCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var status_id: AstroAPI.BigInt { __data["status_id"] }
            var name: String { __data["name"] }
            var abbrev: String { __data["abbrev"] }
          }
        }
      }

      /// Launch_service_providerCollection
      ///
      /// Parent Type: `Launch_service_providerConnection`
      nonisolated struct Launch_service_providerCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_service_providerConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.Launch_service_providerCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Launch_service_providerCollection.Edge
        ///
        /// Parent Type: `Launch_service_providerEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_service_providerEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.Launch_service_providerCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Launch_service_providerCollection.Edge.Node
          ///
          /// Parent Type: `Launch_service_provider`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_service_provider }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("launch_service_provider_id", AstroAPI.BigInt.self),
              .field("name", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.Launch_service_providerCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var launch_service_provider_id: AstroAPI.BigInt { __data["launch_service_provider_id"] }
            var name: String { __data["name"] }
          }
        }
      }

      /// Launch_missionCollection
      ///
      /// Parent Type: `Launch_missionConnection`
      nonisolated struct Launch_missionCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_missionConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.Launch_missionCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Launch_missionCollection.Edge
        ///
        /// Parent Type: `Launch_missionEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_missionEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.Launch_missionCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Launch_missionCollection.Edge.Node
          ///
          /// Parent Type: `Launch_mission`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_mission }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("mission_id", AstroAPI.BigInt.self),
              .field("name", String.self),
              .field("type", String.self),
              .field("description", String.self),
              .field("orbit_id", AstroAPI.BigInt.self),
              .field("orbit_name", String.self),
              .field("orbit_abbrev", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.Launch_missionCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var mission_id: AstroAPI.BigInt { __data["mission_id"] }
            var name: String { __data["name"] }
            var type: String { __data["type"] }
            var description: String { __data["description"] }
            var orbit_id: AstroAPI.BigInt { __data["orbit_id"] }
            var orbit_name: String { __data["orbit_name"] }
            var orbit_abbrev: String { __data["orbit_abbrev"] }
          }
        }
      }

      /// Launch_rocketCollection
      ///
      /// Parent Type: `Launch_rocketConnection`
      nonisolated struct Launch_rocketCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_rocketConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.Launch_rocketCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Launch_rocketCollection.Edge
        ///
        /// Parent Type: `Launch_rocketEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_rocketEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.Launch_rocketCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Launch_rocketCollection.Edge.Node
          ///
          /// Parent Type: `Launch_rocket`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_rocket }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("rocket_id", AstroAPI.BigInt.self),
              .field("full_name", String.self),
              .field("manufacturer", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.Launch_rocketCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var rocket_id: AstroAPI.BigInt { __data["rocket_id"] }
            var full_name: String { __data["full_name"] }
            var manufacturer: String { __data["manufacturer"] }
          }
        }
      }

      /// Launch_padCollection
      ///
      /// Parent Type: `Launch_padConnection`
      nonisolated struct Launch_padCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_padConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.Launch_padCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Launch_padCollection.Edge
        ///
        /// Parent Type: `Launch_padEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_padEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.Launch_padCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Launch_padCollection.Edge.Node
          ///
          /// Parent Type: `Launch_pad`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_pad }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("pad_id", AstroAPI.BigInt.self),
              .field("name", String.self),
              .field("latitude", Double.self),
              .field("longitude", Double.self),
              .field("location", String.self),
              .field("country", String.self),
              .field("alpha_3_code", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.Launch_padCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var pad_id: AstroAPI.BigInt { __data["pad_id"] }
            var name: String { __data["name"] }
            var latitude: Double { __data["latitude"] }
            var longitude: Double { __data["longitude"] }
            var location: String { __data["location"] }
            var country: String { __data["country"] }
            var alpha_3_code: String { __data["alpha_3_code"] }
          }
        }
      }

      /// Launch_video_urlCollection
      ///
      /// Parent Type: `Launch_video_urlConnection`
      nonisolated struct Launch_video_urlCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_video_urlConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LaunchQuery.Data.Launch_video_urlCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// Launch_video_urlCollection.Edge
        ///
        /// Parent Type: `Launch_video_urlEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_video_urlEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LaunchQuery.Data.Launch_video_urlCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// Launch_video_urlCollection.Edge.Node
          ///
          /// Parent Type: `Launch_video_url`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Launch_video_url }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("launch_id", String.self),
              .field("video_url", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LaunchQuery.Data.Launch_video_urlCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var launch_id: String { __data["launch_id"] }
            var video_url: String { __data["video_url"] }
          }
        }
      }
    }
  }

}