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
          if not _.isNull(attributeValue)
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
    # trialRequestIds = [ "57f3eb1abddd0e2900e8079a", "580d6b07b8ea5824004857cf", "583dceedf09fa920006a4037", "584830eae978681f00e85338", "5849b313c9b6b82a00415674", "587e36256f41252100024fd9", "5644cf2324bd4d8705a31541" ]
    trialRequestIds = TRIAL_REQUEST_IDS
    trialRequests = new TrialRequests(trialRequestIds.map (_id) -> new TrialRequest({ _id }))
    console.log trialRequests
    yield trialRequests.map (tr) -> tr.fetch()
    trialRequests = trialRequests.toJSON()
    console.log {trialRequests}
    @$store.dispatch('loadTrialRequests', trialRequests)

TRIAL_REQUEST_IDS = [
  "589253f96da5912a00e8ed87",
  "589251d722ae462100348010",
  "5892516820168220000b924a",
  "58924e8a20168220000b818a",
  "58924ce698d6a22b008e4e04",
  "5892481f9d73ec21003c34ef",
  "58924753eb897a320041778d",
  "5892467bfa5f292000c7aca9",
  "589245273fdfa51b007e80c9",
  "589242aecc6a1e1b004582b7",
  "58924112cc6a1e1b004577cf",
  "589240454a0a222500673100",
  "58923faeeb897a3200414120",
  "58923ec122ae46210033f55f",
  "58923d8f22ae46210033ec53",
  "58923bbc20168220000af9e1",
  "58923b98cc6a1e1b0045480e",
  "58923b41fa5f292000c78f55",
  "58923aa554a11d1c00f9bd82",
  "589238c820168220000ad846",
  "589234c8eb897a320040d4f1",
  "589234593fdfa51b007e2dd7",
  "58923436eb897a320040cbf3",
  "5892334322ae462100338c40",
  "589230a6cc6a1e1b0044cd3a",
  "5892307620168220000a9358",
  "58922c67fa5f292000c750fa",
  "58922a0fcc6a1e1b00447cf8",
  "5892217b22ae46210032c7b1",
  "58921dd3cc6a1e1b004419a1",
  "58921ae122ae4621003278fd",
  "589219f99d73ec21003b7e5b",
  "5892195e22ae4621003269ca",
  "589218f4cc6a1e1b0043f07c",
  "5892181922ae4621003260b4",
  "5892167d22ae46210032516e",
  "5892148c22ae462100324142",
  "589214564a0a222500668315",
  "5892105efa5f292000c6d451",
  "58920e682016822000092de6",
  "58920c4f9d73ec21003b3a93",
  "58920c43201682200009146d",
  "58920af72edbdc2600df533b",
  "58920a8322ae46210031e61c",
  "58920a754a0a222500665b8f",
  "589206e2eb897a32003f1278",
  "5892034222ae4621003190cc",
  "5892017354a11d1c00f8baa1",
  "589200bf22ae462100317a28",
  "5891fd819d73ec21003aed30",
  "5891fce72016822000088195",
  "5891fccd9d73ec21003ae8a8",
  "5891f60722ae462100311ac0",
  "5891f4ac9d73ec21003ac7b2",
  "5891f3be54a11d1c00f86cc8",
  "5891f31098d6a22b008cc202",
  "5891f2adeb897a32003e536e",
  "5891f18c2016822000081af9",
  "5891f0d5fa5f292000c66dc1",
  "5891edf1cc6a1e1b00423c8d",
  "5891e83954a11d1c00f8401a",
  "5891e44122ae4621003087d7",
  "5891e30954a11d1c00f82ce5",
  "5891e285cc6a1e1b0041e6f6",
  "5891de51cc6a1e1b0041c701",
  "5891ddeb3fdfa51b007cfa2f",
  "5891da766da5912a00e7596a",
  "5891d9bf2edbdc2600de8f51",
  "5891d74e3fdfa51b007ceae0",
  "5891d5d62edbdc2600de8904",
  "5891d41f20168220000736d6",
  "5891d386eb897a32003d579f",
  "5891d26aeb897a32003d51e7",
  "5891cf48eb897a32003d4599",
  "5891c98322ae4621002ffcfe",
  "5891c3bbcc6a1e1b00415001",
  "5891bdb22edbdc2600de6165",
  "5891bb85201682200006decf",
  "5891b55eeb897a32003cdca9",
  "5891b4ca22ae4621002f96b6",
  "5891af963fdfa51b007cb9c1",
  "5891a9af20168220000691bd",
  "5891a73022ae4621002f5fc7",
  "589196ee2edbdc2600de2b42",
  "589190b8eb897a32003c5fb3",
  "5891902acc6a1e1b004094e0",
  "589182b6eb897a32003c4101",
  "5891822898d6a22b008bf128",
  "589181699d73ec210039e8f0",
  "58917cd5cc6a1e1b00406e50",
  "5891633b9d73ec210039d7fd",
  "589160b6cc6a1e1b00404a34",
  "58915d446da5912a00e6edcc",
  "58915abe2edbdc2600de02b9",
  "589156c7eb897a32003c03bc",
  "5891546254a11d1c00f77ab9",
  "589151e3eb897a32003bf7e4",
  "58914af23fdfa51b007c8589",
  "58914675eb897a32003bdfa9",
  "589141f8201682200005b66f",
  "5899f4ee6da5912a00f6adb8",
  "5899a02508a5b7310053e466",
  "5890dd489d73ec210038d92b",
  "588fcc732016822000fee8f5",
  "588b858e6e87fc2400b04cae",
  "589861b7cc6a1e1b0058b4c8",
  "5895123122ae4621004238fb",
  "5894fa353fdfa51b0084746e",
  "5893d1132edbdc2600e4d905",
  "58932d702edbdc2600e1f708",
  "5890f79b9d73ec210039426c",
  "588ea43bcac5451f00002b61",
  "5881dda39ac5282f0068e1a6",
  "58810ceeb35ae42500f63ac4",
  "5880f1ace7cb9a2a00252b57",
  "58992d68cc6a1e1b005ded36",
  "58926435cc6a1e1b0046491a",
  "588de581ff56031f000e8111",
  "588a5a9b06d51f20002dc59a",
  "5889dd3a06d51f200028e927"
]
