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
