RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
TrialRequests = require 'collections/TrialRequests'
TrialRequest = require 'models/TrialRequest'
User = require 'models/User'
require('vendor/co')
require('vendor/vue')
require('vendor/vuex')

module.exports = class LeadScoreView extends RootView
  id: 'lead-score-view'
  template: template

  initialize: ->
    super(arguments...)
    # Vuex Store
    @store = new Vuex.Store({
      state:
        trialRequests: []
      actions:
        {}
      strict: not application.isProduction()
      mutations:
        loadTrialRequests: (state, trialRequests) ->
          console.log {trialRequests}
          state.trialRequests = trialRequests
      getters:
        {}
    })

  afterRender: ->
    @vueComponent?.$destroy()
    @vueComponent = new LeadScoreVueComponent({
      el: @$el.find('#site-content-area')[0]
      store: @store
    })
    super(arguments...)

LeadScoreVueComponent = Vue.extend
  template: require('templates/admin/lead-score-view')()
  data: ->
    {}
  computed:
    Vuex.mapState(['trialRequests'])
  created: co.wrap ->
    trialRequestIds = [ "57f3eb1abddd0e2900e8079a", "580d6b07b8ea5824004857cf", "583dceedf09fa920006a4037", "584830eae978681f00e85338", "5849b313c9b6b82a00415674", "587e36256f41252100024fd9" ]
    trialRequests = new TrialRequests(trialRequestIds.map (_id) -> new TrialRequest({ _id }))
    console.log trialRequests
    yield trialRequests.map (tr) -> tr.fetch()
    trialRequests = trialRequests.toJSON()
    console.log {trialRequests}
    @$store.commit('loadTrialRequests', trialRequests)
