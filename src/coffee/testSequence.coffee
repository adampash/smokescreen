window.Sequences =
  green:
    duration: 2
    play: (context, elapsed) ->
      x = elapsed * 100
      y = elapsed * 100
      context.clearRect(0, 0,
                        @aniCanvas.width,
                        @aniCanvas.height)


      context.fillStyle = 'rgba(0, 100, 0, 0.4)'
      context.fillOpacity = 0.1
      context.fillRect(x, y, 400, 400)
