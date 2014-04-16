class window.Recorder
  constructor: (@canvas) ->
    @capturedFrames = []
    @context = @canvas.getContext('2d')
    @width = @canvas.width
    @height = @canvas.height
    @started = false

  reset: ->
    @capturedFrames = []


  record: (seconds, @fps, @options) ->
    @started = true
    @options = @options || {}
    @fps = @fps || 30
    seconds = seconds || 3
    @totalFrames = seconds * @fps
    frames = @totalFrames
    @captureFrames(frames)

  captureFrames: (frames) =>
    @options = @options || {}

    if frames > 0
      @capturedFrames.push(@context.getImageData(0, 0, @width, @height))

      frames--
      setTimeout =>
        @captureFrames(frames)
      , 1000/@fps
      if @options.progress
        @options.progress((@totalFrames - frames) / @totalFrames,
                          @capturedFrames[@capturedFrames.length-1]) 
    else
      @options.complete() if @options.complete
