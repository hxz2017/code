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
        
    describe 'editLevelSystem', ->
      it 'modifies the given system, and saves an unedited copy', ->
        store = new Vuex.Store({ modules: { localDb: _.cloneDeep(localDb) } })
        system = { _id: 'a', name: 'Original', version: {} }
        store.commit('addLevelSystem', system)
        description = 'Some description'
        store.commit('editLevelSystem', { _id: 'a', description })
        expect(store.getters.getLevelSystem('a').description).toBe(description)
        expect(store.state.localDb.levelSystems['a'].description).toBeUndefined()
        store.commit('editLevelSystem', { _id: 'a', name: 'New' })
        expect(store.getters.getLevelSystem('a').name).toBe('New')
        expect(store.state.localDb.levelSystems['a'].name).toBe('Original')
        
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

    describe 'loadLevelSystemVersion', ->
      it 'fetches system by version, which can be retrieved through getter "getLevelSystemVersion"', wrapJasmine ->
        system = {
          _id: 'b'
          name: 'Physics',
          original: 'a',
          version: { major: 0, minor: 1, isLatestMajor: true, isLatestMinor: true }
        }
        spyOn(api.levelSystems, 'getVersion').and.returnValue(Promise.resolve(system))
        store = new Vuex.Store({ modules: { localDb: _.cloneDeep(localDb) } })
        yield store.dispatch('loadLevelSystemVersion', { originalId: 'a' })
        expect(store.getters.getLevelSystemVersion('a')).toDeepEqual(system)
        expect(store.getters.getLevelSystemVersion('a', 0)).toDeepEqual(system)
        expect(store.getters.getLevelSystemVersion('a', 1)).toBeNull()
        
    describe 'saveLevelSystem', ->
      it 'takes changes to the level system and saves them as a new version to the server', wrapJasmine ->
        system = {
          _id: 'b'
          name: 'Physics',
          original: 'a',
          version: { major: 0, minor: 1, isLatestMajor: true, isLatestMinor: true }
        }
        store = new Vuex.Store({ modules: { localDb: _.cloneDeep(localDb) } })
        store.commit('addLevelSystem', system)
        newSystem = _.assign({}, system, {description: 'New and improved!', name: 'Super Physics'})
        expect(store.getters.editedSystems).toDeepEqual([])
        store.commit('editLevelSystem', newSystem)
        expect(store.getters.editedSystems).toDeepEqual(['b'])
        returnedSystem = _.assign({}, newSystem, { _id: 'c', version: { major: 0, minor: 2, isLatestMajor: true, isLatestMinor: true }})
        spyOn(api.levelSystems, 'postNewVersion').and.returnValue(Promise.resolve(returnedSystem))
        expect(store.getters.getLevelSystemVersion('a')._id).toBe('b')
        yield store.dispatch('saveLevelSystem', { id: 'b', commitMessage: 'Updated physics' })
        expect(store.getters.editedSystems).toDeepEqual([])
        expect(store.state.localDb.levelSystems['c']).toDeepEqual(returnedSystem)
        expect(store.getters.getLevelSystemVersion('a')._id).toBe('c')
