import PropTypes from 'prop-types';
import React, {Component} from 'react';
import {
  requireNativeComponent,
  View
} from 'react-native';

import PieRadarChartBase from './PieRadarChartBase';
import {pieData} from './ChartDataConfig';

class PieChart extends React.Component {
  getNativeComponentName() {
    return 'RNPieChart'
  }

  getNativeComponentRef() {
    return this.nativeComponentRef
  }

  render() {
    return <RNPieChart {...this.props} ref={ref => this.nativeComponentRef = ref} />;
  }
}

PieChart.propTypes = {
  ...PieRadarChartBase.propTypes,

  extraOffsets: PropTypes.shape({
    left: PropTypes.number,
    top: PropTypes.number,
    right: PropTypes.number,
    bottom: PropTypes.number
  }),

  drawEntryLabels: PropTypes.bool,
  usePercentValues: PropTypes.bool,

  centerText: PropTypes.string,
  styledCenterText: PropTypes.shape({
    text: PropTypes.string,
    color: PropTypes.number,
    fontFamily: PropTypes.string,
    size: PropTypes.number
  }),
  centerTextRadiusPercent: PropTypes.number,
  holeRadius: PropTypes.number,
  holeColor: PropTypes.number,
  transparentCircleRadius: PropTypes.number,
  transparentCircleColor: PropTypes.number,

  entryLabelColor: PropTypes.number,
  entryLabelTextSize: PropTypes.number,
  entryLabelFontFamily: PropTypes.string,
  maxAngle: PropTypes.number,

  // TODO PieChart should have only one dataset
  data: pieData
};

var RNPieChart = requireNativeComponent('RNPieChart', PieChart, {
  nativeOnly: {onSelect: true, onChange: true, onMarkerClick: true}
});

export default PieChart
