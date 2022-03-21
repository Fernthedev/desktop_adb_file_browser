T clamp<T extends num>(T val, [T? min, T? max]) {
  if (max != null && val > max) return max;
  if (min != null && val < min) return min;

  return val;
}
