$ ->
  class window.VideoTrack
    constructor: (options) ->
      @type = 'video'
      @src = options.src
      @aspect = options.aspect

      @canvas = @createCanvas()
      @canvas.id = new Date().getTime()
      @context = @createContext @canvas

      @videoPlaying = false

      @shouldDraw = options.shouldDraw || true

      if options.littleCanvas?
        @littleCanvas = @createCanvas()
        @littleCanvas.width = 960 # @canvas.width /  3
        @littleCanvas.height = 540 # @canvas.width / 3
        @littleContext = @createContext @littleCanvas


    play: (player, callback, options) ->
      log 'playVideo'
      @player = player
      @callback = callback
      if options
        @onplaystart = options.onplaystart if options.onplaystart?

      $('body').prepend(@canvas)

      @setDimensions()

      @video = document.createElement 'video'
      @video.src = @src

      @setupVideoListeners @video

      @video.play()


    setDimensions: ->
      if @player?
        @canvas.width = @player.displayWidth
        @canvas.height = @player.displayHeight


    drawVideo: =>
      height = @player.displayWidth / @aspect
      spacer = (@player.displayHeight - height) / 2
      if @littleCanvas?
        window.spacer = spacer

      @context.drawImage(@video,0,spacer, @player.displayWidth, height)
      if @littleCanvas?
        @littleContext.drawImage(@video,0,0, @littleCanvas.width, @littleCanvas.height);


      if @videoPlaying
        requestAnimationFrame =>
          @drawVideo()

    setupVideoListeners: (video) =>
      video.addEventListener 'playing', (event) =>
        @onplaystart() if @onplaystart?
        @videoPlaying = true
        @drawVideo() if @shouldDraw

      video.addEventListener 'ended', (event) =>
        if @video is event.srcElement
          @videoPlaying = false

          # cleanup
          @cleanup()

          @callback() if @callback?


    cleanup: ->
      setTimeout =>
        $(@canvas).remove()
      , 300

    createCanvas: ->
      canvas = document.createElement 'canvas'
      canvas

    createContext: (canvas) ->
      context = canvas.getContext '2d'
