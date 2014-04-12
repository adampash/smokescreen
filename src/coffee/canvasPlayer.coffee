class window.CanvasPlayer
  constructor: (@canvas, @frames, @fps, @options) ->
    @options = @options || {}
    @addSpacer = @options.addSpacer
    @progress = @options.progress
    @paused = false
    @context = @canvas.getContext('2d')
    @index = 0
    @fps = @fps || 30
    @loopStyle = 'beginning'
    @loop = false
    @increment = true
    @startFrame = 1
    @endFrame = @frames.length - 1

  reset: ->
    @frames = []
    @options = {}
    @paused = false
    @index = 0
    @fps = @fps || 30
    @loopStyle = 'beginning'
    @increment = true
    @startFrame = 0

  setDimensions: ->
    if @player?
      @canvas.width = @player.displayWidth
      @canvas.height = @player.displayHeight

  play: (options) ->
    @player = options.player if options.player?
    @timeout = 1/@fps * 1000
    unless @paused
      @options = options || @options
      if @endFrame > @index
        if @index <= @startFrame
          @index = @startFrame
          @increment = true
        if @increment then @index++ else @index--
      else
        unless @loop
          return @options.ended() if @options.ended
        if @loopStyle == 'beginning'
          @index = @startFrame
        else
          @index = @endFrame - 1
          @increment = false
      @paintFrame(@index)

    setTimeout =>
      @play(options)
    , @timeout

  pause: ->
    @paused = !@paused

  paintFrame: (index) ->
    return false if index >= @frames.length || index < 0
    @index = index || @index
    frame = @frames[@index]

    if @addSpacer
      spacer = Math.round((@canvas.height - frame.width * 9/16) / 2)
      @context.putImageData(frame, 0, spacer)
    else
      @context.putImageData(frame, 0, 0)
    @progress(index) if @progress

  cleanup: ->
    setTimeout =>
      $(@canvas).remove()
    , 300
