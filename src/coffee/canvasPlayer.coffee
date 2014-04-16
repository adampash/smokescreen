class window.CanvasPlayer
  constructor: (@canvas, @frames, @fps) ->
    # @options = @options || {}
    # @addSpacer = @options.addSpacer
    # @progress = @options.progress
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
    if options.onstart?
      options.onstart()
      log 'start'
      options.onstart = null
    @timeout = 1/@fps * 1000
    @options = options || @options
    if @endFrame > @index
      @index++
    else
        return @options.complete()

    frame = @frames[@index]
    frame = @options.preprocess(frame) if @options.preprocess?
    @paintFrame(frame, @index)
    @options.addition(@context, @index) if @options.addition?
    # if @options.postprocess?
    #   log 'post process'
    #   frame = @context.getImageData 0, 0, @canvas.width, @canvas.height
    #   frame = @options.postprocess(frame)
    #   @paintFrame(frame, @index)

    setTimeout =>
      @play(options)
    , @timeout

  pause: ->
    @paused = !@paused

  paintFrame: (frame, index) ->
    @context.putImageData(frame, 0, 0)
    # @progress(index) if @progress

  cleanup: ->
    setTimeout =>
      $(@canvas).remove()
    , 300
