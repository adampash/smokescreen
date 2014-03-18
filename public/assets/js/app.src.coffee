$ ->
  window.dev = true
  window.log = (args) ->
    if dev
      console.log.apply console,  arguments

  if dev
    $('body').append $('<script src="//localhost:35729/livereload.js"></script>')

$ ->
  class window.Player
    constructor: (@tracks) ->
      @currentTrack = 0
      @videoPlaying = false

      # @videoCanvas = @createCanvas()
      # @videoContext = @createContext @videoCanvas

      # @aniCanvas = @createCanvas()
      # @aniContext = @createContext @aniCanvas

      @setDimensions()

      # $('body').append(@videoCanvas)
      # $('body').append(@aniCanvas)

    createCanvas: ->
      canvas = document.createElement 'canvas'
      canvas

    createContext: (canvas) ->
      context = canvas.getContext '2d'

    setDimensions: (canvas) ->
      @displayWidth = $(document).width()
      @displayHeight = $(document).height()


      # $('canvas').width = @displayWidth
      # $('canvas').height = @displayHeight

      # @aniCanvas.width = @displayWidth
      # @aniCanvas.height = @displayHeight


    play: ->
      log 'play'
      if @currentTrack < @tracks.length
        @queue @tracks[@currentTrack]

    nextTrack: ->
      @currentTrack++
      @play()

    queue: (track) ->
      log 'queue', track

      track.play(
        @, =>
          log 'callback'
          @nextTrack()
      )

      # if track.type is 'video'
      #   @playVideo track
      # else if track.type is 'sequence'
      #   @playSequence track

    playVideo: (track) ->
      log 'playVideo'

      @video = document.createElement 'video'
      @video.src = track.src

      @setupVideoListeners @video, track

      # $('body').append(@video)

      @videoPlaying = true
      @video.play()

      @drawVideo(track)

    playSequence: (track) ->
      log 'playSequence'

      @sequenceStart = new Date()

      if track.src?
        if track.src is 'webcam'
          log 'get webcam'
          track.src = webcam.src
          @playVideo track
        else
          @playVideo track
      else
        @drawSequence track

    drawSequence: (track) =>
      elapsed = (new Date() - @sequenceStart) / 1000
      track.play.call(@, @aniContext, elapsed)

      if elapsed < track.duration
        requestAnimationFrame =>
          @drawSequence track
      else
        log 'end sequence'
        track.ended.call(@, @aniContext, @aniCanvas)
        @nextTrack()

    drawVideo: (track) =>
      height = @displayWidth / track.aspect
      spacer = (@displayHeight - height) / 2
      @videoContext.drawImage(@video,0,spacer, @displayWidth, height)
      if @videoPlaying
        requestAnimationFrame =>
          @drawVideo track


    setupVideoListeners: (video, track) =>
      video.addEventListener 'ended', (event) =>
        if @video is event.srcElement
          @videoEnded()

      if track.type is 'sequence'
        video.addEventListener 'playing', =>
          @drawSequence track

    videoEnded: ->
      log 'ended'
      @videoPlaying = false
      @nextTrack()

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

      @playing = false

      _this = @
      $(window).resize =>
        if @playing
          # debugger
          @setDimensions()


    setDimensions: =>
      if @player?
        @canvas.width = @player.displayWidth
        @canvas.height = @player.displayHeight


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

$ ->
  window.testSequence =
    new Sequence
      type: 'sequence'
      src: '/assets/videos/short.mov'
      aspect: 16/9
      duration: 5

  testSequence.drawAnimation = (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)


    @context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    @context.fillOpacity = 0.1
    @context.fillRect(x, y, 400, 400)

  testSequence.ended = ->
    @callback() if @callback?
    @cleanup()

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

    play: (player, callback, options) ->
      log 'playVideo'
      @player = player
      @callback = callback
      if options
        @onplaystart = options.onplaystart if options.onplaystart?

      $('body').append(@canvas)

      @canvas.width = @player.displayWidth
      @canvas.height = @player.displayHeight

      @video = document.createElement 'video'
      @video.src = @src

      @setupVideoListeners @video

      @video.play()


    drawVideo: =>
      height = @player.displayWidth / @aspect
      spacer = (@player.displayHeight - height) / 2

      @context.drawImage(@video,0,spacer, @player.displayWidth, height)

      if @videoPlaying
        requestAnimationFrame =>
          @drawVideo()

    setupVideoListeners: (video) =>
      video.addEventListener 'playing', (event) =>
        @onplaystart() if @onplaystart?
        @videoPlaying = true
        @drawVideo()

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

$ ->
  window.camSequence = new Sequence
      type: 'sequence'
      src: 'webcam'
      aspect: 16/9
      duration: 5

  camSequence.drawAnimation = (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)


    @context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    @context.fillOpacity = 0.1
    @context.fillRect(x, y, 400, 400)

  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()


# window.CamSequence =
#   type: 'sequence'
#   src: 'webcam'
#   aspect: 16/9
#   duration: 5
#   videoEffect: ->
#     backContext.drawImage(webcam,0,0)
# 
#     # Grab the pixel data from the backing canvas
#     idata = backContext.getImageData(0,0,canvas.width,canvas.height)
#     data = idata.data
# 
#     # Loop through the pixels
#     i = 0
#     while i < data.length
#        r = data[i]
#        g = data[i+1]
#        b = data[i+2]
#        i += 4
#   play: (context, elapsed) ->
#     x = elapsed * 100
#     y = elapsed * 100
#     context.clearRect(0, 0,
#                       @aniCanvas.width,
#                       @aniCanvas.height)
# 
# 
#     context.fillStyle = 'rgba(0, 100, 0, 0.4)'
#     context.fillOpacity = 0.1
#     context.fillRect(x, y, 400, 400)
# 
#   ended: (context, canvas) ->
#     context.clearRect(0, 0,
#              canvas.width,
#              canvas.height)
# 

# GET USER MEDIA
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia

constraints =
  audio: false
  video:
    mandatory:
      minWidth: 1280
      minHeight: 720

successCallback = (stream) ->
  window.webcam = stream # stream available to console
  if (window.URL)
    webcam.src = window.URL.createObjectURL(stream)
  else
    webcam.src = stream

errorCallback = (error) ->
  log("navigator.getUserMedia error: ", error)

navigator.getUserMedia(constraints, successCallback, errorCallback)

$ ->
  window.player = new Player [
      new VideoTrack
        src: '/assets/videos/short.mov'
        aspect: 16/9
    ,
      testSequence
    ,
      camSequence
    ,
      new VideoTrack
        src: '/assets/videos/ocean.mp4'
        aspect: 16/9
    ,
  ]

  $(window).resize ->
    player.setDimensions()
    player.tracks[player.currentTrack].setDimensions()

  player.play()



