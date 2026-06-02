import React, {Component} from 'react';
import {
  Platform,
  requireNativeComponent,
  View
} from 'react-native';

import BarLineChartBase from './BarLineChartBase';
import {scatterData} from './ChartDataConfig';
import MoveEnhancer from './MoveEnhancer'
import ScaleEnhancer from "./ScaleEnhancer";
import HighlightEnhancer from "./HighlightEnhancer";
import ScrollEnhancer from "./ScrollEnhancer";

class ScatterChart extends React.Component {
  getNativeComponentName() {
    return 'RNScatterChart'
  }

  getNativeComponentRef() {
    return this.nativeComponentRef
  }

  render() {
    const {onChange, ...props} = this.props;
    const changeProps = Platform.OS === 'ios' ? {onChartChange: onChange} : {onChange};
    return <RNScatterChart {...props} {...changeProps} ref={ref => this.nativeComponentRef = ref} />;
  }
}

ScatterChart.propTypes = {
  ...BarLineChartBase.propTypes,

  data: scatterData
};

var RNScatterChart = requireNativeComponent('RNScatterChart', ScatterChart, {
  nativeOnly: {onSelect: true, onChange: true, onChartChange: true, onMarkerClick: true}
});

export default ScrollEnhancer(HighlightEnhancer(ScaleEnhancer(MoveEnhancer(ScatterChart))))
