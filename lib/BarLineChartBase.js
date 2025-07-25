import PropTypes from 'prop-types';
import {
  View
} from 'react-native';

import ChartBase from './ChartBase';
import {yAxisIface} from './AxisIface';

const iface = {
  propTypes: {
    ...ChartBase.propTypes,
    maxHighlightDistance: PropTypes.number,
    drawGridBackground: PropTypes.bool,
    gridBackgroundColor: PropTypes.number,

    drawBorders: PropTypes.bool,
    borderColor: PropTypes.number,
    borderWidth: PropTypes.number,

    minOffset: PropTypes.number,
    maxVisibleValueCount: PropTypes.number,
    visibleRange: PropTypes.shape({
      x: PropTypes.shape({
        min: PropTypes.number,
        max: PropTypes.number
      }),
      y: PropTypes.shape({
        left: PropTypes.shape({
          min: PropTypes.number,
          max: PropTypes.number
        }),
        right: PropTypes.shape({
          min: PropTypes.number,
          max: PropTypes.number
        })
      })
    }),
    maxScale: PropTypes.shape({
      x: PropTypes.number,
      y: PropTypes.number
    }),
    autoScaleMinMaxEnabled: PropTypes.bool,
    keepPositionOnRotation: PropTypes.bool,

    highlightPerDragEnabled: PropTypes.bool,

    scaleEnabled: PropTypes.bool,
    scaleXEnabled: PropTypes.bool,
    scaleYEnabled: PropTypes.bool,
    dragEnabled: PropTypes.bool,
    pinchZoom: PropTypes.bool,
    doubleTapToZoomEnabled: PropTypes.bool,

    yAxis: PropTypes.shape({
      left: PropTypes.shape(yAxisIface),
      right: PropTypes.shape(yAxisIface)
    }),
    zoom: PropTypes.shape({
      scaleX: PropTypes.number,
      scaleY: PropTypes.number.isRequired,
      xValue: PropTypes.number.isRequired,
      yValue: PropTypes.number.isRequired,
      axisDependency: PropTypes.oneOf(['LEFT', 'RIGHT'])
    }),
    viewPortOffsets: PropTypes.shape({
      left: PropTypes.number,
      top: PropTypes.number,
      right: PropTypes.number,
      bottom: PropTypes.number
    }),
    extraOffsets: PropTypes.shape({
      left: PropTypes.number,
      top: PropTypes.number,
      right: PropTypes.number,
      bottom: PropTypes.number
    }),

    group: PropTypes.string,
    identifier: PropTypes.string,
    syncX: PropTypes.bool,
    syncY: PropTypes.bool,
    // whether the parent screen is currently locked to landscape mode.
    // This prop is a no-op for the native chart itself but is useful for
    // layout tweaks on the JS side. We still declare it here so React
    // Native doesn’t warn about an unknown prop.
    landscapeOrientation: PropTypes.bool,
  }
};

export default iface;
