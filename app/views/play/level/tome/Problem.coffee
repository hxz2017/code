Range = ace.require('ace/range').Range

# This class can either wrap an AetherProblem,
# or act as a general runtime error container for web-dev iFrame errors.
module.exports = class Problem
  annotation: null
  markerRange: null
  # TODO: Convert calls to constructor to use object
  constructor: ({ @aether, @aetherProblem, @ace, isCast=false, @levelID, error }) ->
    debugger if arguments.length > 1
    if @aetherProblem
      @annotation = @buildAnnotationFromAetherProblem(@aetherProblem)
      {@lineMarkerRange, @textMarkerRange} = @buildMarkerRangesFromAetherProblem(@aetherProblem) if isCast
      
      @level = @aetherProblem.level
      @row = @aetherProblem.range?[0]?.row
      @column = @aetherProblem.range?[0]?.col
      @range = @aetherProblem.range
      @message = @aetherProblem.message
      @hint = @aetherProblem.hint
      @userInfo = @aetherProblem.userInfo
    else
      @annotation = @buildAnnotationFromWebDevError(error)
      @lineMarkerRange = new Range error.line, 0, error.line, 1
      @lineMarkerRange.start = @ace.getSession().getDocument().createAnchor @lineMarkerRange.start
      @lineMarkerRange.end = @ace.getSession().getDocument().createAnchor @lineMarkerRange.end
      @lineMarkerRange.id = @ace.getSession().addMarker @lineMarkerRange, 'problem-line', 'fullLine'

      @level = error?.type or 'error'
      @row = error?.line
      @column = error?.column
      @message = error.text or error.raw or 'Unknown Error'
      @hint = undefined
      @userInfo = undefined

    # TODO: get ACE screen line, too, for positioning, since any multiline "lines" will mess up positioning
    Backbone.Mediator.publish("problem:problem-created", line: @annotation.row, text: @annotation.text) if application.isIPadApp

  destroy: ->
    @removeMarkerRanges()
    @userCodeProblem.off() if @userCodeProblem
    
  buildAnnotationFromWebDevError: (error) ->
    {
      row: error.line
      column: error.column
      raw: error.error
      text: error.message
      type: error.type
      createdBy: 'web-dev-iframe'
    }

  buildAnnotationFromAetherProblem: (aetherProblem) ->
    return unless aetherProblem.range
    text = aetherProblem.message.replace /^Line \d+: /, ''
    start = aetherProblem.range[0]
    {
      row: start.row,
      column: start.col,
      raw: text,
      text: text,
      type: @aetherProblem.level ? 'error'
      createdBy: 'aether'
    }

  buildMarkerRangesFromAetherProblem: (aetherProblem) ->
    return unless aetherProblem.range
    [start, end] = aetherProblem.range
    textClazz = "problem-marker-#{aetherProblem.level}"
    textMarkerRange = new Range start.row, start.col, end.row, end.col
    textMarkerRange.start = @ace.getSession().getDocument().createAnchor textMarkerRange.start
    textMarkerRange.end = @ace.getSession().getDocument().createAnchor textMarkerRange.end
    textMarkerRange.id = @ace.getSession().addMarker textMarkerRange, textClazz, 'text'
    lineClazz = "problem-line"
    lineMarkerRange = new Range start.row, start.col, end.row, end.col
    lineMarkerRange.start = @ace.getSession().getDocument().createAnchor lineMarkerRange.start
    lineMarkerRange.end = @ace.getSession().getDocument().createAnchor lineMarkerRange.end
    lineMarkerRange.id = @ace.getSession().addMarker lineMarkerRange, lineClazz, 'fullLine'
    { lineMarkerRange, textMarkerRange }

  removeMarkerRanges: ->
    if @textMarkerRange
      @ace.getSession().removeMarker @textMarkerRange.id
      @textMarkerRange.start.detach()
      @textMarkerRange.end.detach()
    if @lineMarkerRange
      @ace.getSession().removeMarker @lineMarkerRange.id
      @lineMarkerRange.start.detach()
      @lineMarkerRange.end.detach()
