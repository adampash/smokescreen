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

      @videoCanvas = @createCanvas()
      @videoContext = @createContext @videoCanvas

      @aniCanvas = @createCanvas()
      @aniContext = @createContext @aniCanvas

      @setDimensions()

      $('body').html(@videoCanvas)
      $('body').append(@aniCanvas)

    createCanvas: ->
      canvas = document.createElement 'canvas'
      canvas

    createContext: (canvas) ->
      context = canvas.getContext '2d'

    setDimensions: (canvas) ->
      @displayWidth = $(document).width()
      @displayHeight = $(document).height()

      @videoCanvas.width = @displayWidth
      @videoCanvas.height = @displayHeight

      @aniCanvas.width = @displayWidth
      @aniCanvas.height = @displayHeight


    play: ->
      log 'play'

      if @currentTrack < @tracks.length
        @queue @tracks[@currentTrack]

    nextTrack: ->
      @currentTrack++
      @play()

    queue: (track) ->
      log 'queue', track

      # track.play()

      if track.type is 'video'
        @playVideo track
      else if track.type is 'sequence'
        @playSequence track

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

window.CamSequence =
  type: 'sequence'
  src: 'webcam'
  aspect: 16/9
  duration: 5
  videoEffect: ->
    backContext.drawImage(webcam,0,0)

    # Grab the pixel data from the backing canvas
    idata = backContext.getImageData(0,0,canvas.width,canvas.height)
    data = idata.data

    # Loop through the pixels
    i = 0
    while i < data.length
       r = data[i]
       g = data[i+1]
       b = data[i+2]
       i += 4
  play: (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    context.clearRect(0, 0,
                      @aniCanvas.width,
                      @aniCanvas.height)


    context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    context.fillOpacity = 0.1
    context.fillRect(x, y, 400, 400)

  ended: (context, canvas) ->
    context.clearRect(0, 0,
             canvas.width,
             canvas.height)


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
      type: 'video'
      src: '/assets/videos/short.mov'
      aspect: 16/9
    ,
      TestSequence
    ,
      CamSequence
    ,
      type: 'video'
      src: '/assets/videos/ocean.mp4'
      aspect: 16/9
  ]

  $(window).resize ->
    player.setDimensions()

  player.play()




window.TestSequence =
  type: 'sequence'
  src: '/assets/videos/short.mov'
  aspect: 16/9
  duration: 2
  play: (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    context.clearRect(0, 0,
                      @aniCanvas.width,
                      @aniCanvas.height)


    context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    context.fillOpacity = 0.1
    context.fillRect(x, y, 400, 400)

  ended: (context, canvas) ->
    context.clearRect(0, 0,
             canvas.width,
             canvas.height)
