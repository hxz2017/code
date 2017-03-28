localDb = require('core/store/modules/localDb')
api = require('core/api')
{ wrapJasmine } = require('test/app/utils')

describe 'localDb store module', ->
  describe 'getters', ->
    describe 'getRealName', ->
      it 'returns the id if the user is not stored', ->
        state = { users: {} }
        expect(localDb.getters.getRealName(state)('1234')).toBe('1234')
        
      it 'returns the first and last name together if both are available', ->
        state = { users: { '1234': { firstName: 'James', lastName: 'Bond' }}}
        expect(localDb.getters.getRealName(state)('1234')).toBe('James Bond')
        
      it 'returns just the first name if no last name is available', ->
        state = { users: { '1234': { firstName: 'James' }}}
        expect(localDb.getters.getRealName(state)('1234')).toBe('James')

      it 'returns just the username if available', ->
        state = { users: { '1234': { name: '007' }}}
        expect(localDb.getters.getRealName(state)('1234')).toBe('007')
        
    describe 'getUserName', ->
      it 'returns the `name` of the the user if stored, otherwise empty string', ->
        state = { users: { a: { name: 'b' }} }
        expect(localDb.getters.getUserName(state)('a')).toBe('b')
        expect(localDb.getters.getUserName(state)('c')).toBe('')
        
  describe 'mutations', ->
    describe 'addUsers', ->
      it 'triggers watches', (done) ->
        store = new Vuex.Store({ modules: { localDb: _.cloneDeep(localDb) } })
        store.watch(
          ((state, getters) -> return state.localDb.users['a']),
          done
        )
        store.commit('addUsers', {'a': {name:'a'}})
        
  describe 'actions', ->
    describe 'loadUsers', ->
      it 'takes a list of ids, then loads them from the server and into the state', wrapJasmine ->
        spyOn(api.users, 'getByIds').and.returnValue(Promise.resolve({a:{name: 'b'}}))
        store = new Vuex.Store({ modules: { localDb: _.cloneDeep(localDb) } })
        expect(_.isEmpty(store.state.localDb.users)).toBe(true)
        expect(store.getters.getRealName('a')).toBe('a')
        yield store.dispatch('loadUsers', ['a'])
        expect(store.getters.getRealName('a')).toBe('b')

      it 'only fetches a given id once', wrapJasmine ->
        spyOn(api.users, 'getByIds').and.returnValue(Promise.resolve({a:{name: 'b'}}))
        store = new Vuex.Store({ modules: { localDb: _.cloneDeep(localDb) } })
        store.commit('addUsers', { c: {name:'d'}})
        Component = Vue.extend({
          store,
          computed: {
            aName: -> @$store.getters.getRealName('a')
          }
          template: '<span>{{aName}}</span>'
        })
        new Component().$mount('#test-h2')
        expect(store.getters.getRealName('a')).toBe('a')
        expect(store.getters.getRealName('c')).toBe('d')
        yield store.dispatch('loadUsers', ['a', 'c'])
        expect(store.getters.getRealName('a')).toBe('b')
        expect(api.users.getByIds.calls.argsFor(0)[0]).toDeepEqual(['a'])
        expect(api.users.getByIds.calls.count()).toBe(1)
        yield store.dispatch('loadUsers', ['a', 'c'])
        expect(api.users.getByIds.calls.count()).toBe(1)
