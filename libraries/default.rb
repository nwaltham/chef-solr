def solr_version
  split_version = node.default[:solr][:version].split('.')
  {
    :major => split_version.count >= 1 ? split_version[0].to_i : -1,
    :minor => split_version.count >= 2 ? split_version[1].to_i : -1,
    :tiny => split_version.count >= 3 ? split_version[2].to_i : -1
  }
end