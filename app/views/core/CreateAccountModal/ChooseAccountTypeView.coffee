CocoView = require 'views/core/CocoView'
template = require './choose-account-type-view'

module.exports = class ChooseAccountTypeView extends CocoView
  id: 'choose-account-type-view'
  template: template

  events:
    'click .teacher-path-button': -> @trigger 'choose-path', 'teacher'
    'click .student-path-button': -> @trigger 'choose-path', 'student'
    'click .individual-path-button': -> @trigger 'choose-path', 'individual'
