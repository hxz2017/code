RootView = require 'views/core/RootView'
template = require './artisans-view'

module.exports = class ArtisansView extends RootView
  template: template
  id: 'artisans-view'
