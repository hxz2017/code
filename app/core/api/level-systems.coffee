fetchJson = require './fetch-json'

module.exports = {
  getVersion: ({ originalId, majorVersion, minorVersion }, options) ->
    versionString = switch
      when majorVersion && minorVersion then "/#{majorVersion}.#{minorVersion}"
      when majorVersion then "/#{majorVersion}"
      else ''
    url = "/db/level.system/#{originalId}/version#{versionString}"
    fetchJson(url, options)
}
