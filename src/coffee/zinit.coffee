$ ->
  window.faces = []
  window.player = new Player [
      camSequence
    ,
      testSequence
    ,
    #   playbackCamSequence
    # ,
      new VideoTrack
        src: '/assets/videos/short.mov'
        aspect: 16/9
    ,
      new VideoTrack
        src: '/assets/videos/ocean.mp4'
        aspect: 16/9
    ,
  ]

  $(window).resize ->
    player.setDimensions()
    # player.tracks[player.currentTrack].setDimensions()

  $(window).on 'click', ->
    $('h1').remove()
    player.play()

