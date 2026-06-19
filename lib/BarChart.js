import PropTypes from 'prop-types';
import React, {Component} from 'react';
import {
  Platform,
  requireNativeComponent,
  View
} from 'react-native';

import BarLineChartBase from './BarLineChartBase';
import {barData} from './ChartDataConfig';
import MoveEnhancer from './MoveEnhancer'
import ScaleEnhancer from "./ScaleEnhancer";
import HighlightEnhancer from "./HighlightEnhancer";
import ScrollEnhancer from "./ScrollEnhancer";

class BarChart extends React.Component {
  getNativeComponentName() {
    return 'RNBarChart'
  }

  getNativeComponentRef() {
    return this.nativeComponentRef
  }

  render() {
    const {onChange, ...props} = this.props;
    const isFabric = !!global?.nativeFabricUIManager;
    // Legacy iOS: send both prop names so the event fires regardless of whether the
    // installed native binary predates the v2.5.66 onChange->onChartChange rename.
    const changeProps = Platform.OS === 'ios' && !isFabric ? {onChartChange: onChange, onChange} : {onChange};
    return <RNBarChart {...props} {...changeProps} ref={ref => this.nativeComponentRef = ref} />;
  }
}

BarChart.propTypes = {
  ...BarLineChartBase.propTypes,

  drawValueAboveBar: PropTypes.bool,
  drawBarShadow: PropTypes.bool,
  highlightFullBarEnabled: PropTypes.bool,
  barRadius: PropTypes.number,

  data: barData
}

var RNBarChart = requireNativeComponent('RNBarChart', BarChart, {
  nativeOnly: {onSelect: true, onChange: true, onChartChange: true, onMarkerClick: true}
})

export default ScrollEnhancer(HighlightEnhancer(ScaleEnhancer(MoveEnhancer(BarChart))))
