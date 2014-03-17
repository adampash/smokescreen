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

      @videoPlaying = false

    play: (player, callback) ->
      log 'playSequence'
      @player = player
      @callback = callback

      @canvas.width = @player.displayWidth
      @canvas.height = @player.displayHeight

      if @src?
        if @src is 'webcam'
          log 'get webcam'
          @src = webcam.src
          # @playVideo track
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
