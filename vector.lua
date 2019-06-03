function normalize(x, y)
  local length = length(x, y)
  if length ~= 0 and length ~= 1 then
    return x / length, y / length
  end

  return x, y
end

function length(x, y)
  return math.sqrt(x * x +  y * y)
end