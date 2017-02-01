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
        valueWeights: {}
        attributeWeights: {}
        scoreAttributes: ['country', 'numStudentsTotal', 'role', 'purchaserRole']
        displayAttributes: []
      actions:
        loadTrialRequests: (context, trialRequests) ->
          context.commit('loadTrialRequests', trialRequests)
          context.commit('setInitialWeights', context.getters.possibleValues)
      # strict: not application.isProduction()
      mutations:
        loadTrialRequests: (state, trialRequests) ->
          console.log {trialRequests}
          state.trialRequests = trialRequests
        setInitialWeights: (state, possibleValues) ->
          for attr in possibleValues
            state.valueWeights[attr.name] ?= {}
            state.attributeWeights[attr.name] = 1
            for value in attr.values
              state.valueWeights[attr.name][value] = 0
        updateWeight: (state, { attributeName, attributeValue, weightValue }) ->
          return if _.isNaN(weightValue)
          console.log "Updating weight"
          if attributeValue
            state.valueWeights[attributeName][attributeValue] = weightValue
            Vue.set(state, 'valueWeights', _.assign {}, state.valueWeights)
          else
            state.attributeWeights[attributeName] = weightValue
            Vue.set(state, 'attributeWeights', _.assign {}, state.attributeWeights)
      getters:
        possibleValues: (state) ->
          state.scoreAttributes.map (name) ->
            {
              name
              values: _.uniq state.trialRequests.map (tr) ->
                tr.properties[name]
            }
        getLeadById: (state) -> (_id) ->
          _.find(state.trialRequests, { _id })
        sortedLeads: (state, getters) ->
          sorted = _(state.trialRequests).sortBy((tr) ->
            # console.log state.getLeadScoreById(tr._id)
            getters.getLeadScoreById(tr._id)
          ).reverse().value()
          # console.log sorted
          sorted
        getLeadScoreById: (state, getters) -> (_id) ->
          tr = getters.getLeadById(_id)
          score = state.scoreAttributes.map((attrName)->
            # console.log "Checking score subvalue: #{attrName} = #{tr.properties[attrName]}: #{state.valueWeights[attrName][tr.properties[attrName]]}"
            # debugger if attrName is "country" and tr.properties[attrName] is "Canada"
            state.valueWeights[attrName][tr.properties[attrName]] * state.attributeWeights[attrName]
          ).reduce(((a,b) -> a + b), 0)
          # console.log "Getting lead score for #{_id}: #{score}"
          score
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
  data: -> {}
  computed: _.assign {},
    Vuex.mapState(['trialRequests', 'valueWeights', 'attributeWeights', 'scoreAttributes']),
    Vuex.mapGetters(['possibleValues', 'getLeadScoreById', 'getLeadById', 'sortedLeads'])
  methods:
    updateWeight: (attributeName, attributeValue, weightValue) ->
      @$store.commit('updateWeight', { attributeName, attributeValue, weightValue: parseFloat(weightValue) })


  created: co.wrap ->
    trialRequestIds = [ "57f3eb1abddd0e2900e8079a", "580d6b07b8ea5824004857cf", "583dceedf09fa920006a4037", "584830eae978681f00e85338", "5849b313c9b6b82a00415674", "587e36256f41252100024fd9", "5644cf2324bd4d8705a31541" ]
    trialRequests = new TrialRequests(trialRequestIds.map (_id) -> new TrialRequest({ _id }))
    console.log trialRequests
    yield trialRequests.map (tr) -> tr.fetch()
    trialRequests = trialRequests.toJSON()
    console.log {trialRequests}
    @$store.dispatch('loadTrialRequests', trialRequests)
