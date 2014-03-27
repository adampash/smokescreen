$ ->
  window.player = new Player [
      camSequence
    ,
      playbackCamSequence
    ,
      new VideoTrack
        src: '/assets/videos/short.mov'
        aspect: 16/9
    ,
      testSequence
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

