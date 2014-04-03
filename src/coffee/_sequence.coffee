$ ->
  class window.Sequence
    constructor: (options) ->
      @options = options
      @type = 'sequence'
      @src = options.src
      @aspect = options.aspect
      @duration = options.duration

      @onStart = options.onStart if options.onStart?

      @canvas = @createCanvas()
      @canvas.id = new Date().getTime()
      @context = @createContext @canvas

      @canvases = []
      @canvases.push @canvas

      @playing = false

      _this = @
      $(window).resize =>
        if @playing
          @setDimensions()


    setDimensions: =>
      if @player?
        @canvases.map (canvas) ->
          canvas.width = @player.displayWidth
          canvas.height = @player.displayHeight
        if @video
          @video.setDimensions()


    play: (player, callback) ->
      $('body').append(@canvas)
      log 'playSequence'
      @playing = true
      @player = player
      @callback = callback

      @setDimensions()

      if @src?
        if @src is 'webcam'
          log 'it is a webcam'
          @src = webcam.src
          @video = new VideoTrack
            src: @src
            aspect: @aspect
            littleCanvas: true
            shouldDraw: false
          @video.play(@player, null,
            onplaystart: =>
              @onStart() if @onStart?
          )
          @startSequence()
          @canvases.push @video
        else if @src is 'CanvasPlayer'
          @video = new CanvasPlayer @canvas,
            @options.frames || window.recorder.capturedFrames,
            @options.fps || window.recorder.fps
          @video.play(
            player: @player
            ended: =>
              @ended()
          )
        else
          @video = new VideoTrack
            src: @src
            aspect: @aspect
          @video.play(@player, null
            onplaystart: =>
              @startSequence()
          )
      else
        @startSequence()

    startSequence: ->
      @sequenceStart = new Date()
      @drawSequence()

    drawSequence: =>
      elapsed = (new Date() - @sequenceStart) / 1000
      @drawAnimation(@, elapsed)

      if elapsed < @duration
        requestAnimationFrame =>
          @drawSequence()
      else
        log 'end sequence'
        @ended()

    drawAnimation: ->
      # to be overridden by new object

    cleanup: ->
      setTimeout =>
        $(@canvas).remove()
      , 300
      @context.clearRect(0, 0,
               @canvas.width,
               @canvas.height)

    createCanvas: ->
      canvas = document.createElement 'canvas'
      canvas

    createContext: (canvas) ->
      context = canvas.getContext '2d'
