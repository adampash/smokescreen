$ ->
  class window.Player
    constructor: (@tracks) ->
      @currentTrack = 0
      @videoPlaying = false

      @setDimensions()

    setDimensions: (canvas) ->
      @displayWidth = $(document).width()
      @displayHeight = $(document).height()

      @tracks[@currentTrack].setDimensions()

    play: (trackIndex) ->
      log 'play'
      if trackIndex?
        @currentTrack = trackIndex
        @queue @tracks[trackIndex]
      else if @currentTrack < @tracks.length
        @queue @tracks[@currentTrack]

    nextTrack: ->
      @currentTrack++
      @play()

    prevTrack: ->
      @currentTrack--
      @play()

    queue: (track) ->
      log 'queue', track

      track.play(
        @, =>
          @nextTrack()
      )

    addTrack: (track) ->
      @tracks.push track
      # @play(@tracks.length - 1)
