CocoView = require 'views/core/CocoView'
HeroSelectView = require 'views/core/HeroSelectView'
template = require './extras-view'
State = require 'models/State'

module.exports = class ExtrasView extends CocoView
  id: 'extras-view'
  template: template
  retainSubviews: true

  events:
    'click .next-button': -> @trigger 'nav-forward'

  initialize: ({ @signupState } = {}) ->
    @insertSubView(new HeroSelectView({ showCurrentHero: false }))
