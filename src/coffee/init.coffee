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
