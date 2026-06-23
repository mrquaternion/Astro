// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension AstroAPI {
  nonisolated struct ArticleQuery: GraphQLQuery {
    static let operationName: String = "Article"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Article { articleCollection { __typename edges { __typename node { __typename id article_id title summary url_string published_at website_name image_url_string launches events } } } }"#
      ))

    public init() {}

    nonisolated struct Data: AstroAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("articleCollection", ArticleCollection?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ArticleQuery.Data.self
      ] }

      /// A pagable collection of type `article`
      var articleCollection: ArticleCollection? { __data["articleCollection"] }

      /// ArticleCollection
      ///
      /// Parent Type: `ArticleConnection`
      nonisolated struct ArticleCollection: AstroAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.ArticleConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ArticleQuery.Data.ArticleCollection.self
        ] }

        var edges: [Edge] { __data["edges"] }

        /// ArticleCollection.Edge
        ///
        /// Parent Type: `ArticleEdge`
        nonisolated struct Edge: AstroAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.ArticleEdge }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ArticleQuery.Data.ArticleCollection.Edge.self
          ] }

          var node: Node { __data["node"] }

          /// ArticleCollection.Edge.Node
          ///
          /// Parent Type: `Article`
          nonisolated struct Node: AstroAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AstroAPI.Objects.Article }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AstroAPI.BigInt.self),
              .field("article_id", String.self),
              .field("title", String.self),
              .field("summary", String.self),
              .field("url_string", String.self),
              .field("published_at", AstroAPI.Datetime.self),
              .field("website_name", String.self),
              .field("image_url_string", String.self),
              .field("launches", [String?].self),
              .field("events", [String?].self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ArticleQuery.Data.ArticleCollection.Edge.Node.self
            ] }

            var id: AstroAPI.BigInt { __data["id"] }
            var article_id: String { __data["article_id"] }
            var title: String { __data["title"] }
            var summary: String { __data["summary"] }
            var url_string: String { __data["url_string"] }
            var published_at: AstroAPI.Datetime { __data["published_at"] }
            var website_name: String { __data["website_name"] }
            var image_url_string: String { __data["image_url_string"] }
            var launches: [String?] { __data["launches"] }
            var events: [String?] { __data["events"] }
          }
        }
      }
    }
  }

}