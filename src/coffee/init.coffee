$ ->
  window.player = new Player [
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
      CamSequence
  ]

  $(window).resize ->
    player.setDimensions()

  player.play()

