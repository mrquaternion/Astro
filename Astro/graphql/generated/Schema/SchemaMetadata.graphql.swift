// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol AstroAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == AstroAPI.SchemaMetadata {}

nonisolated protocol AstroAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == AstroAPI.SchemaMetadata {}

nonisolated protocol AstroAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == AstroAPI.SchemaMetadata {}

nonisolated protocol AstroAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == AstroAPI.SchemaMetadata {}

extension AstroAPI {
  typealias SelectionSet = AstroAPI_SelectionSet

  typealias InlineFragment = AstroAPI_InlineFragment

  typealias MutableSelectionSet = AstroAPI_MutableSelectionSet

  typealias MutableInlineFragment = AstroAPI_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "Query": AstroAPI.Objects.Query,
      "article": AstroAPI.Objects.Article,
      "articleConnection": AstroAPI.Objects.ArticleConnection,
      "articleEdge": AstroAPI.Objects.ArticleEdge,
      "asset": AstroAPI.Objects.Asset,
      "assetConnection": AstroAPI.Objects.AssetConnection,
      "assetEdge": AstroAPI.Objects.AssetEdge,
      "asset_shortname": AstroAPI.Objects.Asset_shortname,
      "event": AstroAPI.Objects.Event,
      "launch": AstroAPI.Objects.Launch
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}