RootView = require 'views/core/RootView'
template = require './main-account-view'

module.exports = class MainAccountView extends RootView
  id: 'main-account-view'
  template: template

  events:
    'click .logout-btn': 'logoutAccount'