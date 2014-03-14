window.Sequences =
  green:
    duration: 4
    play: (context) ->
      context.clearRect(0, 0,
                        @aniCanvas.width,
                        @aniCanvas.height)


      context.fillStyle = 'rgba(0, 100, 0, 0.4)'
      context.fillOpacity = 0.1
      context.fillRect(0, 0, 400, 400)
