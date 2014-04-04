var isInsideSquare, triangleArea;

triangleArea = function(a, b, c) {
  return (c.x * b.y - b.x * c.y) - (c.x * a.y - a.x * c.y) + (b.x * a.y - a.x * b.y);
};

isInsideSquare = function(a, b, p) {
  if (p.x > a.x && p.x < b.x && p.y < a.y && p.y > b.y) {
    return true;
  } else {
    return false;
  }
};

//# sourceMappingURL=hitPoint.js.map
