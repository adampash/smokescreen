$ ->
  window.dev = true
  window.log = (args) ->
    if false
      console.log.apply console,  arguments

  if dev
    $('body').append $('<script src="//localhost:35729/livereload.js"></script>')
