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
      "launch": AstroAPI.Objects.Launch,
      "launchConnection": AstroAPI.Objects.LaunchConnection,
      "launchEdge": AstroAPI.Objects.LaunchEdge,
      "launch_mission": AstroAPI.Objects.Launch_mission,
      "launch_missionConnection": AstroAPI.Objects.Launch_missionConnection,
      "launch_missionEdge": AstroAPI.Objects.Launch_missionEdge,
      "launch_pad": AstroAPI.Objects.Launch_pad,
      "launch_padConnection": AstroAPI.Objects.Launch_padConnection,
      "launch_padEdge": AstroAPI.Objects.Launch_padEdge,
      "launch_rocket": AstroAPI.Objects.Launch_rocket,
      "launch_rocketConnection": AstroAPI.Objects.Launch_rocketConnection,
      "launch_rocketEdge": AstroAPI.Objects.Launch_rocketEdge,
      "launch_service_provider": AstroAPI.Objects.Launch_service_provider,
      "launch_service_providerConnection": AstroAPI.Objects.Launch_service_providerConnection,
      "launch_service_providerEdge": AstroAPI.Objects.Launch_service_providerEdge,
      "launch_status": AstroAPI.Objects.Launch_status,
      "launch_statusConnection": AstroAPI.Objects.Launch_statusConnection,
      "launch_statusEdge": AstroAPI.Objects.Launch_statusEdge,
      "launch_video_url": AstroAPI.Objects.Launch_video_url,
      "launch_video_urlConnection": AstroAPI.Objects.Launch_video_urlConnection,
      "launch_video_urlEdge": AstroAPI.Objects.Launch_video_urlEdge,
      "learn_asset": AstroAPI.Objects.Learn_asset,
      "learn_assetConnection": AstroAPI.Objects.Learn_assetConnection,
      "learn_assetEdge": AstroAPI.Objects.Learn_assetEdge,
      "learn_component": AstroAPI.Objects.Learn_component,
      "learn_componentConnection": AstroAPI.Objects.Learn_componentConnection,
      "learn_componentEdge": AstroAPI.Objects.Learn_componentEdge,
      "tracked_asset": AstroAPI.Objects.Tracked_asset,
      "tracked_assetConnection": AstroAPI.Objects.Tracked_assetConnection,
      "tracked_assetEdge": AstroAPI.Objects.Tracked_assetEdge
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}