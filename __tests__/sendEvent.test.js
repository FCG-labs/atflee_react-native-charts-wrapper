const assert = require('assert');
function computeLeft(leftBottomX, rightTopX, minX, maxX, spaceMin, spaceMax) {
  const allowedMin = minX - spaceMin;
  const allowedMax = maxX + spaceMax;
  const originalWidth = rightTopX - leftBottomX;
  let leftValue = leftBottomX;
  let rightValue = rightTopX;
  if (leftValue < allowedMin) {
    leftValue = allowedMin;
    rightValue = leftValue + originalWidth;
  }
  if (rightValue > allowedMax) {
    rightValue = allowedMax;
    leftValue = rightValue - originalWidth;
  }
  if (leftValue < allowedMin) leftValue = allowedMin;
  if (rightValue > allowedMax) rightValue = allowedMax;
  if (leftValue < 0) leftValue = 0;
  return leftValue;
}

assert.strictEqual(computeLeft(-5, 5, 0, 10, 0, 0) >= 0, true);
console.log('All tests passed');
