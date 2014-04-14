$ ->
  window.faces = []
  window.player = new Player [
      camSequence
    ,
      testSequence
    ,
      playbackCamSequence
    ,
      new VideoTrack
        src: '/assets/videos/short.mov'
        aspect: 16/9
    ,
      playbackCamSequence
  ]

  $(window).resize ->
    player.setDimensions()
    # player.tracks[player.currentTrack].setDimensions()

  # $(window).on 'click', ->
  #   $('h1').remove()
  #   player.play()
