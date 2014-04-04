triangleArea = (a,b,c) ->
  (c.x*b.y-b.x*c.y)-(c.x*a.y-a.x*c.y)+(b.x*a.y-a.x*b.y)

isInsideSquare = (a,b,p) ->
  if p.x > a.x and p.x < b.x and p.y < a.y and p.y > b.y
    true
  else
    false
  # if (triangleArea(a,b,p)>0 ||
  #     triangleArea(b,c,p)>0 ||
  #     triangleArea(c,d,p)>0 ||
  #     triangleArea(d,a,p)>0)
  #   false
  # else
  #   true
