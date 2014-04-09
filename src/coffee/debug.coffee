window.debug =
  frame: (frame) ->
    canvas = @createCanvas
              width: frame.width
              height: frame.height
    $('body').html canvas
    context = @createContext canvas
    context.putImageData frame, 0, 0

  createCanvas: (dimensions) ->
    canvas = document.createElement 'canvas'
    canvas.width = dimensions.width
    canvas.height = dimensions.height
    canvas

  createContext: (canvas) ->
    context = canvas.getContext '2d'

