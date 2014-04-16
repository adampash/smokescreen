$ ->
  window.video = $('video')[0]
  window.audioIntensity = 0.5
  init = ->
    window.player = new PlayController()
    player.init()

    # start drawing webcam to player's record canvases

  init()




  # window.faces = []
  # window.player = new Player [
  #     camSequence
  #   ,
  #     testSequence
  #   ,
  #     playbackCamSequence
  #   ,
  #     new VideoTrack
  #       src: '/assets/videos/short.mov'
  #       aspect: 16/9
  #   ,
  #     playbackCamSequence
  # ]

  $(window).resize ->
    player.setDimensions()
  #   # player.tracks[player.currentTrack].setDimensions()

  # $(window).on 'click', ->
  #   $('h1').remove()
  #   video.play()
    # player.play()
