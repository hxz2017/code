api = require 'core/api'

module.exports = {
  state: {
    users: {},
    levelSystems: {}
  }
  getters: {
    getRealName: (state) -> (id) ->
      if state.users[id]?.firstName and state.users[id]?.lastName
        return "#{state.users[id]?.firstName} #{state.users[id]?.lastName}"
      state.users[id]?.firstName or state.users[id]?.name or id
    getUserName: (state) -> (id) ->
      state.users[id]?.name or ''
    getLevelSystemVersion: (state) -> (originalId, majorVersion) ->
      link = if majorVersion? then "#{originalId}.#{majorVersion}.latest" else "#{originalId}.latest"
      id = state.levelSystems[link]
      return if id then state.levelSystems[id] else null
  }
  mutations: {
    addUsers: (state, newUsers) ->
      state.users = _.extend {}, state.users, newUsers
    addLevelSystem: (state, levelSystem) ->
      links = []
      if levelSystem.version.isLatestMajor
        links.push "#{levelSystem.original}.latest"
      if levelSystem.version.isLatestMinor
        links.push "#{levelSystem.original}.#{levelSystem.version.major}.latest"
      state.levelSystems[levelSystem._id] = levelSystem
      for link in links
        state.levelSystems[link] = levelSystem._id
  }
  actions: {
    loadUsers: ({state, commit}, ids) ->
      missingIds = _.reject(ids, (id) -> state.users[id]?)
      return unless missingIds.length > 0
      api.users.getByIds(missingIds)
        .then((newUsers) => commit('addUsers', newUsers))
    loadLevelSystemVersion: ({state, commit }, { originalId, majorVersion, minorVersion }) ->
      api.levelSystems.getVersion({ originalId, majorVersion, minorVersion })
        .then((newSystem) => commit('addLevelSystem', newSystem))
  }
}

###
  TODO:
  * Get all systems from store
  * Compile as needed (LevelSystem.coffee)
  * Maintain changes, be able to save them/commit them, track which systems have changed, save to local storage
  * Get dependencies (LevelSystem.coffee)
  * Get only certain properties, unless they were all already downloaded
  * Add new system, be able to save it
###
