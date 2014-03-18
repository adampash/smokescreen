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

