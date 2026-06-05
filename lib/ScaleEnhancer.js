import React, {Component} from 'react';
import { UIManager, findNodeHandle} from 'react-native';


function getCommand(extendedChart, commandName) {
  if (global?.nativeFabricUIManager) {
    return commandName;
  }

  return UIManager.getViewManagerConfig(extendedChart.getNativeComponentName()).Commands[commandName];
}


export default function ScaleEnhancer(Chart) {
  return class ScaleExtended extends Chart {
    fitScreen() {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'fitScreen'),
        []
      );
    }

  }
}