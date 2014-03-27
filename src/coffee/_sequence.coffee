$ ->
  class window.Sequence
    constructor: (options) ->
      @type = 'sequence'
      @src = options.src
      @aspect = options.aspect
      @duration = options.duration

      @canvas = @createCanvas()
      @canvas.id = new Date().getTime()
      @context = @createContext @canvas

      @canvases = []
      @canvases.push @canvas

      @playing = false

      _this = @
      $(window).resize =>
        if @playing
          # debugger
          @setDimensions()


    setDimensions: =>
      if @player?
        @canvases.map (canvas) ->
          canvas.width = @player.displayWidth
          canvas.height = @player.displayHeight
        if @video
          @video.setDimensions()


    play: (player, callback) ->
      log 'playSequence'
      @playing = true
      @player = player
      @callback = callback

      @setDimensions()

      if @src?
        if @src is 'webcam'
          log 'get webcam'
          @src = webcam.src
          @video = new VideoTrack
            src: @src
            aspect: @aspect
          @video.play(@player)
          @startSequence()
          @canvases.push @video
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
      $('body').append(@canvas)
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
