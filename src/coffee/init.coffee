$ ->
  window.player = new Player [
      type: 'video'
      src: '/assets/videos/short.mov'
      aspect: 16/9
    ,
      type: 'sequence'
      src: '/assets/videos/short.mov'
      callback: Sequences.green.play
      duration: Sequences.green.duration
      aspect: 16/9
    ,
      type: 'video'
      src: '/assets/videos/ocean.mp4'
      aspect: 16/9
  ]

  $(window).resize ->
    player.setDimensions()

  player.play()
