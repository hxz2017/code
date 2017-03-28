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
    addUsers: (state, newUsers) ->
      state.users = _.extend {}, state.users, newUsers

  }
  actions: {
    loadUsers: ({state, commit}, ids) ->
      missingIds = _.reject(ids, (id) -> state.users[id]?)
      return unless missingIds.length > 0
      api.users.getByIds(missingIds).then((newUsers) => commit('addUsers', newUsers))      
  }
}
