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
      devlog 'play'

      if @currentTrack < @tracks.length
        @queue @tracks[@currentTrack]

    nextTrack: ->
      @currentTrack++
      @play()

    queue: (track) ->
      devlog 'queue', track

      if track.type is 'video'
        @playVideo track
      else if track.type is 'sequence'
        @playSequence track

    playVideo: (track) ->
      devlog 'playVideo'

      @video = document.createElement 'video'
      @video.src = track.src

      @setupVideoListeners @video, track

      # $('body').append(@video)

      @videoPlaying = true
      @video.play()

      @drawVideo(track)

    playSequence: (track) ->
      devlog 'playSequence'

      @sequenceStart = new Date()

      if track.src?
        @playVideo track
      else
        @drawSequence track

    drawSequence: (track) =>
      elapsed = (new Date() - @sequenceStart) / 1000
      track.callback.call(@, @aniContext, elapsed)

      if elapsed < track.duration
        requestAnimationFrame =>
          @drawSequence track
      else
        devlog 'end sequence'
        @aniContext.clearRect(0, 0,
                 @aniCanvas.width,
                 @aniCanvas.height)
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
      devlog 'ended'
      @videoPlaying = false
      @nextTrack()
