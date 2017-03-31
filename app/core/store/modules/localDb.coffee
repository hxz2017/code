api = require 'core/api'

clone = (obj) -> JSON.parse(JSON.stringify(obj))

module.exports = {
  state: {
    users: {},
    levelSystems: {
      # id -> levelSystem as received from the server
      # link -> id for things like pointing to the latest version of a given original
      edits: {} # id -> edited levelSystem
      projected: {} # id -> array of projected properties or false if all loaded
    }
  }
  
  getters: {
    getRealName: (state) -> (id) ->
      if state.users[id]?.firstName and state.users[id]?.lastName
        return "#{state.users[id]?.firstName} #{state.users[id]?.lastName}"
      state.users[id]?.firstName or state.users[id]?.name or id
      
    getUserName: (state) -> (id) ->
      state.users[id]?.name or ''
      
    getLevelSystemVersion: (state, getters) -> ({ originalId, majorVersion, minorVersion }) ->
      link = switch
        when originalId and majorVersion and minorVersion then "#{originalId}.#{majorVersion}.#{minorVersion}"
        when originalId and majorVersion then "#{originalId}.#{majorVersion}.latest"
        else "#{originalId}.latest"
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
      links.push "#{levelSystem.original}.#{levelSystem.version.major}.#{levelSystem.version.minor}"
      state.levelSystems[levelSystem._id] = levelSystem
      for link in links
        state.levelSystems[link] = levelSystem._id
        
    editLevelSystem: (state, levelSystemUpdates) ->
      unless state.levelSystems[levelSystemUpdates._id]
        throw new Error('System being edited is not loaded')
      if _.isArray(state.levelSystems.projected[levelSystemUpdates._id])
        throw new Error('System being edited is not fully loaded')
        
      if not state.levelSystems.edits[levelSystemUpdates._id]
        edits = _.clone(state.levelSystems.edits)
        edits[levelSystemUpdates._id] = clone(state.levelSystems[levelSystemUpdates._id])
        state.levelSystems.edits = edits
        
      editedLevelSystem = _.clone(state.levelSystems.edits[levelSystemUpdates._id])
      _.assign(editedLevelSystem, levelSystemUpdates)
      state.levelSystems.edits[levelSystemUpdates._id] = editedLevelSystem
      
    recordLevelSystemProject: (state, { id, project }) ->
      existingProject = state.levelSystems.projected[id]
      if project isnt false
        if existingProject
          project = _.uniq(existingProject.concat(project))
        project = _.uniq(project.concat(['original', 'version'])) # need these for addLevelSystem to work, _id always included
      newProjected = _.assign({}, state.levelSystems.projected)
      newProjected[id] = project
      state.levelSystems.projected = newProjected
      
    clearLevelSystemEdits: (state, id) ->
      state.levelSystems.edits = _.without(state.levelSystems.edits, id)
  }
  
  actions: {
    loadUsers: ({ state, commit }, ids) ->
      missingIds = _.reject(ids, (id) -> state.users[id]?)
      return unless missingIds.length > 0
      api.users.getByIds(missingIds)
      .then((newUsers) => commit('addUsers', newUsers))

    loadLevelSystemVersion: ({ state, commit, getters }, { originalId, majorVersion, minorVersion, project }) ->
      project ?= false
      levelSystem = getters.getLevelSystemVersion({ originalId, majorVersion, minorVersion })
      if levelSystem
        currentProject = state.levelSystems.projected[levelSystem._id]
        if currentProject is false or (_.isArray(project) and _.difference(project, currentProject).length is 0)
          return false
      options = {}
      if project
        options.json = project.join(',')
      api.levelSystems.getVersion({originalId, majorVersion, minorVersion}, options)
      .then((newSystem) =>
        commit('addLevelSystem', newSystem)
        commit('recordLevelSystemProject', { id: newSystem._id, project })
      )

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
  * Add new system, be able to save it
###
