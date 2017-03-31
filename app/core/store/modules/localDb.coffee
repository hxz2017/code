api = require 'core/api'

clone = (obj) -> JSON.parse(JSON.stringify(obj))

module.exports = {
  state: {
    users: {},
    levelSystems: {
      edits: {}
    }
  }
  getters: {
    getRealName: (state) -> (id) ->
      if state.users[id]?.firstName and state.users[id]?.lastName
        return "#{state.users[id]?.firstName} #{state.users[id]?.lastName}"
      state.users[id]?.firstName or state.users[id]?.name or id
      
    getUserName: (state) -> (id) ->
      state.users[id]?.name or ''
      
    getLevelSystemVersion: (state, getters) -> (originalId, majorVersion) ->
      link = if majorVersion? then "#{originalId}.#{majorVersion}.latest" else "#{originalId}.latest"
      id = state.levelSystems[link]
      return getters.getLevelSystem(id)
      
    editedSystems: (state) -> _.keys(state.levelSystems.edits)
    
    getLevelSystem: (state) -> (id) ->
      state.levelSystems.edits?[id] or state.levelSystems[id] or null 
        
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
        
    editLevelSystem: (state, levelSystemUpdates) ->
      unless state.levelSystems[levelSystemUpdates._id]
        throw new Error('System being edited is not loaded')
        
      if not state.levelSystems.edits[levelSystemUpdates._id]
        edits = _.clone(state.levelSystems.edits)
        edits[levelSystemUpdates._id] = clone(state.levelSystems[levelSystemUpdates._id])
        state.levelSystems.edits = edits
        
      editedLevelSystem = _.clone(state.levelSystems.edits[levelSystemUpdates._id])
      _.assign(editedLevelSystem, levelSystemUpdates)
      state.levelSystems.edits[levelSystemUpdates._id] = editedLevelSystem
      
    clearLevelSystemEdits: (state, id) ->
      state.levelSystems.edits = _.without(state.levelSystems.edits, id)
  }
  actions: {
    loadUsers: ({ state, commit }, ids) ->
      missingIds = _.reject(ids, (id) -> state.users[id]?)
      return unless missingIds.length > 0
      api.users.getByIds(missingIds)
      .then((newUsers) => commit('addUsers', newUsers))

    loadLevelSystemVersion: ({ state, commit }, { originalId, majorVersion, minorVersion }) ->
      api.levelSystems.getVersion({originalId, majorVersion, minorVersion})
      .then((newSystem) => commit('addLevelSystem', newSystem))

    saveLevelSystem: ({ state, commit }, { id, commitMessage }) ->
      levelSystem = state.levelSystems.edits[id]
      if not levelSystem
        throw new Error('No changes to save')
      levelSystem = clone(levelSystem)
      levelSystem.commitMessage = commitMessage or ''
      { getI18NCoverage } = require('models/CocoModel')
      levelSystem.i18nCoverage = getI18NCoverage() if levelSystem.i18nCoverage
      api.levelSystems.postNewVersion(levelSystem).then (newSystem) =>
        commit('clearLevelSystemEdits', levelSystem._id)
        commit('addLevelSystem', newSystem)
  }
}

###
  TODO: to be able to replace LevelSystem model and supermodel sharing with this store
  * Get all systems from store
  * Compile as needed (LevelSystem.coffee)
  * Save to local storage
  * Get dependencies (LevelSystem.coffee)
  * Get only certain properties, unless they were all already downloaded
  * Add new system, be able to save it
###
