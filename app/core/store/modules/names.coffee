api = require 'core/api'

module.exports = {
  state: {
    users: {},
    systems: {}
  }
  getters: {
    getRealName: (state) -> (id) ->
      if state.users[id]?.firstName and state.users[id]?.lastName
        return "#{state.users[id]?.firstName} #{state.users[id]?.lastName}"
      state.users[id]?.firstName or state.users[id]?.name or id
    getUserName: (state) -> (id) ->
      state.users[id]?.name or ''
  }
  mutations: {
    addUserNames: (state, newNames) ->
      state.users = _.extend {}, state.users, newNames

  }
  actions: {
    loadUserNames: ({state, commit}, ids) ->
      missingIds = _.reject(ids, (id) -> state.users[id]?)
      return unless missingIds.length > 0
      api.users.getNames(missingIds).then((newNames) => commit('addUserNames', newNames))      
  }
}
